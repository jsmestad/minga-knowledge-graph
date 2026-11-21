defmodule MingaKnowledgeGraph.TrackerTest do
  # The test host uses a named registry, just like the production tracker.
  use ExUnit.Case, async: false

  alias Minga.Events.BufferChangedEvent
  alias Minga.Events.BufferEvent
  alias MingaKnowledgeGraph.TestHost
  alias MingaKnowledgeGraph.Tracker

  @moduletag :tmp_dir
  @ext :minga_knowledge_graph

  setup %{tmp_dir: tmp_dir} do
    start_supervised!({TestHost, {self(), tmp_dir}})
    :ok
  end

  # `seed: false` skips the git cold-start so tests don't shell out.
  defp start_tracker(id, opts \\ []) do
    start_opts = Keyword.put_new(opts, :seed, false)
    start_supervised!(%{id: id, start: {Tracker, :start_link, [start_opts]}})
  end

  defp open(path) do
    TestHost.publish(:buffer_opened, %BufferEvent{buffer: self(), path: path})
  end

  test "opening a file publishes heat and refresh re-publishes it", %{tmp_dir: tmp_dir} do
    server = start_tracker(:open)
    path = Path.join(tmp_dir, "unwritten.ex")

    open(path)

    assert_receive {:file_badge, @ext, ^path, [level: 1]}

    Tracker.refresh_heat(server)
    assert_receive {:file_badge, @ext, ^path, [level: 1]}
  end

  test "familiarity summary reflects opens", %{tmp_dir: tmp_dir} do
    server = start_tracker(:summary)
    path = Path.join(tmp_dir, "unwritten.ex")

    open(path)

    summary = Tracker.familiarity(server, path)
    assert summary =~ Path.basename(path)
    assert summary =~ "opened 1"
  end

  test "user-sourced changes count as edits and update heat", %{tmp_dir: tmp_dir} do
    server = start_tracker(:user_edit)
    path = Path.join(tmp_dir, "edited.ex")
    buffer = start_supervised!({Agent, fn -> path end})
    open(path)

    TestHost.publish(:buffer_changed, %BufferChangedEvent{source: :user, buffer: buffer})

    assert Tracker.familiarity(server, path) =~ "edited 1"
    assert_receive {:file_badge, @ext, ^path, [level: 2]}
  end

  test "agent-sourced changes do not count as edits", %{tmp_dir: tmp_dir} do
    server = start_tracker(:agent)
    path = Path.join(tmp_dir, "unwritten.ex")
    buffer = start_supervised!({Agent, fn -> path end})
    open(path)

    TestHost.publish(:buffer_changed, %BufferChangedEvent{
      source: {:agent, self(), nil},
      buffer: buffer
    })

    assert Tracker.familiarity(server, path) =~ "edited 0"
  end

  test "unknown files report as unfamiliar", %{tmp_dir: tmp_dir} do
    server = start_tracker(:unknown)
    assert Tracker.familiarity(server, Path.join(tmp_dir, "unknown.ex")) =~ "unfamiliar"
  end

  test "opening a real unfamiliar file records familiarity without auto-briefing",
       %{tmp_dir: tmp_dir} do
    test_pid = self()

    stream_ai = fn messages, _opts ->
      send(test_pid, {:briefing_started, messages})
      {:ok, make_ref()}
    end

    server = start_tracker(:no_auto_briefing, stream_ai: stream_ai)
    path = Path.join(tmp_dir, "no_auto.ex")
    File.write!(path, "defmodule NoAuto do\nend\n")

    open(path)

    assert Tracker.familiarity(server, path) =~ "opened 1"
    refute_received {:briefing_started, _messages}
    refute_received {:panel, @ext, :briefing, _panel}
  end

  test "each explicit briefing request starts a fresh stream and displays the result",
       %{tmp_dir: tmp_dir} do
    test_pid = self()

    stream_ai = fn messages, opts ->
      ref = make_ref()
      send(test_pid, {:briefing_started, ref, messages})
      reply_to = Keyword.fetch!(opts, :reply_to)
      send(reply_to, {:minga_ai, ref, {:chunk, "Briefing"}})
      send(reply_to, {:minga_ai, ref, {:done, "Briefing complete"}})
      {:ok, ref}
    end

    server = start_tracker(:explicit_briefing, stream_ai: stream_ai)
    path = Path.join(tmp_dir, "explicit.ex")
    File.write!(path, "defmodule Explicit do\nend\n")

    Tracker.request_briefing(server, path)

    assert_receive {:briefing_started, first_ref, messages}, 2_000
    assert [%{role: "system"}, %{role: "user", content: content}] = messages
    assert content =~ path
    assert content =~ "defmodule Explicit"

    assert_receive {:panel, @ext, :briefing,
                    %{position: :float, visible: true, content: [text: "Generating briefing…"]}}

    assert_receive {:panel, @ext, :briefing, %{content: [text: "Briefing"]}}
    assert_receive {:panel, @ext, :briefing, %{content: [text: "Briefing complete"]}}

    Tracker.request_briefing(server, path)
    assert_receive {:briefing_started, second_ref, ^messages}, 2_000
    assert first_ref != second_ref
  end

  test "the graph persists in the original JSON layout across a tracker restart",
       %{tmp_dir: tmp_dir} do
    path = Path.join(tmp_dir, "unwritten.ex")

    start_tracker(:persist_a)
    open(path)
    open(path)
    assert Tracker.familiarity(Tracker, path) =~ "opened 2"
    stop_supervised!(:persist_a)

    stored = Path.join(tmp_dir, "extensions/minga_knowledge_graph/data/graph.json")

    assert %{
             ^path => %{
               "open_count" => 2,
               "edit_count" => 0,
               "first_seen" => first_seen,
               "last_seen" => last_seen
             }
           } = stored |> File.read!() |> JSON.decode!()

    assert first_seen <= last_seen

    server2 = start_tracker(:persist_b)
    assert Tracker.familiarity(server2, path) =~ "opened 2"
  end
end
