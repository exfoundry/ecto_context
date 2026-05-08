if Code.ensure_loaded?(Credo.Check) do
  defmodule EctoContext.Check.ForceScoped do
    @moduledoc """
    In ecto_context modules, use the generated scoped functions — not Repo directly.

    ecto_context generates scoped, authorized CRUD functions. Calling Repo directly for
    operations it covers bypasses scope/permission entirely.

    The following Repo functions are banned because ecto_context replaces them:
    `all`, `get`, `get!`, `get_by`, `get_by!`, `insert`, `insert!`, `update`, `update!`,
    `delete`, `delete!`, `aggregate`

    Everything else (`transact`, `delete_all`, `insert_all`, `update_all`, `preload`, …)
    is allowed — ecto_context does not cover those.

    ## Configuration

        {EctoContext.Check.ForceScoped, [repos: [MyApp.Repo, MyApp.ReadonlyRepo]]}

    If `repos` is omitted or empty, the check reads `:ecto_repos` from the application
    config (`Mix.Project.config()[:app]`). If that is also empty, any module whose last
    segment is `Repo` is matched.
    """

    @explanation [check: @moduledoc]

    use Credo.Check, base_priority: :high, category: :design, exit_status: 1

    @banned_funs ~w[all get get! get_by get_by! insert insert! update update! delete delete! aggregate]a

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)
      suffixes = repo_suffixes(params)

      if Credo.Code.prewalk(source_file, &detect_ecto_context/2, false) do
        Credo.Code.prewalk(source_file, &collect_issues(&1, &2, issue_meta, suffixes), [])
      else
        []
      end
    end

    defp detect_ecto_context({:ecto_context, _, _} = node, _acc), do: {node, true}
    defp detect_ecto_context(node, acc), do: {node, acc}

    defp collect_issues(
           {{:., meta, [{:__aliases__, _, mod_parts}, fun]}, _call_meta, _args} = node,
           issues,
           issue_meta,
           suffixes
         )
         when is_list(mod_parts) and fun in @banned_funs do
      if List.last(mod_parts) in suffixes do
        {node, [issue_for(issue_meta, meta[:line], fun) | issues]}
      else
        {node, issues}
      end
    end

    defp collect_issues(node, issues, _issue_meta, _suffixes), do: {node, issues}

    defp issue_for(issue_meta, line_no, fun) do
      format_issue(issue_meta,
        message:
          "Do not call Repo.#{fun} directly in an ecto_context module — this bypasses scope/permission. " <>
            "Use the generated functions (list/2, get!/3, create/3, etc.) instead. " <>
            "See: https://hexdocs.pm/ecto_context",
        line_no: line_no,
        trigger: "Repo.#{fun}"
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
