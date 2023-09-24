OUTPUT_ARCH( "riscv" );
ENTRY( _start );
PROVIDE(_heap_size = 0);

MEMORY {
    FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 128k
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH  = 32k
}

/* Large parts copied from here temporarily: https://github.com/rust-embedded/riscv-rt/blob/master/link.x */

SECTIONS {
    .text : {
        /* Put reset handler first in .text section so it ends up as the entry */
        /* point of the program. */
        KEEP(*(.init));
        KEEP(*(.init.rust));
        . = ALIGN(4);
        *(.trap);
        *(.trap.rust);
        *(.text.abort);
        *(.text .text.*);
    } > FLASH

    .rodata : ALIGN(4) {
        *(.srodata .srodata.*);
        *(.rodata .rodata.*);

        /* 4-byte align the end (VMA) of this section.
        This is required by LLD to ensure the LMA of the following .data
        section will have the correct alignment. */
        . = ALIGN(4);
    } > FLASH

    .data : ALIGN(4) {
        _data_start_flash = LOADADDR(.data);
        _data_start_ram = .;
        /* Must be called __global_pointer$ for linker relaxations to work. */
        PROVIDE(__global_pointer$ = . + 0x800);
        *(.sdata .sdata.* .sdata2 .sdata2.*);
        *(.data .data.*);
        . = ALIGN(4);
        _data_end_ram = .;
    } > RAM AT>FLASH

    .bss (NOLOAD) : {
        _bss_start_ram = .;
        *(.sbss .sbss.* .bss .bss.*);
        . = ALIGN(4);
        _bss_end_ram = .;
    } > RAM

    .stack (NOLOAD) : {
        _stack_start_ram = .;
        . += LENGTH(RAM) - (SIZEOF(.data) + SIZEOF(.bss));
        . = ALIGN(4);
        _stack_end_ram = .;
    } > RAM

}
