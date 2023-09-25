  # message layout: message type (initial, echo, ready), initiator PID, sender PID, round identifier, value/message
  defmodule Message do
    defstruct [:type , :initiator_pid, :sender_pid, :round_identifier, :value]
  end
