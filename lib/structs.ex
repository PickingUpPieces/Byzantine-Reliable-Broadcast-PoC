  # message layout: message type (initial, echo, ready), initiator PID, sender PID, round identifier, value/message
  defmodule Message do
    defstruct [:type , :initiator_pid, :sender_pid, :round_identifier, :value]
  end

  defmodule Rounds do
    defstruct value: nil, value_accepted: false, echo_sent: false, ready_sent: false, echos_received: [], readies_received: []
  end

  defmodule State do
    defstruct num_nodes: 0, num_byzantine_nodes: 0, round_identifier: 0, delivered_msg: [], brb_messages: %{}
  end
