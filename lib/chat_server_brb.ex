defmodule ChatServerBRB do
  @moduledoc """
  Documentation for `ChatServerBRB`.
  """

  @doc """
  Chat Server with Byzantine Reliable Broadcast (BRB) implementation.
  """

  @nodenames [:elisa, :martin, :carlos, :kevin]

  def nodenames, do: @nodenames

  @spec loop_brb(State) :: :ok
  def loop_brb(state) do
    receive do
      {:brb_broadcast, value} ->
        message = %Message{
          type: :initial,
          initiator_pid: self(),
          sender_pid: self(),
          round_identifier: state.round_identifier,
          value: value
        }

        IO.puts(
          "On #{inspect(self())}, START NEW BROADCAST (#{inspect(self())}, #{state.round_identifier}) with value: #{value}"
        )

        send(self(), {:beb_broadcast, message})
        loop_brb(%State{state | round_identifier: state.round_identifier + 1})

      {:beb_broadcast, message} ->
        Enum.each(nodenames(), fn n -> send(:global.whereis_name(n), {:ptp, self(), message}) end)
        loop_brb(state)

      {:ptp, from, message} ->
        send(self(), {:beb_deliver, from, message})
        loop_brb(state)

      {:beb_deliver, _from, message} ->
        send(self(), {:brb_deliver, message})
        loop_brb(state)

      {:brb_deliver, message} ->
        {value_accepted, state, messages} = MessageHandler.handle_message(message.type, message, state)

        for msg <- messages do
          if !is_nil(msg) do
            send(self(), {:beb_broadcast, msg})
          end
        end

        if value_accepted do
          current_round =
            Map.get(state.brb_messages, {message.initiator_pid, message.round_identifier}, %Round{})
          IO.puts(
            "On #{inspect(self())}: VALUE HAS BEEN ACCEPTED: #{inspect(message.value)} (Initiator, rID: #{inspect(message.initiator_pid)}, #{inspect(message.round_identifier)}) (Nodes: #{state.num_nodes}/#{state.num_byzantine_nodes}}) (Echo/ready: #{length(current_round.echos_received)}/#{length(current_round.readies_received)})"
          )
        end

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
      state = %State{
        num_nodes: length(nodenames()),
        num_byzantine_nodes: 1
      }

      pid = spawn(__MODULE__, :loop_brb, [state])
      :global.register_name(name, pid)
      IO.puts("#{inspect(name)} registered at #{inspect(pid)}")
    else
      IO.puts("#{name} is not in the list.")
    end
  end

  # TODO: Add num_nodes parameter
  def start_all() do
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
