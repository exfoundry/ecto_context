defmodule EctoContext do
  @moduledoc """
  Generates standard data access functions for Ecto-backed contexts at compile time.

  The `ecto_context` declaration is the table of contents for a context module.
  Every generated function threads a `scope` through, forcing explicit authorization
  decisions at every call site.

  ## Usage

      import EctoContext

      ecto_context schema: Article, scope: &__MODULE__.scope/2 do
        list()
        get!()
        get_by!()
        create()
        update()
        delete()
        change()
      end

      def scope(query, %Scope{admin: true}), do: query
      def scope(query, %Scope{user_id: uid}), do: where(query, user_id: ^uid)

      def permission(_action, _record, %Scope{admin: true}), do: true
      def permission(_, _, _), do: false

  ## Generated functions

  | Function     | Signature                                             | Opts                                              |
  |--------------|-------------------------------------------------------|----------------------------------------------------|
  | `list`       | `list(scope, opts \\\\ [])`                           | :preload, :order_by, :limit, :select, :query       |
  | `list_for`   | `list_for(scope, assoc_atom, parent_id, opts \\\\ [])` | :preload, :order_by, :limit, :select, :query      |
  | `list_by`    | `list_by(scope, clauses, opts \\\\ [])`               | :preload, :order_by, :limit, :select, :query       |
  | `get`        | `get(scope, id, opts \\\\ [])`                        | :preload                                           |
  | `get!`       | `get!(scope, id, opts \\\\ [])`                       | :preload, :query                                   |
  | `get_by`     | `get_by(scope, clauses, opts \\\\ [])`                | :preload                                           |
  | `get_by!`    | `get_by!(scope, clauses, opts \\\\ [])`               | :preload, :query                                   |
  | `create`     | `create(scope, attrs, opts \\\\ [])`                  | :changeset (default: `:changeset`)                 |
  | `create_for` | `create_for(scope, assoc_atom, parent_id, attrs, opts \\\\ [])` | :changeset (default: `:changeset`)        |
  | `update`     | `update(scope, record, attrs, opts \\\\ [])`          | :changeset (default: `:changeset`)                 |
  | `delete`     | `delete(scope, record)`                               | —                                                  |
  | `change`     | `change(scope, record, attrs \\\\ %{}, opts \\\\ [])` | :changeset (default: `:changeset`)                |
  | `count`      | `count(scope, opts \\\\ [])`                          | :query                                             |
  | `paginate`   | `paginate(scope, opts \\\\ [])`                       | :page, :per_page, :order_by, :preload, :query      |
  | `subscribe`  | `subscribe(scope)`                                    | —                                                  |
  | `broadcast`  | `broadcast(scope, message)`                           | —                                                  |
  """

  @doc """
  Declares the generated functions for an Ecto-backed context module.

  Accepts a keyword list of context-level options (`:schema`, `:scope`, `:repo`, etc.)
  and a `do` block containing function declarations like `list()`, `get!()`, `create()`.

  See the module documentation for the full list of supported functions and options.
  """
  defmacro ecto_context(context_opts_ast, do: block) do
    {context_opts, _} =
      context_opts_ast
      |> Macro.expand(__CALLER__)
      |> Code.eval_quoted([], __CALLER__)

    settings = resolve_settings(context_opts)

    for declaration <- parse_declarations(block, __CALLER__) do
      declaration
      |> generate_function_string(settings)
      |> Code.string_to_quoted!()
    end
  end

  @doc false
  @spec parse_declarations(Macro.t(), Macro.Env.t()) :: [%{type: atom(), opts: keyword()}]
  def parse_declarations({:__block__, _, calls}, caller_env) do
    Enum.map(calls, &parse_single_declaration(&1, caller_env))
  end

  def parse_declarations(ast_call, caller_env),
    do: [parse_single_declaration(ast_call, caller_env)]

  defp parse_single_declaration({function_name, _, raw_args}, caller_env) do
    {opts_ast} =
      case raw_args do
        [] -> {[]}
        [opts] -> {opts}
      end

    {evaluated_opts, _} = Code.eval_quoted(opts_ast, [], caller_env)

    %{type: function_name, opts: evaluated_opts}
  end

  @doc false
  @spec generate_function_string(%{type: atom(), opts: keyword()}, keyword()) :: String.t()
  def generate_function_string(%{type: type, opts: declaration_opts}, ecto_context_opts) do
    merged_options = Keyword.merge(ecto_context_opts, declaration_opts)
    singular = merged_options[:schema] |> Module.split() |> List.last() |> Macro.underscore()
    bindings = Keyword.merge(merged_options, singular: singular)

    Path.join([
      :code.priv_dir(:ecto_context) |> to_string(),
      "templates",
      "ecto_context",
      "#{type}.ex.eex"
    ])
    |> EEx.eval_file(bindings)
  end

  ###########################################################################
  ### Settings resolution (compile-time, three-layer pipeline)
  ###########################################################################

  @doc """
  Resolves the effective settings for a context declaration.

  Merges three layers (lowest to highest priority):
  guessed defaults from Mix/app config, library config from
  `config :ecto_context, :defaults`, and the declaration-level opts.
  """
  @spec resolve_settings(keyword()) :: keyword()
  def resolve_settings(declaration_opts) do
    guess_defaults()
    |> merge_library_config()
    |> Keyword.merge(declaration_opts)
  end

  defp guess_defaults do
    app = Mix.Project.config()[:app]
    web_module = Module.concat([Macro.camelize("#{app}_web")])
    endpoint = Module.concat([web_module, Endpoint])

    repo =
      case Application.get_env(app, :ecto_repos) do
        [repo | _] -> repo
        nil -> nil
      end

    pubsub = Application.get_env(app, endpoint)[:pubsub_server]

    [
      app: app,
      repo: repo,
      endpoint: endpoint,
      pubsub_server: pubsub,
      topic_key: &EctoContext.default_topic_key/1,
      default_changeset: :changeset
    ]
  end

  defp merge_library_config(settings) do
    Keyword.merge(settings, Application.get_env(:ecto_context, :defaults, []))
  end

  @doc """
  Default topic key function for `subscribe/1` and `broadcast/2`.
  Returns `scope.user.id`. Override via `topic_key:` in `ecto_context`.
  """
  @spec default_topic_key(term()) :: term()
  def default_topic_key(scope), do: scope.user.id
end
