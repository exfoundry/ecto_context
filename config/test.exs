import Config

config :ecto_context, EctoContext.Test.Repo,
  database: ":memory:",
  pool_size: 1,
  log: false
