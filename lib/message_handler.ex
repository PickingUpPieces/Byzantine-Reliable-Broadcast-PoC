defmodule MessageHandler do
  @moduledoc """
  Documentation for `MessageHandler` which handels incoming messages.
  """
  alias ChatServerBRB.State

  @spec handle_message(any, Message, State) :: {State, [Message]}
  def handle_message(:initial, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'initial' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})

    # Create echo message, if not already sent
    {current_round, echo_message} = create_echo_message(current_round, message)

    {put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round),
     echo_message}
  end

  def handle_message(:echo, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'echo' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})

    current_round = %Rounds{
      current_round
      | echos_received: [message | current_round.echos_received]
    }

    state =
      put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round)

    # UNSAFE: Check if the value is equal for all 2f+1 echos
    if length(current_round.echos_received) >= 2 * state.num_byzantine_nodes + 1 do
      # Create echo message, if not already sent
      {current_round, echo_message} = create_echo_message(current_round, message)
      # Create ready message, if not already sent
      {current_round, ready_message} = create_ready_message(current_round, message)

      {put_in(
         state.brb_messages[{message.initiator_pid, message.round_identifier}],
         current_round
       ), echo_message ++ ready_message}
    else
      {state, []}
    end
  end

  def handle_message(:ready, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'ready' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Rounds{})

    current_round = %Rounds{
      current_round
      | readies_received: [message | current_round.readies_received]
    }

    state =
      put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round)

    # UNSAFE: Check if the value is equal for all f+1 readies
    if length(current_round.readies_received) >= state.num_byzantine_nodes + 1 do
      # UNSAFE: Check if the value is equal for all 2f+1 echos
      if length(current_round.readies_received) >= 2 * state.num_byzantine_nodes + 1 do
        if current_round.value_accepted == false do
          IO.puts(
            "On #{inspect(self())}: VALUE HAS BEEN ACCEPTED: #{inspect(message.value)} (Initiator, rID: #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}) (Nodes: #{state.num_nodes}/#{state.num_byzantine_nodes}}) (Echo/ready: #{length(current_round.echos_received)}/#{length(current_round.readies_received)})"
          )

          current_round = %Rounds{current_round | value_accepted: true}

          {put_in(
             state.brb_messages[{message.initiator_pid, message.round_identifier}],
             current_round
           ), []}
        else
          {state, []}
        end
      else
        # Create echo message, if not already sent
        {current_round, echo_message} = create_echo_message(current_round, message)
        # Create ready message, if not already sent
        {current_round, ready_message} = create_ready_message(current_round, message)

        {put_in(
           state.brb_messages[{message.initiator_pid, message.round_identifier}],
           current_round
         ), echo_message ++ ready_message}
      end
    else
      {state, []}
    end
  end

  def handle_message(_message_type, _message, state) do
    IO.puts("Unknown message type received. Ignoring...")
    {state, []}
  end

  @spec create_echo_message(Rounds, Message) :: {Rounds, [Message]}
  def create_echo_message(round, message) do
    if round.echo_sent == false do
      round = %Rounds{round | echo_sent: true, value: message.value}
      echo_message = %Message{message | type: :echo, sender_pid: self()}
      {round, [echo_message]}
    else
      {round, []}
    end
  end

  @spec create_ready_message(Rounds, Message) :: {Rounds, [Message]}
  def create_ready_message(round, message) do
    if round.ready_sent == false do
      round = %Rounds{round | ready_sent: true}
      ready_message = %Message{message | type: :ready, sender_pid: self()}
      {round, [ready_message]}
    else
      {round, []}
    end
  end
end
