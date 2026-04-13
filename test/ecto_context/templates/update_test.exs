defmodule EctoContext.Templates.UpdateTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "update/4" do
    test "updates record when permitted" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id, title: "Old")

      assert {:ok, %Article{title: "New"}} =
               Articles.update(Scope.for_user(user), article, %{title: "New"})
    end

    test "returns :unauthorized when permission(:update, ...) denies" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user1.id)

      assert {:error, :unauthorized} =
               Articles.update(Scope.for_user(user2), article, %{title: "Hacked"})
    end

    test "returns changeset error for invalid attrs when permitted" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert {:error, changeset} =
               Articles.update(Scope.for_user(user), article, %{title: nil})

      assert changeset.errors[:title]
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.update(Scope.for_user(user), article, %{}, unknown: true)
      end
    end
  end

  describe "update/4 changeset_permission" do
    test "allows admin_changeset when scope is admin" do
      user = Factory.insert(:user, is_admin: true)
      article = Factory.insert(:article, user_id: user.id, title: "Old")

      assert {:ok, %Article{title: "New"}} =
               Articles.update(Scope.for_user(user), article, %{title: "New"},
                 changeset: :admin_changeset
               )
    end

    test "returns :unauthorized for admin_changeset when scope is regular user" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert {:error, :unauthorized} =
               Articles.update(Scope.for_user(user), article, %{title: "Nope"},
                 changeset: :admin_changeset
               )
    end

    test "default changeset is never gated by changeset_permission" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert {:ok, %Article{}} =
               Articles.update(Scope.for_user(user), article, %{title: "Normal"})
    end
  end
end
