<p align="center">
  <img src="assets/ferris.png" width="120" alt="Ferris the Rust Crab" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="assets/arduino-logo.png" width="120" alt="Arduino" />
</p>

<h1 align="center">unoq-starter</h1>

<p align="center">
  A Rust starter project for the <strong>Arduino UNO Q</strong> development board
</p>

---

## Overview

This workspace targets both processors on the Arduino UNO Q board:

| Crate | Processor         | Core                       | Target                      | OS                    |
| ----- | ----------------- | -------------------------- | --------------------------- | --------------------- |
| `mpu` | Qualcomm QRB2210  | Arm Cortex-A53 (quad-core) | `aarch64-unknown-linux-gnu` | Debian Linux          |
| `mcu` | STMicro STM32U585 | Arm Cortex-M33             | `thumbv8m.main-none-eabihf` | Bare-metal (`no_std`) |

## Project Structure

```
unoq-starter/
├── Cargo.toml              # Workspace root
├── Makefile                # Build, deploy, and run targets
├── .cargo/config.toml      # Cross-compilation & cargo aliases
├── mpu/                    # QRB2210 MPU — Linux userspace binary
│   ├── Cargo.toml
│   └── src/main.rs
├── mcu/                    # STM32U585 MCU — Embedded bare-metal binary
│   ├── Cargo.toml
│   ├── memory.x            # Linker script (Flash + SRAM layout)
│   ├── build.rs            # Linker search path setup
│   └── src/main.rs
```

## Prerequisites

### Rust Toolchain

