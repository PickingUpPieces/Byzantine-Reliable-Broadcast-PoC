defmodule ChatServerBRBTest do
  use ExUnit.Case
  doctest ChatServerBRB

  test "greets the world" do
    assert ChatServerBRB.hello() == :world
  end
end
