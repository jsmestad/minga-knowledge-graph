defmodule MingaKnowledgeGraph.TestHost do
  @moduledoc false

  @spec child_spec({pid(), Path.t()}) :: Supervisor.child_spec()
  def child_spec({recipient, directory}) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__, meta: [host: {recipient, directory}])
  end

  @spec subscribe(atom()) :: :ok
  def subscribe(topic) do
    {:ok, _owner} = Registry.register(__MODULE__, topic, nil)
    :ok
  end

  @spec publish(atom(), struct()) :: :ok
  def publish(topic, payload) do
    Registry.dispatch(__MODULE__, topic, fn subscribers ->
      Enum.each(subscribers, fn {pid, _value} -> send(pid, {:minga_event, topic, payload}) end)
    end)
  end

  @spec report(term()) :: :ok
  def report(message) do
    {:ok, {recipient, _directory}} = Registry.meta(__MODULE__, :host)
    send(recipient, message)
    :ok
  end

  @spec storage_path(atom(), Path.t()) :: Path.t()
  def storage_path(extension, relative_path) do
    {:ok, {_recipient, directory}} = Registry.meta(__MODULE__, :host)
    Path.join([directory, "extensions", Atom.to_string(extension), "data", relative_path])
  end
end
