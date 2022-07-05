defmodule ShortenerTest do
  use ExUnit.Case
  doctest Shortener

  test "greets the world" do
    assert Shortener.hello() == :world
  end
end
