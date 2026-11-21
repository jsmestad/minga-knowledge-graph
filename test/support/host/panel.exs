defmodule Minga.Extension.Panel do
  @moduledoc false

  alias MingaKnowledgeGraph.TestHost

  @spec set(atom(), term(), map()) :: :ok
  def set(extension, id, opts), do: TestHost.report({:panel, extension, id, opts})
end
