defmodule EctoContext.Templates.ChangeTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Articles

  describe "change/4" do
    test "returns a changeset when permitted" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert %Ecto.Changeset{} = Articles.change(Scope.for_user(user), article)
    end

    test "changeset reflects passed attrs" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id, title: "Old")

      changeset = Articles.change(Scope.for_user(user), article, %{title: "Draft"})
      assert Ecto.Changeset.get_change(changeset, :title) == "Draft"
    end

    test "raises ArgumentError when not permitted" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user1.id)

      assert_raise ArgumentError, ~r/unauthorized/, fn ->
        Articles.change(Scope.for_user(user2), article)
      end
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.change(Scope.for_user(user), article, %{}, unknown: true)
      end
    end
  end

  describe "change/4 changeset_permission" do
    test "allows admin_changeset when scope is admin" do
      user = Factory.insert(:user, is_admin: true)
      article = Factory.insert(:article, user_id: user.id)

      assert %Ecto.Changeset{} =
               Articles.change(Scope.for_user(user), article, %{title: "Admin"},
                 changeset: :admin_changeset
               )
    end

    test "raises for admin_changeset when scope is regular user" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert_raise ArgumentError, ~r/changeset :admin_changeset not permitted/, fn ->
        Articles.change(Scope.for_user(user), article, %{title: "Nope"},
          changeset: :admin_changeset
        )
      end
    end

    test "default changeset is never gated by changeset_permission" do
      user = Factory.insert(:user)
      article = Factory.insert(:article, user_id: user.id)

      assert %Ecto.Changeset{} = Articles.change(Scope.for_user(user), article)
    end
  end
end
