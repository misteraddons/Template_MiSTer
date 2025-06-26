//============================================================================
// GPIO LoanIO Header - Function declarations for loaning HPS GPIO to FPGA
// For MiSTer cores demonstrating loanIO functionality
//============================================================================

#ifndef LOAN_GPIO_H
#define LOAN_GPIO_H

#include <stdint.h>

// IOMGR register addresses for Cyclone V HPS
#define IOMGR_BASE          0xFFD05000
#define IOMGR_GENERALIO     (IOMGR_BASE + 0x784)

// GPIO pin definitions (HPS pins we want to loan to FPGA)
// These correspond to GPIO 48-53 on DE10-Nano
#define GPIO_LOAN_MASK      0x3F0000  // Bits 16-21 (GPIO 48-53)

// Function declarations
void loan_gpio_to_fpga(void);
void restore_gpio_to_hps(void);
void print_iomgr_status(void);

#endif // LOAN_GPIO_H