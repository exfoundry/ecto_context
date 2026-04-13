defmodule EctoContext.Templates.CreateTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "create/3" do
    test "creates a record with valid attrs" do
      user = Factory.insert(:user)

      assert {:ok, %Article{title: "New"}} =
               Articles.create(Scope.for_user(user), %{title: "New", user_id: user.id})
    end

    test "returns changeset error for invalid attrs" do
      user = Factory.insert(:user)

      assert {:error, changeset} =
               Articles.create(Scope.for_user(user), %{user_id: user.id})

      assert changeset.errors[:title]
    end

    test "persists the record to the database" do
      user = Factory.insert(:user)

      {:ok, article} =
        Articles.create(Scope.for_user(user), %{title: "Persisted", user_id: user.id})

      assert Articles.get(Scope.for_user(user), article.id)
    end

    test "returns :unauthorized when permission(:create, ...) denies" do
      assert {:error, :unauthorized} =
               Articles.create(%Scope{}, %{title: "Hacked"})
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.create(Scope.for_user(user), %{title: "x"}, unknown: true)
      end
    end
  end

  describe "create/3 changeset_permission" do
    test "allows admin_changeset when scope is admin" do
      user = Factory.insert(:user, is_admin: true)

      assert {:ok, %Article{}} =
               Articles.create(Scope.for_user(user), %{title: "Admin", user_id: user.id},
                 changeset: :admin_changeset
               )
    end

    test "returns :unauthorized for admin_changeset when scope is regular user" do
      user = Factory.insert(:user)

      assert {:error, :unauthorized} =
               Articles.create(Scope.for_user(user), %{title: "Nope", user_id: user.id},
                 changeset: :admin_changeset
               )
    end

    test "default changeset is never gated by changeset_permission" do
      user = Factory.insert(:user)

      assert {:ok, %Article{}} =
               Articles.create(Scope.for_user(user), %{title: "Normal", user_id: user.id})
    end
  end
end
