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

    dut._log.info("Check initial (red on)")

    # Anfangszustand prüfen
    await ClockCycles(dut.clk, 2)
    val = int(dut.uo_out.value)
    red = (val & 0b001) != 0
    yellow = (val & 0b010) != 0
    green = (val & 0b100) != 0


    assert red and not yellow and not green, f"Expected red ON initially, got {dut.uo_out.value.binstr}"

    # Jetzt einfach ein paar Zyklen laufen lassen und Zustände beobachten
    dut._log.info("Stepping through light states")

    for i in range(20):
        await ClockCycles(dut.clk, 10)
        dut._log.info(f"t={i}: uo_out={dut.uo_out.value.binstr}")

    # Keine feste Assertion am Ende – nur Ablauf prüfen
    dut._log.info("Traffic light test completed")
