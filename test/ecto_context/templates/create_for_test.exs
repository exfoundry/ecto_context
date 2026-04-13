defmodule EctoContext.Templates.CreateForTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "create_for/5" do
    test "creates a record associated to the given parent" do
      user = Factory.insert(:user)

      assert {:ok, %Article{title: "New", user_id: user_id}} =
               Articles.create_for(Scope.for_user(user), :user, user.id, %{title: "New"})

      assert user_id == user.id
    end

    test "parent_id from assoc overrides any user_id in attrs" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)

      assert {:ok, %Article{user_id: user_id}} =
               Articles.create_for(
                 Scope.for_user(user1),
                 :user,
                 user1.id,
                 %{title: "New", user_id: user2.id}
               )

      assert user_id == user1.id
    end

    test "returns changeset error for invalid attrs" do
      user = Factory.insert(:user)

      assert {:error, changeset} =
               Articles.create_for(Scope.for_user(user), :user, user.id, %{})

      assert changeset.errors[:title]
    end

    test "returns :unauthorized when permission(:create, ...) denies" do
      user = Factory.insert(:user)

      assert {:error, :unauthorized} =
               Articles.create_for(%Scope{}, :user, user.id, %{title: "Hacked"})
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.create_for(Scope.for_user(user), :user, user.id, %{title: "x"}, unknown: true)
      end
    end
  end

  describe "create_for/5 changeset_permission" do
    test "allows admin_changeset when scope is admin" do
      user = Factory.insert(:user, is_admin: true)

      assert {:ok, %Article{}} =
               Articles.create_for(Scope.for_user(user), :user, user.id, %{title: "Admin"},
                 changeset: :admin_changeset
               )
    end

    test "returns :unauthorized for admin_changeset when scope is regular user" do
      user = Factory.insert(:user)

      assert {:error, :unauthorized} =
               Articles.create_for(Scope.for_user(user), :user, user.id, %{title: "Nope"},
                 changeset: :admin_changeset
               )
    end

    test "default changeset is never gated by changeset_permission" do
      user = Factory.insert(:user)

      assert {:ok, %Article{}} =
               Articles.create_for(Scope.for_user(user), :user, user.id, %{title: "Normal"})
    end
  end
end
