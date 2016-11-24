defmodule Interactor.Interaction do
  defstruct [assigns: %{}, success: true, error: nil]

  def assign(%__MODULE__{} = interaction, key, val) do
    Map.update!(interaction, :assigns, &(Map.put(&1, key, val)))
  end
end
