# "unoq1" is the hostname assigned to this specific board.
# Change this to match your device's hostname or IP address.
DEVICE     ?= unoq1.local
DEVICE_USER ?= arduino
DEVICE_DIR  ?= /home/arduino/bin

MPU_TARGET  = aarch64-unknown-linux-gnu
MCU_TARGET  = thumbv8m.main-none-eabihf
MCU_ELF     = target/$(MCU_TARGET)/release/mcu

# --- MPU (QRB2210) ---

mpu-build:
	cargo build -p mpu --target $(MPU_TARGET) --release

mpu-install: mpu-build
	scp target/$(MPU_TARGET)/release/mpu $(DEVICE_USER)@$(DEVICE):$(DEVICE_DIR)/mpu

mpu-run: 
	ssh $(DEVICE_USER)@$(DEVICE) 'RUST_LOG=info $(DEVICE_DIR)/mpu'

mpu-deploy: mpu-install mpu-run

# --- MCU (STM32U585) ---
# The STM32U585 SWD pins are not externally exposed. The QRB2210 acts as
# an internal SWD debug bridge running OpenOCD, accessed via ADB over USB.
#
# Workflow:
#   1. make mcu-server   (Terminal 1 — starts OpenOCD, blocks)
#   2. make mcu-forward  (Terminal 2 — one-time port forwarding setup)
#   3. make mcu-flash    (Terminal 2 — build + push + flash)

mcu-build:
	cargo build -p mcu --target $(MCU_TARGET) --release

mcu-forward:
	adb forward tcp:3333 tcp:3333
	adb forward tcp:4444 tcp:4444
	adb forward tcp:9090 tcp:9090

mcu-server:
	adb shell arduino-debug --forward-rtt

mcu-flash: mcu-build
	adb push $(MCU_ELF) /tmp/mcu.elf
	@echo "Flashing MCU via OpenOCD..."
	(echo "init; reset halt; flash write_image erase /tmp/mcu.elf; verify_image /tmp/mcu.elf; arm semihosting enable; reset run"; sleep 1) | nc localhost 4444
	@echo "Firmware flashed. Semihosting output appears in the mcu-server terminal."

mcu-debug: mcu-build
	arm-none-eabi-gdb $(MCU_ELF) \
		-ex "target remote localhost:3333" \
		-ex "monitor reset halt" \
		-ex "load" \
		-ex "monitor reset run"

mcu-log:
	@echo "Semihosting output appears in the mcu-server terminal."

# --- Utilities ---

clean:
	cargo clean

.PHONY: mpu-build mpu-install mpu-run mpu-deploy \
        mcu-build mcu-forward mcu-server mcu-flash mcu-run mcu-debug mcu-log \
        clean
