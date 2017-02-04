ExUnit.start()

defmodule TestHelper do
  def press_button(pin, pid) do
    send(pid, {:gpio_interrupt, pin, :falling})
  end

  def get_state(pid) do
    send(pid, {:get_state, self()})
  end
end
