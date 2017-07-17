defmodule Todo.Web do
  use Plug.Router

  plug :match
  plug :dispatch

  post "/add_entry" do
    conn
    |> Plug.Conn.fetch_query_params
    |> add_entry
    |> respond
  end

  get "/entries" do
    conn
    |> Plug.Conn.fetch_query_params
    |> get_entries
    |> respond
  end

  defp get_entries(conn) do
    Plug.Conn.assign(
      conn,
      :response,
      entries(conn.params["list"], parse_date(conn.params["date"]))
    )
  end

  defp entries(list_name, date) do
    list_name
    |> Todo.Cache.server_process
    |> Todo.Server.entries(date)
    |> format_entries
  end

  defp format_entries(entries) do
    for entry <- entries do
      {y,m,d} = entry.date
      "#{y}-#{m}-#{d}   #{entry.title}"
    end
    |> Enum.join("\n")
  end

  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: 5454)
  end

  defp add_entry(conn) do
    conn.params["list"]
    |> Todo.Cache.server_process
    |> Todo.Server.add_entry(
      %{
        date: parse_date(conn.params["date"]),
        title: conn.params["title"]
      }
    )

    Plug.Conn.assign(conn, :response, "OK")
  end

  defp parse_date(date_string) do
    year = String.slice(date_string, 0, 4)
    month = String.slice(date_string, 4, 2)
    day = String.slice(date_string, 6, 2)

    [year, month, day] # returns {2013, 12, 19}
    |> Enum.map(&String.to_integer/1) 
    |> List.to_tuple
  end

  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, conn.assigns[:response])
  end
end