Install Rust via [rustup](https://rustup.rs/):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Add the compilation targets:

```bash
rustup target add thumbv8m.main-none-eabihf   # MCU (Cortex-M33)
rustup target add aarch64-unknown-linux-gnu    # MPU (Cortex-A53)
```

### Cross-Compilation Toolchain (MPU)

To cross-compile the MPU crate from a non-aarch64 host, install the GNU cross-linker:

**Debian/Ubuntu:**

```bash
sudo apt-get install gcc-aarch64-linux-gnu
```

**macOS (Homebrew):**

```bash
brew install aarch64-elf-gcc
brew tap messense/macos-cross-toolchains && brew install aarch64-unknown-linux-gnu
```

Alternatively, use [cross](https://github.com/cross-rs/cross) for Docker-based cross-compilation with zero setup:

```bash
cargo install cross
cross build -p mpu --target aarch64-unknown-linux-gnu
```

### ADB + OpenOCD Tooling (MCU)

The STM32U585 SWD debug pins are **not externally exposed** on the Arduino UNO Q. Instead, the QRB2210 MPU acts as an internal SWD debug bridge running OpenOCD, accessed via ADB over USB.

Install ADB (Android Debug Bridge):

**macOS (Homebrew):**

```bash
brew install android-platform-tools
```

**Debian/Ubuntu:**

```bash
sudo apt-get install adb
```

Install ARM GDB for MCU debugging:

**macOS (Homebrew):**

```bash
brew install arm-none-eabi-gdb
```

Install the defmt log decoder for RTT log output:

```bash
cargo install defmt-print
```

Verify the board is detected via ADB:

```bash
adb devices
```

### Binary Analysis Tools (Optional)

```bash
# Binary size analysis — find what's eating your flash
cargo install cargo-bloat

# LLVM tools — objdump, size, nm, readobj, strip
cargo install cargo-binutils
rustup component add llvm-tools
```

## Building & Deploying

### Makefile Targets (Recommended)

The project includes a `Makefile` for the full build-deploy-run workflow:

```bash
# --- MPU (QRB2210) ---
make mpu-build       # Cross-compile for aarch64
make mpu-install     # Build + copy binary to the board via scp
make mpu-run         # Build + install + run on the board via ssh
make mpu-deploy      # Same as mpu-run (build + install + run)

# --- MCU (STM32U585) — requires ADB + OpenOCD ---
make mcu-build       # Build for Cortex-M33
make mcu-server      # Start OpenOCD on the board (run in its own terminal)
make mcu-forward     # Set up ADB port forwarding (one-time)
make mcu-flash       # Build + push + flash via OpenOCD
make mcu-run         # Build + flash + stream defmt RTT logs
make mcu-debug       # Build + launch GDB debug session
make mcu-log         # Stream RTT logs (after flashing)

# --- Utilities ---
make clean           # cargo clean
```

**Default device settings** (override via environment or command line).
`unoq1` is the hostname assigned to this specific board — yours will likely be different. Update the `DEVICE` variable in the `Makefile` or pass it on the command line:

| Variable      | Default              | Description              |
| ------------- | -------------------- | ------------------------ |
| `DEVICE`      | `unoq1.local`       | Board hostname or IP     |
| `DEVICE_USER` | `arduino`            | SSH user on the board    |
| `DEVICE_DIR`  | `/home/arduino/bin`  | Install directory        |

```bash
# Example: deploy to a different board
make mpu-run DEVICE=192.168.1.50 DEVICE_USER=root
```

### Cargo Aliases

For build-only operations without deployment:

```bash
cargo mcu-build    # Build MCU for STM32U585
cargo mpu-build    # Cross-compile MPU for QRB2210
```

### Manual Build Commands

```bash
# MCU — STM32U585 (Cortex-M33, bare-metal)
cargo build -p mcu --target thumbv8m.main-none-eabihf --release

# MPU — QRB2210 (Cortex-A53, Linux) — cross-compile
cargo build -p mpu --target aarch64-unknown-linux-gnu --release

# MPU — build for host (for local testing)
cargo build -p mpu
```

### Output Binaries

```
target/thumbv8m.main-none-eabihf/release/mcu      # MCU release
target/aarch64-unknown-linux-gnu/release/mpu       # MPU release
```

## Debugging

### MCU (STM32U585)

The MCU crate uses [defmt](https://defmt.ferrous-systems.com/) + RTT for structured, high-performance logging. Panics are captured by [panic-probe](https://crates.io/crates/panic-probe) with defmt output.

Flashing and debugging goes through the QRB2210's internal OpenOCD server, accessed via ADB over USB. This requires two terminals.

**Terminal 1 — Start the OpenOCD debug server (runs until stopped):**

```bash
make mcu-server
```

**Terminal 2 — Set up port forwarding (once per USB connection):**

```bash
make mcu-forward
```

**Terminal 2 — Build, flash, and stream RTT logs:**

```bash
make mcu-run
```

This will build the firmware, push it to the board via ADB, flash it through OpenOCD, and stream `defmt` log messages to your terminal.

**Flash only (no log streaming):**

```bash
make mcu-flash
```

**Stream RTT logs (after flashing):**

```bash
make mcu-log
```

**GDB debug session:**

```bash
make mcu-debug
```

This launches GDB connected to the OpenOCD server, loads the firmware, and resets the MCU.

### MPU (QRB2210)

The MPU crate uses [env_logger](https://docs.rs/env_logger/) for runtime-configurable structured logging.

**Build, deploy, and run on the board:**

```bash
make mpu-run
```

**Run locally (host build):**

```bash
RUST_LOG=info cargo run -p mpu
```

**Log level control** (on the board or locally):

```bash
RUST_LOG=debug ./mpu     # Show debug and above
RUST_LOG=mpu=trace       # Trace-level for the mpu crate only
RUST_LOG=warn            # Warnings and errors only
```

**Remote debugging on the board:**

On the QRB2210 (via SSH):

```bash
ssh arduino@unoq1.local 'gdbserver :1234 /home/arduino/bin/mpu'
```

On your development machine:

```bash
gdb-multiarch target/aarch64-unknown-linux-gnu/release/mpu
(gdb) target remote unoq1.local:1234
```

## Binary Size Analysis

```bash
# Show memory usage by section (Flash/RAM)
cargo size -p mcu --target thumbv8m.main-none-eabihf --release -- -A

# Find the largest functions and crates
cargo bloat -p mcu --target thumbv8m.main-none-eabihf --release

# Disassemble the binary
cargo objdump -p mcu --target thumbv8m.main-none-eabihf --release -- -d
```

## MCU Memory Map

The STM32U585 linker script (`mcu/memory.x`) defines:

| Region | Origin       | Size    | Usage                                 |
| ------ | ------------ | ------- | ------------------------------------- |
| FLASH  | `0x08000000` | 2048 KB | Program code and constants            |
| RAM    | `0x20000000` | 192 KB  | Stack, heap, static variables (SRAM1) |

Additional SRAM regions (SRAM2: 64 KB, SRAM3: 512 KB, SRAM4: 16 KB) can be added to `memory.x` as needed.

## License

See [LICENSE](LICENSE) for details.

