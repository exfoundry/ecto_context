defmodule EctoContext.Check.Warning.DeprecateRepoTransactionTest do
  use Credo.Test.Case

  alias EctoContext.Check.Warning.DeprecateRepoTransaction

  describe "run/2" do
    test "reports Repo.transaction with full module path" do
      """
      defmodule MyApp.Things do
        def transfer do
          MyApp.Repo.transaction(fn -> :ok end)
        end
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.transaction" end)
    end

    test "reports aliased Repo.transaction" do
      """
      defmodule MyApp.Things do
        alias MyApp.Repo
        def transfer do
          Repo.transaction(fn -> :ok end)
        end
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> assert_issue(fn issue -> assert issue.trigger == "Repo.transaction" end)
    end

    test "reports multiple issues" do
      """
      defmodule MyApp.Things do
        def a, do: MyApp.Repo.transaction(fn -> :ok end)
        def b, do: MyApp.Repo.transaction(fn -> :ok end)
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> assert_issues(2)
    end

    test "raises no issue for Repo.transact" do
      """
      defmodule MyApp.Things do
        def transfer do
          MyApp.Repo.transact(fn -> {:ok, :done} end)
        end
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> refute_issues()
    end

    test "raises no issue for other Repo calls" do
      """
      defmodule MyApp.Things do
        def fetch_all, do: MyApp.Repo.all(Thing)
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> refute_issues()
    end

    test "raises no issue for transaction on a non-Repo module" do
      """
      defmodule MyApp.Things do
        def run, do: SomeLibrary.transaction(fn -> :ok end)
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction)
      |> refute_issues()
    end

    test "raises no issue for a repo not in the configured list" do
      """
      defmodule MyApp.Things do
        def run, do: MyApp.ReadonlyRepo.transaction(fn -> :ok end)
      end
      """
      |> to_source_file()
      |> run_check(DeprecateRepoTransaction, repos: [MyApp.Repo])
      |> refute_issues()
    end
  end
end
