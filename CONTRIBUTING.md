# Contributing to SuperUART

Thank you for your interest in SuperUART.

## Before submitting a change

1. Open an issue or discussion for substantial changes before investing in implementation.
2. Keep changes focused and explain the hardware/software assumptions they rely on.
3. Do not commit generated Vivado output, machine-specific paths, credentials, or hardware logs containing sensitive information.
4. Preserve existing attribution and third-party notices when modifying source files.
5. Update the documentation when changing interfaces, protocol behaviour, build steps, or limitations.

## Verification

- Python changes should pass syntax compilation and, where practical, tests using mocked serial I/O so no physical hardware is required.
- VHDL changes should include a reproducible simulation procedure and test results. Clearly identify any required Vivado IP that is not included in the repository.
- Hardware-dependent checks must state the board, tool version, and setup used.

## Pull requests

Describe the motivation, implementation, compatibility impact, and verification performed. Do not claim hardware validation unless it was actually performed.
