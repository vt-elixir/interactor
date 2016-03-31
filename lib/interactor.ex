defmodule Interactor do
  use Behaviour
  @callback meta(map) :: Interactor.Results.t | Task.t

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @_repo Keyword.get(opts, :repo)
      @behaviour Interactor
      unquote(define_peform)
      unquote(define_peform_async)
    end
  end

  defp define_peform do
    quote do
      @spec perform(map) :: Interactor.Results.t
      def perform(map) do
        %Interactor.Results{
          results: Interactor.Handler.handle(call(map), @_repo)
        }
      end
    end
  end

  defp define_peform_async do
    quote do
      @spec perform_async(map) :: Task.t
      def perform_async(map), do: Task.async(__MODULE__, :perform, [map])
    end
  end

  defmodule Results do
    defstruct [:results]
    @type t :: %__MODULE__{}
  end

  # Handle call responses

  defprotocol Handler do
    @fallback_to_any true
    def handle(data, repo)
  end

  defimpl Handler, for: Any do
    def handle(data, _repo), do: data
  end

  if Code.ensure_compiled?(Ecto.Multi) do
    defimpl Handler, for: Ecto.Multi do
      def handle(_multi, nil), do: raise "No repo defined."
      def handle(multi, repo), do: repo.transaction(multi)
    end
  end

  if Code.ensure_compiled?(Ecto.Changeset) do
    defimpl Handler, for: Ecto.Changeset do
      def handle(changeset, nil), do: raise "No repo defined."
      def handle(changeset, repo), do: repo.insert_or_update(changeset)
    end
  end
end
