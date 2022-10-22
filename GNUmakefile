all: elf.bin hash

elf.bin: elf.asm
	touch OS.asm
	echo "OS equ \"Linux\"" > OS.asm
	fasm elf.asm
	chmod +x elf.bin
hash: hash.c
	cc hash.c -o hash
clean:
	@rm elf.bin hash OS.asm
