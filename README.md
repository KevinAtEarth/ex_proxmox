# ExProxmox

ExProxmox is an Elixir client for interacting with the Proxmox PVE APIv2. It allows you to manage virtual machines, containers, and other resources on a Proxmox server.

## Installation

Add `ex_proxmox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_proxmox, "~> 0.1.0"}
  ]
end
```

Then, run mix deps.get to fetch the dependencies.

## Usage
To create a new ExProxmox client, use the ExProxmox.new/2 function:
```elixir
client = ExProxmox.new("https://proxmox-ve:8006/api2/json/", %{
  "username" => "root@pam",
  "password" => "secret"
})
```
You can submit requests to the Proxmox API using the ExProxmox.submit/3 function:
```elixir
response = ExProxmox.submit(client, :get, "nodes")
```

## Example

Here's a complete example of how to create a client and fetch the list of nodes:

```elixir
defmodule Example do
def run do
client = ExProxmox.new("https://proxmox-ve:8006/api2/json/", %{
"username" => "root@pam",
"password" => "secret"
})

    response = ExProxmox.submit(client, :get, "nodes")
    IO.inspect(response)
end
end

Example.run()
```