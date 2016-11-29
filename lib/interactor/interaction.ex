defmodule Interactor.Interaction do
  @moduledoc """
  An interaction holds the state to be passed between Interactors.
  """

  defstruct [assigns: %{}, success: true, error: nil, rollback: []]

  @type t :: %__MODULE__{
    assigns: Map.t,
    success: boolean,
    error: nil | any,
    rollback: [{module, atom}],
  }

  @doc """
  Assign a value to the interaction's assigns map.
  """
  @spec assign(Interaction.t, atom, any) :: Interaction.t
  def assign(%__MODULE__{} = interaction, key, val) do
    Map.update!(interaction, :assigns, &(Map.put(&1, key, val)))
  end

  @doc """
  Push a rollback function into the interaction's rollback list.
  """
  @spec add_rollback(Interaction.t, nil | {module, atom}) :: Interaction.t
  def add_rollback(%__MODULE__{} = interaction, nil), do: interaction
  def add_rollback(%__MODULE__{} = interaction, {module, fun}) do
    Map.update!(interaction, :rollback, &([{module, fun} | &1]))
  end

  @doc """
  Execute all rollback functions in reverse of the order they were added.

  Called when an interactor up the chain returns {:error, anyvalue}.

  NOTE: Rollback for the interactor that fails is not called, only previously
  successful interactors have rollback called.
  """
  @spec rollback(Interaction.t) :: Interaction.t
  def rollback(%__MODULE__{} = interaction) do
    Enum.reduce interaction.rollback, interaction, fn({mod, fun}, i) ->
      apply(mod, fun, [i])
    end
  end
end
