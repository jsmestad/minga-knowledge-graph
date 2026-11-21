defmodule Minga.Buffer do
  @moduledoc false

  @spec file_path(pid()) :: Path.t()
  def file_path(buffer), do: Agent.get(buffer, &Function.identity/1)
end
