defmodule MessageHandler do
  @moduledoc """
  Documentation for `MessageHandler` which handels incoming messages.
  """
  alias ChatServerBRB.State

  @spec handle_message(any, Message, State) :: {boolean, State, [Message]}
  def handle_message(:initial, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'initial' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Round{})

    # Create echo message, if not already sent
    {current_round, echo_message} = create_echo_message(current_round, message)

    {false,
     put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round),
     echo_message}
  end

  def handle_message(:echo, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'echo' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Round{})

    current_round = %Round{
      current_round
      | echos_received: [message | current_round.echos_received]
    }

    state =
      put_in(state.brb_messages[{message.initiator_pid, message.round_identifier}], current_round)

    # UNSAFE: Check if the value is equal for all (n+f)/2 echos
    if length(current_round.echos_received) >= Float.ceil((state.num_nodes + state.num_byzantine_nodes) / 2) do
      # Create echo message, if not already sent
      {current_round, echo_message} = create_echo_message(current_round, message)
      # Create ready message, if not already sent
      {current_round, ready_message} = create_ready_message(current_round, message)

      {false,
       put_in(
         state.brb_messages[{message.initiator_pid, message.round_identifier}],
         current_round
       ), echo_message ++ ready_message}
    else
      {false, state, []}
    end
  end

  def handle_message(:ready, message, state) do
    IO.puts(
      "On #{inspect(self())}, from #{inspect(message.sender_pid)}: Handling type 'ready' with : #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}, #{inspect(message.value)}"
    )

    current_round =
      Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Round{})

    current_round = %Round{
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
          current_round = %Round{current_round | value_accepted: true}

          {true,
           put_in(
             state.brb_messages[{message.initiator_pid, message.round_identifier}],
             current_round
           ), []}
        else
          {false, state, []}
        end
      else
        # Create echo message, if not already sent
        {current_round, echo_message} = create_echo_message(current_round, message)
        # Create ready message, if not already sent
        {current_round, ready_message} = create_ready_message(current_round, message)

        {false,
         put_in(
           state.brb_messages[{message.initiator_pid, message.round_identifier}],
           current_round
         ), echo_message ++ ready_message}
      end
    else
      {false, state, []}
    end
  end

  def handle_message(message_type, _message, state) do
    IO.puts("Unknown message type '#{message_type}' received. Ignoring...")
    {false, state, []}
  end

  @spec create_echo_message(Round, Message) :: {Round, [Message]}
  def create_echo_message(round, message) do
    if round.echo_sent == false do
      round = %Round{round | echo_sent: true, value: message.value}
      echo_message = %Message{message | type: :echo, sender_pid: self()}
      {round, [echo_message]}
    else
      {round, []}
    end
  end

  @spec create_ready_message(Round, Message) :: {Round, [Message]}
  def create_ready_message(round, message) do
    if round.ready_sent == false do
      round = %Round{round | ready_sent: true}
      ready_message = %Message{message | type: :ready, sender_pid: self()}
      {round, [ready_message]}
    else
      {round, []}
    end
  end
end
