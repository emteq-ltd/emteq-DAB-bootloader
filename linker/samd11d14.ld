/*
modified from original (which can be found at https://github.com/ataradov/mcu-starter-projects):
+ formal stack declaration (rather than just use the end of RAM)
+ entry point of "Reset_Handler" instead of "irq_handler_reset"
+ used Rowley convention of section names (i.e. "data_load" instead of "etext")
+ BOOT_FLASH size reduced to 1kByte (since bootloader must fit in this)
*/

/*
 * Copyright (c) 2016, Alex Taradov <alex@taradov.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

 
OUTPUT_FORMAT("elf32-littlearm", "elf32-littlearm", "elf32-littlearm")
OUTPUT_ARCH(arm)
SEARCH_DIR(.)


ENTRY(Reset_Handler)

SECTIONS
{
    .hardwareData (NOLOAD) :
    {
        . = ALIGN(4);
		KEEP(*(.hardwareData)) ;
    } > HWDATA_FLASH
    
    .userPage (NOLOAD):
    {
        KEEP(*(.userPageReserved));   
        . = __length_UserPageReserved;
        KEEP(*(.factoryCalibrationData));
    } > USERPAGE_FLASH

  .text : ALIGN(4)
  {
    FILL(0xff)
    KEEP(*(.vectors))
    
    . = ALIGN(4);
    KEEP(*(.versionTag)) ;
    . = ALIGN(4);

    *(.text*)
    *(.rodata)
    *(.rodata.*)
    . = ALIGN(4);
  } > TARGET_FLASH

  . = ALIGN(4);
  __data_load_start__ = .;

  .uninit_RESERVED : ALIGN(4)
  {
    KEEP(*(.bss.$RESERVED*))
  } > RAM

  .data : ALIGN(4)
  {
    FILL(0xff)
    __data_start__ = .;
    *(.ramfunc .ramfunc.*);
    *(vtable)
    *(.data*)
    . = ALIGN(4);
    __data_end__ = .;
  } > RAM AT > TARGET_FLASH

  .bss : ALIGN(4)
  {
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end__ = .;
    PROVIDE(_end = .);
  } > RAM
  
    
	/* .stack_dummy section doesn't contains any symbols. It is only
	 * used for linker to calculate size of stack sections, and assign
	 * values to stack symbols later */
	.stack_dummy (COPY):
	{
		*(.stack*)
	} > RAM
    
	/* Set stack top to end of RAM, and stack limit move down by
	 * size of stack_dummy section */
	__stack_end__ = __end_RAM - SIZEOF(.resetMagic);
	__stack_start__ = __stack_end__ - SIZEOF(.stack_dummy) - SIZEOF(.resetMagic);
	PROVIDE(__stack = __stack_end__);  

    /** We place resetMagic at the very end of memory i.e. Before the stack
    */
    __RAM_reset_magic__ = __end_RAM - 4;
    .resetMagic __RAM_reset_magic__ (NOLOAD) :
    {
        . = ALIGN(4);
        KEEP(*(.resetMagic)) ;
    } > RAM

	__ram_end__ = __end_RAM;
}


ASSERT( __origin_CALDATA_FLASH == 0x804020, "Factory Calibration Data address moved" )
ASSERT( ORIGIN(HWDATA_FLASH) == 0x1FC0, "Hardware Data address moved" )
ASSERT( ORIGIN(APP_FLASH) == __APP_OFFSET__, "App-Image address moved" )