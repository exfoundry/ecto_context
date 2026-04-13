defmodule EctoContext.ValidateTest do
  use ExUnit.Case, async: true

  describe "validate_opts!/2" do
    test "passes for empty opts" do
      assert :ok == EctoContext.Validate.validate_opts!([], [:preload, :limit])
    end

    test "passes for valid opts" do
      assert :ok ==
               EctoContext.Validate.validate_opts!([preload: :tags, limit: 10], [
                 :preload,
                 :limit
               ])
    end

    test "raises for unknown opts" do
      assert_raise ArgumentError, ~r/Unsupported option/, fn ->
        EctoContext.Validate.validate_opts!([unknown: true], [:preload])
      end
    end

    test "includes all invalid keys in the error message" do
      assert_raise ArgumentError, ~r/:foo.*:bar|:bar.*:foo/, fn ->
        EctoContext.Validate.validate_opts!([foo: 1, bar: 2], [:preload])
      end
    end
  end
end
