#!/usr/bin/env python3
"""
SuperUART host utility for UART-to-I2C register access.

Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL.
Licensed under the MIT License; see the repository LICENSE file.

This utility sends the command patterns implemented by SUART_IIC_Bridge.vhd.
It does not configure hardware at import time; connect to a port only when a
command is executed.
"""

from __future__ import annotations

import argparse
import sys
import time
from typing import Sequence

try:
    import serial
except ImportError:  # pragma: no cover - depends on the user's environment
    serial = None


DEFAULT_PORT = "/dev/ttyUSB3"
DEFAULT_BAUDRATE = 9600
DEFAULT_TIMEOUT = 1.0
READ_PATTERN = bytes((0xA0, 0xB0, 0xC0, 0xD0))
WRITE_PATTERN = bytes((0xA5, 0xB5, 0xC5, 0xD5))
AUTOBAUD_PATTERN = b"\x55"
SOFT_RESET_PATTERN = bytes((0x76, 0xB1, 0x9D, 0x08))


def parse_byte(value: str) -> int:
    """Parse a byte written in decimal or prefixed hexadecimal notation."""
    try:
        parsed = int(value, 0)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            f"invalid byte {value!r}; use decimal or 0x-prefixed hexadecimal"
        ) from exc
    if not 0 <= parsed <= 0xFF:
        raise argparse.ArgumentTypeError(f"byte value out of range: {value!r}")
    return parsed


def require_serial() -> None:
    if serial is None:
        raise RuntimeError(
            "pyserial is not installed. Install it with: python -m pip install pyserial"
        )


def open_port(port: str, baudrate: int, timeout: float):
    """Open and return a configured serial connection."""
    require_serial()
    if baudrate <= 0:
        raise ValueError("baud rate must be positive")
    if timeout <= 0:
        raise ValueError("timeout must be positive")
    return serial.Serial(
        port=port,
        baudrate=baudrate,
        timeout=timeout,
        write_timeout=timeout,
    )


def write_all(connection, payload: bytes) -> None:
    """Write a complete payload or fail explicitly."""
    written = connection.write(payload)
    connection.flush()
    if written != len(payload):
        raise IOError(f"serial write incomplete: {written}/{len(payload)} bytes")


def read_response(connection, quiet_period: float = 0.2) -> bytes:
    """Collect response bytes until the serial read times out."""
    response = bytearray()
    deadline = time.monotonic() + quiet_period
    while time.monotonic() < deadline:
        chunk = connection.read(1)
        if chunk:
            response.extend(chunk)
            deadline = time.monotonic() + quiet_period
    return bytes(response)


def initialise(connection) -> None:
    """Send the 0x55 pattern used by SuperUART for baud-rate detection."""
    write_all(connection, AUTOBAUD_PATTERN)


def soft_reset(connection) -> None:
    """Send the default 32-bit soft-reset key, most-significant byte first."""
    write_all(connection, SOFT_RESET_PATTERN)


def i2c_write(connection, slave_address: int, register_address: int, value: int) -> bytes:
    """Write one register using the bridge's four-byte write command pattern."""
    payload = WRITE_PATTERN + bytes((slave_address, register_address, value))
    write_all(connection, payload)
    return read_response(connection)


def i2c_read(connection, slave_address: int, register_address: int) -> bytes:
    """Read a register using the bridge's four-byte read command pattern."""
    payload = READ_PATTERN + bytes((slave_address, register_address))
    write_all(connection, payload)
    return read_response(connection)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Read and write registers through the ETROYL SuperUART UART-to-I2C bridge."
    )
    parser.add_argument("--port", default=DEFAULT_PORT, help=f"serial port (default: {DEFAULT_PORT})")
    parser.add_argument("--baudrate", type=int, default=DEFAULT_BAUDRATE, help="serial baud rate (default: 9600)")
    parser.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT, help="serial timeout in seconds (default: 1.0)")
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("init", help="send the 0x55 auto-baud detection pattern")
    subparsers.add_parser("reset", help="send the default soft-reset key")

    read_parser = subparsers.add_parser("read", help="read one I2C register")
    read_parser.add_argument("slave_address", type=parse_byte, help="slave address byte (decimal or 0xNN)")
    read_parser.add_argument("register_address", type=parse_byte, help="register address (decimal or 0xNN)")

    write_parser = subparsers.add_parser("write", help="write one I2C register")
    write_parser.add_argument("slave_address", type=parse_byte, help="slave address byte (decimal or 0xNN)")
    write_parser.add_argument("register_address", type=parse_byte, help="register address (decimal or 0xNN)")
    write_parser.add_argument("value", type=parse_byte, help="value to write (decimal or 0xNN)")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        with open_port(args.port, args.baudrate, args.timeout) as connection:
            if args.command == "init":
                initialise(connection)
                print("Sent auto-baud pattern: 55")
            elif args.command == "reset":
                soft_reset(connection)
                print("Sent soft-reset key: 76b19d08")
            elif args.command == "read":
                response = i2c_read(connection, args.slave_address, args.register_address)
                print(response.hex() if response else "(no response)")
                if not response:
                    print("No response received before timeout.", file=sys.stderr)
                    return 2
            elif args.command == "write":
                response = i2c_write(
                    connection, args.slave_address, args.register_address, args.value
                )
                print(response.hex() if response else "(no response)")
                if not response:
                    print("No response received before timeout.", file=sys.stderr)
                    return 2
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"superuart: error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
