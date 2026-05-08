if Code.ensure_loaded?(Credo.Check) do
  defmodule EctoContext.Check.Design.NoUnscopedRepoInsideAppLib do
    @moduledoc """
    Unscoped Repo calls are forbidden everywhere in `lib/[app]/`.

    Inside ecto_context modules the message is more specific: bypassing the generated
    scope-aware functions undermines the permission model. Outside ecto_context modules
    the message directs callers to use context functions instead.

    ## Options

        * `:excluded_schemas` - list of schema modules whose presence in a function's head
        or body suppresses violations for that function. Use for legitimate direct-Repo
        patterns involving specific structs (e.g. `[Oban.Job]`). Pattern-matching the
        struct in the function head (`%MySchema{} = arg`) is sufficient to suppress.
        Both aliased and full-module forms are matched via suffix comparison.

        * `:excluded_paths` - list of path prefixes (relative to project root) that are
        excluded from this check entirely. Use for directories where direct Repo access
        is intentional, e.g. `["lib/mix/tasks"]`.

    """

    @explanation [check: @moduledoc]

    use Credo.Check,
      base_priority: :high,
      category: :design,
      exit_status: 1,
      param_defaults: [excluded_schemas: [], excluded_paths: [], repos: []]

    alias EctoContext.Check.Helpers

    @banned_funs ~w[all get get! get_by get_by! insert insert! update update! delete delete! aggregate]a

    @impl true
    def run(%SourceFile{} = source_file, params) do
      issue_meta = IssueMeta.for(source_file, params)
      suffixes = Helpers.configured_repo_aliases(params)
      excluded = excluded_module_parts(params)
      excluded_paths = Keyword.get(params, :excluded_paths, [])

      app = Mix.Project.config()[:app] |> to_string()
      in_app = String.starts_with?(source_file.filename, "lib/#{app}/")
      in_excluded_path = Enum.any?(excluded_paths, &String.starts_with?(source_file.filename, &1))

      if in_app and not in_excluded_path do
        is_ecto_context = Credo.Code.prewalk(source_file, &detect_ecto_context/2, false)

        source_file
        |> Credo.Code.prewalk(&collect_functions/2, [])
        |> Enum.flat_map(&issues_for_function(&1, issue_meta, suffixes, excluded, is_ecto_context))
      else
        []
      end
    end

    defp issues_for_function({_head, body} = function, issue_meta, suffixes, excluded, is_ecto_context) do
      if excluded != [] and has_excluded_module?(function, excluded) do
        []
      else
        Credo.Code.prewalk(body, &collect_repo_calls(&1, &2, issue_meta, suffixes, is_ecto_context), [])
      end
    end

    defp detect_ecto_context({:ecto_context, _, _} = node, _acc), do: {node, true}
    defp detect_ecto_context(node, acc), do: {node, acc}

    defp collect_functions({def_type, _meta, [head, [do: body]]} = node, acc)
         when def_type in [:def, :defp] do
      {node, [{head, body} | acc]}
    end

    defp collect_functions(node, acc), do: {node, acc}

    defp has_excluded_module?(_function, []), do: false

    defp has_excluded_module?({head, body}, excluded) do
      check = fn
        {:__aliases__, _, mod_parts} = node, acc ->
          {node, acc or Enum.any?(excluded, &suffix_match?(&1, mod_parts))}

        node, acc ->
          {node, acc}
      end

      {_, found_in_head} = Macro.prewalk(head, false, check)
      found_in_head or elem(Macro.prewalk(body, false, check), 1)
    end

    defp suffix_match?(allowed_parts, mod_parts) do
      n = length(mod_parts)
      n <= length(allowed_parts) and Enum.take(allowed_parts, -n) == mod_parts
    end

    defp collect_repo_calls(
           {{:., meta, [{:__aliases__, _, mod_parts}, fun]}, _call_meta, _args} = node,
           issues,
           issue_meta,
           suffixes,
           is_ecto_context
         )
         when is_list(mod_parts) and fun in @banned_funs do
      if List.last(mod_parts) in suffixes do
        {node, [issue_for(issue_meta, meta[:line], fun, is_ecto_context) | issues]}
      else
        {node, issues}
      end
    end

    defp collect_repo_calls(node, issues, _issue_meta, _suffixes, _is_ecto_context), do: {node, issues}

    defp issue_for(issue_meta, line_no, fun, true) do
      format_issue(issue_meta,
        message: "Direct Repo.#{fun} inside an ecto_context module bypasses scope/permission — use the generated context functions instead.",
        line_no: line_no,
        trigger: "Repo.#{fun}"
      )
    end

    defp issue_for(issue_meta, line_no, fun, false) do
      format_issue(issue_meta,
        message: "Direct Repo.#{fun} call outside of an ecto_context module — use a context function instead.",
        line_no: line_no,
        trigger: "Repo.#{fun}"
      )
    end

    defp excluded_module_parts(params) do
      case Keyword.get(params, :excluded_schemas, []) do
        [] -> []
        list -> Enum.map(list, fn mod -> mod |> Module.split() |> Enum.map(&String.to_atom/1) end)
      end
    end
  end
end
