defmodule Interactor.Perform do
  def perform(interactor, input, nil) do
    do_perform(interactor, input, nil)
  end

  def perform(interactor, input, repo) do
    repo.transaction fn ->
      do_perform(interactor, input, repo)
    end
  end

  defp do_perform(interactor, input, repo) do
    input
    |> interactor.before_call
    |> interactor.call
    |> interactor.after_call
    |> Interactor.Handler.handle(repo)
    |> interactor.after_perform
  end
end
