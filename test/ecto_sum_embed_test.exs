defmodule EctoSumEmbedTest do
  use ExUnit.Case

  describe "Sum embed" do
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
      use EctoSumEmbed
      use Ecto.Schema
      import Ecto.Changeset
      alias EctoSumEmbedTest.{Boolean, ChooseOne}

      schema "answers" do
        field :name, :string

        embeds_one_of :answer do
          option :boolean, Boolean
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

    test "Changeset produces correct polymorphic type" do
      # ChooseOne
      attrs = %{
        name: "Elvis",
        answer: %{tag: "choose_one", one: "happy"},
        choose_one_normal: %{one: "Good"}
      }

      changeset = Answer.changeset(attrs)
      assert %Ecto.Changeset{} = changeset

      assert %Answer{answer: %EctoSumEmbedTest.ChooseOne{}} =
               Ecto.Changeset.apply_changes(changeset)

      # Boolean
      attrs2 = %{
        name: "Elvis",
        answer: %{tag: "boolean", answer: true}
      }

      changeset2 = Answer.changeset(attrs2)
      assert %Ecto.Changeset{} = changeset

      assert %Answer{answer: %EctoSumEmbedTest.Boolean{}} =
               Ecto.Changeset.apply_changes(changeset2)
    end

    test "Cast failures" do
      attrs = %{
        name: 3,
        answer: %{tag: "whatever"},
        choose_one_normal: %{}
      }

      changeset = Answer.changeset(attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
    end
  end
end
