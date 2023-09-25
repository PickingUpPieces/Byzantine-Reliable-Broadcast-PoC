  # message layout: message type (initial, echo, ready), initiator PID, sender PID, round identifier, value/message
  defmodule Message do
    defstruct [:type , :initiator_pid, :sender_pid, :round_identifier, :value]
  end

  # state: map containing:
  #   num_nodes: Number of nodes
  #   num_byzantine_nodes: Amount of maximum possible f
  #   round_identifier: Round identifier
  #   delivered_msg: list of delivered messages
  #   brb_messages:  map with key {initiator_pid, round}
  #     value: broadcasted value
  #     value_accepted: true/false
  #     echo_sent: true/false
  #     ready_sent: true/false
  #     echos_received: List of received echos
  #     readies_received: List of received readies

  defmodule State do
    defstruct num_nodes: 0, num_byzantine_nodes: 0, round_identifier: 0, delivered_msg: [], brb_messages: %{}
  end

  defmodule Rounds do
    defstruct value: nil, value_accepted: false, echo_sent: false, ready_sent: false, echos_received: [], readies_received: []
  end
