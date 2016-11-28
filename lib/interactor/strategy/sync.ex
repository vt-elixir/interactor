defmodule Interactor.Strategy.Sync do
  @behaviour Interactor.Strategy

  @moduledoc """
  Execute interaction synchronously. Default strategy.
  """

  @doc """
  Execute interactor in current process.
  """
  def execute(module, fun, interaction, opts) do
    apply(module, fun, [interaction, opts])
  end
end
