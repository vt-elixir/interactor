defmodule Interactor.Ecto do
  @behaviour Interactor

  @moduledoc """
  An interactor which will insert/update/transact your changesets and multis.
  """

  # TODO: Better name for source option? :from, :changeset, :multi ?
  def call(interaction, opts) do
    case {opts[:source], opts[:repo]} do
      {nil, _} -> raise "Interactor.Ecto requires a :source option to indicate which assign field should be attempted to be inserted"
      {_, nil} -> raise "Interactor.Ecto requires a :repo option to use to insert or transact with."
      {source, repo} -> execute(interaction.assigns[source], repo)
    end
  end

  defp execute(nil, _), do: raise "Interactor.Ecto could not find given source"
  defp execute(%{__struct__: Ecto.Multi} = multi, repo) do
    repo.transaction(multi)
  end
  defp execute(%{__struct__: Ecto.Changeset} = changeset, repo) do
    repo.insert_or_update(changeset)
  end
end
