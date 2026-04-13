defmodule EctoContext.Templates.GetBangTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "get!/3" do
    test "returns record by id when permission(:get, ...) allows" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert %Article{id: id} = Articles.get!(Scope.for_user(user), article.id)
      assert id == article.id
    end

    test "raises for unknown id" do
      user = Factory.insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get!(Scope.for_user(user), -1)
      end
    end

    test "raises when permission(:get, ...) denies" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user1.id)

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get!(Scope.for_user(user2), article.id)
      end
    end

    test ":query further narrows results" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id, published: false)

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get!(Scope.for_user(user), article.id, query: &Articles.published/1)
      end
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.get!(Scope.for_user(user), article.id, unknown: true)
      end
    end
  end
end
