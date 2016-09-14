defmodule Router.Registry do
  use GenServer

  @table_name :registry

  def start_link() do
    GenServer.start_link(__MODULE__, @table_name, name: __MODULE__)
  end

  def init(table) do
    :net_kernel.monitor_nodes(true)
    {:ok, ets}  = :dets.open_file(table, [type: :set])
    {:ok, %{name: ets}}
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def insert(key, payload) do
    GenServer.call(__MODULE__, {:insert, {key, payload}})
  end

  def add_endpoint({key, payload}) do
    data   = {key, payload}
    GenServer.call(__MODULE__, {:insert, data})
  end

  def endpoints do
    GenServer.call(__MODULE__, {:all})
  end

  def update(key, new_data) do
    GenServer.call(__MODULE__, {:update, key, new_data})
  end

  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  defp find(_, :"$end_of_table", acc) do
    {:ok, List.delete(acc, :"$end_of_table") |> Enum.sort}
  end

  defp find(table, nil, acc) do
    next = :dets.first(table)
    find(table, next, [next|acc])
  end

  defp find(table, thing, acc) do
    next = :dets.next(table, thing)
    find(table, next, [next|acc])
  end

  def handle_call({:all}, _from, state) do
    {:reply, find(state.name, nil, []), state}
  end
  def handle_call({:insert, payload}, _from, state) do
    results =
    case :dets.insert(state.name, payload) do
      :ok -> {:ok, "inserted"}
      _ -> {:error}
    end
    {:reply, results, state}
  end
  def handle_call({:lookup, key}, _from, state) do
    results =
    case :dets.lookup(state.name, key) do
      [{^key, token}] -> {key, token}
      [] -> {:error, "not_found"}
    end
    {:reply, results, state}
  end
  def handle_call({:delete, key}, _from, state) do
    results =
    case :dets.delete(state.name, key) do
      :ok -> :ok
      error -> error
    end
    {:reply, results, state}
  end

  def handle_info({:nodedown, node_name}, state) do
    results =
    case :dets.delete(state.name, node_name) do
      :ok -> :ok
      error -> error
    end

    {:noreply, state}
  end
  def handle_info({:nodeup, node_name}, state) do
    results =
    case :dets.insert(state.name, {node_name, []}) do
      :ok -> {:ok, "inserted"}
      _ ->   {:error}
    end

    {:noreply, state}
  end

end
