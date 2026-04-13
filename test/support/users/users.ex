defmodule EctoContext.Test.Users do
  import EctoContext

  alias EctoContext.Test.Scope
  alias EctoContext.Test.User

  ecto_context schema: User, scope: &__MODULE__.scope/2, repo: EctoContext.Test.Repo do
    list()
    get()
    get!()
    create()
    update()
    delete()
    change()
  end

  def scope(query, _scope), do: query

  def permission(_action, _user, %Scope{admin: true}), do: true
  def permission(_action, _user, _scope), do: false
end
