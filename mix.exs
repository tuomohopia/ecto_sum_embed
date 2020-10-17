defmodule EctoSumEmbeds.MixProject do
  use Mix.Project

  def project do
    [
      app: :ecto_sum_embeds,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Ecto Sum Embed",
      source_url: "https://github.com/tuomohopia/ecto_sum_embed",
      homepage_url: "https://github.com/tuomohopia/ecto_sum_embed",
      docs: [
        # The main page in the docs
        main: "EctoSumEmbeds",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.5"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.22", only: :dev, runtime: false}
    ]
  end
end
