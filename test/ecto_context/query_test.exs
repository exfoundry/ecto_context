defmodule EctoContext.QueryTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  describe "maybe_query/2" do
    test "returns queryable unchanged when nil" do
      assert :my_query == EctoContext.Query.maybe_query(:my_query, nil)
    end

    test "applies function when given" do
      result = EctoContext.Query.maybe_query(:my_query, fn q -> {q, :modified} end)
      assert result == {:my_query, :modified}
    end
  end

  describe "maybe_preload/2" do
    test "returns query unchanged when nil" do
      q = from(x in "table")
      assert q == EctoContext.Query.maybe_preload(q, nil)
    end
  end

  describe "maybe_order_by/2" do
    test "returns query unchanged when nil" do
      q = from(x in "table")
      assert q == EctoContext.Query.maybe_order_by(q, nil)
    end
  end

  describe "maybe_limit/2" do
    test "returns query unchanged when nil" do
      q = from(x in "table")
      assert q == EctoContext.Query.maybe_limit(q, nil)
    end
  end

  describe "maybe_select/2" do
    test "returns query unchanged when nil" do
      q = from(x in "table")
      assert q == EctoContext.Query.maybe_select(q, nil)
    end
  end
end
