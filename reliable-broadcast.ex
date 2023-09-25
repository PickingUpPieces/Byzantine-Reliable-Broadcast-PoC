defmodule ChatServerRB do
  @nodenames [:elisa, :martin, :kevin, :carlos]

  def nodenames, do: @nodenames

  # state: map containing:
  #   num_nodes: Number of nodes
  #   max_byzantine_nodes: Amount of maximum possible f
  #   round_identifier: Round identifier
  #   delivered_msg: list of delivered messages
  #   brb_messages: map with key node_initiator PID
  #     round: map for each round with key round_identifier
  #       value: broadcasted value
  #       value_accepted: true/false
  #       echo_sent: true/false
  #       ready_sent: true/false
  #       echos_received: List of received echos
  #       readies_received: List of received readies


  def loop_rb(state) do
    receive do
      {:initial, message} ->
        # Rely on rb broadcast and only_once delivery -> Not save the initial message
        # TODO: Set echo_sent = true
        # TODO: Set value = message
        # TODO: broadcast echo
        send(self(), {:brb_broadcast, message}) # send rb_broadcast to self
        loop_rb(state)
      {:echo, message} ->
        # TODO: Save echo message in map with (initiator, round identifier)
        # TODO: Implement following logic:
        # Check if equal more than echo 2f+1 messages with value v have already been received
          # Yes:
            # If echo_sent == false:
              # Set value
              # Echo broadcast

            # Set ready_sent = true
            # ready broadcast
        loop_rb(state)
      {:ready, message} ->
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

        loop_rb(state)
      {:brb_broadcast, message} ->
        # TODO: Create initial message and send out initial message
        mid = :erlang.unique_integer([:positive]) # mid: unique message identifier
        round_identifier = Map.get(state, :round_identifier, 0)
        msg = {"initial", 0, round_identifier, message} # msg layout: message type, initiator PID, round identifier, value/message
        # TODO: update round_identifier+1 and store it
        send(self(), {:rb_broadcast, msg})
        loop_rb(state)
      {:rb_broadcast, message} ->
        mid = :erlang.unique_integer([:positive])
        send(self(), {:beb_broadcast, {mid, message}})
        loop_rb(state)
      {:beb_broadcast, message} ->
        Enum.each(nodenames(), fn n -> send(:global.whereis_name(n), {:ptp, self(), message}) end) # sending msg to all nodes via point2point (ptp)
        loop_rb(state)
      {:ptp, from, message} ->
        send(self(), {:beb_deliver, from, message}) # beb deliver msg to self
        loop_rb(state)
      {:beb_deliver, from, {mid, message}} ->
        delivered = Map.get(state, :delivered_msg, []) # get delivered messages from state
        if not Enum.member?(delivered, mid) do # check if message has been delivered already
          new_delivered = [mid | delivered]
          send(self(), {:rb_deliver, from, message}) # deliver message to self
          loop_rb(Map.put(state, :delivered_msg, new_delivered)) # update state with new delivered messages
        else
          loop_rb(state)
        end
      {:rb_deliver, from, message} ->
          send(self(), {:brb_deliver, from, message}) # deliver message to self
          loop_rb(state)
      {:brb_deliver, from, {type, initiator_pid, round_identifier, message}} ->
          # TODO: Implement here logic for handling echo, ready etc.
          IO.puts "On #{inspect(self())}, #{inspect(from)} says: #{inspect(message)} (#{inspect(type)}, #{inspect(initiator_pid)}, #{inspect(round_identifier)})"
          loop_rb(state)
      :stop ->
          IO.puts "Bye!"
      msg ->
        IO.puts "Unkown message type: #{inspect(msg)}"
        loop_rb(state)
    end
  end

  def start(name) do
    if Enum.member?(nodenames(), name) do
      state = %{
        num_nodes: length(nodenames()),
        num_byzantine_nodes: 1, # Replace with the appropriate value
        round_identifier: 0,
        delivered_msg: [],
        brb_messages: %{}
      }
      pid = spawn(__MODULE__, :loop_rb, [state]) # [%{}] is a list containing a single empty map
      :global.register_name(name, pid)
      IO.puts "#{inspect(name)} registered at #{inspect(pid)}"
    else
      IO.puts("#{name} is not in the list.")
    end
  end

  # TODO: Add num_nodes parameter
  def start_all() do
    # TODO: Create state here and fill num_nodes, max_byzantine_nodes
    Enum.each(nodenames(), fn n -> start(n) end)
  end


  def stop_all() do
    Enum.each(nodenames(), fn n -> send(:global.whereis_name(n), :stop) end)
  end

  def brb_broadcast(name, msg) do
    if Enum.member?(nodenames(), name) do
      send(:global.whereis_name(name),{:brb_broadcast, msg})
    end
  end
end
