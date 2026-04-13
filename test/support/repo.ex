defmodule EctoContext.Test.Repo do
  use Ecto.Repo, otp_app: :ecto_context, adapter: Ecto.Adapters.SQLite3
end
