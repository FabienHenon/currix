defmodule Currix do
  @moduledoc """
  Documentation for Currix.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Currix.hello
      :world

  """
  defmacro defcurry(definition, do: body) do
    fns = curry(definition, body, false)

    quote do
      unquote(fns)
    end
  end

  defmacro defpcurry(definition, do: body) do
    fns = curry(definition, body, true)

    quote do
      unquote(fns)
    end
  end

  # Functions with arity 0
  defp curry({_, _, nil} = definition, body, private), do: deffunc(definition, body, private)
  defp curry({_, _, []} = definition, body, private), do: deffunc(definition, body, private)
  # Functions with arity > 0
  defp curry({func_name, ctx, [first_arg | rest_args]}, body, private) do
    make_funcs(func_name, ctx, [first_arg], rest_args, body, private, [])
  end

  # Call def or defp
  defp deffunc(definition, body, false), do: quote do: (def unquote(definition), do: unquote(body))
  defp deffunc(definition, body, _), do: quote do: (defp unquote(definition), do: unquote(body))

  # Define the curried functions
  def make_funcs(func_name, ctx, curr_args, [], body, private, fns), do: [deffunc({func_name, ctx, curr_args}, body, private) | fns]
  def make_funcs(func_name, ctx, curr_args, [first_arg | rest_args] = args, body, private, fns) do
    new_body = make_body(args, body)

    [deffunc({func_name, ctx, curr_args}, new_body, private) |
    make_funcs(func_name, ctx, curr_args ++ [first_arg], rest_args, body, private, fns)]
  end

  # Recursively create the body of the functions
  def make_body([], body), do: body
  def make_body([first_arg | rest_args], body) do
    quote do
      fn unquote(first_arg) -> unquote(make_body(rest_args, body)) end
    end
  end
end
