# Changelog

## [0.1.5] - 2026-05-08

### Added
- `EctoContext.Check.ForceScoped` — optional Credo check (requires `{:credo, "~> 1.7"}`)
  that enforces use of generated scoped functions in ecto_context modules. Bans direct
  Repo calls for operations ecto_context covers (`all`, `get`, `get!`, `get_by`,
  `get_by!`, `insert`, `insert!`, `update`, `update!`, `delete`, `delete!`, `aggregate`);
  allows everything else (`transact`, `delete_all`, `insert_all`, `update_all`, …).
  Repos are configured via `repos: [MyApp.Repo]` or auto-detected from `:ecto_repos`.
- `EctoContext.Check.DeprecateRepoTransaction` — flags `Repo.transaction/2` project-wide
  and points to `Repo.transact/2`, the official Ecto replacement.

## [0.1.4] - 2026-04-30

### Added
- `get_by` and `get_by!` now support `:order_by` and `:limit` options, enabling
  "fetch first matching by ordering" patterns without a custom `:query` function

## [0.1.3] - 2026-04-30

### Fixed
- README and `usage-rules.md` now correctly document `get`, `get!`, `get_by`, `get_by!` opts (`:preload, :select, :query`)
- `usage-rules.md` clarifies that `:query` is always a 1-arity function; separates list-family opts from get-family opts

## [0.1.2] - 2026-04-30

### Added
- `get`, `get!`, `get_by`, `get_by!` now support `:select` and `:query` options
- All four get-family functions now accept the same uniform option set: `:preload`, `:select`, `:query`

## [0.1.1] - 2026-04-17

### Added
- `usage-rules.md` — focused LLM-oriented rules file ships with the hex
  package. Covers return-value shapes, `scope/2` vs `permission/3`, the
  `:get` unauthorized-collapses-to-nil trap, and common API pitfalls.
- README section pointing AI agents at `deps/ecto_context/usage-rules.md`.

## [0.1.0] - 2026-04-13

### Added
- `ecto_context/2` macro for generating scoped CRUD functions
- 16 generated functions: list, list_by, list_for, get, get!, get_by, get_by!, create, create_for, update, delete, change, count, paginate, subscribe, broadcast
- `EctoContext.Query` — runtime query helpers
- `EctoContext.Validate` — runtime validation helpers
- `EctoContext.Paginator` — pagination struct
