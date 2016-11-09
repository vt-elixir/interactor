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
    try do
      with {:ok, new_context} <- Interactor.call(interactor, context) do
        case execute_interactors(new_context, interactors) do
          {:error, error} ->
            {:ok, _} = interactor.cleanup(new_context)
            {:error, error, new_context}
          other -> other
        end
      end
    rescue error -> {:error, error}
    end
  end
end
