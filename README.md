# EctoSumEmbed
[![Build Status](https://travis-ci.com/tuomohopia/ecto_sum_embed.svg?token=kkyD4t9rsytpc3U64M9V&branch=master)](https://travis-ci.com/tuomohopia/ecto_sum_embed)
> Embed sum types with `embeds_one_of` in Ecto
---

Allow embedding multiple types as the `embeds_one` type in Ecto Schemas.

Instead of defining `embeds_one` we would define `embeds_one_of` instead,
defining a sum type whose each member is an embedded schema.

### Example

```elixir
defmodule Citizen do
  use EctoSumEmbeds # Import library to scope
  use Ecto.Schema
  import Ecto.Changeset
  alias Citizen.{Student, Graduate, Professional}

  schema "citizen" do
    field :name, :string
    field birth_year:, :integer

    embeds_one_of :profession do # `:profession` is the field name
      option :student, Student # Sum member types
      option :graduate, Graduate
      option :professional, Professional
    end
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name])
    |> cast_embed(:answer) # Cast sum embeds using Ecto's own `cast_embed/3`
  end
end
```

Here `Student`, `Graduate` and `Professional` modules are normal
embedded schema modules with their own validation logic.

However, we need to add a field `:tag` with a default string value matching
each `option` second parameter atom. This is so that we can infer the right embedded schema to use
when pulling the record from the database.

The tag key can be configured with `:tag_key` option. See OPTIONS for reference

```elixir
defmodule Citizen.Student do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :tag, :string, default: "student" 
    field :school, :string
    field :enrollment_year, :integer
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:school, :enrollment_year]) # do not cast `:tag`
    |> validate_required([:school])
  end
end
```

Ecto Sum Embed defaults to using the first paramter to `option` as the
tag value determining what type.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_sum_embed` to your list of dependencies in `mix.exs`:

### Dependency

```elixir
def deps do
  [
    {:ecto_sum_embed, "~> 0.1.0"}
  ]
end
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_sum_embed](https://hexdocs.pm/ecto_sum_embed).

### Formatter

Add formatter rules for `option` and `opts` for

## Defining options

You can customize the behavior by adding configuration options after `opts` 
inside the `embeds_one_of` `do`-block:

```elixir
defmodule Citizen.Student do
  use Ecto.Schema
  import Ecto.Changeset

  schema "citizen" do
    field :name, :string

    embeds_one_of :profession do
      option :student, Student
      option :graduate, Graduate

      opts tag_key: :type, on_replace: :delete
    end
end
```
And with each associated type, we redefine the tagged union key to `type`:
```elixir
defmodule Citizen.Student do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :type, :string, default: "student" # this is now `:type` as configured with `opts`
    field :school, :string
  end
end
```

### Options

On top of allowing to use Ecto's native `:on_replace` and `:source` this library only defines one additional configuration option: `:tag_key`.
`:tag_key` is the key that needs to be present in all external data structures to be cast with `cast_embed`. Its value needs to match with one and only one of the sum type member `:tag_key` values.

* `:tag_key` - The key that holds the value which is used to determine the actual type.
  If you change this key, remember to also change each member `embedded_schema`'s key accordingly. Default: `:tag`.
* `:on_replace` - Same as `embeds_one` from Ecto: https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3-options
* `:source` - Same as `embeds_one` from Ecto: https://hexdocs.pm/ecto/Ecto.Schema.html#embeds_one/3-options
