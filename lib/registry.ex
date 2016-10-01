defmodule Router.Registry do
  use GenServer
  require Logger

  @table_name :registry

  def start_link() do
    GenServer.start_link(__MODULE__, @table_name, name: __MODULE__)
  end

  def init(table_name) do
    table = :ets.new(table_name, [:set, :named_table])
    :net_kernel.monitor_nodes(true)
    {:ok, %{name: table}}
  end

  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  def get_path(path) do
    :ets.match_object(@table_name, {:'$0', %{paths: [path]}})
  end

  def insert(key, payload) do
    GenServer.call(__MODULE__, {:insert, {key, payload}})
  end

  def all do
    GenServer.call(__MODULE__, :all_endpoints)
  end

  # we store the path as the key and the value as a list of maps
  # for example, {"/info", [%{name: :"foo@127.0.0.1", counter: 0}, %{name: :"bar@127.0.0.1", counter: 0}]}
  def add_endpoint({key, payload}) do
    data = {key, %{paths: payload, counter: 0}}
    GenServer.call(__MODULE__, {:insert, data})
  end

  def endpoints do
    GenServer.call(__MODULE__, :all)
  end

  def update(key, new_data) do
    GenServer.call(__MODULE__, {:update, key, new_data})
  end

  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  #defp find(_, :"$end_of_table", acc) do
  #  {:ok, List.delete(acc, :"$end_of_table") |> Enum.sort}
  #end

  #defp find(table, nil, acc) do
  #  next = :ets.first(table)
  #  find(table, next, [next|acc])
  #end

  #defp find(table, thing, acc) do
  #  next = :ets.next(table, thing)
  #  find(table, next, [next|acc])
  #end

  def handle_call(:all_endpoints, _from, state) do
    results = :ets.select(state.name, [{{:"$1", :"$2"}, [], [{{:"$1", :"$2"}}]}])
    {:reply, results, state}
  end
  def handle_call({:insert, payload}, _from, state) do
    results =
    case :ets.insert(state.name, payload) do
      :ok -> {:ok, "inserted"}
      _ -> {:error}
    end
    {:reply, results, state}
  end
  def handle_call({:lookup, key}, _from, state) do
    results =
    case :ets.lookup(state.name, key) do
      [{^key, token}] -> {key, token}
      [] -> {:error, "not_found"}
    end
    {:reply, results, state}
  end
  def handle_call({:delete, key}, _from, state) do
    results =
    case :ets.delete(state.name, key) do
      :ok -> :ok
      error -> error
    end
    {:reply, results, state}
  end
  def handle_call({:update, _key, payload}, _from, state) do
    modified_client = Map.merge(%{}, payload)
    results =
      case :ets.insert(state.name, modified_client) do
	true -> {:ok, "inserted"}
	_ -> {:error}
      end
      {:reply, results, state}
  end
  def handle_info({:nodedown, node_name}, state) do
    Logger.warn("node #{node_name} went down")
    # find where the node is
    case :ets.delete(state.name, node_name) do
      :ok -> :ok
      error -> error
    end

    {:noreply, state}
  end
  def handle_info({:nodeup, node_name}, state) do
    Logger.warn("node #{node_name} is up")
    case :ets.insert(state.name, {node_name, []}) do
      :ok -> {:ok, "inserted"}
      _ ->   {:error}
    end

    {:noreply, state}
  end

end
