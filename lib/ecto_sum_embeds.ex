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

  defmacro embeds_one_of(name, [schema, _]) do
    IO.inspect(schema, label: "schema before")
    schema = expand_alias(schema, __CALLER__)
    IO.inspect(schema, label: "schema after")

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
        EctoSumEmbeds.create_embedded_module(unquote(name), unquote(caller), unquote(schema))

      IO.inspect(module, label: "created module")

      Ecto.Schema.__embeds_one__(__MODULE__, unquote(name), module, [])
    end
  end

  def create_embedded_module(field, base_module, _attrs) do
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

        # Add sum type members to generated module attributes
        Module.register_attribute(__MODULE__, :ecto_sum_embeds, accumulate: true)

        @primary_key false
        embedded_schema do
        end

        def changeset(module, params) do
          IO.inspect(module, label: "changeset module")
          IO.inspect(module, label: "changeset params")
          Changeset.cast(module, params, [])
        end
      end

    Module.create(module, ast, Macro.Env.location(__ENV__))
  end

  defp expand_alias({:__aliases__, _, _} = ast, env),
    do: Macro.expand(ast, %{env | function: {:__schema__, 2}})

  defp expand_alias(ast, _env),
    do: ast
end
