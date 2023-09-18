OUTPUT_ARCH( "riscv" )

ENTRY( _start )

MEMORY {
    flash (rx) : ORIGIN = 0x00000000, LENGTH = 128k
    ram (rwx) : ORIGIN = 0x20000000, LENGTH  = 32k
}

SECTIONS {
    .init: {}
    .vector: {}
    .data: {}
    .bss: {}
}
