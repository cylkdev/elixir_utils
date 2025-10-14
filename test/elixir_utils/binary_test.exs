defmodule ElixirUtils.BinaryTest do
  use ExUnit.Case
  doctest ElixirUtils.Binary

  describe "chunk_stream/2 (enum)" do
    test "binary - exact multiples" do
      assert ["ab", "cd", "ef"] ==
               "abcdef"
               |> ElixirUtils.Binary.chunk_stream(2)
               |> Enum.to_list()
    end

    test "binary - emits final short chunk once" do
      assert ["abc", "d"] ==
               "abcd"
               |> ElixirUtils.Binary.chunk_stream(3)
               |> Enum.to_list()
    end

    test "binary - whole input when size equals length" do
      assert ["abc"] ==
               "abc"
               |> ElixirUtils.Binary.chunk_stream(3)
               |> Enum.to_list()
    end

    test "binary - shorter than size still emits once" do
      assert ["a"] ==
               "a"
               |> ElixirUtils.Binary.chunk_stream(2)
               |> Enum.to_list()
    end

    test "binary - empty input yields empty stream" do
      assert [] ==
               ""
               |> ElixirUtils.Binary.chunk_stream(4)
               |> Enum.to_list()
    end

    test "binary - size 1 splits into single bytes" do
      assert ["a", "b", "c", "d"] ==
               "abcd"
               |> ElixirUtils.Binary.chunk_stream(1)
               |> Enum.to_list()
    end

    test "enum - iodata across boundaries emits promptly" do
      assert ["abc", "def", "g"] =
               ["ab", "c", "def", "g"]
               |> ElixirUtils.Binary.chunk_stream(3)
               |> Enum.to_list()
    end

    test "enum - exact multiples over multiple items" do
      assert ["ab", "cd", "ef"] =
               ["a", "b", "c", "d", "e", "f"]
               |> ElixirUtils.Binary.chunk_stream(2)
               |> Enum.to_list()
    end

    test "enum - single huge iodata entry splits into many" do
      assert ["xxx", "xxx", "x"] =
               ["xxxxxxx"]
               |> ElixirUtils.Binary.chunk_stream(3)
               |> Enum.to_list()
    end

    test "enum - empty enum yields empty stream" do
      assert [] = [] |> ElixirUtils.Binary.chunk_stream(4) |> Enum.to_list()
    end
  end

  describe "split/3" do
    test "takes up to length from beginning" do
      assert {"abc", "def"} = ElixirUtils.Binary.split("abcdef", 0, 3)
    end

    test "takes up to length from random start" do
      assert {"cde", "f"} = ElixirUtils.Binary.split("abcdef", 2, 3)
    end

    test "clamps when length exceeds tail" do
      assert {"ef", ""} = ElixirUtils.Binary.split("abcdef", 4, 10)
    end

    test "start at last byte returns that byte" do
      assert {"f", ""} = ElixirUtils.Binary.split("abcdef", 5, 3)
    end

    test "returns empty binary when start equals size" do
      {<<>>, <<>>} = ElixirUtils.Binary.split("abc", 3, 1)
    end

    test "returns empty binary when start is greater than size" do
      {<<>>, <<>>} = ElixirUtils.Binary.split("abcdef", 6, 2)
    end

    test "returns empty binary when given an empty binary" do
      assert {<<>>, <<>>} = ElixirUtils.Binary.split("", 0, 1)
    end

    test "length of 1 walks forward one byte" do
      assert {"a", "bc"} = ElixirUtils.Binary.split("abc", 0, 1)
      assert {"b", "c"} = ElixirUtils.Binary.split("abc", 1, 1)
      assert {"c", ""} = ElixirUtils.Binary.split("abc", 2, 1)
    end

    test "works with multibyte utf8 input" do
      # "é" is 2 bytes
      assert {"é", ""} = ElixirUtils.Binary.split("café", 3, 2)
    end
  end
end
