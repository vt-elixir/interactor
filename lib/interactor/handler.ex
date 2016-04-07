defprotocol Interactor.Handler do
  @fallback_to_any true
  def handle(data, repo)
end

defimpl Interactor.Handler, for: Any do
  def handle(data, _repo), do: data
end

if Code.ensure_compiled?(Ecto.Multi) do
  defimpl Interactor.Handler, for: Ecto.Multi do
    def handle(_multi, nil), do: raise "No repo defined."
    def handle(multi, repo), do: repo.transaction(multi)
  end
end

if Code.ensure_compiled?(Ecto.Changeset) do
  defimpl Interactor.Handler, for: Ecto.Changeset do
    def handle(changeset, nil), do: raise "No repo defined."
    def handle(changeset, repo), do: repo.insert_or_update(changeset)
  end
end
