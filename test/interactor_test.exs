defmodule InteractorTest do
  use ExUnit.Case
  doctest Interactor

  defmodule Foo do
    use Ecto.Schema

    schema "foos" do
      field :foo, :string
    end
  end

  # We don't need to test ecto, just handle repo calls and return something.
  defmodule FakeRepo do
    def insert_or_update(changeset) do
      %Foo{foo: Ecto.Changeset.get_field(changeset, :foo)}
    end

    def transaction(fun) when is_function(fun), do: fun.()
    def transaction(%Ecto.Multi{} = multi) do
      foos = multi
              |> Ecto.Multi.to_list
              |> Enum.reduce(%{}, fn({key, {_, cs, _}}, m) ->
                Map.put(m, key, insert_or_update(cs))
              end)
      {:ok, foos}
    end
  end

  defmodule SimpleExample do
    use Interactor
    def handle_call(%{foo: bar}), do: {:ok, "foo" <> bar}
  end

  defmodule ChangesetExample do
    use Interactor, repo: FakeRepo
    import Ecto.Changeset
    def handle_call(params), do: cast(%Foo{}, params, [:foo])
  end

  defmodule MultiExample do
    use Interactor, repo: FakeRepo
    alias Ecto.Multi
    def handle_call(%{foo1: foo1, foo2: foo2}) do
      Multi.new
      |> Multi.insert(:foo1, ChangesetExample.handle_call(%{foo: foo1}))
      |> Multi.insert(:foo2, ChangesetExample.handle_call(%{foo: foo2}))
    end
  end

  test "simple - calling call" do
    assert {:ok, "foobar"} = Interactor.call(SimpleExample, %{foo: "bar"})
  end

  test "simple - calling call_task" do
    task = Interactor.call_task(SimpleExample, %{foo: "bar"})
    assert {:ok, "foobar"} = Task.await(task)
  end

  test "changeset - calling call" do
    foo = Interactor.call(ChangesetExample, %{foo: "bar"})
    assert foo.foo == "bar"
  end

  test "changeset - calling call_task" do
    task = Interactor.call_task(ChangesetExample, %{foo: "bar"})
    foo = Task.await(task)
    assert foo.foo == "bar"
  end

  test "multi - calling call_async" do
    results = Interactor.call_async(MultiExample, %{foo1: "bar", foo2: "baz"})
    assert {:ok, _} = results
  end

  test "multi - calling call_task" do
    task = Interactor.call_task(MultiExample, %{foo1: "bar", foo2: "baz"})
    assert {:ok, %{foo1: foo1, foo2: foo2}} = Task.await(task)
    assert foo1.foo == "bar"
    assert foo2.foo == "baz"
  end
end
