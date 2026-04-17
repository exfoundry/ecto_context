# ecto_context usage rules

Rules apply to `ecto_context ~> 0.1`.

Compile-time macro DSL that generates scoped, authorized CRUD for Ecto
schemas. Every generated function takes `scope` as its first argument.
There is no unscoped alternative — this is intentional.

## Minimal pattern

```elixir
defmodule MyApp.Articles do
  import Ecto.Query
  import EctoContext

  alias MyApp.Article
  alias MyApp.Scope

  ecto_context schema: Article, scope: &__MODULE__.scope/2 do
    list()
    get!()
    create()
    update()
    delete()
  end

  # Query-level scoping: runs for every list/count/paginate.
  def scope(query, %Scope{admin: true}), do: query
  def scope(query, %Scope{user_id: uid}), do: where(query, user_id: ^uid)

  # Action-level permission: runs before every write AND for every get.
  def permission(:create, _article, %Scope{user_id: uid}) when not is_nil(uid), do: true
  def permission(:update, article, %Scope{user_id: uid}), do: article.user_id == uid
  def permission(:get, article, %Scope{user_id: uid}), do: article.user_id == uid
  def permission(_, _, _), do: false
end
```

Call sites always pass scope first: `Articles.list(scope)`, `Articles.get!(scope, id)`.

## Available functions

Declare only what you need — the block is the public API surface.

- Reads: `list/2`, `list_for/4`, `list_by/3`, `get/3`, `get!/3`, `get_by/3`,
  `get_by!/3`, `count/2`, `paginate/2`
- Writes: `create/3`, `create_for/5`, `update/4`, `delete/2`, `change/4`
- PubSub: `subscribe/1`, `broadcast/2` (requires `:pubsub_server`)

Read opts: `:preload`, `:order_by`, `:limit`, `:select`, `:query`.
Write opts: `:changeset` (default `:changeset`).

## Return values

Reads and writes use different conventions. This is intentional (Phoenix
idiom) but easy to miss.

| Function | Success | Not found | Unauthorized | Validation error |
|---|---|---|---|---|
| `get/3`, `get_by/3` | `record` | `nil` | `nil` | — |
| `get!/3`, `get_by!/3` | `record` | raises `Ecto.NoResultsError` | raises `Ecto.NoResultsError` | — |
| `list/2`, `list_for/4`, `list_by/3` | `[record]` | `[]` | `[]` (filtered by scope) | — |
| `count/2` | integer | `0` | `0` | — |
| `paginate/2` | `%{entries: [...], ...}` | entries `[]` | entries `[]` | — |
| `create/3`, `create_for/5` | `{:ok, record}` | — | `{:error, :unauthorized}` | `{:error, changeset}` |
| `update/4` | `{:ok, record}` | — | `{:error, :unauthorized}` | `{:error, changeset}` |
| `delete/2` | `{:ok, record}` | — | `{:error, :unauthorized}` | — |
| `change/4` | `%Ecto.Changeset{}` | — | `%Ecto.Changeset{}` | — |

Key traps:

