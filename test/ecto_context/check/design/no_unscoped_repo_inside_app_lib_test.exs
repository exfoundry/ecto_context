defmodule EctoContext.Check.Design.NoUnscopedRepoInsideAppLibTest do
  use Credo.Test.Case

  alias EctoContext.Check.Design.NoUnscopedRepoInsideAppLib

  @repos [repos: [Platform.Repo]]

  describe "run/2" do
    test "flags Repo.all outside an ecto_context module" do
      """
      defmodule Platform.SomeWorker do
        def run, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "flags Repo.insert outside an ecto_context module" do
      """
      defmodule Platform.SomeWorker do
        def run(attrs), do: Platform.Repo.insert(%Thing{} |> Thing.changeset(attrs))
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.insert" end)
    end

    test "flags multiple violations in multiple functions" do
      """
      defmodule Platform.SomeWorker do
        def fetch_all, do: Platform.Repo.all(Thing)
        def fetch(id), do: Platform.Repo.get(Thing, id)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> assert_issues(2)
    end

    test "flags Repo.all inside ecto_context module with scoped message" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def fetch_all, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/things/things.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> assert_issue(fn issue ->
        assert issue.trigger == "Repo.all"
        assert issue.message =~ "bypasses scope/permission"
      end)
    end

    test "skips files outside lib/[app]/" do
      """
      defmodule Platform.SomeWorker do
        def run, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("test/some_test.exs")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> refute_issues()
    end

    test "skips files in lib/ but outside lib/[app]/ (covered by NoRepoOutsideAppLib)" do
      """
      defmodule PlatformWeb.SomeController do
        def index(conn, _), do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> refute_issues()
    end

    test "reports aliased Repo call" do
      """
      defmodule Platform.SomeWorker do
        alias Platform.Repo
        def run, do: Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "reports deeply nested full module path form (e.g. Platform.Data.Repo.insert)" do
      """
      defmodule Platform.SomeWorker do
        def run(attrs), do: Platform.Data.Repo.insert(%Thing{} |> Thing.changeset(attrs))
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, repos: [Platform.Data.Repo])
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.insert" end)
    end

    test "does not flag Repo.insert_all, Repo.delete_all, Repo.update_all, Repo.transact" do
      """
      defmodule Platform.SomeWorker do
        def bulk(rows), do: Platform.Repo.insert_all(Thing, rows)
        def purge(q), do: Platform.Repo.delete_all(q)
        def touch(q), do: Platform.Repo.update_all(q, set: [updated_at: DateTime.utc_now()])
        def tx(fun), do: Platform.Repo.transact(fun)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos)
      |> refute_issues()
    end
  end

  describe "allowed_schemas option" do
    test "suppresses violations when an allowed schema is referenced in the same function" do
      """
      defmodule Platform.SomeWorker do
        def run do
          job = Oban.Job |> where(state: "available") |> Platform.Repo.all()
        end
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Oban.Job]])
      |> refute_issues()
    end

    test "still flags violations when the allowed schema is not present" do
      """
      defmodule Platform.SomeWorker do
        def run, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Oban.Job]])
      |> assert_issue()
    end

    test "only suppresses the function containing the allowed schema, not others" do
      """
      defmodule Platform.SomeWorker do
        def with_oban do
          Platform.Repo.all(Oban.Job)
        end

        def without_oban do
          Platform.Repo.all(Thing)
        end
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Oban.Job]])
      |> assert_issues(1)
    end
  end

  describe "allowed_schemas — function head pattern match" do
    test "suppresses violation when allowed schema is pattern-matched in function head (short alias form)" do
      """
      defmodule Platform.Accounts.UserTokens do
        alias Platform.Accounts.UserTokens.UserToken
        def insert!(%UserToken{} = token), do: Platform.Repo.insert!(token)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Platform.Accounts.UserTokens.UserToken]])
      |> refute_issues()
    end

    test "suppresses violation when allowed schema is pattern-matched in function head (full module form)" do
      """
      defmodule Platform.Accounts.UserTokens do
        def insert!(%Platform.Accounts.UserTokens.UserToken{} = token), do: Platform.Repo.insert!(token)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Platform.Accounts.UserTokens.UserToken]])
      |> refute_issues()
    end

    test "still flags when allowed schema is in head of a different function" do
      """
      defmodule Platform.Accounts.UserTokens do
        alias Platform.Accounts.UserTokens.UserToken
        def insert!(%UserToken{} = token), do: Platform.Repo.insert!(token)
        def purge, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoUnscopedRepoInsideAppLib, @repos ++ [allowed_schemas: [Platform.Accounts.UserTokens.UserToken]])
      |> assert_issues(1)
    end
  end
end
