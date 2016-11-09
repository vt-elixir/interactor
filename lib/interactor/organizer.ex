defmodule Interactor.Organizer do
  defmacro __using__(opts) do
    quote do
      use Interactor, unquote(opts)
      import Interactor.Organizer, only: [organize: 1]

      Module.register_attribute(__MODULE__, :interactors, accumulate: true)
    end
  end

  defmacro organize(interactors) do
    quote do
      import Interactor.Organizer
      unquote(interactors)
      |> Enum.reverse
      |> Enum.each(&(Module.put_attribute(__MODULE__, :interactors, &1)))
      unquote(define_callbacks)
    end
  end

  defp define_callbacks do
    quote do
      def handle_call(attributes) do
        execute_interactors(attributes, @interactors)
      end
    end
  end

  def execute_interactors(context, []), do: {:ok, context}
  def execute_interactors(context, [interactor | interactors]) do
    with {:ok, new_context} <- Interactor.call(interactor, context) do
      try do
        case execute_interactors(new_context, interactors) do
          {:error, error, error_context} ->
            handle_cleanup(interactor, error, error_context)
          {:error, error} ->
            handle_cleanup(interactor, error, new_context)
          other -> other
        end
      rescue error in RuntimeError -> handle_cleanup(interactor, error, new_context)
      end
    end
  end

  def handle_cleanup(interactor, error, context) do
    {:ok, cleanup_context} = interactor.cleanup(context)
    {:error, error, cleanup_context}
  end
end
