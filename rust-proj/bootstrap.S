// Register init section 
.section .init, "ax", @progbits

// Export _start label
.global	_start
// Align to single byte
.align 1
_start:
    .option push
    .option norelax
    la gp, __global_pointer$ // Load the global pointer address to the gp register
    .option pop

    // TODO: Do we need to zero-out registers?

    // Initialize stack pointer to correct location
    // Interestingly the rust-embedded groups minimal 
    // riscv-rt calculates stack_end at runtime using 
    // stack_start & stack_size, since we are using a 
    // mcu with fixed memory size I dont see a reason 
    // to do that here
    la sp, _stack_end_ram 

    // Load all data from flash into ram
    la a0, _data_start_flash
    la a1, _data_start_ram
    la a2, _data_end_ram

    1: // Loop through each word of data to load the entire data chunk from flash to ram
        // a0 - flash address start
        // a1 - flash address end
        // a2 - RAM address start
        lw t0, (a0)
        sw t0, (a1)
        addi a0, a0, 4
        addi a1, a1, 4
        bltu a1, a2, 1b

    // Clear bss to mimic C runtime
    la a0, _bss_start_ram
    la a1, _bss_end_ram

    1: // Loop through every word of bss to zero out a section of memory
        // a0 - address start
        // a1 - address end
        sw zero, (a0)
        addi a0, a0, 4
        bltu a0, a1, 1b

    /*
     * WCH Custom CSR's
     * 
     * WCH define several vendor specific CSR's for the QingKeV4 series of chips:
     * 
     * | CSR Register | Address | Description                                                                                 |
     * |--------------|---------|---------------------------------------------------------------------------------------------|
     * | gintenr      | 0x800   |                                                                                             |
     * | intsyscr     | 0x804   | Interrupt configuration, changes how interrupts are processed by the processor              |
     * | corecfgr     | 0xBC0   | Processor pipeline configuration, used to configure branch prediction and simmilar features |
     * 
     */

    // Configure processor pipeline
    // Set corecfgr to 0x1f (magic value provided by WCH)
    li t0, 0x1f
    csrw 0xbc0, t0
    // TODO: can replace with csrwi 0xbc0, 0x1f?

    // Configure interrupt system
    // Set intsyscr to 0x0b (value provided in the WCH bootstrap)
    // 0x0b sets the following configuration:
    // - HWSTKOVEN [1]: Keep interrupts enabled after a HPE overflow
    // - PMTCFG   [10]: Allow 4 levels of interrupt nesting with 2 preemption bits
    // - INESTEN   [1]: Enable interrupt nesting
    // - HWSTKEN   [1]: Enable HPE (Hardware Prologue/Epilogue)
    li t0, 0x0b // load 0x0b to t0 (temporary register 0x5)
    csrw 0x804, t0 // write t0 to 0x804 (csrrw x0, 0x804, t0)
    // TODO: can replace with csrwi 0x804, 0x0b?

    // Configure mstatus
    // Set mstatus to 0x6088 (value provided in the WCH bootstrap)
    // 0x6088 sets the following configuration:
    // - FS  [11]: Enable floating point support by setting FS to dirty, I believe this is because this implmentation does not track dirty state
    // - MPIE [1]
    // - MIE  [1] 
    li t0, 0x6088           
    csrs mstatus, t0

    # // TODO: Load exception vector table
    # la t0, _vectors
    # // The bottom 2 bits of the vector address are ignored,
    # // they are used for MODE0 & MODE1 bits
    # ori t0, t0, 0b11
    # csrw mtvec, t0

    // Switch to user mode and run main function
    la t0, entry_point // Load main function address
    csrw mepc, t0 // Write address to mepc
    mret // This will switch from M-mode to U-mode and jump to the address stored in mepc as dictated by MPP set in mstatus
