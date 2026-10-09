"""Unit tests for the SuperUART host utility.

Copyright (c) 2023-2026 Dr. Ir. Siavash Ardekani and ETROYL.
SPDX-License-Identifier: MIT
"""

import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "host"
    / "superuart.py"
)
SPEC = importlib.util.spec_from_file_location("superuart_host", SCRIPT)
HOST = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HOST)


class FakeSerial:
    def __init__(self):
        self.writes = []
        self.flushed = False

    def write(self, payload):
        self.writes.append(payload)
        return len(payload)

    def flush(self):
        self.flushed = True


class HostUtilityTests(unittest.TestCase):
    def test_parse_byte_accepts_decimal_and_hex(self):
        self.assertEqual(HOST.parse_byte("42"), 42)
        self.assertEqual(HOST.parse_byte("0x2a"), 42)
        self.assertEqual(HOST.parse_byte("0xff"), 255)

    def test_parse_byte_rejects_out_of_range(self):
        with self.assertRaises(Exception):
            HOST.parse_byte("256")
        with self.assertRaises(Exception):
            HOST.parse_byte("-1")

    def test_initialise_sends_autobaud_pattern(self):
        connection = FakeSerial()
        HOST.initialise(connection)
        self.assertEqual(connection.writes, [b"\x55"])
        self.assertTrue(connection.flushed)

    def test_soft_reset_sends_default_key(self):
        connection = FakeSerial()
        HOST.soft_reset(connection)
        self.assertEqual(connection.writes, [bytes.fromhex("76 b1 9d 08")])

    @patch.object(HOST, "read_response", return_value=b"\x42")
    def test_i2c_read_sends_expected_frame(self, _read_response):
        connection = FakeSerial()
        response = HOST.i2c_read(connection, 0xA2, 0x0A)
        self.assertEqual(connection.writes, [bytes.fromhex("a0 b0 c0 d0 a2 0a")])
        self.assertEqual(response, b"\x42")

    @patch.object(HOST, "read_response", return_value=b"")
    def test_i2c_write_sends_expected_frame(self, _read_response):
        connection = FakeSerial()
        response = HOST.i2c_write(connection, 0xA2, 0x10, 0x88)
        self.assertEqual(connection.writes, [bytes.fromhex("a5 b5 c5 d5 a2 10 88")])
        self.assertEqual(response, b"")


if __name__ == "__main__":
    unittest.main()
