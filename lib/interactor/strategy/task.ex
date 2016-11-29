defmodule Interactor.Strategy.Task do
  @behaviour Interactor.Strategy
  alias Interactor.TaskSupervisor
  import Interactor.Interaction

  @moduledoc """
  Execute interaction in a task, return value is a Task which is assigned to interaction.

  To use:

      interactor :do_work, strategy: :task

  or:

      interactor :do_work, strategy: Interactor.Strategy.Task

  Interaction with %Task{} in assigns can be all waited on with Interactor.Strategy.Task.await/1.
  """

  @doc """
  Execute interactor in a supervised task.

  Task is returned for assignment in interaction.
  """
  def execute(module, fun, interaction, opts) do
    Task.Supervisor.async TaskSupervisor, fn() ->
      apply(module, fun, [interaction, opts])
    end
  end

  @doc """
  Await all tasks in assigns, return interaction with fulfilled values replacing tasks.
  """
  def await(interaction) do
    Enum.reduce interaction.assigns, interaction, fn
      {k, %Task{} = t}, interaction ->
        val = case Task.await(t) do
          {:ok, val} -> val
          val -> val
        end
        assign(interaction, k, val)
      _, interaction -> interaction
    end
  end
end
