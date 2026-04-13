defmodule EctoContext.Test.Articles do
  import EctoContext
  import Ecto.Query, only: [where: 2, where: 3]

  alias EctoContext.Test.Article
  alias EctoContext.Test.Scope

  ecto_context schema: Article, scope: &__MODULE__.scope/2, repo: EctoContext.Test.Repo do
    list()
    list_by()
    list_for()
    get()
    get!()
    get_by()
    get_by!()
    create()
    create_for()
    update()
    delete()
    change()
    count()
    paginate()
  end

  def published(query), do: where(query, [a], a.published == true)

  def scope(query, %Scope{admin: true}), do: query
  def scope(query, %Scope{user_id: user_id}), do: where(query, user_id: ^user_id)

  # Admins can do everything
  def permission(_action, _article, %Scope{admin: true}), do: true
  # Regular users can create articles
  def permission(:create, %Article{}, %Scope{user_id: user_id}) when not is_nil(user_id), do: true
  # Regular users can get and update their own articles, but not delete them
  def permission(action, %Article{user_id: user_id}, %Scope{user_id: user_id})
      when action in [:get, :update] and not is_nil(user_id),
      do: true

  def permission(_, _, _), do: false

  def changeset_permission(:admin_changeset, %Scope{admin: true}), do: true
  def changeset_permission(:admin_changeset, _scope), do: false
end
