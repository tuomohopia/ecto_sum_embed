defmodule EctoSumEmbedTest do
  use ExUnit.Case

  describe "Changeset" do
    defmodule Citizen.Professional do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :tag, :string, default: "professional"
        field :employer, :string
        field :position, :string
      end

      def changeset(schema \\ %__MODULE__{}, attrs) do
        schema
        |> cast(attrs, [:employer])
        |> validate_required([:employer])
      end
    end

    defmodule Citizen.Student do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false
      embedded_schema do
        field :tag, :string, default: "student"
        field :school, :string
        field :enrollment_year, :integer
      end

      def changeset(schema \\ %__MODULE__{}, attrs) do
        schema
        |> cast(attrs, [:school, :enrollment_year])
        |> validate_required([:school])
      end
    end

    defmodule Citizen do
      use EctoSumEmbed
      use Ecto.Schema
      import Ecto.Changeset
      alias __MODULE__.{Student, Professional}

      schema "citizens" do
        field :name, :string

        embeds_one_of :profession do
          option :student, Student
          option :professional, Professional
        end

        embeds_one :job, Professional
      end

      def changeset(attrs) do
        %__MODULE__{}
        |> cast(attrs, [:name])
        |> cast_embed(:job)
        |> cast_embed(:profession)
        |> validate_required([:name, :profession, :job])
      end
    end

    # setup do
    #   professional =
    # end

    test "produces correct sum type when external parameters have a valid tag and value" do
      professional_attrs = %{
        name: "Elvis",
        profession: %{tag: "professional", employer: "NASA"},
        job: %{employer: "government"}
      }

      professional_changeset = Citizen.changeset(professional_attrs)
      assert %Ecto.Changeset{valid?: true} = professional_changeset

      assert %Citizen{
               profession: %EctoSumEmbedTest.Citizen.Professional{employer: "NASA"},
               job: %EctoSumEmbedTest.Citizen.Professional{employer: "government"}
             } = Ecto.Changeset.apply_changes(professional_changeset)

      # Boolean
      attrs2 = %{
        name: "Elvis",
        profession: %{tag: "student", school: "MIT"}
      }

      changeset2 = Citizen.changeset(attrs2)
      assert %Ecto.Changeset{} = changeset2

      assert %Citizen{profession: %EctoSumEmbedTest.Citizen.Student{school: "MIT"}} =
               Ecto.Changeset.apply_changes(changeset2)
    end

    test "produces a failure changeset when no `profession` tag supplied" do
      attrs = %{
        name: 3,
        hello: %{tag: "whatever"},
        job: %{}
      }

      changeset = Citizen.changeset(attrs)
      assert %Ecto.Changeset{valid?: false} = changeset
      assert %Citizen{profession: nil} = Ecto.Changeset.apply_changes(changeset)
    end

    test "produces a failure changeset when faulty `profession` tag value" do
      attrs = %{
        name: "Preston",
        profession: %{tag: "whatever"},
        job: %{}
      }

      changeset = Citizen.changeset(attrs)
      IO.inspect(changeset, label: "changeset")
      IO.inspect(changeset |> Ecto.Changeset.apply_changes(), label: "changeset")
      assert %Ecto.Changeset{valid?: false} = changeset
      assert %Citizen{profession: nil} = Ecto.Changeset.apply_changes(changeset)
    end
  end
end
