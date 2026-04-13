defmodule EctoContext.Templates.ListTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles
  alias EctoContext.Test.Users

  describe "list/2" do
    test "returns all records within scope" do
      Factory.insert(:user)
      Factory.insert(:user)
      assert length(Users.list(Scope.global_access())) == 2
    end

    test "returns empty list when no matching records" do
      user = Factory.insert(:user)
      assert Articles.list(Scope.for_user(user)) == []
    end

    test "filters by scope" do
      user = Factory.insert(:user)
      other = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Mine")
      Factory.insert(:article, user_id: other.id, title: "Theirs")

      assert [%Article{title: "Mine"}] = Articles.list(Scope.for_user(user))
    end

    test "global scope returns all records" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id)
      Factory.insert(:article, user_id: user2.id)

      assert length(Articles.list(Scope.global_access())) == 2
    end

    test "supports :limit opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)
      Factory.insert(:article, user_id: user.id)
      Factory.insert(:article, user_id: user.id)

      assert length(Articles.list(Scope.for_user(user), limit: 2)) == 2
    end

    test "supports :order_by opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Zebra")
      Factory.insert(:article, user_id: user.id, title: "Apple")

      assert [%Article{title: "Apple"}, %Article{title: "Zebra"}] =
               Articles.list(Scope.for_user(user), order_by: :title)
    end

    test "supports :query opt for composable filtering" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Draft", published: false)
      Factory.insert(:article, user_id: user.id, title: "Live", published: true)

      assert [%Article{title: "Live"}] =
               Articles.list(Scope.for_user(user), query: &Articles.published/1)
    end

    test "supports :preload opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)

      [article] = Articles.list(Scope.for_user(user), preload: :user)
      assert %EctoContext.Test.User{} = article.user
    end

    test "supports :select opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Selected")

      assert [%Article{title: "Selected", id: nil}] =
               Articles.list(Scope.for_user(user), select: [:title])
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.list(Scope.for_user(user), unknown: true)
      end
    end
  end
end
