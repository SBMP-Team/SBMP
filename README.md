# SBMP
SBMP (Sixteen Bit Micro Processor) is a simple, 16-bit microprocessor architecture designed for educational purposes. It features a straightforward instruction set and is ideal for learning about computer architecture, assembly language programming, and low-level system design. SBMP is currently in early development by two friends from across the globe. Future plans include a working chipset, custom software to write/draw for the language and running DOOM on the chipset, because ofcourse it has to run doom. This is currently made for windows with linux support in the future (after we have written doom hopefully)

Detailed documentation about the ISA can be found in the [isa.txt](isa.txt) file.

## Features
- 16-bit architecture
- Simple instruction set, with 42 instructions that pretty much explain themselves
- 3 general-purpose, 16 bit registers (A, B, C)
- 2 general purpose, 8 bit registers (X, Y)
- Branching and conditional execution
- Basic arithmetic and logic operations
- Memory access and manipulation
- Input/Output operations
- Sound
- Graphics

## Writing a Program

Writing a program for SBMP is fairly simple, as long as you are familiar with assembly language concepts and low level programming. By default, the emulator will print out the last value in register 0x0000 when the program halts, this can be used as an output if needed.
To start, download or build the editor, compiler, linker and emulator.
Open the editor and make a new file. Here is where you will write your assembly.
Here is a simple example program that adds two numbers and stores the result in memory:
```assembly
	Start:  :: a doubble colon is a comment
	  LDA $#0x0005   :: Load the value 5 into register A, $# indicates a raw value, not a memory address
	  LDB $#0x0003   :: Load the value 3 into register B
	  ADA $b         :: Add the value in register B to register A, $ indicates a register or a memory address
	  STA $0x0011    :: Store the result from register A into memory address 0x0011
	  RST Start:     :: Reset the program pointer to the start label and hault. this ensures that on next execution, the program will start from the beginning.
	   
```

Save the file with the editor, we will save it as `add.asm`.
Next, open a terminal and navigate to the directory where you saved `add.asm`. Run the following commands to compile, link, and run the program:
```bash
	sbmpc.exe -i add.asm -o add.o
	sbmpl.exe -i add.o -o add.smb
	sbmpe.exe -f add.smb
```

if everything went well, the emulator should give the following output:
```
	Starting program execution...
	Loaded instruction LDA with args $#0x0005 into memory at 0x1f6 and 0x1f7
	Loaded instruction LDB with args $#0x0003 into memory at 0x1f8 and 0x1f9
	Loaded instruction ADA with args $B into memory at 0x1fa and 0x1fb
	Loaded instruction STA with args $0x0011 into memory at 0x1fc and 0x1fd
	Loaded instruction RST with args  into memory at 0x1fe and 0x1ff
	Value of 0x0011 was 0x8. Program took 0.002S to run.
```
