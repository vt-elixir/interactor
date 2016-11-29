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
    def rollback(interaction), do: Interaction.assign(interaction, :two, 0)
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

  test "call/2 - async - Interaction returned" do
    assert %Interaction{assigns: assigns} = Interactor.call(One, %{zero: 0}, strategy: :async)
    assert %{zero: 0, one: pid} = assigns
    assert is_pid(pid)
  end

  test "call/2 - task - Interaction returned" do
    assert %Interaction{} = int = Interactor.call(Two, %{zero: 0}, strategy: :task)
    assert %{zero: 0, two: %Task{}} = int.assigns
    int = Interactor.Strategy.Task.await(int)
    assert %{zero: 0, two: 2} = int.assigns
  end

  test "rollback/1" do
    assert %Interaction{} = int = Interactor.call(Two, %{zero: 0})
    assert %{zero: 0, two: 2} = int.assigns
    int = Interaction.rollback(int)
    assert %{zero: 0, two: 0} = int.assigns
  end
end
