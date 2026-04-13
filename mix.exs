defmodule EctoContext.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/exfoundry/ecto_context"

  def project do
    [
      app: :ecto_context,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: description(),
      package: package(),
      name: "EctoContext",
      source_url: @source_url,
      docs: [
        main: "EctoContext",
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"],
        skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
      ]
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Scoped CRUD with permission layer via macro DSL for Ecto schemas."
  end

  defp deps do
    [
      {:ecto, "~> 3.5"},
      {:ecto_sqlite3, "~> 0.22", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Elias Forge"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "https://hexdocs.pm/ecto_context/changelog.html"
      },
      files: ~w(lib priv mix.exs .formatter.exs README.md CHANGELOG.md LICENSE)
    ]
  end
end
