defmodule Minga.Extension.Storage do
  @moduledoc false

  alias MingaKnowledgeGraph.TestHost

  @spec read(atom(), Path.t()) :: {:ok, binary()} | {:error, File.posix()}
  def read(extension, path), do: File.read(TestHost.storage_path(extension, path))

  @spec write(atom(), Path.t(), iodata()) :: :ok | {:error, File.posix()}
  def write(extension, relative_path, contents) do
    path = TestHost.storage_path(extension, relative_path)

    with :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write(path, contents)
    end
  end
end
