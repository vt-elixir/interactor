defmodule Interactor.Strategy do
  use Behaviour

  @moduledoc """
  An interactor strategy is how the interactor is executed.

  Built in strategies are:

    * :sync - Interactor.Strategy.Sync - default
    * :async - Interactor.Strategy.Async
    * :task - Interactor.Strategy.Task

  Strategies are determined with the `strategy` option, eg:

      Interactor.call(SimpleInteractor, %{foo: :bar}, strategy: :task)

  Or with Interactor.Builder:

      interactor :create_user
      interactor :send_email, strategy: :async

  The default strategy is `:sync` which simply executes the interactor in the
  current process and assigns the results. See docs on each strategy for more.

  Custom strategies can be used by passing a module implementing the
  Interactor.Strategy behaviour as the strategy option. For example:

      interactor :create_user
      interactor :send_email, strategy: MyApp.Exq

  """

  @doc """
  Execute the interactor.

  Receives the module and function of the interactor, the interaction and the
  opts. The simplest possible implementation is just to apply the function
  inline, which is in fact what the :sync strategy does.

      apply(module, fun, [interaction, opts])

  This callback should return either the %Interaction{}, {:ok, value}, or
  {:error, error}.
  """
  @callback execute(module, atom, Interaction.t, Keyword.t) :: Interaction.t | {:ok, any} | {:error, any}
end
