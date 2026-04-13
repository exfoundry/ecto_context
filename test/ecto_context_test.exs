defmodule EctoContextTest do
  use ExUnit.Case, async: true

  alias EctoContext.Test.Repo

  describe "resolve_settings/1" do
    test "returns all expected keys" do
      settings = EctoContext.resolve_settings([])

      for key <- [:app, :repo, :endpoint, :pubsub_server, :topic_key] do
        assert Keyword.has_key?(settings, key), "expected key #{inspect(key)}"
      end
    end

    test "default topic_key is default_topic_key/1" do
      settings = EctoContext.resolve_settings([])
      assert settings[:topic_key] == (&EctoContext.default_topic_key/1)
    end

    test "declaration opts take precedence over guessed defaults" do
      settings = EctoContext.resolve_settings(repo: Repo)
      assert settings[:repo] == Repo
    end

    test "library config overrides guessed defaults" do
      Application.put_env(:ecto_context, :defaults, repo: Repo)
      settings = EctoContext.resolve_settings([])
      assert settings[:repo] == Repo
    after
      Application.delete_env(:ecto_context, :defaults)
    end

    test "declaration opts take precedence over library config" do
      Application.put_env(:ecto_context, :defaults, repo: Repo)
      settings = EctoContext.resolve_settings(repo: SomeOtherRepo)
      assert settings[:repo] == SomeOtherRepo
    after
      Application.delete_env(:ecto_context, :defaults)
    end
  end

  describe "default_topic_key/1" do
    test "returns scope.user.id" do
      scope = %{user: %{id: 42}}
      assert EctoContext.default_topic_key(scope) == 42
    end
  end
end
