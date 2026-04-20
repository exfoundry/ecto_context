defmodule EctoContext.Templates.SubscribeTest do
  use ExUnit.Case, async: true

  describe "subscribe/1" do
    test "raises at compile time when pubsub_server is not set" do
      assert_raise ArgumentError, ~r/pubsub_server/, fn ->
        defmodule SubscribeNoPubsub do
          import EctoContext

          ecto_context schema: Article, scope: &__MODULE__.scope/2, repo: EctoContext.Test.Repo do
            subscribe()
          end

          def scope(q, _), do: q
        end
      end
    end

    test "compiles when pubsub_server is set" do
      defmodule SubscribeWithPubsub do
        import EctoContext

        ecto_context schema: Article,
                     scope: &__MODULE__.scope/2,
                     repo: EctoContext.Test.Repo,
                     pubsub_server: MyApp.PubSub do
          subscribe()
        end

        def scope(q, _), do: q
      end

      assert function_exported?(SubscribeWithPubsub, :subscribe, 1)
    end

    test "compiles with custom topic_key" do
      defmodule SubscribeCustomTopicKey do
        import EctoContext

        ecto_context schema: Article,
                     scope: &__MODULE__.scope/2,
                     repo: EctoContext.Test.Repo,
                     pubsub_server: MyApp.PubSub,
                     topic_key: &__MODULE__.topic_key/1 do
          subscribe()
        end

        def scope(q, _), do: q
        def topic_key(scope), do: scope.user_id
      end

      assert function_exported?(SubscribeCustomTopicKey, :subscribe, 1)
    end
  end
end
