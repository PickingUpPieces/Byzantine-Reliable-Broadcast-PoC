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

        send(self(), {:rb_broadcast, message})
        loop_brb(%State{state | round_identifier: state.round_identifier + 1})

      {:rb_broadcast, message} ->
        mid = :erlang.unique_integer([:positive])
        send(self(), {:beb_broadcast, {mid, message}})
        loop_brb(state)

      {:beb_broadcast, message} ->
        Enum.each(nodenames(), fn n -> send(:global.whereis_name(n), {:ptp, self(), message}) end)
        loop_brb(state)

      {:ptp, from, message} ->
        send(self(), {:beb_deliver, from, message})
        loop_brb(state)

      {:beb_deliver, from, {mid, message}} ->
        if not Enum.member?(state.delivered_msg, mid) do
          send(self(), {:rb_deliver, from, message})
          loop_brb(%State{state | delivered_msg: [mid | state.delivered_msg]})
        else
          loop_brb(state)
        end

      {:rb_deliver, from, message} ->
        send(self(), {:brb_deliver, from, message})
        loop_brb(state)

      {:brb_deliver, _from, message} ->
        {state, message} = MessageHandler.handle_message(message.type, message, state)

        for msg <- message do
          if !is_nil(msg) do
            send(self(), {:rb_broadcast, msg})
          end
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
