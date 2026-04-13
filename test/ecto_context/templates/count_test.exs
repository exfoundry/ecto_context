defmodule EctoContext.Templates.CountTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Articles

  describe "count/2" do
    test "returns count of records within scope" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)
      Factory.insert(:article, user_id: user.id)

      assert 2 == Articles.count(Scope.for_user(user))
    end

    test "returns 0 when no records" do
      user = Factory.insert(:user)
      assert 0 == Articles.count(Scope.for_user(user))
    end

    test "only counts records within scope" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id)
      Factory.insert(:article, user_id: user1.id)
      Factory.insert(:article, user_id: user2.id)

      assert 2 == Articles.count(Scope.for_user(user1))
      assert 1 == Articles.count(Scope.for_user(user2))
    end

    test ":query narrows the count" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, published: true)
      Factory.insert(:article, user_id: user.id, published: false)

      assert 1 == Articles.count(Scope.for_user(user), query: &Articles.published/1)
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.count(Scope.for_user(user), unknown: true)
      end
    end
  end
end
