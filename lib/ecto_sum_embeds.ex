defmodule EctoSumEmbeds do
  @moduledoc """
  Adds `:embeds_one_of` functionality to Ecto Schema

  Also brings `cast_sum_embed/3` to scope.
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import EctoSumEmbeds
    end
  end

  defmacro option(name, schema, opts \\ []) do
    IO.inspect(name, label: "option name")
    IO.inspect(__ENV__, label: "env")

    quote do
      EctoSumEmbeds.option(__MODULE__, unquote(name), unquote(schema), unquote(opts))
    end
  end

  defmacro embeds_one_of(name, do: block) do
    IO.puts(
      "------------------------------------------------------------------------------------------------------"
    )

    # Add `name` (name of the polymorphic field) as the first
    # parameter to `option/
    prewalk_result =
      Macro.prewalk(block, fn expr ->
        case expr do
          {:option, line, args} -> {:option, line, [name] ++ args}
          whatever -> whatever
        end
      end)

    IO.inspect(prewalk_result, label: "prewalk result")

    IO.inspect(name, label: "name")
    IO.inspect(block, label: "do block")

    IO.puts(
      "------------------------------------------------------------------------------------------------------"
    )
  end

  defmacro embeds_one_of(name, opts) when is_list(opts) do
    # IO.inspect(schema, label: "schema before")
    # schema = expand_alias(schema, __CALLER__)
    # IO.inspect(schema, label: "schema after")

    caller = __CALLER__.module
    IO.inspect(caller, label: "caller module")

    module_name =
      name
      |> Atom.to_string()
      |> Macro.camelize()
      |> String.to_atom()

    IO.inspect(module_name, label: "module name")

    quote do
      {:module, module, _binary, _term} =
        EctoSumEmbeds.create_embedded_module(unquote(name), unquote(caller), unquote(opts))

      IO.inspect(module, label: "created module")

      Ecto.Schema.__embeds_one__(__MODULE__, unquote(name), module, [])
    end
  end

  def create_embedded_module(field, base_module, opts) do
    module_name =
      field
      |> Atom.to_string()
      |> Macro.camelize()

    module = Atom.to_string(base_module) <> "." <> module_name
    module = String.to_atom(module)

    IO.inspect(opts, label: "opts")

    ast =
      quote do
        use Ecto.Schema
        alias Ecto.Changeset

        @tag_key :tag

        # Add sum type members to generated module attributes
        :ok = Module.register_attribute(__MODULE__, :ecto_sum_embeds, accumulate: false)
        :ok = Module.put_attribute(__MODULE__, :ecto_sum_embeds, %{})

        :ok =
          Enum.each(unquote(opts), fn {tag, member} ->
            IO.inspect(member, label: "member")
            # Module.put_attribute(__MODULE__, :ecto_sum_embeds, {to_string(key), member})
            # Module.put_attribute(__MODULE__, :ecto_sum_embeds, Map.new([{key, member}]))
            EctoSumEmbeds.add_to_attribute(
              __MODULE__,
              :ecto_sum_embeds,
              {to_string(tag), member}
            )
          end)

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
              struct = struct(embedded_module)
              Kernel.apply(embedded_module, :changeset, [struct, params])

            :error ->
              custom = [validation: :cast, type: :ecto_sum_embeds]

              Changeset.cast(%__MODULE__{}, %{}, [])
              |> Changeset.add_error(@tag_key, "cannot detect correct type", custom)
          end
        end

        # Default function
        defp get_module(params, tag_key) do
          with {:ok, tag} <- Map.fetch(params, tag_key),
               {:ok, module} <- Map.fetch(@ecto_sum_embeds, tag) do
            {:ok, module}
          end
        end
      end

    Module.create(module, ast, Macro.Env.location(__ENV__))
  end

  def add_to_attribute(module, attribute, {key, value}) do
    current = Module.get_attribute(module, attribute)
    updated = Map.put(current, key, value)
    Module.put_attribute(module, attribute, updated)
  end

  def option(mod, name, schema, opts) do
  end

  defp expand_alias({:__aliases__, _, _} = ast, env),
    do: Macro.expand(ast, %{env | function: {:__schema__, 2}})

  defp expand_alias(ast, _env),
    do: ast
end
