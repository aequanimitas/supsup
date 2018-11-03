defmodule SupSupTest do
  use ExUnit.Case

  defmodule Add do
    @doc """
    Open `name` argument so it can be referenced
    by other procs
    """
    def start_link(name, num_add) do
      pid = spawn_link(__MODULE__, :loop, [num_add])
      pid |> Process.register(name)
      {:ok, pid}
    end

    def call(pid, number) do
      send(pid, {:request, self(), number})
      receive do
        {:reply, reply} -> reply
      end
    end

    def reply(from, reply), do: send(from, {:reply, reply})
    def loop(num_add) do
      receive do
        {:request, from, message} ->
          reply(from, message + num_add)
          loop(num_add)
      end
    end
  end

  test "start_child/2" do
    #{:ok, spid} = SupSup.start_link(:supsup, [])
    child_spec = {Add, :start_link, [:add_one, 1]}
    {:ok, pid} = SupSup.start_child(child_spec)
  end

  @tag skip: true
  test "start_link/2" do
    {:ok, spid} = SupSup.start_link(:supsup, [])
    assert is_pid(spid)
    SupSup.stop(spid)
    {:ok, spid} = SupSup.start_link(:supsup, [{Add, :start_link, [1]}])
    assert is_pid(spid)
    assert Process.alive?(spid)
  end

  @tag skip: true
  test "stop/1" do
    {:ok, spid} = SupSup.start_link(:supsup, [])
    SupSup.stop(spid)
    refute Process.alive?(spid)
  end

  @tag skip: true
  test "count_children/1" do
    {:ok, spid} = SupSup.start_link(:supsup, [])
    assert is_pid(spid)
    SupSup.stop(spid)
    #{:ok, spid} = SupSup.start_link(:supsup, [{Add, :start_link, [:add_one, 1]}])
    #ao_pid = :add_one |> :erlang.whereis() |> IO.inspect
    #assert is_pid(ao_pid)
    assert is_pid(spid)
    assert 1 = SupSup.count_children(spid)
  end
end
