defmodule EctoContext.Test.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :body, :string
    field :published, :boolean, default: false
    belongs_to :user, EctoContext.Test.User
    field :category_id, :string
    timestamps()
  end

  def changeset(article, attrs, _scope) do
    article
    |> cast(attrs, [:title, :body, :published, :user_id, :category_id])
    |> validate_required([:title])
  end

  def admin_changeset(article, attrs, _scope) do
    article
    |> cast(attrs, [:title, :body, :published, :user_id, :category_id])
    |> validate_required([:title])
  end
end
