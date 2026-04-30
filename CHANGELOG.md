# Changelog

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
