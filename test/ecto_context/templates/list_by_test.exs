defmodule EctoContext.Templates.ListByTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "list_by/3" do
    test "filters by a single clause" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Alpha")
      Factory.insert(:article, user_id: user.id, title: "Beta")

      assert [%Article{title: "Alpha"}] =
               Articles.list_by(Scope.for_user(user), title: "Alpha")
    end

    test "filters by multiple clauses" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Alpha", published: true)
      Factory.insert(:article, user_id: user.id, title: "Alpha", published: false)

      assert [%Article{title: "Alpha", published: true}] =
               Articles.list_by(Scope.for_user(user), title: "Alpha", published: true)
    end

    test "returns empty list when clause matches nothing" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Alpha")

      assert [] = Articles.list_by(Scope.for_user(user), title: "Nonexistent")
    end

    test "does not return records outside scope" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id, title: "Shared")
      Factory.insert(:article, user_id: user2.id, title: "Shared")

      result = Articles.list_by(Scope.for_user(user1), title: "Shared")
      assert length(result) == 1
      assert hd(result).user_id == user1.id
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.list_by(Scope.for_user(user), [title: "Alpha"], unknown: true)
      end
    end
  end
end
