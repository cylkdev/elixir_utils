defmodule ElixirUtils.BinaryUtilTest do
  use ExUnit.Case
  doctest ElixirUtils.BinaryUtil

  alias ElixirUtils.BinaryUtil

  describe "chunk_stream/2 (enum)" do
    test "binary - exact multiples" do
      assert ["ab", "cd", "ef"] ==
               "abcdef"
               |> BinaryUtil.chunk_stream(2)
               |> Enum.to_list()
    end

    test "binary - emits final short chunk once" do
      assert ["abc", "d"] ==
               "abcd"
               |> BinaryUtil.chunk_stream(3)
               |> Enum.to_list()
    end

    test "binary - whole input when size equals length" do
      assert ["abc"] ==
               "abc"
               |> BinaryUtil.chunk_stream(3)
               |> Enum.to_list()
    end

    test "binary - shorter than size still emits once" do
      assert ["a"] ==
               "a"
               |> BinaryUtil.chunk_stream(2)
               |> Enum.to_list()
    end

    test "binary - empty input yields empty stream" do
      assert [] ==
               ""
               |> BinaryUtil.chunk_stream(4)
               |> Enum.to_list()
    end

    test "binary - size 1 splits into single bytes" do
      assert ["a", "b", "c", "d"] ==
               "abcd"
               |> BinaryUtil.chunk_stream(1)
               |> Enum.to_list()
    end

    test "enum - iodata across boundaries emits promptly" do
      assert ["abc", "def", "g"] =
               ["ab", "c", "def", "g"]
               |> BinaryUtil.chunk_stream(3)
               |> Enum.to_list()
    end

    test "enum - exact multiples over multiple items" do
      assert ["ab", "cd", "ef"] =
               ["a", "b", "c", "d", "e", "f"]
               |> BinaryUtil.chunk_stream(2)
               |> Enum.to_list()
    end

    test "enum - single huge iodata entry splits into many" do
      assert ["xxx", "xxx", "x"] =
               ["xxxxxxx"]
               |> BinaryUtil.chunk_stream(3)
               |> Enum.to_list()
    end

    test "enum - empty enum yields empty stream" do
      assert [] = [] |> BinaryUtil.chunk_stream(4) |> Enum.to_list()
    end
  end

  describe "split/3" do
    test "takes up to length from beginning" do
      assert {"abc", "def"} = BinaryUtil.split("abcdef", 0, 3)
    end

    test "takes up to length from random start" do
      assert {"cde", "f"} = BinaryUtil.split("abcdef", 2, 3)
    end

    test "clamps when length exceeds tail" do
      assert {"ef", ""} = BinaryUtil.split("abcdef", 4, 10)
    end

    test "start at last byte returns that byte" do
      assert {"f", ""} = BinaryUtil.split("abcdef", 5, 3)
    end

    test "returns empty binary when start equals size" do
      {<<>>, <<>>} = BinaryUtil.split("abc", 3, 1)
    end

    test "returns empty binary when start is greater than size" do
      {<<>>, <<>>} = BinaryUtil.split("abcdef", 6, 2)
    end

    test "returns empty binary when given an empty binary" do
      assert {<<>>, <<>>} = BinaryUtil.split("", 0, 1)
    end

    test "length of 1 walks forward one byte" do
      assert {"a", "bc"} = BinaryUtil.split("abc", 0, 1)
      assert {"b", "c"} = BinaryUtil.split("abc", 1, 1)
      assert {"c", ""} = BinaryUtil.split("abc", 2, 1)
    end

    test "works with multibyte utf8 input" do
      # "é" is 2 bytes
      assert {"é", ""} = BinaryUtil.split("café", 3, 2)
    end
  end
end
