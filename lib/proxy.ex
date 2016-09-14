defmodule Router.Proxy do
  use Plug.Router
  plug :match
  plug :dispatch

  get "/*path" do
    IO.inspect conn.request_path #Map.keys(conn)
    {:ok, node_list} = Router.Registry.endpoints
    nodes = Enum.map(node_list, fn(nd) -> Router.Registry.lookup(nd) end)
    IO.inspect nodes
    result =
    case Enum.find(nodes, fn(x) -> elem(x,1) == conn.request_path end) do
      {nd, ep} -> :rpc.call(nd, Endpoint.Path, :run, [1])
      _ -> "not found"
    end

    IO.inspect result

    send_resp(conn, 200, result)
  end

  defp match_request(request_path) do
    node_list = Router.Registry.endpoints
  end

  #defp paths([], acc), do: acc
  #def paths([h|t], acc)
  #defp paths({nd, paths}, request_path) when is_list(paths) do
  #  case Enum.any?(paths, fn(x) -> request_path == x end) do
  #    true ->
  #  end
  #end

end
