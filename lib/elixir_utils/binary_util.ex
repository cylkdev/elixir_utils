defmodule ElixirUtils.BinaryUtil do
  @moduledoc """
  `ElixirUtils.BinaryUtil` provides utility functions for working with
  binary data as bytes instead of characters (graphemes).
  """

  @doc """

  ### Examples

      # the last item can be less than the target size
      iex> "ABCDE" |> ElixirUtils.BinaryUtil.chunk_stream(2) |> Enum.to_list()
      ["AB", "CD", "E"]

      iex> ["ABCDEFG"] |> ElixirUtils.BinaryUtil.chunk_stream(3) |> Enum.to_list()
      ["ABC", "DEF", "G"]

      # handles binaries of arbitrary sizes
      iex> ["A", "B", "CDEF"] |> ElixirUtils.BinaryUtil.chunk_stream(2) |> Enum.to_list()
      ["AB", "CD", "EF"]

      # handles binaries of arbitrary sizes
      iex> ["A", "B", "CDEF"] |> ElixirUtils.BinaryUtil.chunk_stream(1) |> Enum.to_list()
      ["A", "B", "C", "D", "E", "F"]
  """
  def chunk_stream(bin, size) when is_binary(bin) do
    bin
    |> split(0, size)
    |> Tuple.to_list()
    |> chunk_stream(size)
  end

  def chunk_stream(enum, size) when is_integer(size) and size > 0 do
    enum
    |> Stream.transform(
      fn -> {[], 0} end,
      fn
        data, {buf, buf_size} when buf_size >= size ->
          case buf |> combine() |> chunk_bytes(size) do
            {items, <<>>} -> {items, {[data], byte_size(data)}}
            {items, rest} -> {items, {[data, rest], byte_size(rest) + byte_size(data)}}
          end

        data, {buf, buf_size} ->
          {[], {[data | buf], buf_size + byte_size(data)}}
      end,
      fn {buf, _} ->
        case buf |> combine() |> chunk_bytes(size) do
          {items, <<>>} -> {items, nil}
          {items, rest} -> {items ++ [rest], nil}
        end
      end,
      fn _ -> :ok end
    )
  end

  defp combine(buf) do
    buf |> Enum.reverse() |> :erlang.iolist_to_binary()
  end

  @doc """
  Splits a binary into chunks that are target_size in bytes.

  ## Examples

      iex> ElixirUtils.BinaryUtil.chunk_bytes("ABCD", 2)
      {["AB"], "CD"}

      iex> ElixirUtils.BinaryUtil.chunk_bytes("ABCDE", 2)
      {["AB", "CD"], "E"}

      iex> ElixirUtils.BinaryUtil.chunk_bytes("A", 2)
      {[], "A"}

      iex> ElixirUtils.BinaryUtil.chunk_bytes("", 2)
      {[], ""}
  """
  def chunk_bytes(bin, size) when is_binary(bin) do
    transform(
      bin,
      size,
      [],
      fn fragment, acc -> [fragment | acc] end,
      fn bin, acc -> {Enum.reverse(acc), bin} end
    )
  end

  @doc """
  Transforms a binary, ensuring each fragment is at most the given size.

  This function is used as the base for all transformations.
  For example, the `chunk_bytes/2` function is implemented as:

      target_size = 1
      ElixirUtils.BinaryUtil.transform(
        bin,
        size,
        [],
        fn fragment, acc -> [fragment | acc] end,
        fn bin, acc -> {Enum.reverse(acc), bin} end
      )
      {["h", "e", "l", "l", "o"], ""}
  """
  def transform(bin, target_size, acc, reducer, last_fun) when is_binary(bin) do
    case split(bin, 0, target_size) do
      {fragment, <<>>} ->
        last_fun.(fragment, acc)

      {fragment, rest} ->
        next_acc = reducer.(fragment, acc)
        transform(rest, target_size, next_acc, reducer, last_fun)
    end
  end

  @doc """
  Extracts a fragment from a binary.

  Returns `{fragment, rest}` where `fragment` is max of `length`
  bytes in size starting at `start`, and `rest` is the remaining
  binary (or `nil` when none).

  ## Examples

      iex> ElixirUtils.BinaryUtil.split("ABC", 0, 1)
      {"A", "BC"}

      iex> ElixirUtils.BinaryUtil.split("ABC", 1, 1)
      {"B", "C"}

      iex> ElixirUtils.BinaryUtil.split("ABC", 0, 3)
      {"ABC", ""}
  """
  def split(bin, start, length) when is_binary(bin) do
    total = byte_size(bin)

    if start >= total do
      {<<>>, <<>>}
    else
      # how many bytes remain from start
      avail = total - start
      # ensures we never read past the end.
      take = min(length, avail)
      <<_::binary-size(start), fragment::binary-size(take), rest::binary>> = bin
      {fragment, rest}
    end
  end
end
