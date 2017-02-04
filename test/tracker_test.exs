defmodule TrackerTest do
  use ExUnit.Case, async: true
  import TestHelper

  test "initial state" do
    {:ok, pid} = Tracker.start_link([], [], nil)
    get_state(pid)
    assert_receive :locked
  end

  test "unlocking successfully" do
    {:ok, pid} = Tracker.start_link([], [1, 2, 3], nil)
    press_button(1, pid)
    get_state(pid)
    assert_receive :try_unlock
    press_button(2, pid)
    press_button(3, pid)
    get_state(pid)
    assert_receive :ready
  end

  test "invalid sequence" do
    {:ok, pid} = Tracker.start_link([], [11, 14, 21, 34], nil)
    press_button(14, pid)
    press_button(11, pid)
    press_button(21, pid)
    get_state(pid)
    assert_receive :try_unlock
    press_button(34, pid)
    get_state(pid)
    assert_receive :locked
  end
end
