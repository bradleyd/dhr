defmodule Router do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Router.Registry, []),
      Plug.Adapters.Cowboy.child_spec(:http, Router.Proxy, [], [port: 4001])
    ]

    opts = [strategy: :one_for_one, name: Router.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
