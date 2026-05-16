CC = gcc
CFLAGS = -Wall -Wextra -std=c11

SRC_DIR = src
BUILD_DIR = build

ifeq ($(OS),Windows_NT)
    EMULATOR = $(BUILD_DIR)/sbmpe.exe
    COMPILER = $(BUILD_DIR)/sbmpc.exe
    LINKER   = $(BUILD_DIR)/sbmpl.exe
    RM = del /Q /S
else
    EMULATOR = $(BUILD_DIR)/sbmpe
    COMPILER = $(BUILD_DIR)/sbmpc
    LINKER   = $(BUILD_DIR)/sbmpl
    RM = rm -f
endif

all: $(BUILD_DIR) $(EMULATOR) $(COMPILER) $(LINKER) rm_objects

emulator: $(BUILD_DIR) $(EMULATOR) rm_objects

linker: $(BUILD_DIR) $(LINKER) rm_objects

compiler: $(BUILD_DIR) $(COMPILER) rm_objects

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(EMULATOR): $(BUILD_DIR)/emulator.o $(BUILD_DIR)/lookup.o
	$(CC) $(CFLAGS) -o $@ $^

$(COMPILER): $(BUILD_DIR)/compiler.o $(BUILD_DIR)/lookup.o
	$(CC) $(CFLAGS) -o $@ $^

$(LINKER): $(BUILD_DIR)/linker.o $(BUILD_DIR)/lookup.o
	$(CC) $(CFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(BUILD_DIR)/*.o $(EMULATOR) $(COMPILER) $(LINKER)

rm_objects:
	$(RM) $(BUILD_DIR)/*.o