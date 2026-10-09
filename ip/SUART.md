# SuperUART (SUART) Core Guide

**Project:** ETROYL/SuperUART  
**Core:** `SUART` in `vhdl_codes/SUART.vhd`  
**License:** MIT — see the repository `LICENSE`.

This guide documents the source-code UART core. The repository also contains a UART-to-I²C bridge; see the root [README](../README.md) for the complete system, host utility, and bridge protocol.

## 1. Features

- Automatic baud-rate detection from a host-sent `0x55` byte after reset.
- 8-bit UART data, no parity, one stop bit (8N1); idle line is high.
- RX buffering through a Xilinx Vivado FIFO Generator IP.
- Runtime re-lock using hardware reset or an optional 32-bit soft-reset key.
- Byte-at-a-time transmit interface; this version has no TX FIFO.

The original project notes report successful tests from 300 baud to 1,843,200 baud. Treat this as a historical test report, not a guarantee for every FPGA, clock, or implementation.

## 2. Clock and baud rate

The legacy project notes suggest keeping the main clock at least four times faster than the target baud rate (for example, 100 MHz for up to 25 Mbaud). This is a design guideline from the original notes, **not a limit enforced by the RTL**. The core measures the training-byte bit period in clock cycles, and counter range, measurement quantisation, timing closure, and integration affect the usable range. Use a comfortably higher clock-to-baud ratio where practical and validate the intended operating point in simulation and hardware.

## 3. Entity interface

The entity is defined in `vhdl_codes/SUART.vhd`.

| Port | Direction | Description |
|---|---|---|
| `CLK` | Input | Main FPGA clock. |
| `rst_n` | Input | Active-low hardware reset. Resets the core and re-arms baud detection. |
| `RX` | Input | UART receive input. Idle high; connect to the host's TX. Ensure suitable electrical levels and pull-up/biasing for the interface. |
| `TX` | Output | UART transmit output. Connect to the host's RX. |
| `Transmit` | Input | Rising-edge request to transmit `TX_DATA`; request only when `RDY2Transmit` is high. Return low before the next request. |
| `RDY2Transmit` | Output | Indicates that the transmitter is ready for a new byte. Low while a byte is being transmitted. |
| `TX_DATA[7:0]` | Input | Byte to transmit. Keep stable when issuing the request. |
| `Read_RX` | Input | Read request for the RX FIFO. Use a low-to-high transition and return low before the next request. |
| `RX_DATA[7:0]` | Output | Data output from the RX FIFO. |
| `RX_Data_Valid` | Output | FIFO valid indication for read data. Wait for this signal before sampling the returned byte. |
| `BUFF_EMPTY` | Output | Active-high empty indication: low means at least one byte is available to read. |
| `BUFF_FULL` | Output | Active-high full indication. If the FIFO is full, incoming bytes may be lost. |
| `fifo_wr_ack` | Output | FIFO write-acknowledge indication. |

### Generics

| Generic | Default | Description |
|---|---|---|
| `soft_rst_enable` | `true` | Enables recognition of the soft-reset key. Set to `false` to disable it. |
| `soft_rst_pattern` | `X"76B19D08"` | 32-bit soft-reset key, received most-significant byte first. |

## 4. Start-up and baud detection

1. Apply a hardware reset by asserting `rst_n = '0'`, then release it.
2. Send the byte `0x55` at the desired UART baud rate.
3. Allow the core to detect the bit period and lock before sending application data. The `0x55` used for detection is not application data in the RX FIFO.
4. Transfer ordinary data using 8N1 framing.

The core does not expose its internal baud-lock signal as a top-level port. A host-side delay may be used as a practical workaround, but it should be validated for the target clock and baud rate rather than treated as a formal ready handshake.

To re-arm baud detection, apply hardware reset or, when enabled, send the configured four-byte soft-reset key in byte order. The default key is:

`76 B1 9D 08`

A matching key is intended as a control sequence, so avoid sending it as ordinary payload when soft reset is enabled.

## 5. Transmitting one byte

1. Wait until `RDY2Transmit = '1'`.
2. Put the byte on `TX_DATA[7:0]`.
3. Ensure `Transmit` is low, then assert it high to create a rising edge.
4. Wait for the transfer to finish; `RDY2Transmit` returns high when the core is ready again.
5. Return `Transmit` low before issuing another request.

There is no transmit FIFO in this version. The caller is responsible for waiting until the core can accept the next byte.

## 6. Receiving one byte

1. Wait until `BUFF_EMPTY = '0'`.
2. Ensure `Read_RX` is low, then assert it high to request a FIFO read.
3. Wait for `RX_Data_Valid = '1'`.
4. Sample `RX_DATA[7:0]`.
5. Return `Read_RX` low before requesting another byte.

Hold control levels long enough to be sampled by `CLK`. Check the FIFO Generator's configured read mode and timing against this handshake.

## 7. Required Vivado FIFO IP

The RTL instantiates a FIFO Generator component named `fifo_generator_0`; its generated IP is not included as a standalone VHDL source in this repository. Create the IP in Vivado and ensure its component interface matches the declaration and port map in `SUART.vhd`.

The RTL expects these ports: `clk`, `srst`, `din[7:0]`, `wr_en`, `rd_en`, `dout[7:0]`, `full`, `wr_ack`, `empty`, `valid`, `wr_rst_busy`, and `rd_rst_busy`.

- Data width: 8 bits.
- Clock: common clock driven by `CLK`.
- Reset: synchronous reset input `srst`.
- Enable the `wr_ack` and `valid` flags.
- Select a read mode compatible with the RTL's one-cycle read-enable pulse and the FIFO `valid` output. The core wires `valid` directly to `RX_Data_Valid`; verify the generated IP's latency and timing before relying on the sample handshake above.
- Choose FIFO depth based on the maximum burst of incoming bytes and how long downstream logic may take to consume them.

FIFO Generator settings and generated port lists can vary by Vivado/IP version. Verify the generated component interface before building the design.

## 8. Scope and limitations

- No parity, framing-error, or break-detection outputs are provided.
- No TX FIFO is implemented.
- `BUFF_FULL` indicates the RX FIFO is full; the design does not provide a complete flow-control mechanism to prevent the host from sending more data.
- Baud detection depends on a correctly received `0x55` training byte and suitable clock/baud conditions.
- This core uses FPGA logic-level UART signals. A PC serial port may require a USB-to-UART adapter and compatible voltage levels; do not connect RS-232 voltage levels directly to FPGA pins.
- Successful synthesis, timing closure, simulation, and hardware operation depend on the target device, Vivado version, generated FIFO IP, constraints, and integration.

## 9. Related files

- `vhdl_codes/SUART.vhd` — UART core RTL.
- `vhdl_codes/SUART_IIC_Bridge.vhd` — optional UART-to-I²C command bridge.
- `host/superuart.py` — Python host utility for the bridge.
- [Root README](../README.md) — architecture, bridge command format, host CLI examples, and repository notes.

