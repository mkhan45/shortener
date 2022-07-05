defmodule Router.Auth do
  use Plug.Router
  import Plug.BasicAuth

  plug :match
  plug :basic_auth, username: "mk", password: "short"
  plug :dispatch

  get "/" do
    conn = Plug.Conn.fetch_query_params(conn)
    with %{"short" => short, "long" => long} <- conn.query_params do
      Links.put(short, long)
      send_resp(conn, 200, "success")
    else
      _ -> send_resp(conn, 200, "error")
    end
  end
end

defmodule Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "" do
    send_resp(conn, 200, ">:(")
  end

  forward "/shorten", to: Router.Auth

  get "/:short" do
    case Links.get(conn.params["short"]) do
      nil -> 
        send_resp(conn, 200, ">:(")

      long -> 
        conn 
        |> Plug.Conn.put_resp_header("location", long) 
        |> send_resp(conn.status || 302, ">:(")
    end
  end
end

defmodule Links do
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def get(short), do: Agent.get(__MODULE__, & Access.get(&1, short))
  def put(short, long), do: Agent.update(__MODULE__, & Map.put(&1, short, long))
end

defmodule ServerApp do
  use Application

  def start(_type, _args) do
    port = 4000

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http, 
        plug: Router, 
        options: [port: port]
      ),
      {Links, []},
    ]

    opts = [strategy: :one_for_one, name: ServerApp.Supervisor]                         
    IO.puts("Starting Server at http://localhost:#{port}...")                                                         
    Supervisor.start_link(children, opts)
  end
end
