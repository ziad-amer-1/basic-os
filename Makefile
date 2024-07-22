ASM=nasm

SRC_DIR=src
BUILD_DIR=build

# Target to create the floppy image from the binary
$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

# Target to create the binary from source files
$(BUILD_DIR)/main.bin: $(SRC_DIR)/bootloader.asm
	mkdir -p $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/bootloader.asm -f bin -o $(BUILD_DIR)/main.bin

# Clean up build artifacts
clean:
	rm -r $(BUILD_DIR)

# Phony target to prevent conflicts with file names
.PHONY: clean
