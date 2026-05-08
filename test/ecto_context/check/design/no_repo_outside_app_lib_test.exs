defmodule EctoContext.Check.Design.NoRepoOutsideAppLibTest do
  use Credo.Test.Case

  alias EctoContext.Check.Design.NoRepoOutsideAppLib

  @repos [repos: [Platform.Repo]]

  describe "run/2" do
    test "flags any Repo call in lib/ outside lib/[app]/" do
      """
      defmodule PlatformWeb.SomeController do
        def index(conn, _), do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "flags Repo calls in mix tasks" do
      """
      defmodule Mix.Tasks.MyTask do
        def run(_), do: Platform.Repo.insert(%Thing{})
      end
      """
      |> to_source_file("lib/mix/tasks/my_task.ex")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.insert" end)
    end

    test "flags multiple violations" do
      """
      defmodule PlatformWeb.SomeController do
        def index(conn, _), do: Platform.Repo.all(Thing)
        def show(conn, %{"id" => id}), do: Platform.Repo.get(Thing, id)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> assert_issues(2)
    end

    test "skips files inside lib/[app]/ (covered by NoUnscopedRepoInsideAppLib)" do
      """
      defmodule Platform.SomeWorker do
        def run, do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context/some_worker.ex")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> refute_issues()
    end

    test "skips test files" do
      """
      defmodule PlatformWeb.SomeControllerTest do
        def setup(_), do: Platform.Repo.insert!(%Thing{})
      end
      """
      |> to_source_file("test/ecto_context_web/some_controller_test.exs")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> refute_issues()
    end

    test "flags aliased Repo call" do
      """
      defmodule PlatformWeb.SomeController do
        alias Platform.Repo
        def index(conn, _), do: Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoRepoOutsideAppLib, @repos)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end

    test "flags deeply nested full module path form (e.g. Platform.Data.Repo.all)" do
      """
      defmodule PlatformWeb.SomeController do
        def index(conn, _), do: Platform.Data.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoRepoOutsideAppLib, repos: [Platform.Data.Repo])
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.all" end)
    end
  end

  describe "excluded_paths option" do
    test "skips files whose path starts with an excluded path" do
      """
      defmodule Mix.Tasks.MyTask do
        def run(_), do: Platform.Repo.insert(%Thing{})
      end
      """
      |> to_source_file("lib/mix/tasks/my_task.ex")
      |> run_check(NoRepoOutsideAppLib, @repos ++ [excluded_paths: ["lib/mix/tasks"]])
      |> refute_issues()
    end

    test "still flags files outside the excluded path" do
      """
      defmodule PlatformWeb.SomeController do
        def index(conn, _), do: Platform.Repo.all(Thing)
      end
      """
      |> to_source_file("lib/ecto_context_web/some_controller.ex")
      |> run_check(NoRepoOutsideAppLib, @repos ++ [excluded_paths: ["lib/mix/tasks"]])
      |> assert_issue()
    end

    test "supports multiple excluded paths" do
      """
      defmodule Mix.Tasks.MyTask do
        def run(_), do: Platform.Repo.insert(%Thing{})
      end
      """
      |> to_source_file("lib/mix/tasks/my_task.ex")
      |> run_check(NoRepoOutsideAppLib, @repos ++ [excluded_paths: ["lib/mix/tasks", "lib/ecto_context_web/admin"]])
      |> refute_issues()
    end
  end
end
