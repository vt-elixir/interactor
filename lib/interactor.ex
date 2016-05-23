defmodule Interactor do
  use Behaviour
  @callback handle_call(map) :: any
  @callback before_call(map) :: map
  @callback after_call(any) :: any

  defmacro __using__(opts) do
    quote do
      @_repo Keyword.get(unquote(opts), :repo)
      @behaviour Interactor
      unquote(import_changeset)
      unquote(alias_multi)
      unquote(define_call)
      unquote(define_call_task)
      unquote(define_call_async)
    end
  end

  if Code.ensure_compiled?(Ecto.Changeset) do
    defp import_changeset, do: quote(do: import Ecto.Changeset)
  else
    defp import_changeset, do: nil
  end

  if Code.ensure_compiled?(Ecto.Multi) do
    defp alias_multi, do: quote(do: alias Ecto.Multi)
  else
    defp alias_multi, do: nil
  end

  defp define_call do
    quote do
      def call(input) do
        Interactor.call(__MODULE__, input, @_repo)
      end

      def before_call(c), do: c
      def after_call(r), do: r

      defoverridable [before_call: 1, after_call: 1]
    end
  end

  defp define_call_task do
    quote do
      @spec call_task(map) :: Task.t
      def call_task(map),
        do: Task.Supervisor.async(Interactor.TaskSupervisor, __MODULE__, :call, [map])
    end
  end

  defp define_call_async do
    quote do
      @spec call_aync(map) :: {:ok, pid}
      def call_aync(map),
        do: Task.Supervisor.start_child(Interactor.TaskSupervisor, __MODULE__, :call, [map])
    end
  end

  def call(interactor, input, repo) do
    input
    |> interactor.before_call
    |> interactor.handle_call
    |> Interactor.Handler.handle(repo)
    |> interactor.after_call
  end
end
