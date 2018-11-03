defmodule SupSup do
  @moduledoc false

  def start_link(name, child_spec_list) do
    pid = __MODULE__ |> spawn_link(:init, [child_spec_list])
    true = pid |> Process.register(name)
    {:ok, pid}
  end

  def stop(name) do
    send(name, {:stop, self()})
    receive do
      {:reply, reply} -> reply
    end
  end

  def init(child_spec_list) do
    Process.flag(:trap_exit, true)

    child_spec_list
    #|> start_child()
    |> loop() 
  end

  def terminate([]), do: :ok
  def terminate([{pid, _} | child_list]) do
    Process.exit(pid, :kill)
    child_list |> terminate
  end

  @doc """
  Assumes that the child process is started using spawn_link/3 so
  that it gets linked with the supervising process
  """
  #def start_child([]), do: []
  def start_child({m, f, a} = _mfa) do
    try do
      apply(m, f, a)
    catch
      kind, reason ->
        {:error, __STACKTRACE__}
    else 
      {:ok, pid} ->
        #[{pid, {m, f, a}} | start_child(child_spec_list)]
        {:ok, pid}
    end
  end

  def call(pid, message) do
    send(pid, {:request, self(), message})
    receive do
      {:reply, reply} ->
        reply
    end
  end

  def reply(from, reply), do: send(from, {:reply, reply})

  def restart_child(pid, child_list) do
    {^pid, {module, function, args} = mfa} = List.keyfind(child_list, pid, 0)  
    {:ok, new_pid} = apply(module, function, args)
    new_list = List.keydelete(child_list, pid, 0)
    [{new_pid, mfa} | new_list]
  end

  def loop(child_list) do
    receive do
      {:request, from, message} ->
        {new_state, reply} = handle_msg(message, child_list)
        reply(from, reply)
        loop(child_list)
      {:EXIT, pid, _reason} ->
        new_child_list = restart_child(pid, child_list)
        new_child_list |> loop()

      {:stop, from} ->
        send from, {:reply, terminate(child_list)}
    end
  end

  def handle_msg(:count_children, child_list) do
    {child_list, child_list |> length}
  end

  ## API
  def count_children(pid) do
    call(pid, :count_children)
  end
end
