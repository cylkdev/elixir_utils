defmodule ElixirUtils.PathUtil do
  @doc """
  Returns all extensions after the basename.

  ### Examples

      iex> ElixirUtils.PathUtil.extname("example.zip.gz")
      ".zip.gz"
  """
  def extname(path) do
    path
    |> Path.split()
    |> List.last()
    |> String.split(".")
    |> tl()
    |> Enum.join(".")
    |> then(fn str -> "." <> str end)
  end
end
