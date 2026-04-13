defmodule EctoContext.Test.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name, :string
    field :is_admin, :boolean, default: false
    has_many :articles, EctoContext.Test.Article
    timestamps()
  end

  def changeset(user, attrs, _scope) do
    user
    |> cast(attrs, [:name, :is_admin])
    |> validate_required([:name])
  end
end
