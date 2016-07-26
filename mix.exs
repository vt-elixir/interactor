defmodule Interactor.Mixfile do
  use Mix.Project

  def project do
    [app: :interactor,
     version: "0.1.0",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/AgilionApps/interactor",
     package: package,
     description: description,
     deps: deps]
  end

  def application do
    [applications: [:logger],
     mod: {Interactor.Application, []}]
  end

  defp deps do
    [
      {:ecto, "~> 1.0 or ~> 2.0", optional: true},
      {:earmark, "~> 0.2.0", only: :dev},
      {:ex_doc, "~> 0.12", only: :dev}
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      maintainers: ["Alan Peabody"],
      links: %{
        "GitHub" => "https://github.com/AgilionApps/interactor"
      },
    ]
  end

  defp description do
    """
    Interactor provides an opinionated interface for performing complex user
    interactions.
    """
  end
end
