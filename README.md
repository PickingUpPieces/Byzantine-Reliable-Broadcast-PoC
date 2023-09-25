# dare23-project
Project for the Summer School DARE2023.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `brb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:brb, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/brb>.


## Instructions to connect processes/nodes 
Start the software with the following command: `iex --sname test1 --cookie secret -r reliable-broadcast.ex` 
Connect the nodes with the following command: `Node.ping(:'test1@computer-name')`
Check if the nodes are connected with the following command: `Node.list`
Register process with names: `:global.register_name(:process_name, self())`
Look up all registered names: `:global.registered_names`
Send message to a process: `send(:process_name, hi)`
