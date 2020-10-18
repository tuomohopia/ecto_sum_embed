defmodule EctoSumEmbed.DataCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import EctoSumEmbed.DataCase
      # Support modules
      alias EctoSumEmbed.Support.Citizen
      alias EctoSumEmbed.Support.Citizen.{Professional, Student, Graduate}
      alias EctoSumEmbed.Support.NormalCitizen
      # Ecto
      alias Ecto.Changeset
    end
  end
end
