defmodule EctoContext.Test.Scope do
  defstruct [:user_id, admin: false]

  def for_user(%{is_admin: true}), do: %__MODULE__{admin: true}
  def for_user(user), do: %__MODULE__{user_id: user.id}

  def global_access, do: %__MODULE__{admin: true}
end
