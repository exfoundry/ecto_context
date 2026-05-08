if Code.ensure_loaded?(Credo.Check) do
  defmodule EctoContext.Check.Design.NoRepoOutsideAppLib do
    @moduledoc """
    Bans all direct Repo calls in `lib/` outside of the core app directory.

    The core app (`lib/[app]/`) has its own `NoUnscopedRepoInsideAppLib` check.
    Everything else in `lib/` — the web layer, mix tasks, and any other support
    code — must never touch Repo directly, no exceptions.

    ## Options

        * `:excluded_paths` - list of path prefixes (relative to project root) that
        are excluded from this check entirely. Use for directories outside `lib/[app]/`
        where direct Repo access is intentional, e.g. `["lib/mix/tasks"]`.

    """

    @explanation [check: @moduledoc]

    use Credo.Check,
      base_priority: :high,
      category: :design,
      exit_status: 1,
      param_defaults: [excluded_paths: [], repos: []]

    alias EctoContext.Check.Helpers

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)
      suffixes = Helpers.configured_repo_aliases(params)
      excluded_paths = Keyword.get(params, :excluded_paths, [])

      app = Mix.Project.config()[:app] |> to_string()
      filename = source_file.filename

      in_lib = String.starts_with?(filename, "lib/")
      in_app = String.starts_with?(filename, "lib/#{app}/")
      in_excluded_path = Enum.any?(excluded_paths, &String.starts_with?(filename, &1))

      if in_lib and not in_app and not in_excluded_path do
        source_file
        |> Credo.Code.prewalk(&collect_function_bodies/2, [])
        |> Enum.flat_map(&collect_repo_calls(&1, issue_meta, suffixes))
      else
        []
      end
    end

    defp collect_function_bodies({def_type, _meta, [_head, [do: body]]} = node, acc)
         when def_type in [:def, :defp] do
      {node, [body | acc]}
    end

    defp collect_function_bodies(node, acc), do: {node, acc}

    defp collect_repo_calls(body, issue_meta, suffixes) do
      Credo.Code.prewalk(body, &find_repo_calls(&1, &2, issue_meta, suffixes), [])
    end

    defp find_repo_calls(
           {{:., meta, [{:__aliases__, _, mod_parts}, fun]}, _call_meta, _args} = node,
           issues,
           issue_meta,
           suffixes
         )
         when is_list(mod_parts) do
      if List.last(mod_parts) in suffixes do
        {node, [issue_for(issue_meta, meta[:line], fun) | issues]}
      else
        {node, issues}
      end
    end

    defp find_repo_calls(node, issues, _issue_meta, _suffixes), do: {node, issues}

    defp issue_for(issue_meta, line_no, fun) do
      format_issue(issue_meta,
        message: "Direct Repo.#{fun} call is not allowed here — use a context function instead.",
        line_no: line_no,
        trigger: "Repo.#{fun}"
      )
    end
  end
end
