defmodule EctoSumEmbed.Support.Citizen.Professional do
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

defmodule EctoSumEmbed.Support.Citizen.Student do
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

# Using `embeds_one_of`

defmodule EctoSumEmbed.Support.Citizen do
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
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:profession)
    |> validate_required([:name, :profession])
  end
end

# Normal schema using `embeds_one`

defmodule EctoSumEmbed.Support.NormalCitizen do
  use EctoSumEmbed
  use Ecto.Schema
  import Ecto.Changeset
  alias EctoSumEmbed.Support.Citizen.Student

  schema "normal_citizens" do
    field :name, :string

    embeds_one :student, Student
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name])
    |> cast_embed(:student)
    |> validate_required([:name, :student])
  end
end
