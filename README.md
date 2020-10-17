# EctoSumEmbeds
[![Build Status](https://travis-ci.com/tuomohopia/ecto_sum_embed.svg?token=kkyD4t9rsytpc3U64M9V&branch=master)](https://travis-ci.com/tuomohopia/ecto_sum_embed)
> Embed sum types with `embeds_one_of` in Ecto
---

```elixir
defmodule Answer do
  use EctoSumEmbeds
  use Ecto.Schema
  import Ecto.Changeset

  schema "answers" do
    field :name, :string

    embeds_one_of :answer do 
      option :boolean, Boolean
      option :choose_one, ChooseOne

      opts tag_key: :tag, source: :answer, :on_replace: :raise
    end

    has_many :questions, Question
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:answer)
  end
end
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_sum_embeds` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_sum_embeds, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecto_sum_embeds](https://hexdocs.pm/ecto_sum_embeds).

