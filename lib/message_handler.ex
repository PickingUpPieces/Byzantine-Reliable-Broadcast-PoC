defmodule MessageHandler do
  @moduledoc """
  Documentation for `MessageHandler` which handels incoming messages.
  """
alias ChatServerBRB.State


  @spec handle_message(any, Message, State) :: {State, nil | Message}
  def handle_message(:initial, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'initial' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}, #{inspect(state)}")
    current_round = Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})

    # Set echo_sent = true; Set value = value
    # It could be that the node already received enough echos from other nodes to sent its own echo message
    if current_round.echo_sent == false do
      current_round = %Rounds{current_round | echo_sent: true, value: message.value}
      state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round
      message = %Message{message | type: :echo, sender_pid: self()}
      {state, message}
    else
      {state, nil}
    end
  end

  def handle_message(:echo, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'echo' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}, #{inspect(state)}")
    current_round = Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})
    current_round = %Rounds{current_round | echos_received: [ message | current_round.echos_received]}
    # UNSAFE: Check if the value is equal at all 2f+1 echos
    if length(current_round.echos_received) >= 2 * state.num_byzantine_nodes + 1 do
      {current_round, echo_message} = (
        if current_round.echo_sent == false do
          current_round = %Rounds{current_round | echo_sent: true, value: message.value}
          echo_message = %Message{message | type: :echo, sender_pid: self()}
          {current_round, echo_message}
        else
          {current_round, nil}
        end
      )

      # TODO: Here are two messages sent, not only one -> ECHO IS FOR NOW IGNORED, SINCE IT'S A CORNER CASE
      if current_round.ready_sent == false do
        current_round = %Rounds{current_round | ready_sent: true}
        state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round
        ready_message = %Message{message | type: :ready, sender_pid: self()}
        {state, ready_message}
      else
        {state, nil}
      end
    else
      {state, nil}
    end
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

  def handle_message(_message_type, _message, state) do
    IO.puts("Unknown message type received. Ignoring...")
    {state, nil}
  end
end
