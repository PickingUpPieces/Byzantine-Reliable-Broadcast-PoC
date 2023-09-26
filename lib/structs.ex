defmodule Message do
  @type t :: %Message{
    type: atom(),
    initiator_pid: pid(),
    sender_pid: pid(),
    round_identifier: integer(),
    value: any()
  }

  defstruct [:type, :initiator_pid, :sender_pid, :round_identifier, :value]
end

defmodule State do
  @type t :: %State{
    num_nodes: integer(),
    num_byzantine_nodes: integer(),
    round_identifier: integer(),
    brb_messages: %{{pid, integer()} => Round.t()}
  }

  defstruct num_nodes: 0,
            num_byzantine_nodes: 0,
            round_identifier: 0,
            brb_messages: %{}
end

defmodule Round do
  @type t :: %Round{
    value: any(),
    value_accepted: boolean(),
    echo_sent: boolean(),
    ready_sent: boolean(),
    echos_received: [Message.t()],
    readies_received: [Message.t()]
  }
  defstruct value: nil,
            value_accepted: false,
            echo_sent: false,
            ready_sent: false,
            echos_received: [],
            readies_received: []
end
