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

  defmacro option(caller, _embeds_one_of, field, schema) do
    opts = []
    schema_full = Macro.expand(schema, caller)

    quote do
      EctoSumEmbeds.__option__(__MODULE__, unquote(field), unquote(schema_full), unquote(opts))
    end
  end

  defmacro embeds_one_of(name, do: block) when is_atom(name) do
    IO.puts("defmacro embeds_one_of")
    caller = __CALLER__

    # 1. Add `name` (name of the polymorphic field) as the first
    # parameter to `option/3`
    ast_with_option_converted =
      Macro.prewalk(block, fn expr ->
        case expr do
          {:option, line, args} ->
            {:option, line, [caller, name] ++ args}

          whatever ->
            whatever
        end
      end)

    # 2. `option/3` registers
    caller = __CALLER__.module
    IO.puts("entering embeds_one_of quote")

    quote do
      # Create host module
      # whose `changeset/2` determines which type to give back to caller
      {:module, module, _binary, _term} =
        EctoSumEmbeds.create_embedded_module(
          unquote(name),
          unquote(caller),
          unquote(Macro.escape(ast_with_option_converted))
        )

      IO.inspect(module, label: "created module")

      # Puts the attributes to `__MODULE__` which means `Answer` in my example.
      # It embeds the macro-generated `module`, based on the `embeds_one_of` name to it
      # as the only `embeds_one` module. This is so that `cast_embed` from the main Changeset
      # will trigger this module's `changeset/2` where the polymorphic determination happens.
      Ecto.Schema.__embeds_one__(__MODULE__, unquote(name), module, [])
    end
  end

  def create_embedded_module(field, base_module, option_ast) do
    IO.puts("def create_embedded_module")
    IO.inspect(option_ast, label: "option ast")

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
          IO.inspect(module, label: "changeset module")
          IO.inspect(params, label: "changeset params")
          IO.inspect(@ecto_sum_embeds, label: "attributes")
          # Infer cast embedded schema module first
          # Then use that module's Changeset
          case get_module(params, :tag) do
            {:ok, embedded_module} ->
              IO.inspect(embedded_module, label: "embedded module")
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
                "Cannot detect correct polymorphic type. Supplied #{@tag_key} value should be one of: #{
                  tag_values
                }"

              %__MODULE__{}
              |> Changeset.cast(%{}, [])
              |> Changeset.add_error(@tag_key, err_msg, custom)
          end
        end

        # Default function
        defp get_module(params, tag_key) do
          IO.puts("def get_module")

          with {:ok, tag} <- Map.fetch(params, tag_key),
               {:ok, module} <- Map.fetch(@ecto_sum_embeds, tag) do
            {:ok, module}
          end
        end
      end

    Module.create(module, ast, Macro.Env.location(__ENV__))
  end

  def add_to_attribute(module, attribute, {key, value}) do
    IO.puts("def add_to_attribute")
    IO.inspect(module, label: "add_to_attribute mod:")
    current = Module.get_attribute(module, attribute)
    IO.inspect(current, label: "current")
    updated = Map.put(current, key, value)
    Module.put_attribute(module, attribute, updated)
  end

  def __option__(mod, name, schema, _opts) do
    IO.puts("def __option__")
    IO.inspect(Module.get_attribute(mod, :ecto_sum_embeds), label: ":ecto_sum_embeds fields")

    add_to_attribute(
      mod,
      :ecto_sum_embeds,
      {to_string(name), schema}
    )
  end
end
