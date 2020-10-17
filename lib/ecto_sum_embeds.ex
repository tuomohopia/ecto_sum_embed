defmodule EctoSumEmbeds do
  @moduledoc """
  Adds `:embeds_one_of` functionality to Ecto Schemas.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import EctoSumEmbeds
    end
  end

  defmacro option(caller, field, schema) do
    schema_full = Macro.expand(schema, caller)

    quote do
      EctoSumEmbeds.__option__(__MODULE__, unquote(field), unquote(schema_full))
    end
  end

  defmacro embeds_one_of(name, do: block) when is_atom(name) do
    # 1. Add `__CALLER__` to each `option/3` arguments for constructing
    # full embedded schema module path.
    block =
      Macro.prewalk(block, fn expr ->
        case expr do
          {:option, line, args} ->
            {:option, line, [__CALLER__] ++ args}

          whatever ->
            whatever
        end
      end)

    caller = __CALLER__.module

    quote do
      # Create host module
      # whose `changeset/2` determines which type to give back to caller
      {:module, module, _binary, _term} =
        EctoSumEmbeds.create_embedded_module(
          unquote(name),
          unquote(caller),
          unquote(Macro.escape(block))
        )

      # Embeds the macro-generated host `embedded_schema` module
      # so that that module can catch `cast_embed/3` calls.
      Ecto.Schema.__embeds_one__(__MODULE__, unquote(name), module, [])
    end
  end

  def create_embedded_module(field, base_module, option_ast) do
    module_name =
      field
      |> Atom.to_string()
      |> Macro.camelize()

    module = Atom.to_string(base_module) <> "." <> module_name
    module = String.to_atom(module)

    ast =
      quote do
        use Ecto.Schema
        alias Ecto.Changeset
        use EctoSumEmbeds

        @tag_key :tag

        # Add sum type members to generated module attributes
        :ok = Module.register_attribute(__MODULE__, :ecto_sum_embeds, accumulate: false)
        :ok = Module.put_attribute(__MODULE__, :ecto_sum_embeds, %{})

        unquote(option_ast)

        @primary_key false
        embedded_schema do
        end

        def changeset(module, params) do
          # Infer cast embedded schema module
          case get_module(params, :tag) do
            {:ok, embedded_module} ->
              struct = struct(embedded_module)
              # Then use that module's `changeset/2`
              Kernel.apply(embedded_module, :changeset, [struct, params])

            :error ->
              custom = [validation: :cast, type: :ecto_sum_embeds]

              tag_values =
                @ecto_sum_embeds
                |> Map.keys()
                |> Enum.map(&to_string/1)
                |> Enum.join(", ")

              err_msg =
                "Cannot detect correct embed sum type member. Supplied tag key :#{@tag_key} value should be one of: #{
                  tag_values
                }"

              %__MODULE__{}
              |> Changeset.cast(%{}, [])
              |> Changeset.add_error(@tag_key, err_msg, custom)
          end
        end

        # Default polymorhic inference function
        # that takes the external data and picks
        # the correct polymorphic member.
        defp get_module(params, tag_key) do
          case Map.fetch(params, tag_key) do
            {:ok, tag} ->
              Map.fetch(@ecto_sum_embeds, tag)

            _ ->
              :error
          end
        end
      end

    Module.create(module, ast, Macro.Env.location(__ENV__))
  end

  def __option__(mod, name, schema) do
    pair = {to_string(name), schema}
    add_to_attribute(mod, :ecto_sum_embeds, pair)
  end

  # Internal

  defp add_to_attribute(module, attribute, {key, value}) do
    current = Module.get_attribute(module, attribute)
    updated = Map.put(current, key, value)
    Module.put_attribute(module, attribute, updated)
  end
end
