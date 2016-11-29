defmodule Interactor do
  use Behaviour
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
  Optional callback to be executed if interactors up the chain return an error. When using Interaction.Builder prefer the `rollback` option.
  """
  @callback rollback(Interaction.t) :: Interaction.t
  @optional_callbacks rollback: 1

  @doc """
  Call an Interactor.

  #TODO: Docs, Examples

  """
  @spec call(module | {module, atom}, Interaction.t | map, Keyword.t) :: Interaction.t
  def call(interactor, interaction, opts \\ [])
  def call({module, fun}, %Interaction{} = interaction, opts),
    do: do_call(module, fun, interaction, opts[:strategy], opts)
  def call(module, %Interaction{} = i, opts),
    do: call({module, :call}, i, opts)
  def call(interactor, assigns, opts),
    do: call(interactor, %Interaction{assigns: assigns}, opts)

  defp do_call(module, fun, interaction, :sync, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Sync, opts)
  defp do_call(module, fun, interaction, nil, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Sync, opts)
  defp do_call(module, fun, interaction, :async, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Async, opts)
  defp do_call(module, fun, interaction, :task, opts),
    do: do_call(module, fun, interaction, Interactor.Strategy.Task, opts)
  defp do_call(module, fun, interaction, strategy, opts) do
    assign_to = determine_assign_to(module, fun, opts[:assign_to])
    rollback = determine_rollback(module, fun, opts[:rollback])
    case strategy.execute(module, fun, interaction, opts) do
      %Interaction{success: false} = interaction ->
        Interaction.rollback(interaction)
      %Interaction{} = interaction ->
        Interaction.add_rollback(interaction, rollback)
      {:error, error} ->
        Interaction.rollback(%{interaction | success: false, error: error})
      {:ok, other} ->
        interaction
        |> Interaction.assign(assign_to, other)
        |> Interaction.add_rollback(rollback)
      other ->
        interaction
        |> Interaction.assign(assign_to, other)
        |> Interaction.add_rollback(rollback)
    end
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

  defp determine_rollback(module, :call, nil) do
    if {:rollback, 1} in module.__info__(:functions) do
      {module, :rollback}
    end
  end
  defp determine_rollback(_module, _fun, nil), do: nil
  defp determine_rollback(module, _fun, rollback), do: {module, rollback}

end
