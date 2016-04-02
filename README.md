# Interactor


## What this is

This is a library implementing a simple pattern that encourages modularity and
the Single Responsibility Principle around _doing_ things primarially with ecto.

The goal is a module whose sole responsibility is doing one thing, removing that
responsibility from the schema (model) module. Some examples might be:

* CreatePost
* UpdatePost
* DeletePost
* RegisterUser
* TrackPostView
* CreateComment

The goal is simple schemas that don't change much over time, and easy to
maintain, test, and understand modules in charge of creating things.

In addition each module has three ways the same logic can be called:

* call - returns the Changeset or Multi (or other) to be handled by caller.
* perform - executes the Changeset or Multi
* perform_async - executes the Changeset or Multi in the returned Task

It is inspired by CollectiveIdea's Ruby gem Interactors and influenced by
Ello's async interactors and years of working on many MVC apps.

## What this isn't

**Fully baked.**

This is an experiment in application architectual patterns using the tools
Elixir and Ecto provide. Ecto Changesets and Multi are (relatively) new
concepts (to me) and these theories need testing out.

Is this a good idea? A bad one? Open an issue and let me know!

**A lot of code**

This library really doesn't do much, but it doesn't need to. This is mostly
about promoting and enabling a pattern to make Elixir/Phoenix apps even more
maintainable.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add interactor to your list of dependencies in `mix.exs`:

        def deps do
          [{:interactor, "~> 0.0.1"}]
        end

  2. Ensure interactor is started before your application:

        def application do
          [applications: [:interactor]]
        end

## Examples

### A basic 'post creation' interactor

```elixir
defmodule ExampleApp.CreatePost do
  alias ExampleApp.Post
  use Interactor, repo: ExampleApp.Repo

  def call(%{post: params, author: author}) do
    cast(%Post{}, params, [:title, :body])
    |> put_change(:author_id, author.id)
    # validations etc
  end
end

defmodule ExampleApp.PostController do
  use ExampleApp.Web, :controller
  alias ExampleApp.CreatePost

  def post(%{assigns: %{user: user}} = conn, %{post: params}) do
    case CreatePost.perform(%{post: params, author: user}).results do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", post_path(conn, :show, post))
        |> render(:show, post: post)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ExampleApp.ChangesetView, :error, changeset: changeset)
    end
  end
end
```

### Create and update author post count

A more complicated example might involve updating the author as well:

```elixir
defmodule ExampleApp.CreatePost do
  alias ExampleApp.Post
  use Interactor, repo: ExampleApp.Repo

  def call(%{post: params, author: author}) do
    Multi.new
    |> Multi.insert(:post, post_changeset(params, author))
    |> Multi.update(:author, author_changset(author))
  end

  defp post_changeset(params, author)
    cast(%Post{}, params, [:title, :body])
    |> put_change(:author_id, author.id)
    # validations etc
  end

  defp author_changeset(author) do
    case(author, %{posts_count: author.posts_count + 1}, [:posts_count])
  end
end

defmodule ExampleApp.PostController do
  use ExampleApp.Web, :controller
  alias ExampleApp.CreatePost

  def post(%{assigns: %{user: user}} = conn, %{post: params}) do
    case CreatePost.perform(%{post: params, author: user}).results do
      {:ok, %{post: post}} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", post_path(conn, :show, post))
        |> render(:show, post: post)
      {:error, _, changeset, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(ExampleApp.ChangesetView, :error, changeset: changeset)
    end
  end
end
```


## TODO:

* Callbacks? - A per interactor way of formatting the ecto response might be nice
* Use it in some more real projects
* Collect feedback
* Release to hex.pm

## License

The Interactor source code is released under Apache 2 License. Check LICENSE
file for more information.

