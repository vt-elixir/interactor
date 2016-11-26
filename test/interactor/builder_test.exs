defmodule Interactor.BuilderTest do
  use ExUnit.Case

  defmodule Two do
    use Interactor.Builder

    interactor :two
    interactor :three
    interactor :four, assign_to: :for

    def two(i,_), do: assign(i, :two, "two")
    def three(_,_), do: "three"
    def four(_,_), do: "four"
  end


  defmodule One do
    use Interactor.Builder

    interactor :one
    interactor Two
    interactor :five

    def one(_,_), do: {:ok, "one"}
    def five(_,_), do: "five"
  end

  defmodule FailOne do
    use Interactor.Builder

    interactor :one
    interactor :two
    interactor :three

    def one(_,_), do: {:ok, "one"}
    def two(_,_), do: {:error, "error"}
    def three(_,_), do: {:ok, "three"}
  end

  test "success assigns" do
    interaction = %Interactor.Interaction{} = Interactor.call(One, %{})
    assert interaction.success
    assert interaction.assigns == %{
      one: "one",
      two: "two",
      three: "three",
      for: "four",
      five: "five",
    }
  end

  test "failure assigns" do
    interaction = %Interactor.Interaction{} = Interactor.call(FailOne, %{})
    refute interaction.success
    assert interaction.assigns == %{
      one: "one",
    }
    assert interaction.error == "error"
  end
end
