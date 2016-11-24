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
  Warning: Deprecated

  The primary callback. Typically returns an Ecto.Changeset or an Ecto.Multi.
  """
  @callback handle_call(map) :: any

  @doc """
  Warning: Deprecated

  A callback executed before handle_call. Useful for normalizing inputs.
  """
  @callback before_call(map) :: map

  @doc """
  Warning: Deprecated


  A callback executed after handle_call and after the Repo executes.

  Useful for publishing events, tracking metrics, and other non-transaction
  worthy calls.
  """
  @callback after_call(any) :: any

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}
  @callback call(Interactor.Interaction.t, opts) :: Interactor.Interaction.t

  @doc """
  Executes the `before_call/1`, `handle_call/1`, and `after_call/1` callbacks.

  If an Ecto.Changeset or Ecto.Multi is returned by `handle_call/1` and a
  `repo` options was passed to `use Interactor` the changeset or multi will be
  executed and the results returned.
  """
  #@spec call(module, map, key) :: Interaction.id | any
  def call(interactor, assigns, opts \\ []) do
    %Interactor.Interaction{assigns: assigns}
    |> interactor.call(opts)
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

  Async can be disabled in tests by setting (will still return {:ok, pid}):

      config :interactor,
        force_syncronous_tasks: true

  """
  @spec call_async(module, map) :: {:ok, pid}
  def call_async(interactor, map) do
    if sync_tasks do
      t = Task.Supervisor.async(TaskSupervisor, Interactor, :call, [interactor, map])
      Task.await(t)
      {:ok, t.pid}
    else
      Task.Supervisor.start_child(TaskSupervisor, Interactor, :call, [interactor, map])
    end
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
      def handle_call(r), do: c

      def call(%{assigns: assigns}, _) do
        IO.puts("Warning: using deprecated 0.1.0 behaviour, please see README and CHANGELOG for upgrade instructions. This functionality will be removed in 0.3.0")
        assigns
        |> before_call
        |> handle_call
        |> Interactor.Handler.handle(__repo)
        |> after_call
      end

      defoverridable [before_call: 1, after_call: 1, handle_call: 1, call: 2]
    end
  end

  defp sync_tasks do
    Application.get_env(:interactor, :force_syncronous_tasks, false)
  end
end
