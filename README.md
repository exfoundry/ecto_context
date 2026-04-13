# EctoContext

Scoped CRUD with permission layer via macro DSL for Ecto schemas.

Write the declaration block once — `ecto_context` generates the full set of
data access functions at compile time, each threading a `scope` through for
authorization. No hidden behaviour: `import EctoContext`, declare what you
need, and the generated code is visible in the compiled module.

Part of the [ExFoundry](https://github.com/exfoundry) family.
Pairs well with [`static_context`](https://github.com/exfoundry/static_context)
for in-memory lookup data that plugs into Ecto schemas via `static_belongs_to`.

## Why scope is mandatory

`ecto_context` is designed for codebases where LLMs generate and modify
application code. When an LLM writes a new context or adds a query, the
scope parameter is always there — it cannot be forgotten or skipped. There
is no `unscoped` escape hatch and there never will be.

This is a deliberate design choice: in AI-assisted development, the path of
least resistance must be the secure path. If a convenience function without
authorization exists, an LLM will eventually use it. By making scope the
only option, every generated data access function is authorized by default.

## Installation

```elixir
def deps do
  [{:ecto_context, "~> 0.1"}]
end
```

## Usage

```elixir
defmodule MyApp.Articles do
  import Ecto.Query
  import EctoContext

  alias MyApp.Article
  alias MyApp.Scope

  ecto_context schema: Article, scope: &__MODULE__.scope/2 do
    list()
    list_by()
    list_for()
    get!()
    get_by!()
    create()
    update()
    delete()
    change()
    count()
    paginate()
  end

  def scope(query, %Scope{admin: true}), do: query
  def scope(query, %Scope{user_id: uid}), do: where(query, user_id: ^uid)

  def permission(:create, _article, %Scope{user_id: uid}) when not is_nil(uid), do: true
  def permission(:update, article, %Scope{user_id: uid}), do: article.user_id == uid
  def permission(_, _, _), do: false
end
```

Every generated function receives the `scope` as its first argument, which is
passed to your `scope/2` callback to apply query-level filtering (e.g.
multi-tenancy, ownership). Write operations call `permission/3` on the module
to authorize the action before executing.

## Generated functions

| Function     | Signature                                                       | Runtime opts                                      |
|--------------|-----------------------------------------------------------------|---------------------------------------------------|
| `list`       | `list(scope, opts \\ [])`                                      | :preload, :order_by, :limit, :select, :query      |
| `list_for`   | `list_for(scope, assoc_atom, parent_id, opts \\ [])`           | :preload, :order_by, :limit, :select, :query      |
| `list_by`    | `list_by(scope, clauses, opts \\ [])`                          | :preload, :order_by, :limit, :select, :query      |
| `get`        | `get(scope, id, opts \\ [])`                                   | :preload                                          |
| `get!`       | `get!(scope, id, opts \\ [])`                                  | :preload, :query                                  |
| `get_by`     | `get_by(scope, clauses, opts \\ [])`                           | :preload                                          |
| `get_by!`    | `get_by!(scope, clauses, opts \\ [])`                          | :preload, :query                                  |
| `create`     | `create(scope, attrs, opts \\ [])`                             | :changeset (default: `:changeset`)                |
| `create_for` | `create_for(scope, assoc_atom, parent_id, attrs, opts \\ [])` | :changeset (default: `:changeset`)                |
| `update`     | `update(scope, record, attrs, opts \\ [])`                     | :changeset (default: `:changeset`)                |
| `delete`     | `delete(scope, record)`                                        | —                                                 |
| `change`     | `change(scope, record, attrs \\ %{}, opts \\ [])`             | :changeset (default: `:changeset`)                |
| `count`      | `count(scope, opts \\ [])`                                     | :query                                            |
| `paginate`   | `paginate(scope, opts \\ [])`                                  | :page, :per_page, :order_by, :preload, :query     |
| `subscribe`  | `subscribe(scope)`                                             | —                                                 |
| `broadcast`  | `broadcast(scope, message)`                                    | —                                                 |

Only declare the functions you need — nothing else is generated.

## Configuration

`ecto_context` auto-detects `:repo`, `:endpoint`, and `:pubsub_server` from
your application config. Override any of these at the declaration level:

```elixir
ecto_context schema: Article,
             scope: &__MODULE__.scope/2,
             repo: MyApp.Repo,
             pubsub_server: MyApp.PubSub do
  list()
  subscribe()
  broadcast()
end
```

Library-wide defaults can be set in config:

```elixir
config :ecto_context, :defaults,
  repo: MyApp.Repo,
  pubsub_server: MyApp.PubSub
```

## How it works

Each function declaration in the `do` block maps to an EEx template in
`priv/templates/ecto_context/`. At compile time the macro renders the template,
converts the result to AST via `Code.string_to_quoted!/1`, and injects it into
the calling module. No runtime overhead, no hidden middleware — the generated
functions are plain Elixir.

## License

MIT
