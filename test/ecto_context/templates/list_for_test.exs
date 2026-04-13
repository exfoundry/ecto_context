defmodule EctoContext.Templates.ListForTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "list_for/4" do
    test "returns records associated to the given parent" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Mine")

      assert [%Article{title: "Mine"}] =
               Articles.list_for(Scope.global_access(), :user, user.id)
    end

    test "returns empty list when parent has no records" do
      user = Factory.insert(:user)

      assert [] = Articles.list_for(Scope.global_access(), :user, user.id)
    end

    test "does not return records from other parents" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id, title: "U1")
      Factory.insert(:article, user_id: user2.id, title: "U2")

      result = Articles.list_for(Scope.global_access(), :user, user1.id)
      assert length(result) == 1
      assert hd(result).user_id == user1.id
    end

    test "respects scope" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id)

      assert [] = Articles.list_for(Scope.for_user(user2), :user, user1.id)
    end

    test "raises on invalid association" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Invalid association/, fn ->
        Articles.list_for(Scope.global_access(), :nonexistent, user.id)
      end
    end

    test "works with convention-based foreign key field" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, category_id: "news", title: "News Article")
      Factory.insert(:article, user_id: user.id, category_id: "tutorial", title: "Tutorial Article")

      result = Articles.list_for(Scope.global_access(), :category, "news")
      assert [%Article{title: "News Article"}] = result
    end
  end
end
