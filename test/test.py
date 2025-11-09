# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    """Test traffic light behavior with 1 MHz clock and internal dividers"""
    dut._log.info("Start test")

    # 1 MHz Clock
    cocotb.start_soon(Clock(dut.clk, 1, unit="us").start())

    # Reset
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 10)

    dut._log.info("Check initial yellow blinking (1 Hz)")

    yellow_seen = False
    cycles_to_check = 4_000_000 #4s
    for i in range(0, cycles_to_check, 100_000):
        await ClockCycles(dut.clk, 100_000)
        val = int(dut.uo_out.value)
        red    = (val & 0b001) != 0
        yellow = (val & 0b010) != 0
        green  = (val & 0b100) != 0
        dut._log.info(f"Cycle {i}: R={red} Y={yellow} G={green}")

        if yellow and not red and not green:
            yellow_seen = True

    assert yellow_seen, "Yellow should blink at startup"
