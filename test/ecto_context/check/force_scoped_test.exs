defmodule EctoContext.Check.ForceScopedTest do
  use Credo.Test.Case

  alias EctoContext.Check.ForceScoped

  @repos [repos: [Platform.Repo]]

  describe "run/2" do
    test "reports Repo.all in ecto_context module" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def fetch_all, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "reports Repo.get in ecto_context module" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          get!()
        end
        def fetch(id), do: Platform.Repo.get(Thing, id)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.get" end)
    end

    test "reports Repo.insert in ecto_context module" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          create()
        end
        def raw_insert(attrs), do: Platform.Repo.insert(%Thing{} |> Thing.changeset(attrs))
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.insert" end)
    end

    test "reports Repo.update in ecto_context module" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          update()
        end
        def raw_update(cs), do: Platform.Repo.update(cs)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.update" end)
    end

    test "reports Repo.delete in ecto_context module" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          delete()
        end
        def raw_delete(thing), do: Platform.Repo.delete(thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.delete" end)
    end

    test "reports multiple issues" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
          get!()
        end
        def fetch_all, do: Platform.Repo.all(Thing)
        def fetch(id), do: Platform.Repo.get(Thing, id)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issues(2)
    end

    test "raises no issue for outside ecto_context module" do
      """
      defmodule Platform.SomeModule do
        def fetch_all, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for Repo.transact" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def transfer(scope, a, b) do
          Platform.Repo.transact(fn -> {:ok, delete(scope, a)} end)
        end
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for Repo.delete_all" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def purge_expired, do: Platform.Repo.delete_all(expired_query())
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for Repo.insert_all" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def bulk_import(rows), do: Platform.Repo.insert_all(Thing, rows)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for Repo.update_all" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def touch_all(ids), do: Platform.Repo.update_all(query(ids), set: [last_seen_at: DateTime.utc_now()])
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for Repo.preload" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def with_assocs(thing), do: Platform.Repo.preload(thing, :tags)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "reports aliased Repo call" do
      """
      defmodule Platform.Things do
        import EctoContext
        alias Platform.Repo
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def fetch_all, do: Repo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "raises no issue for a module whose last segment happens to be Repo" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def fetch_all, do: ThirdParty.MockRepo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, @repos)
      |> refute_issues()
    end

    test "raises no issue for a repo not in the configured list" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def fetch_all, do: Platform.ReadonlyRepo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, repos: [Platform.Repo])
      |> refute_issues()
    end

    test "reports issues for any repo in the configured list" do
      """
      defmodule Platform.Things do
        import EctoContext
        ecto_context schema: Thing, scope: &__MODULE__.scope/2 do
          list()
        end
        def a, do: Platform.Repo.all(Thing)
        def b, do: Platform.ReadonlyRepo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(ForceScoped, repos: [Platform.Repo, Platform.ReadonlyRepo])
      |> assert_issues(2)
    end
  end
end
