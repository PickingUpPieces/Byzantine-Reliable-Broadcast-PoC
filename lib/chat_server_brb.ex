defmodule ChatServerBRB do
  @moduledoc """
  Documentation for `ChatServerBRB`.
  """

  @doc """
  Chat Server with Byzantine Reliable Broadcast (BRB) implementation.

  ## Examples

      iex> ChatServerBRB.brb_broadcast(:elisa, "Hello World!")
      "Hi" TODO: Change return value

  """

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

  def loop_brb(state) do
    receive do
      {:initial, message} ->
        # Rely on rb broadcast and only_once delivery -> Not save the initial message
        # TODO: Set echo_sent = true
        # TODO: Set value = message
        # TODO: broadcast echo
        # send rb_broadcast to self
        send(self(), {:brb_broadcast, message})
        loop_brb(state)

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
        loop_brb(state)

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

        loop_brb(state)

      {:brb_broadcast, message} ->
        # TODO: Create initial message and send out initial message
        round_identifier = Map.get(state, :round_identifier, 0)
        # msg layout: message type, initiator PID, round identifier, value/message
        msg = {"initial", 0, round_identifier, message}
        # TODO: update round_identifier+1 and store it
        send(self(), {:rb_broadcast, msg})
        loop_brb(state)

      {:rb_broadcast, message} ->
        mid = :erlang.unique_integer([:positive])
        send(self(), {:beb_broadcast, {mid, message}})
        loop_brb(state)

      {:beb_broadcast, message} ->
        # sending msg to all nodes via point2point (ptp)
        Enum.each(nodenames(), fn n -> send(:global.whereis_name(n), {:ptp, self(), message}) end)
        loop_brb(state)

      {:ptp, from, message} ->
        # beb deliver msg to self
        send(self(), {:beb_deliver, from, message})
        loop_brb(state)

      {:beb_deliver, from, {mid, message}} ->
        # get delivered messages from state
        delivered = Map.get(state, :delivered_msg, [])
        # check if message has been delivered already
        if not Enum.member?(delivered, mid) do
          new_delivered = [mid | delivered]
          # deliver message to self
          send(self(), {:rb_deliver, from, message})
          # update state with new delivered messages
          loop_brb(Map.put(state, :delivered_msg, new_delivered))
        else
          loop_brb(state)
        end

      {:rb_deliver, from, message} ->
        # deliver message to self
        send(self(), {:brb_deliver, from, message})
        loop_brb(state)

      {:brb_deliver, from, {type, initiator_pid, round_identifier, message}} ->
        # TODO: Implement here logic for handling echo, ready etc.
        IO.puts(
          "On #{inspect(self())}, #{inspect(from)} says: #{inspect(message)} (#{inspect(type)}, #{inspect(initiator_pid)}, #{inspect(round_identifier)})"
        )

        loop_brb(state)

      :stop ->
        IO.puts("Bye!")

      msg ->
        IO.puts("Unkown message type: #{inspect(msg)}")
        loop_brb(state)
    end
  end

  def start(name) do
    if Enum.member?(nodenames(), name) do
      state = %{
        num_nodes: length(nodenames()),
        # Replace with the appropriate value
        num_byzantine_nodes: 1,
        round_identifier: 0,
        delivered_msg: [],
        brb_messages: %{}
      }

      # [%{}] is a list containing a single empty map
      pid = spawn(__MODULE__, :loop_brb, [state])
      :global.register_name(name, pid)
      IO.puts("#{inspect(name)} registered at #{inspect(pid)}")
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
      send(:global.whereis_name(name), {:brb_broadcast, msg})
    end
  end
end
