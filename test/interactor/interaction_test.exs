defmodule Interactor.InteractionTest do
  use ExUnit.Case
  alias Interactor.Interaction
  import Interaction

  test "assigns" do
    assert %Interaction{assigns: %{foo: :bar}} ==
      assign(%Interaction{}, :foo, :bar)
  end

  test "add_rollback" do
    assert %Interaction{rollback: []} ==
      add_rollback(%Interaction{}, nil)

    assert %Interaction{rollback: [{Foo, :bar}]} ==
      add_rollback(%Interaction{}, {Foo, :bar})
  end

  test "rollback" do
    interaction = %Interaction{}
                  |> add_rollback({__MODULE__, :rollback1})
                  |> add_rollback({__MODULE__, :rollback2})

    assert %Interaction{assigns: %{one: 1, two: 2}} =
      rollback(interaction)
  end

  def rollback1(int), do: assign(int, :one, 1)
  def rollback2(int), do: assign(int, :two, 2)
end
