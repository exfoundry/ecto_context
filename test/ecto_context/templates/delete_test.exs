defmodule EctoContext.Templates.DeleteTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "delete/2" do
    test "deletes record when permission(:delete, ...) allows" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert {:ok, %Article{}} = Articles.delete(Scope.global_access(), article)
      assert nil == Articles.get(Scope.global_access(), article.id)
    end

    test "returns :unauthorized when permission(:delete, ...) denies for another user's record" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user1.id)

      assert {:error, :unauthorized} = Articles.delete(Scope.for_user(user2), article)
    end

    test "returns :unauthorized for :delete even when user owns the record" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert {:error, :unauthorized} = Articles.delete(Scope.for_user(user), article)
    end

    test "does not delete record when unauthorized" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user1.id)

      Articles.delete(Scope.for_user(user2), article)
      assert Articles.get(Scope.global_access(), article.id)
    end
  end
end
