defmodule Tracker do
  @callback start_link() :: {:ok, pid} | {:error, String.t}
  @callback begin_unlock(pid) :: no_return
  @callback continue_unlock(pid) :: no_return
  @callback unlocked(pid) :: no_return
  @callback unlocked_failed(pid) :: no_return

  defstruct buttons: [], code: [], input_code: [], output: nil, output_mod: Output

  def start_link(buttons \\ [], code \\ [], output_mod \\ Output)
    when is_list(buttons) and is_list(code) do
    :gen_fsm.start_link(__MODULE__, %Tracker{buttons: buttons, code: code, output_mod: output_mod}, [])
  end

  defmacrop output_call(func_name) do
    quote do
      if var!(state).output_mod do
        apply(var!(state).output_mod, unquote(func_name), [var!(state).output])
      end
    end
  end

  # Callbacks

  def init(state = %Tracker{output_mod: nil}) do
    link_buttons(state)
    {:ok, :locked, state}
  end

  def init(state = %Tracker{output_mod: output_mod}) do
    link_buttons(state)
    {:ok, output_pid} = output_mod.start_link()
    {:ok, :locked, %{state | output: output_pid}}
  end

  defp link_buttons(%Tracker{buttons: buttons}) do
    for pin <- buttons do
      {:ok, pid} = Gpio.start_link(pin, :input)
      Gpio.set_int(pid, :falling)
    end
  end

  def handle_info({:get_state, callback_pid}, event, state) do
    send(callback_pid, event)
    {:next_state, event, state}
  end

  def handle_info({:gpio_interrupt, pin, :falling}, :locked, state = %Tracker{input_code: []}) do
    output_call(:begin_unlock)
    {:next_state, :try_unlock, %{state | input_code: [pin]}}
  end

  def handle_info({:gpio_interrupt, pin, :falling}, :try_unlock, state = %Tracker{code: code, input_code: input_code})
    when length(code) > length(input_code) do
    case input_code ++ [pin] do
      updated_input_code when updated_input_code == code ->
        output_call(:unlocked)
        {:next_state, :ready, %{state | input_code: code}}
      updated_input_code when length(updated_input_code) < length(code) ->
        output_call(:continue_unlock)
        {:next_state, :try_unlock, %{state | input_code: updated_input_code}}
      _ ->
        output_call(:unlock_failed)
        {:next_state, :locked, %{state | input_code: []}}
    end
  end

  def handle_info({:gpio_interrupt, _pin, :rising}, event, state) do
    {:next_state, event, state}
  end
end
