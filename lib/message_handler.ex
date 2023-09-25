defmodule MessageHandler do
  @moduledoc """
  Documentation for `MessageHandler` which handels incoming messages.
  """
alias ChatServerBRB.State


  @spec handle_message(any, Message, State) :: {State, nil | Message}
  def handle_message(:initial, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'initial' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}")
    current_round = Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})

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
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'echo' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}")
    current_round = Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})
    current_round = %Rounds{current_round | echos_received: [ message | current_round.echos_received]}
    state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round

    # UNSAFE: Check if the value is equal at all 2f+1 echos
    if length(current_round.echos_received) >= 2 * state.num_byzantine_nodes + 1 do
      # TODO: Here are two messages sent, not only one -> ECHO IS FOR NOW IGNORED, SINCE IT'S A CORNER CASE
      {current_round, echo_message} = (
        if current_round.echo_sent == false do
          current_round = %Rounds{current_round | echo_sent: true, value: message.value}
          echo_message = %Message{message | type: :echo, sender_pid: self()}
          {current_round, echo_message}
        else
          {current_round, nil}
        end
      )

      {current_round, ready_message} = (
        if current_round.ready_sent == false do
          current_round = %Rounds{current_round | ready_sent: true}
          ready_message = %Message{message | type: :ready, sender_pid: self()}
          {current_round, ready_message}
        else
          {current_round, nil}
        end
      )
      {put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round), ready_message}
    else
      {state, nil}
    end
  end

  def handle_message(:ready, message, state) do
    IO.puts("On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'ready' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}")
    current_round = Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})
    current_round = %Rounds{current_round | readies_received: [message | current_round.readies_received]}
    state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round

    # UNSAFE: Check if the value is equal at all f+1 readies
    if length(current_round.readies_received) >= state.num_byzantine_nodes + 1 do
      # UNSAFE: Check if the value is equal at all 2f+1 echos
      if length(current_round.readies_received) >= 2 * state.num_byzantine_nodes + 1 do
        if current_round.value_accepted == false do
          current_round = %Rounds{current_round | value_accepted: true}
          state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round
          IO.puts("On #{inspect(self())}: VALUE HAS BEEN ACCEPTED: #{inspect(message.value)} (Initiator, rID: #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}) (Nodes: #{state.num_nodes}/#{state.num_byzantine_nodes}}) (Echo/ready: #{length(current_round.echos_received)}/#{length(current_round.readies_received)})")
          {state, nil}
        else
          {state, nil}
        end
      else
        # TODO: Here are two messages sent, not only one -> ECHO IS FOR NOW IGNORED, SINCE IT'S A CORNER CASE
        {current_round, echo_message} = (
          if current_round.echo_sent == false do
            current_round = %Rounds{current_round | echo_sent: true, value: message.value}
            echo_message = %Message{message | type: :echo, sender_pid: self()}
            {current_round, echo_message}
          else
            {current_round, nil}
          end
        )

        if current_round.ready_sent == false do
          current_round = %Rounds{current_round | ready_sent: true}
          state = put_in state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round
          ready_message = %Message{message | type: :ready, sender_pid: self()}
          {state, ready_message}
        else
          {state, nil}
        end
      end
    else
      {state, nil}
    end
  end

  def handle_message(_message_type, _message, state) do
    IO.puts("Unknown message type received. Ignoring...")
    {state, nil}
  end
end
