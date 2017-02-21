defmodule Output do
  @behaviour Tracker
  @pin 26

  def start_link() do
    Gpio.start_link(@pin, :output)
  end

  def begin_unlock(pid) do
    IO.puts "begin_unlock"
  end

  def continue_unlock(pid) do
    IO.puts "continue_unlock"
  end

  def unlocked(pid) do
    IO.puts "unlocked"
  end

  def unlock_failed(pid) do
    IO.puts "unlock_failed"
  end
end
