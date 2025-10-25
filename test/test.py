# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # dut._log.info("Test project behavior")

    # # Set the input values you want to test
    # dut.ui_in.value = 20
    # dut.uio_in.value = 30

    # # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)

    # # The following assersion is just an example of how to check the output values.
    # # Change it to match the actual expected output of your module:
    # assert dut.uo_out.value == 50

    # # Keep testing the module by changing the input values, waiting for
    # # one or more clock cycles, and asserting the expected output values.

    dut._log.info("Check initial yellow blinking")

    yellow_seen = False
    cycles_to_check = 10  # Anzahl der Takte, die wir beobachten wollen

    for i in range(cycles_to_check):
        await ClockCycles(dut.clk, 5)  # Warte 5 Takte pro Iteration
        val = int(dut.uo_out.value)    # LogicArray → int
        red    = (val & 0b001) != 0
        yellow = (val & 0b010) != 0
        green  = (val & 0b100) != 0
        dut._log.info(f"Cycle {i}: R={red} Y={yellow} G={green}")

        # Prüfen, ob Gelb an ist, während Rot und Grün aus sind
        if yellow and not red and not green:
            yellow_seen = True

    # Assertion: Gelb hat mindestens einmal geleuchtet
    assert yellow_seen, "Expected yellow blinking at startup"
