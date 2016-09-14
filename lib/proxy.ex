defmodule Router.Proxy do
  use Plug.Router
  plug :match
  plug :dispatch

  get "/*path" do
    {:ok, node_list} = Router.Registry.endpoints
    nodes_and_paths  = Enum.map(node_list, fn(nd) -> Router.Registry.lookup(nd) end)

    result =
    case Enum.find(nodes_and_paths, fn(x) -> Enum.any?(elem(x,1), fn(x) -> x  == conn.request_path end) end) do
      {nd, ep} -> forward_request(nd)
      _ -> [code: 404, message: "request path not found"]
    end

    send_resp(conn, result[:code], result[:message])
  end

  defp match_request(request_path) do
    node_list = Router.Registry.endpoints
  end

  defp forward_request(remote_node) do
    case :rpc.call(remote_node, Endpoint.Path, :run, [1]) do
      {:badrpc, :nodedown} -> [code: 500, message: "There was an internal server error"]
      result -> [code: 200, message: result]
    end
  end

  #defp paths([], acc), do: acc
  #def paths([h|t], acc)
  #defp paths({nd, paths}, request_path) when is_list(paths) do
  #  case Enum.any?(paths, fn(x) -> request_path == x end) do
  #    true ->
  #  end
  #end

end
