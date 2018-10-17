defmodule SupSupTest do
  use ExUnit.Case
  doctest SupSup

  test "greets the world" do
    assert SupSup.hello() == :world
  end
end
