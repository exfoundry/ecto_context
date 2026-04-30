defmodule EctoContext.Templates.GetByTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "get_by/3" do
    test "returns record matching clauses when permission(:get, ...) allows" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Specific")

      assert %Article{title: "Specific"} =
               Articles.get_by(Scope.for_user(user), title: "Specific")
    end

    test "returns nil when no match" do
      user = Factory.insert(:user)
      assert nil == Articles.get_by(Scope.for_user(user), title: "Nonexistent")
    end

    test "returns nil when permission(:get, ...) denies" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id, title: "Specific")

      assert nil == Articles.get_by(Scope.for_user(user2), title: "Specific")
    end

    test ":query further narrows results" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Draft", published: false)

      assert nil ==
               Articles.get_by(Scope.for_user(user), [title: "Draft"], query: &Articles.published/1)
    end

    test ":select returns only selected fields" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Hello")

      result =
        Articles.get_by(Scope.for_user(user), [title: "Hello"], select: [:id, :title, :user_id])

      assert result.title == "Hello"
      assert result.body == nil
    end

    test ":order_by and :limit return first matching record" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "B")
      Factory.insert(:article, user_id: user.id, title: "A")

      result =
        Articles.get_by(Scope.for_user(user), [user_id: user.id],
          order_by: [asc: :title],
          limit: 1
        )

      assert result.title == "A"
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.get_by(Scope.for_user(user), [title: "x"], unknown: true)
      end
    end
  end

  describe "get_by!/3" do
    test "returns record matching clauses when permission(:get, ...) allows" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Specific")

      assert %Article{title: "Specific"} =
               Articles.get_by!(Scope.for_user(user), title: "Specific")
    end

    test "raises when no match" do
      user = Factory.insert(:user)

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get_by!(Scope.for_user(user), title: "Nonexistent")
      end
    end

    test "raises when permission(:get, ...) denies" do
      user1 = Factory.insert(:user)
      user2 = Factory.insert(:user)
      Factory.insert(:article, user_id: user1.id, title: "Specific")

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get_by!(Scope.for_user(user2), title: "Specific")
      end
    end

    test ":query further narrows results" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Draft", published: false)

      assert_raise Ecto.NoResultsError, fn ->
        Articles.get_by!(Scope.for_user(user), [title: "Draft"], query: &Articles.published/1)
      end
    end

    test ":select returns only selected fields" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Hello")

      result =
        Articles.get_by!(Scope.for_user(user), [title: "Hello"], select: [:id, :title, :user_id])

      assert result.title == "Hello"
      assert result.body == nil
    end

    test ":order_by and :limit return first matching record" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "B")
      Factory.insert(:article, user_id: user.id, title: "A")

      result =
        Articles.get_by!(Scope.for_user(user), [user_id: user.id],
          order_by: [asc: :title],
          limit: 1
        )

      assert result.title == "A"
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.get_by!(Scope.for_user(user), [title: "x"], unknown: true)
      end
    end
  end
end
