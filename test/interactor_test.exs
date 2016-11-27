defmodule InteractorTest do
  use ExUnit.Case
  doctest Interactor
  alias Interactor.Interaction

  defmodule One do
    @behaviour Interactor
    def call(%Interaction{} = int, _opts), do: Interaction.assign(int, :one, 1)
  end

  defmodule Two do
    @behaviour Interactor
    def call(_interaction, _opts), do: {:ok, 2}
  end

  defmodule Fail do
    @behaviour Interactor
    def call(_interaction, _opts), do: {:error, "error"}
  end

  test "call/2 - %Interaction{} returned" do
    assert %Interaction{assigns: assigns} = Interactor.call(One, %{zero: 0})
    assert assigns == %{zero: 0, one: 1}
  end

  test "call/2 - {:ok, 2} returned" do
    assert %Interaction{assigns: assigns} = Interactor.call(Two, %{zero: 0})
    assert assigns == %{zero: 0, two: 2}
  end

  test "call/3 - {:ok, 2} returned - with assign to" do
    assert %Interaction{assigns: assigns} = Interactor.call(Two, %{zero: 0}, assign_to: :too)
    assert assigns == %{zero: 0, too: 2}
  end

  test "call/2 - {:error, 2} returned" do
    assert %Interaction{success: false, error: "error", assigns: %{zero: 0}} =
      Interactor.call(Fail, %{zero: 0})
  end

end
