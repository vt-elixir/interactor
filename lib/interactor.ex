defmodule Interactor do
  use Behaviour
  alias Interactor.TaskSupervisor

  @moduledoc """
  A tool for modeling events that happen in your application.

  TODO: More on interactor concept

  Interactor provided a behaviour and functions to execute the behaviours.

  To use simply `use Interactor` in a module and implement the `handle_call/1`
  callback. When `use`-ing you can optionaly include a Repo option which will
  be used to execute any Ecto.Changesets or Ecto.Multi structs you return.

  Interactors supports three callbacks:

    * `before_call/1` - Useful for manipulating input etc.
    * `handle_call/1` - The meat, usually returns an Ecto.Changeset or Ecto.Multi.
    * `after_call/1` - Useful for metrics, publishing events, etc

  Interactors can be called in three ways:

    * `Interactor.call/2` - Executes callbacks, optionaly insert, and return results.
    * `Interactor.call_task/2` - Same as call, but returns a `Task` that can be awated on.
    * `Interactor.call_aysnc/2` - Same as call, but does not return results.

  Example:

      defmodule CreateArticle do
        use Interactor, repo: Repo

        def handle_call(%{attributes: attrs, author: author}) do
          cast(%Article{}, attrs, [:title, :body])
          |> put_change(:author_id, author.id)
        end
      end

      Interactor.call(CreateArticle, %{attributes: params, author: current_user})
  """

  @doc """
  The primary callback. Typically returns an Ecto.Changeset or an Ecto.Multi.
  """
  @callback handle_call(map) :: any

  @doc """
  A callback executed before handle_call. Useful for normalizing inputs.
  """
  @callback before_call(map) :: map

  @doc """
  A callback executed after handle_call and after the Repo executes.

  Useful for publishing events, tracking metrics, and other non-transaction
  worthy calls.
  """
  @callback after_call(any) :: any

  @doc """
  Executes the `before_call/1`, `handle_call/1`, and `after_call/1` callbacks.

  If an Ecto.Changeset or Ecto.Multi is returned by `handle_call/1` and a
  `repo` options was passed to `use Interactor` the changeset or multi will be
  executed and the results returned.
  """
  @spec call_task(module, map) :: Task.t
  def call(interactor, context) do
    context
    |> interactor.before_call
    |> interactor.handle_call
    |> Interactor.Handler.handle(interactor.__repo)
    |> interactor.after_call
  end

  @doc """
  Wraps `call/2` in a supervised Task. Returns the Task.

  Useful if you want async, but want to await results.
  """
  @spec call_task(module, map) :: Task.t
  def call_task(interactor, map) do
    Task.Supervisor.async(TaskSupervisor, Interactor, :call, [interactor, map])
  end

  @doc """
  Executes `call/2` asynchronously via a supervised task. Returns {:ok, pid}.

  Primary use case is task you want completely asynchronos with no care for
  return values.
  """
  @spec call_async(module, map) :: {:ok, pid}
  def call_async(interactor, map) do
    Task.Supervisor.start_child(TaskSupervisor, Interactor, :call, [interactor, map])
  end

  defmacro __using__(opts) do
    quote do
      @behaviour Interactor
      @doc false
      def __repo, do: unquote(opts[:repo])
      unquote(define_callback_defaults)
    end
  end

  defp define_callback_defaults do
    quote do
      def before_call(c), do: c
      def after_call(r), do: r

      defoverridable [before_call: 1, after_call: 1]
    end
  end
end
