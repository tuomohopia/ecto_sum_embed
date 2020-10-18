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
  use EctoSumEmbeds
  use Ecto.Schema
  import Ecto.Changeset
  alias Citizen.{Student, Graduate, Professional}

  schema "citizen" do
    field :name, :string
    field birth_year: :integer

    embeds_one_of :profession do
      option :student, Student # sum member types
      option :graduate, Graduate
      option :professional, Professional

      opts tag_key: :tag, source: :answer, :on_replace: :raise
    end
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:answer) # cast 
  end
end
```

Here `Student`, `Graduate` and `Professional` modules are normal
embedded schema modules with their own validation logic. No need
to import `ecto_sum_embeds` here.

```elixir
defmodule Citizen.Student do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :school, :string
    field :enrollment_year, :integer
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:school, :enrollment_year])
    |> validate_required([:school])
  end
end
```

Ecto Sum Embed defaults to using the first paramter to `option` as the
tag value determining what type...

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

### Formatter

Add formatter rules for `option` and `opts` for 

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_sum_embed](https://hexdocs.pm/ecto_sum_embed).

