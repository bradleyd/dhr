defmodule Router.Proxy do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/*path" do
    nodes_and_paths  = Router.Registry.all

    # fetch query params
    conn = fetch_query_params(conn)

    endpoint =
    find_path(nodes_and_paths, conn.request_path)
    Logger.info(inspect(endpoint))
    endpoint = load_balance(endpoint)

    result =
    case endpoint do
      {:error, error_message} ->
        [code: 404, message: "request path not found, #{error_message}"]
      {endpoint, data} ->
        Logger.info(inspect(endpoint))
        update_counter_for_endpoint(endpoint)
        forward_request(endpoint, conn.params)
    end

    send_resp(conn, result[:code], result[:message])
  end

  defp match_request(request_path) do
    node_list = Router.Registry.endpoints
  end

  defp forward_request(remote_node, params) do
    case :rpc.call(remote_node, Endpoint.Path, :run, [params]) do
      {:badrpc, :nodedown} -> [code: 500, message: "There was an internal server error"]
      result -> [code: 200, message: result]
    end
  end

  defp update_counter_for_endpoint(endpoint) do
    # make another call just in case counter has changed since last time -- race condition
    {remote_node, data} = Router.Registry.lookup(endpoint)
    update              = %{ data | counter: (data.counter + 1) }
    Router.Registry.insert(remote_node, update)
  end

  def load_balance([]) do
    {:error, "no endpoints available"}
  end
  def load_balance(endpoints) do
    Enum.min_by(endpoints, fn({nd, data}) -> data.counter end)
  end

  defp find_path(endpoints, request_path) do
    Enum.filter(endpoints, fn({nd, data}) -> path_exist?(data.paths, request_path)end)
  end

  defp path_exist?(paths, request_path) do
    Enum.any?(paths, fn(path) -> path  == request_path end)
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end
