defmodule Interactor do
  use Behaviour
  alias Interactor.TaskSupervisor
  alias Interactor.Interaction

  @moduledoc """
  A tool for modeling events that happen in your application.

  #TODO: Docs, Examples, WHY

  """

  @type opts :: binary | tuple | atom | integer | float | [opts] | %{opts => opts}

  @doc """
  Primary interactor callback.

  #TODO: Docs, Examples, explain return values and assign_to

  """
  @callback call(Interaction.t, opts) :: Interaction.t | {:ok, any} | {:error, any} | any

  @doc """
  Call an Interactor.

  #TODO: Docs, Examples

  """
  @spec call(module | {module, atom}, Interaction.t | map, Keyword.t) :: Interaction.t
  def call(interactor, interaction, opts \\ [])
  def call({interactor, fun}, %Interaction{} = interaction, opts),
    do: do_call({interactor, fun}, interaction, opts[:strategy], opts)
  def call(interactor, %Interaction{} = i, opts),
    do: call({interactor, :call}, i, opts)
  def call(interactor, assigns, opts),
    do: call(interactor, %Interaction{assigns: assigns}, opts)

  defp do_call({interactor, fun}, interaction, nil, opts) do
    assign_to = determine_assign_to(interactor, fun, opts[:assign_to])
    case apply(interactor, fun, [interaction, opts]) do
      # When interaction is returned do nothing
      %Interaction{} = interaction -> interaction
      # Otherwise properly add result to interaction
      {:error, error} -> %{interaction | success: false, error: error}
      {:ok, other} -> Interaction.assign(interaction, assign_to, other)
      other -> Interaction.assign(interaction, assign_to, other)
    end
  end

  defp do_call({interactor, fun}, interaction, :task, opts) do
    assign_to = determine_assign_to(interactor, fun, opts[:assign_to])
    task = Task.Supervisor.async(TaskSupervisor, fn() ->
      apply(interactor, fun, [interaction, opts])
    end)

    Interaction.assign(interaction, assign_to, task)
  end

  defp do_call({interactor, fun}, interaction, :async, opts) do
    assign_to = determine_assign_to(interactor, fun, opts[:assign_to])
    {:ok, pid} = if sync_tasks do
      task = Task.Supervisor.async(TaskSupervisor, fn() ->
        apply(interactor, fun, [interaction, opts])
      end)
      Task.await(task)
      {:ok, task.pid}
    else
      Task.Supervisor.start_child(TaskSupervisor, fn() ->
        apply(interactor, fun, [interaction, opts])
      end)
    end

    Interaction.assign(interaction, assign_to, pid)
  end

  defp determine_assign_to(module, :call, nil) do
    module
    |> Atom.to_string
    |> String.split(".")
    |> Enum.reverse
    |> hd
    |> Macro.underscore
    |> String.to_atom
  end
  defp determine_assign_to(_module, fun, nil), do: fun
  defp determine_assign_to(_module, _fun, assign_to), do: assign_to

  defp sync_tasks do
    Application.get_env(:interactor, :force_syncronous_tasks, false)
  end
end
