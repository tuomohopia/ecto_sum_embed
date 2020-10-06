defmodule EctoSumEmbedsTest do
  use ExUnit.Case

  describe "Works" do
    defmodule TestSchema do
      use Ecto.Schema
      import Ecto.Changeset

      schema "test_schema" do
        field(:name, :string)
      end

      def changeset(attrs) do
        %__MODULE__{}
        |> cast(attrs, [:name])
      end
    end

    test "Changeset works" do
      assert %Ecto.Changeset{} = TestSchema.changeset(%{name: "Elvis"})
    end
  end
end
