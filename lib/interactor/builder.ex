defmodule Interactor.Builder do

  @moduledoc """


  The Interactor.Builer module functionality and code is **heavily** influenced
  and copied from the Plug.Builder code.
  TODO.

  Example:

      def Example.CreatePost do
        use Interactor.Interaction
        import Ecto.Changeset

        interactor :post_changeset
        interactor Interactor.Ecto, from: :post_changeset, to: post
        interactor Example.SyncToSocket, async: true
        interactor :push_to_rss_service, async: true

        def post_changeset(%{assigns: %{attributes: attrs}}, _) do
          cast(%Example.Post, attrs, [:title, :body])
        end

        def push_to_rss_service(interaction, _) do
          # ... External service call ...
          interaction
        end
      end

  """

  @type interactor :: module | atom

  @doc """

  """
  defmacro interactor(interactor, opts \\ []) do
    quote do
      @interactors {unquote(interactor), unquote(opts), true}
    end
  end

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Interactor
      import Interactor.Builder, only: [interactor: 1, interactor: 2]
      import Interactor.Interaction # TODO, is this a good idea? assign/3 could conflict

      def call(interaction, opts) do
        interactor_builder_call(interaction, opts)
      end

      defoverridable [call: 2]

      Module.register_attribute(__MODULE__, :interactors, accumulate: true)
      @before_compile Interactor.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    interactors = Module.get_attribute(env.module, :interactors)
    {interaction, body} = Interactor.Builder.compile(env, interactors)

    quote do
      defp interactor_builder_call(unquote(interaction), _), do: unquote(body)
    end
  end

  @doc false
  #@spec compile(Macro.Env.t, [{interactor, Interactor.opts, Macro.t}]) :: {Macro.t, Macro.t}
  def compile(env, pipeline) do
    interaction = quote do: interaction
    {interaction, Enum.reduce(pipeline, interaction, &quote_interactor(&1, &2, env))}
  end

  # `acc` is a series of nested interactor calls in the form of
  # interactor3(interactor2(interactor1(interaction))).
  # `quote_interactor` wraps a new interactor around that series of calls.
  defp quote_interactor({interactor, opts, guards}, acc, env) do
    call = quote_interactor_call(interactor, opts)

    {fun, meta, [arg, [do: clauses]]} =
      quote do
        case unquote(compile_guards(call, guards)) do
          %Interactor.Interaction{success: false} = interaction -> interaction
          %Interactor.Interaction{} = interaction -> unquote(acc)
        end
      end

    generated? = :erlang.system_info(:otp_release) >= '19'

    clauses = Enum.map(clauses, fn {:->, meta, args} ->
      if generated? do
        {:->, [generated: true] ++ meta, args}
      else
        {:->, Keyword.put(meta, :line, -1), args}
      end
    end)

    {fun, meta, [arg, [do: clauses]]}
  end

  # Use Interactor.call to execute the Interactor.
  # Always returns an interaction, but handles async strategies, assigning
  # values, etc.
  defp quote_interactor_call(interactor, opts) do
    case Atom.to_char_list(interactor) do
      ~c"Elixir." ++ _ ->
        quote do: Interactor.call({unquote(interactor), :call}, interaction, unquote(Macro.escape(opts)))
      _                ->
        quote do: Interactor.call({__MODULE__, unquote(interactor)}, interaction, unquote(Macro.escape(opts)))
    end
  end

  defp compile_guards(call, true) do
    call
  end

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> conn
      end
    end
  end
end
