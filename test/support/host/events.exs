defmodule Minga.Events do
  @moduledoc false

  @spec subscribe(atom()) :: :ok
  defdelegate subscribe(topic), to: MingaKnowledgeGraph.TestHost
end
