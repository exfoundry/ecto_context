if Code.ensure_loaded?(Credo.Check) do
  defmodule EctoContext.Check.Helpers do
    @moduledoc "Shared helpers for EctoContext Credo checks."

    @doc """
    Returns the short atom names of the configured Repo modules.

    Reads `:repos` from `params` if provided, otherwise falls back to the app's
    `:ecto_repos` config. Returns the last segment of each module as an atom —
    e.g. `[MyApp.Repo, MyApp.ReadonlyRepo]` becomes `[:Repo, :ReadonlyRepo]`.
    These are the names that appear at aliased call sites in the AST.
    """
    def configured_repo_aliases(params) do
      repos =
        case Keyword.get(params, :repos, []) do
          [] ->
            app = Mix.Project.config()[:app]
            Application.get_env(app, :ecto_repos, [])

          explicit ->
            explicit
        end

      case repos do
        [] -> [:Repo]
        list -> Enum.map(list, fn repo -> repo |> Module.split() |> List.last() |> String.to_atom() end)
      end
    end
  end
end
