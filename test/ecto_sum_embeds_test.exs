defmodule EctoSumEmbedsTest do
  use ExUnit.Case

  describe "Works" do
    defmodule Boolean do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :answer, :boolean
      end

      def changeset(schema \\ %__MODULE__{}, attrs) do
        schema
        |> cast(attrs, [:answer])
      end
    end

    defmodule ChooseOne do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :one, :string
      end

      def changeset(schema \\ %__MODULE__{}, attrs) do
        schema
        |> cast(attrs, [:one])
        |> validate_required([:one])
      end
    end

    defmodule Answer do
      use EctoSumEmbeds
      use Ecto.Schema
      import Ecto.Changeset

      schema "answers" do
        field :name, :string
        embeds_one_of :answer, choose_one: ChooseOne, boolean: Boolean

        embeds_one_of :hello do
          option :foo, :string
          field :bar, :string
          option :choose_one, ChooseOne
        end

        embeds_one :choose_one_normal, ChooseOne
      end

      def changeset(attrs) do
        %__MODULE__{}
        |> cast(attrs, [:name])
        |> cast_embed(:choose_one_normal)
        |> cast_embed(:answer)
        |> validate_required([:name, :answer, :choose_one_normal])
      end
    end

    test "Changeset works" do
      attrs = %{
        name: "Elvis",
        answer: %{tag: "choose_one", one: "happy"},
        choose_one_normal: %{one: "Good"}
      }

      assert %Ecto.Changeset{} = Answer.changeset(attrs)
      # Answer.Answer.hello()

      IO.inspect(Answer.changeset(attrs) |> Ecto.Changeset.apply_changes(),
        label: "Changeset after applying"
      )
    end

    test "Cast failures" do
      attrs = %{
        name: 3,
        answer: %{tag: "whatever"},
        choose_one_normal: %{}
      }

      changeset = Answer.changeset(attrs)
      assert %Ecto.Changeset{} = changeset

      IO.inspect(changeset, label: "cast failure changeset")
    end
  end
end
