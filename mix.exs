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
    This is a library implementing a simple pattern that encourages modularity and
    the Single Responsibility Principle around _doing_ things primarially with ecto.
    """
  end
end
