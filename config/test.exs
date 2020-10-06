use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ecto_sum_embeds, EctoSumEmbeds.Repo,
  username: "postgres",
  password: "postgres",
  database: "ecto_sum_embeds_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  port: 5432

# Print only warnings and errors during test
config :logger, level: :warn
