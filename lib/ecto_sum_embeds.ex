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
    caller = __CALLER__

    # 1. Add caller to `option/3` arguments for constructing
    # full embedded schema module path.
    ast_with_option_converted =
      Macro.prewalk(block, fn expr ->
        case expr do
          {:option, line, args} ->
            {:option, line, [caller] ++ args}

          whatever ->
            whatever
        end
      end)

    # 2. `option/3` registers
    caller = __CALLER__.module

    quote do
      # Create host module
      # whose `changeset/2` determines which type to give back to caller
      {:module, module, _binary, _term} =
        EctoSumEmbeds.create_embedded_module(
          unquote(name),
          unquote(caller),
          unquote(Macro.escape(ast_with_option_converted))
        )

      # Puts the attributes to `__MODULE__` which means `Answer` in my example.
      # It embeds the macro-generated `module`, based on the `embeds_one_of` name to it
      # as the only `embeds_one` module. This is so that `cast_embed` from the main Changeset
      # will trigger this module's `changeset/2` where the polymorphic determination happens.
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
          # Infer cast embedded schema module first
          # Then use that module's Changeset
          case get_module(params, :tag) do
            {:ok, embedded_module} ->
              struct = struct(embedded_module)
              Kernel.apply(embedded_module, :changeset, [struct, params])

            :error ->
              custom = [validation: :cast, type: :ecto_sum_embeds]

              tag_values =
                @ecto_sum_embeds
                |> Map.keys()
                |> Enum.map(&to_string/1)
                |> Enum.join(", ")

              err_msg =
                "Cannot detect correct polymorphic type. Supplied tag key :#{@tag_key} value should be one of: #{
                  tag_values
                }"

              %__MODULE__{}
              |> Changeset.cast(%{}, [])
              |> Changeset.add_error(@tag_key, err_msg, custom)
          end
        end

        # Default function
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
    add_to_attribute(
      mod,
      :ecto_sum_embeds,
      {to_string(name), schema}
    )
  end

  # Internal

  defp add_to_attribute(module, attribute, {key, value}) do
    current = Module.get_attribute(module, attribute)
    updated = Map.put(current, key, value)
    Module.put_attribute(module, attribute, updated)
  end
end
