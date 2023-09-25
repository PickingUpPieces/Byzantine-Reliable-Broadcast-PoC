defmodule MessageHandler do
  @moduledoc """
  Documentation for `MessageHandler` which handels incoming messages.
  """

  def handle_message(:initial, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'initial' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}, #{inspect(state)}")
    current_round = Map.get(Map.get(state, :brb_messages, %{}), {message.initiator_pid, message.round_identifier}, %{})
    echo_sent = Map.get(current_round, :echo_sent, false)

    # Set echo_sent = true; Set value = value
    # It could be that the node already received enough echos from other nodes to sent its own echo message
    if echo_sent == false do
      current_round = Map.put(current_round, :echo_sent, true)
      current_round = Map.put(current_round, :value, message.value)
      state = Map.put(state, :brb_messages, current_round)
      message = %{message | type: :echo, sender_pid: self()}
      {state, message}
    else
      {state, nil}
    end
  end

  def handle_message(:echo, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'echo' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}, #{inspect(state)}")
      # TODO: Save echo message in map with (initiator, round identifier)
      # TODO: Implement following logic:
      # Check if equal more than echo 2f+1 messages with value v have already been received
      # Yes:
      # If echo_sent == false:
      # Set value
      # Echo broadcast

      # Set ready_sent = true
      # ready broadcast
    {state, nil}
  end

  def handle_message(:ready, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'ready' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}, #{inspect(state)}")
      # TODO: Save ready message in readies_received
      # TODO: Implement following logic:
      # Check if equal more than f+1 ready messages with value v have been received
      # Yes:
        # If echo_sent == false:
      # Set value
      # Echo broadcast
      # If ready_sent == false:
      # ready broadcast
      # Check if equal more than 2f+1 ready messages with value v have been received
      # Yes:
      # --> Accept value
      # Set value_accepted = true
    {state, nil}
  end

  def handle_message({_message_type, _initiator_pid, _sender_pid, _round_identifier, _value}, state) do
    IO.puts("Unknown message type received. Ignoring...")
    {state, nil}
  end
end
