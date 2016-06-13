defmodule Interactor.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Task.Supervisor, [[name: Interactor.TaskSupervisor]])
    ]

    opts = [strategy: :one_for_one, name: Interactor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
