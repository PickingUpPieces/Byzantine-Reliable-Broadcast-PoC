defmodule ChatServerBRBTest do
  use ExUnit.Case, async: true

  describe "Test message handler" do
    setup do
      [state: %State{
        num_nodes: 4,
        num_byzantine_nodes: 1,
        round_identifier: 0,
        brb_messages: %{}
        }
      ]
    end

    test "handle initial message", context do
      initial_message = %Message{
        type: :initial,
        initiator_pid: self(),
        sender_pid: self(),
        round_identifier: 0,
        value: "Hello World"
      }

      expected_echo_message = %Message{
        type: :echo,
        initiator_pid: self(),
        sender_pid: self(),
        round_identifier: 0,
        value: "Hello World"
      }

      {_, _, messages} = MessageHandler.handle_message(:initial, initial_message, context.state)
      assert messages == [expected_echo_message]
    end

    test "handle echo message", context do
      echo_message = %Message{
        type: :echo,
        initiator_pid: self(),
        sender_pid: self(),
        round_identifier: 0,
        value: "Hello World"
      }

      {_, _, messages} = MessageHandler.handle_message(:echo, echo_message, context.state)
      assert messages == []
    end

    test "handle ready message", context do
      ready_message = %Message{
        type: :ready,
        initiator_pid: self(),
        sender_pid: self(),
        round_identifier: 0,
        value: "Hello World"
      }

      {_, _, messages} = MessageHandler.handle_message(:ready, ready_message, context.state)
      assert messages == []
    end
  end
end
