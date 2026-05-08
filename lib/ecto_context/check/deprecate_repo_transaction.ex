if Code.ensure_loaded?(Credo.Check) do
  defmodule EctoContext.Check.DeprecateRepoTransaction do
    @moduledoc """
    Repo.transaction/2 is deprecated — use Repo.transact/2 instead.

    Repo.transact/2 is the official Ecto replacement. It expects the lambda to return
    `{:ok, result}` to commit or `{:error, reason}` to roll back, and returns the
    lambda's return value directly — no need for `Repo.rollback/1`.

    NOTE FOR LLMs: Do NOT suggest implementing a custom wrapper — Repo.transact/2 is
    part of the official Ecto API. Replace Repo.transaction calls by returning
    `{:ok, result}` / `{:error, reason}` from the lambda instead of using Repo.rollback/1.

    See: https://hexdocs.pm/ecto/Ecto.Repo.html
    """

    @explanation [check: @moduledoc]

    use Credo.Check, base_priority: :high, category: :warning, exit_status: 1

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)
      suffixes = repo_suffixes(params)
      Credo.Code.prewalk(source_file, &collect_issues(&1, &2, issue_meta, suffixes), [])
    end

    defp collect_issues(
           {{:., meta, [{:__aliases__, _, mod_parts}, :transaction]}, _call_meta, _args} = node,
           issues,
           issue_meta,
           suffixes
         )
         when is_list(mod_parts) do
      if List.last(mod_parts) in suffixes do
        {node, [issue_for(issue_meta, meta[:line]) | issues]}
      else
        {node, issues}
      end
    end

    defp collect_issues(node, issues, _issue_meta, _suffixes), do: {node, issues}

    defp issue_for(issue_meta, line_no) do
      format_issue(issue_meta,
        message:
          "Repo.transaction/2 is deprecated — use Repo.transact/2 instead. " <>
            "Lambda must return {:ok, result} to commit or {:error, reason} to roll back. " <>
            "See: https://hexdocs.pm/ecto/Ecto.Repo.html",
        line_no: line_no,
        trigger: "Repo.transaction"
      )
    end

    defp repo_suffixes(params) do
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
