defmodule EctoContext.Templates.BroadcastTest do
  use ExUnit.Case, async: true

  describe "broadcast/2" do
    test "raises at compile time when pubsub_server is not set" do
      assert_raise ArgumentError, ~r/pubsub_server/, fn ->
        defmodule BroadcastNoPubsub do
          import EctoContext

          ecto_context schema: Article, scope: &__MODULE__.scope/2, repo: EctoContext.Test.Repo do
            broadcast()
          end

          def scope(q, _), do: q
        end
      end
    end

    test "compiles when pubsub_server is set" do
      defmodule BroadcastWithPubsub do
        import EctoContext

        ecto_context schema: Article,
                          scope: &__MODULE__.scope/2,
                          repo: EctoContext.Test.Repo,
                          pubsub_server: MyApp.PubSub do
          broadcast()
        end

        def scope(q, _), do: q
      end

      assert function_exported?(BroadcastWithPubsub, :broadcast, 2)
    end

    test "compiles with custom topic_key" do
      defmodule BroadcastCustomTopicKey do
        import EctoContext

        ecto_context schema: Article,
                          scope: &__MODULE__.scope/2,
                          repo: EctoContext.Test.Repo,
                          pubsub_server: MyApp.PubSub,
                          topic_key: &__MODULE__.topic_key/1 do
          broadcast()
        end

        def scope(q, _), do: q
        def topic_key(scope), do: scope.user_id
      end

      assert function_exported?(BroadcastCustomTopicKey, :broadcast, 2)
    end
  end
end
