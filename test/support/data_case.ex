defmodule EctoContext.Test.DataCase do
  @moduledoc """
  Case template for tests that hit the database.

  Provides common aliases and imports, and truncates all tables before each
  test. Uses `async: false` — SQLite in-memory with pool_size: 1 does not
  support concurrent DB tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: false
      alias EctoContext.Test.Factory
      alias EctoContext.Test.Repo
      alias EctoContext.Test.Scope
    end
  end

  setup do
    EctoContext.Test.Repo.delete_all(EctoContext.Test.Article)
    EctoContext.Test.Repo.delete_all(EctoContext.Test.User)
    :ok
  end
end