- **`get/3` returns `nil` for both not-found AND unauthorized.** You cannot
  distinguish the two. Treat unauthorized as not-found (that's the point).
- **`get!/3` raises `Ecto.NoResultsError` on unauthorized**, not a permission
  error. Same rationale — caller should not learn the record exists.
- **Reads never return `{:error, _}` tuples.** Only writes do.
- **`list/2` silently filters unauthorized records** via `scope/2`. An empty
  list is ambiguous: no data exists, or scope excluded everything.

## `scope/2` vs `permission/3`

Core rule: **multiple records → `scope/2`. One record → `permission/3`.**

- **`scope/2`** — `(query, scope) -> query`. Always required. Filters every
  list/count/paginate. Not called for `get`/`get!`/`get_by`/`get_by!` —
  those use `Repo.get` and then check `permission(:get, record, scope)`.
- **`permission/3`** — `(action, record_or_nil, scope) -> boolean`. Required
  if you use any write OR any get. Action is `:create | :update | :delete | :get`.

Which action atom fires for which function:

| Action | Fires for |
|---|---|
| `:create` | `create/3`, `create_for/5` |
| `:get` | `get/3`, `get!/3`, `get_by/3`, `get_by!/3` |
| `:update` | `update/4` |
| `:delete` | `delete/2` |

`change/4` infers the action from the record: `:create` if `record.id == nil`,
`:update` otherwise.

Both callbacks must be `def` (public), not `defp`. The generated code calls
them by name.

## Do

- **Use `import EctoContext`** — this module has no `use/2`.
- **Always pass scope first**, including reads: `Articles.list(scope)`.
- **Handle every scope variant in `scope/2`.** Add a catch-all deny clause
  for secure-by-default:
  ```elixir
  def scope(_query, _), do: from(x in Article, where: false)
  ```
- **Implement `permission(:get, ...)`** if you declare `get/get!/get_by/get_by!`.
  Forgetting it means every fetch returns `nil` / raises.
- **Match `nil` on get**, not `{:error, _}`:
  ```elixir
  case Articles.get(scope, id) do
    nil -> {:error, :not_found}
    article -> {:ok, article}
  end
  ```
- **Pair with `ecto_trim`** for text fields — ecto_context does not trim.
- **Use fully-qualified module names** for `:schema` if alias resolution
  misbehaves at compile time.

## Don't

- **Don't `use EctoContext`** — `use/2` does not exist on this module.
- **Don't call reads without scope** — `Articles.list()` is a compile error,
  not a convenience.
- **Don't expect `{:ok, record}` from `get/3`** — it returns `record | nil`,
  where `nil` covers both not-found and unauthorized.
- **Don't expect a distinct unauthorized signal from reads** — `get` returns
  `nil`, `get!` raises `Ecto.NoResultsError`, `list` silently filters.
- **Don't `def list/2`, `def get!/3`, etc. yourself** — generated names
  clash with hand-written ones. The macro owns those arities.
- **Don't reach for `unscoped`** — it does not exist and never will. For
  true bypasses (migrations, admin one-offs), call `Repo.all(query)` in a
  separate, clearly-named function outside the context.
- **Don't make `scope/2` or `permission/3` private** — the macro expands to
  external calls by name.

## Configuration

Repo, PubSub server, and Phoenix endpoint auto-detect from
`Mix.Project.config()` — usually no config needed.

Library-wide defaults:

```elixir
config :ecto_context, :defaults,
  repo: MyApp.Repo,
  pubsub_server: MyApp.PubSub
```

Per-module override:

```elixir
ecto_context schema: Article,
             scope: &__MODULE__.scope/2,
             repo: MyApp.OtherRepo do
  list()
end
```

## Testing

Test your callbacks — `scope/2`, `permission/3`, custom changesets. Don't
re-test the macro (covered in `ecto_context` itself).

```elixir
test "list/2 filters by scope" do
  admin = %Scope{admin: true}
  user  = %Scope{user_id: 42}
  assert length(Articles.list(admin)) == 2
  assert length(Articles.list(user))  == 1
end

test "get/3 returns nil for unauthorized" do
  other = %Scope{user_id: 999}
  article = insert_article(user_id: 42)
  assert Articles.get(other, article.id) == nil
end

test "create/3 denied without user_id" do
  assert {:error, :unauthorized} = Articles.create(%Scope{user_id: nil}, %{...})
end
```

Factory/fixture choice is up to the project — ecto_context has no opinion.

## Debugging the macro

To see exactly what a generated function does, read the EEx templates:

```
deps/ecto_context/priv/templates/ecto_context/*.eex
```

One file per generated function (`get.ex.eex`, `create.ex.eex`, etc.).
Faster than inferring from `@doc` or guessing.
