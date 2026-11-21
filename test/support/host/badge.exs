defmodule Minga.Extension.Badge do
  @moduledoc false

  alias MingaKnowledgeGraph.TestHost

  @spec set_file(atom(), Path.t(), keyword()) :: :ok
  def set_file(extension, path, opts), do: TestHost.report({:file_badge, extension, path, opts})
end
