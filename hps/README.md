# LoanIO Implementation for MiSTer

This directory contains HPS (ARM) code for implementing loanIO functionality in MiSTer cores.

## Overview

LoanIO allows you to "loan" HPS-dedicated GPIO pins to the FPGA fabric for general-purpose use. This is useful for:
- Additional user interface elements (LEDs, buttons)
- Custom SPI/I2C interfaces implemented in FPGA  
- Analog board interfaces
- Extra GPIO for core-specific functionality

## Files

- **loan_gpio.h** - Header file with function declarations and register definitions
- **loan_gpio.c** - Implementation of GPIO loaning functions
- **README.md** - This documentation file

## Hardware Connections

The example uses GPIO pins 48-53 on the DE10-Nano:

```
GPIO 48 (Pin Y15)  -> USER_LED[0] -> LED 0
GPIO 49 (Pin Y16)  -> USER_LED[1] -> LED 1  
GPIO 50 (Pin AA15) -> USER_LED[2] -> LED 2
GPIO 51 (Pin AA16) -> USER_LED[3] -> LED 3
GPIO 52 (Pin AB15) -> USER_BTN[0] -> Button 0 (with pull-up)
GPIO 53 (Pin AB16) -> USER_BTN[1] -> Button 1 (with pull-up)
```

## Usage in MiSTer Core

1. **Include in your HPS code:**
```c
#include "loan_gpio.h"

int main() {
    // Initialize your core...
    
    // Loan GPIO pins to FPGA
    loan_gpio_to_fpga();
    
    // Your main loop...
    return 0;
}
```

2. **Compile with your core:**
```bash
gcc -o mycore mycore.c loan_gpio.c
```

3. **Run with root privileges:**
```bash
sudo ./mycore
```

## Functions

### `void loan_gpio_to_fpga(void)`
Loans GPIO pins 48-53 to the FPGA fabric. After calling this, the FPGA can control these pins via the USER_LED and USER_BTN signals.

### `void restore_gpio_to_hps(void)` 
Restores GPIO pins to HPS control. Usually not needed in MiSTer as pins are restored on reset.

### `void print_iomgr_status(void)`
Prints the current loan status of all GPIO pins. Useful for debugging.

### `void example_usage(void)`
Demonstrates complete usage flow. Call this function to see how loanIO works.

## FPGA Side

The FPGA side is implemented in:
- **sys/user_io.sv** - User interface module with LED/button control
- **sys/sys_top.v** - Integration with MiSTer system
- **mycore.qsf** - Pin assignments for loaned GPIO

## Demo Functionality

The example implements a simple LED pattern demo:
- **Button 0**: Rotate LED pattern left
- **Button 1**: Rotate LED pattern right  
- **LEDs**: Show different blink patterns (solid, slow blink, fast blink, inverted)

## Technical Details

### IOMGR Registers
- **Base Address**: 0xFFD05000
- **GENERALIO Register**: Base + 0x784
- **GPIO 48-53**: Bits 16-21 in GENERALIO register

### Memory Mapping
The code uses `/dev/mem` to access physical memory, so it requires root privileges. This is standard for bare-metal HPS access in MiSTer.

### Safety
- Loans are automatically restored on system reset
- Safe to call multiple times
- Non-destructive to other GPIO settings

## Notes

- Requires root privileges to access `/dev/mem`
- Pin mappings are specific to DE10-Nano
- Other Cyclone V boards may have different pin assignments
- Always verify pin availability before loaning
- Some HPS pins may be used by Linux and shouldn't be loaned