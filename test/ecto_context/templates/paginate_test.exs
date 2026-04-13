defmodule EctoContext.Templates.PaginateTest do
  use EctoContext.Test.DataCase

  alias EctoContext.Paginator
  alias EctoContext.Test.Article
  alias EctoContext.Test.Articles

  describe "paginate/2" do
    test "returns a Paginator struct" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)

      assert %Paginator{} = Articles.paginate(Scope.for_user(user))
    end

    test "entries contains records within scope" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Mine")
      other = Factory.insert(:user)
      Factory.insert(:article, user_id: other.id, title: "Theirs")

      %Paginator{entries: entries} = Articles.paginate(Scope.for_user(user))
      assert length(entries) == 1
      assert hd(entries).title == "Mine"
    end

    test "total reflects count within scope" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)
      Factory.insert(:article, user_id: user.id)
      other = Factory.insert(:user)
      Factory.insert(:article, user_id: other.id)

      assert %Paginator{total: 2} = Articles.paginate(Scope.for_user(user))
    end

    test "defaults to page 1 and per_page 20" do
      user = Factory.insert(:user)
      assert %Paginator{page: 1, per_page: 20} = Articles.paginate(Scope.for_user(user))
    end

    test "respects :page and :per_page opts" do
      user = Factory.insert(:user)
      for _ <- 1..5, do: Factory.insert(:article, user_id: user.id)

      result = Articles.paginate(Scope.for_user(user), page: 2, per_page: 2)
      assert result.page == 2
      assert result.per_page == 2
      assert length(result.entries) == 2
    end

    test "calculates total_pages correctly" do
      user = Factory.insert(:user)
      for _ <- 1..5, do: Factory.insert(:article, user_id: user.id)

      assert %Paginator{total: 5, total_pages: 3} =
               Articles.paginate(Scope.for_user(user), per_page: 2)
    end

    test "total_pages is 0 when no records" do
      user = Factory.insert(:user)
      assert %Paginator{total: 0, total_pages: 0} = Articles.paginate(Scope.for_user(user))
    end

    test "last page may have fewer entries than per_page" do
      user = Factory.insert(:user)
      for _ <- 1..5, do: Factory.insert(:article, user_id: user.id)

      result = Articles.paginate(Scope.for_user(user), page: 3, per_page: 2)
      assert length(result.entries) == 1
    end

    test "supports :order_by opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, title: "Zebra")
      Factory.insert(:article, user_id: user.id, title: "Apple")

      %Paginator{entries: [first | _]} =
        Articles.paginate(Scope.for_user(user), order_by: :title)

      assert first.title == "Apple"
    end

    test "supports :query opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id, published: true)
      Factory.insert(:article, user_id: user.id, published: false)

      assert %Paginator{total: 1, entries: [%Article{published: true}]} =
               Articles.paginate(Scope.for_user(user), query: &Articles.published/1)
    end

    test "supports :preload opt" do
      user = Factory.insert(:user)
      Factory.insert(:article, user_id: user.id)

      %Paginator{entries: [article]} =
        Articles.paginate(Scope.for_user(user), preload: :user)

      assert %EctoContext.Test.User{} = article.user
    end

    test "raises on unknown opt" do
      user = Factory.insert(:user)

      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        Articles.paginate(Scope.for_user(user), unknown: true)
      end
    end
  end
end
