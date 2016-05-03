defmodule Interactor.Perform do
  def perform(interactor, input, repo) do
    input
    |> interactor.before_call
    |> interactor.call
    |> interactor.after_call
    |> Interactor.Handler.handle(repo)
    |> interactor.after_perform
  end
end
