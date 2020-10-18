defmodule EctoSumEmbed.ChangesetTest do
  @moduledoc false
  use EctoSumEmbed.DataCase, async: true

  alias EctoSumEmbed.Support.Citizen
  alias EctoSumEmbed.Support.Citizen.Student
  alias EctoSumEmbed.Support.NormalCitizen
  alias Ecto.Changeset

  require EctoSumEmbed

  def attrs_fixture do
    prof_valid = %{
      name: "Elvis",
      profession: %{tag: "professional", employer: "NASA"}
    }

    student_valid = %{
      name: "Presley",
      profession: %{tag: "student", school: "MIT"}
    }

    grad_valid = %{
      name: "Jack",
      profession: %{tag: "graduate", degree: "MBA"}
    }

    empty = %{
      name: "Jack"
    }

    invalid_tag_value = %{
      name: "Jack",
      profession: %{tag: "hello", degree: "MBA"}
    }

    invalid_tag_key = %{
      name: "Jack",
      profession: %{type: "student", school: "MIT"}
    }

    %{
      valid: [prof_valid, student_valid, grad_valid],
      invalid: [empty, invalid_tag_value, invalid_tag_key]
    }
  end

  describe "cast_embed/3 from embeds_one_of schema" do
    setup do
      attrs_fixture()
    end

    test "behaves identically at changeset level with embeds_one with valid attrs with default tag",
         %{
           valid: [_prof, student | _grad]
         } do
      normal_student_attrs = %{name: student.name, student: student.profession}
      normal_changeset = NormalCitizen.changeset(normal_student_attrs)
      sum_changeset = Citizen.changeset(student)
      # Assertions
      assert %Changeset{valid?: true} = sum_changeset
      assert normal_changeset.changes.name == sum_changeset.changes.name
      assert normal_changeset.changes.student == sum_changeset.changes.profession
      assert normal_changeset.changes.student.data == sum_changeset.changes.profession.data
      # Changes applied
      normal_applied = Changeset.apply_changes(normal_changeset)
      sum_applied = Changeset.apply_changes(sum_changeset)
      # Assertions
      assert normal_applied.name == sum_applied.name
      assert normal_applied.id == sum_applied.id
      assert normal_applied.student == sum_applied.profession
    end
  end

  describe "put_embed_of/4" do
    setup do
      attrs_fixture()
    end

    test "behaves identically with Ecto's native put_embed/4",
         %{
           valid: [_prof, student | _grad]
         } do
      # Make valid embedded changeset
      student_embedded_attrs = %{school: student.profession.school}
      student_changeset = Student.changeset(student_embedded_attrs)
      assert %Changeset{valid?: true} = student_changeset

      # Make Citizen and NormalCitizen changesets without embed
      attrs = %{name: student.name}
      normal_changeset = NormalCitizen.changeset(attrs)
      sum_changeset = Citizen.changeset(attrs)
      assert %Changeset{valid?: false} = normal_changeset
      assert %Changeset{valid?: false} = sum_changeset

      # Put embeds
      normal_with_embed = Changeset.put_embed(normal_changeset, :student, student_changeset)
      # use custom `put_embed_of`
      sum_with_embed = EctoSumEmbed.put_embed_of(sum_changeset, :profession, student_changeset)
      assert normal_with_embed.changes.student == sum_with_embed.changes.profession
    end
  end
end
