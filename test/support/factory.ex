defmodule EctoContext.Test.Factory do
  alias EctoContext.Test.Article
  alias EctoContext.Test.Repo
  alias EctoContext.Test.User

  def insert(factory, attrs \\ [])

  def insert(:user, attrs) do
    attrs = Enum.into(attrs, %{})
    name = Map.get(attrs, :name, "User #{System.unique_integer([:positive])}")
    is_admin = Map.get(attrs, :is_admin, false)

    %User{}
    |> Ecto.Changeset.change(%{name: name, is_admin: is_admin})
    |> Repo.insert!()
  end

  def insert(:article, attrs) do
    attrs = Enum.into(attrs, %{})
    title = Map.get(attrs, :title, "Article #{System.unique_integer([:positive])}")
    body = Map.get(attrs, :body, "Body")
    published = Map.get(attrs, :published, false)
    user_id = Map.fetch!(attrs, :user_id)

    category_id = Map.get(attrs, :category_id)

    changes = %{title: title, body: body, published: published, user_id: user_id}
    changes = if category_id, do: Map.put(changes, :category_id, category_id), else: changes

    %Article{}
    |> Ecto.Changeset.change(changes)
    |> Repo.insert!()
  end
end
