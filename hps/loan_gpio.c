//============================================================================
// GPIO LoanIO Implementation - Loans HPS GPIO pins to FPGA fabric
// For MiSTer cores demonstrating loanIO functionality
//============================================================================

#include "loan_gpio.h"
#include <stdio.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>

// Global variables for memory mapping
static int mem_fd = -1;
static void *iomgr_map = NULL;
static volatile uint32_t *generalio_reg = NULL;

// Initialize memory mapping to IOMGR registers
static int init_iomgr_mapping(void) {
    if (mem_fd >= 0) return 0; // Already initialized
    
    // Open /dev/mem to access physical memory
    mem_fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (mem_fd < 0) {
        printf("Error: Cannot open /dev/mem (need root privileges)\n");
        return -1;
    }
    
    // Map IOMGR registers
    iomgr_map = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE, 
                     MAP_SHARED, mem_fd, IOMGR_BASE);
    if (iomgr_map == MAP_FAILED) {
        printf("Error: Cannot map IOMGR registers\n");
        close(mem_fd);
        mem_fd = -1;
        return -1;
    }
    
    // Access GENERALIO register
    generalio_reg = (volatile uint32_t*)((char*)iomgr_map + 0x784);
    
    return 0;
}

// Clean up memory mapping
static void cleanup_iomgr_mapping(void) {
    if (iomgr_map) {
        munmap(iomgr_map, 0x1000);
        iomgr_map = NULL;
        generalio_reg = NULL;
    }
    if (mem_fd >= 0) {
        close(mem_fd);
        mem_fd = -1;
    }
}

// Loan GPIO pins 48-53 to FPGA
void loan_gpio_to_fpga(void) {
    if (init_iomgr_mapping() < 0) return;
    
    // Read current value and set loan bits
    uint32_t current = *generalio_reg;
    uint32_t new_value = current | GPIO_LOAN_MASK;
    *generalio_reg = new_value;
    
    printf("LoanIO: Loaned GPIO pins 48-53 to FPGA\n");
    printf("GENERALIO register: 0x%08X -> 0x%08X\n", current, new_value);
    printf("Loaned pins can now be controlled by FPGA logic\n");
}

// Restore GPIO pins to HPS control
void restore_gpio_to_hps(void) {
    if (init_iomgr_mapping() < 0) return;
    
    // Read current value and clear loan bits
    uint32_t current = *generalio_reg;
    uint32_t new_value = current & ~GPIO_LOAN_MASK;
    *generalio_reg = new_value;
    
    printf("LoanIO: Restored GPIO pins 48-53 to HPS control\n");
    printf("GENERALIO register: 0x%08X -> 0x%08X\n", current, new_value);
}

// Print current IOMGR status
void print_iomgr_status(void) {
    if (init_iomgr_mapping() < 0) return;
    
    uint32_t current = *generalio_reg;
    printf("IOMGR GENERALIO Status: 0x%08X\n", current);
    printf("GPIO Loan Status:\n");
    
    for (int i = 48; i <= 53; i++) {
        int bit = i - 32;  // GPIO 48 = bit 16, etc.
        int loaned = (current >> bit) & 1;
        printf("  GPIO %d: %s\n", i, loaned ? "LOANED to FPGA" : "HPS control");
    }
    
    cleanup_iomgr_mapping();
}

// Example usage function (for reference)
void example_usage(void) {
    printf("=== LoanIO Example Usage ===\n");
    
    // Show initial status
    printf("\n1. Initial GPIO status:\n");
    print_iomgr_status();
    
    // Loan GPIO to FPGA
    printf("\n2. Loaning GPIO to FPGA:\n");
    loan_gpio_to_fpga();
    
    // Show loaned status
    printf("\n3. GPIO status after loaning:\n");
    print_iomgr_status();
    
    printf("\n4. FPGA can now control these pins via USER_LED and USER_BTN signals\n");
    printf("   Connect LEDs to GPIO 48-51 and buttons to GPIO 52-53\n");
    printf("   Use buttons to rotate LED patterns!\n");
    
    // Optionally restore (usually not needed in MiSTer)
    // printf("\n5. Restoring GPIO to HPS:\n");
    // restore_gpio_to_hps();
    
    cleanup_iomgr_mapping();
}