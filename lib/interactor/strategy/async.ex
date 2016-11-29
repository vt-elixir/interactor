defmodule Interactor.Strategy.Async do
  @behaviour Interactor.Strategy
  alias Interactor.TaskSupervisor

  @moduledoc """
  Execute interaction asynchronously, only return value is PID.

  To use:

      interactor :update_view_count, strategy: :async

  or:

      interactor :update_view_count, strategy: Interactor.Strategy.Async


  When running tests async interactors can be forced to run synchronously by setting the following config. Return values will still be pids.

      config :interactor,
        force_syncronous_tasks: true
  """

  @doc """
  Execute interactor asynchronously in a supervised fashion.

  Returns pid for assignment in interaction.
  """
  def execute(module, fun, interaction, opts) do
    if sync_tasks do
      task = Task.Supervisor.async(TaskSupervisor, fn() ->
        apply(module, fun, [interaction, opts])
      end)
      Task.await(task)
      {:ok, task.pid}
    else
      Task.Supervisor.start_child(TaskSupervisor, fn() ->
        apply(module, fun, [interaction, opts])
      end)
    end
  end

  defp sync_tasks do
    Application.get_env(:interactor, :force_syncronous_tasks, false)
  end
end
