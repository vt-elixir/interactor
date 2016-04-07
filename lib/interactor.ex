defmodule Interactor do
  use Behaviour
  @callback call(map) :: any
  @callback before_call(map) :: map
  @callback after_call(any) :: any
  @callback after_perform(any) :: any

  defmacro __using__(opts) do
    quote do
      @_repo Keyword.get(unquote(opts), :repo)
      @behaviour Interactor
      unquote(import_changeset)
      unquote(alias_multi)
      unquote(define_peform)
      unquote(define_peform_async)
    end
  end

  if Code.ensure_compiled?(Ecto.Changeset) do
    defp import_changeset, do: quote(do: import Ecto.Changeset)
  else
    defp import_changeset, do: nil
  end

  if Code.ensure_compiled?(Ecto.Multi) do
    defp alias_multi, do: quote(do: alias Ecto.Multi)
  else
    defp alias_multi, do: nil
  end

  defp define_peform do
    quote do
      def perform(input) do
        Interactor.Perform.perform(__MODULE__, input, @_repo)
      end

      def before_call(c), do: c
      def after_call(r), do: r
      def after_perform(r), do: r

      defoverridable [before_call: 1, after_call: 1, after_perform: 1]
    end
  end

  defp define_peform_async do
    quote do
      @spec perform_async(map) :: Task.t
      def perform_async(map), do: Task.async(__MODULE__, :perform, [map])
    end
  end
end
