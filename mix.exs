defmodule MingaKnowledgeGraph.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/jsmestad/minga-knowledge-graph"

  def project do
    [
      app: :minga_knowledge_graph,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: false,
      deps: deps(),
      description:
        "Personal knowledge graph: tracks what you know and briefs you on what you don't",
      source_url: @source_url,
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @source_url},
        files: ~w(lib mix.exs README.md LICENSE)
      ],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:minga_sdk, "~> 0.1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
