# Interactor

[![Build Status](https://travis-ci.org/AgilionApps/interactor.svg?branch=master)](https://travis-ci.org/AgilionApps/interactor)
[![Hex Version](https://img.shields.io/hexpm/v/interactor.svg)](https://hex.pm/packages/interactor)

**Interactor provides an opinionated interface for performing complex user interactions.**

## What this is

This is a library implementing a simple pattern that encourages modularity and
the Single Responsibility Principle around _doing_ things primarially with ecto.

You can think of this as a second layer of domain modeling that happens in your
application. You existing schema (model) layer represents the data itself and
it's relationships. The new interaction layer represents high level actions or
events that happen on your domain. Some good examples in a blog domain might be:

* CreateArticle
* UpdateArticle
* DeleteArticle
* TrackArticleView
* RegisterUser
* SpamifyUser
* ResetUserPassword
* CreateComment
* DeleteComment

By seperating these actions into their own modules you gain smaller "models"
and controllers. The interactors themselves stay extremely focused and the code
easy to maintain.

Interactor is inspired by CollectiveIdea's Ruby gem Interactors and influenced
by Ello's async interactor usage and years of working on many MVC apps.

## What this isn't

*Fully baked.*

This is an experiment in application architectual patterns using the tools
Elixir and Ecto provide. Ecto Changesets and Multi are (relatively) new
concepts (to me) and these theories need testing out.

Is this a good idea? A bad one? Open an issue and let me know!

*A lot of code*

This library really doesn't do much, but it doesn't need to. This is mostly
about promoting and enabling a pattern to make Elixir/Phoenix apps even more
maintainable then they already are.

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

### A basic 'Article creation' interactor

```elixir
defmodule ExampleApp.CreateArticle do
  use Interactor, repo: ExampleApp.Repo
  alias ExampleApp.Article

  def handle_call(%{attributes: attrs, author: author}) do
    cast(%Article{}, attrs, [:title, :body])
    |> put_change(:author_id, author.id)
    # validations etc
  end
end

defmodule ExampleApp.ArticleController do
  use ExampleApp.Web, :controller
  alias ExampleApp.CreateArticle

  def post(%{assigns: %{user: user}} = conn, %{article: attrs}) do
    case Interactor.call(CreateArticle, %{attributes: attrs, author: user}) do
      {:ok, article} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", article_path(conn, :show, article))
        |> render(:show, article: article)
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
defmodule ExampleApp.CreateArticle do
  use Interactor, repo: ExampleApp.Repo
  alias ExampleApp.Article

  def handle_call(%{attributes: attrs, author: author}) do
    Multi.new
    |> Multi.insert(:article, article_changeset(attrs, author))
    |> Multi.update(:author, author_changset(author))
  end

  defp post_changeset(attrs, author)
    cast(%Article{}, attrs, [:title, :body])
    |> put_change(:author_id, author.id)
    # validations etc
  end

  defp author_changeset(author) do
    case(author, %{posts_count: author.posts_count + 1}, [:posts_count])
  end
end

defmodule ExampleApp.ArticleController do
  use ExampleApp.Web, :controller
  alias ExampleApp.CreateArticle

  def post(%{assigns: %{user: user}} = conn, %{article: attrs}) do
    case Interactor.call(CreateArticle, %{attributes: attrs, author: user}) do
      {:ok, %{article: article}} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", article_path(conn, :show, article))
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

* Chainability?
* Collect feedback
* Release to hex.pm

## License

The Interactor source code is released under Apache 2 License. Check LICENSE
file for more information.
