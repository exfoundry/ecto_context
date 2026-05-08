defmodule EctoContext.Check.HelpersTest do
  use ExUnit.Case, async: false

  alias EctoContext.Check.Helpers

  describe "configured_repo_aliases/1" do
    test "returns last atom of each module when :repos param is given" do
      assert Helpers.configured_repo_aliases(repos: [MyApp.Repo]) == [:Repo]
    end

    test "returns multiple suffixes when multiple repos are configured" do
      assert Helpers.configured_repo_aliases(repos: [MyApp.Repo, MyApp.ReadonlyRepo]) ==
               [:Repo, :ReadonlyRepo]
    end

    test "handles deeply nested module paths" do
      assert Helpers.configured_repo_aliases(repos: [MyApp.Data.Persistence.Repo]) == [:Repo]
    end

    test "falls back to [:Repo] when params is empty and no :ecto_repos configured" do
      assert Helpers.configured_repo_aliases([]) == [:Repo]
    end

    test "falls back to [:Repo] when :repos key is present but empty" do
      assert Helpers.configured_repo_aliases(repos: []) == [:Repo]
    end

    test "reads :ecto_repos from app env when no :repos param given" do
      app = Mix.Project.config()[:app]
      Application.put_env(app, :ecto_repos, [MyApp.Repo, MyApp.ReadonlyRepo])

      try do
        assert Helpers.configured_repo_aliases([]) == [:Repo, :ReadonlyRepo]
      after
        Application.delete_env(app, :ecto_repos)
      end
    end

    test ":repos param takes precedence over :ecto_repos app env" do
      app = Mix.Project.config()[:app]
      Application.put_env(app, :ecto_repos, [SomeOther.Repo])

      try do
        assert Helpers.configured_repo_aliases(repos: [MyApp.CustomRepo]) == [:CustomRepo]
      after
        Application.delete_env(app, :ecto_repos)
      end
    end
  end
end
