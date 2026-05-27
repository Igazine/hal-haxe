# HAL for Haxe

A Haxe implementation of the Hybrid Automation Language (HAL).

This repository provides a spec-compliant, environment-agnostic library (`hal-haxe`) for embedding the HAL interpreter into any Haxe-supported target (C++, JavaScript, Python, Java, C#, etc.).

## Features
- **Strict Spec Compliance**: Implements the v1.2.0-alpha2 specification.
- **Environment Agnostic**: The core library has zero dependencies on `sys` or target-specific APIs.
- **Universal Parity**: Bit-perfect execution parity with Go, Rust, TS, and Dart implementations.
- **Modular StdLib**: Full parity with HAL 1.0 standard library specifications.

## Installation

```bash
haxelib git hal-haxe https://github.com/Igazine/hal-haxe.git
```

## Example Demo

An example CLI demo is included in `examples/demo`. To run the conformance tests:

1. **Initialize Submodules**:
   ```bash
   git submodule update --init --recursive
   ```
2. **Run Demo**:
   ```bash
   cd examples/demo
   haxe build.hxml
   ```

## Project Links

- **HAL Core Repo**: [Igazine/hal](https://github.com/Igazine/hal)
- **Official Documentation**: [https://igazine.github.io/hal/](https://igazine.github.io/hal/)

## License

This project is licensed under the MIT License.
