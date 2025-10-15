defmodule ElixirUtils.EnumUtil do
  def reduce_responses(enum) do
    enum
    |> Enum.reduce({[], []}, fn
      :ok, {values, errors} -> {[:ok | values], errors}
      :error, {values, errors} -> {values, [:error | errors]}
      {:ok, value}, {values, errors} -> {[value | values], errors}
      {:exit, reason}, {values, errors} -> {values, [{:exit, reason} | errors]}
      {:error, reason}, {values, errors} -> {values, [reason | errors]}
    end)
    |> then(fn
      {values, []} -> {:ok, Enum.reverse(values)}
      {_values, errors} -> {:error, Enum.reverse(errors)}
    end)
  end
end
