format binary
use64

include "OS.asm"

ELFCLASS64 equ 2
ELFDATA2LSB equ 1
EV_CURRENT equ 1
ELFOSABI_LINUX equ 3
ELFOSABI_FREEBSD equ 9
ET_REL equ 1
ET_EXEC equ 2
ET_DYN equ 3
EM_AMD64 equ 62

PT_NULL equ 0
PT_LOAD equ 1
PT_DYNAMIC equ 2
PT_INTERP equ 3
PT_NOTE equ 4
PT_SHLIB equ 5
PT_PHDR equ 6
PT_TLS equ 7
PT_LOOS equ 0x60000000
PT_SUNW_UNWIND equ 0x6464e550
PT_GNU_EH_FRAME equ 0x6474e550
PT_GNU_STACK equ 0x6474e551
PT_GNU_RELRO equ 0x6474e552
PT_DUMP_DELTA equ 0x6fb5d000

PF_R equ 0x4
PF_W equ 0x2
PF_X equ 0x1

SHT_NULL equ 0
SHT_PROGBITS equ 1
SHT_SYMTAB equ 2
SHT_STRTAB equ 3
SHT_RELA equ 4
;SHT_HASH equ 5
SHT_DYNAMIC equ 6
;SHT_NOTE equ 7
SHT_NOBITS equ 8
;SHT_REL equ 9
;SHT_SHLIB equ 10
SHT_DYNSYM equ 11
SHT_GNU_HASH equ 0x6ffffff6

SHF_WRITE equ 0x1
SHF_ALLOC equ 0x2
SHF_EXECINSTR equ 0x4
;SHF_MERGE equ 0x10
SHF_STRINGS equ 0x20

STT_OBJECT = 0x1
STT_FUNC = 0x2
STB_LOCAL = 0x0
STB_GLOBAL = 0x1

DT_NULL = 0
DT_NEEDED = 1
DT_PLTRELSZ = 2
DT_PLTGOT = 3
DT_HASH = 4
DT_STRTAB = 5
DT_SYMTAB = 6
DT_RELA = 7
DT_RELASZ = 8
DT_RELAENT = 9
DT_STRSZ = 10
DT_SYMENT = 11
DT_INIT = 12
DT_FINI = 13
DT_SONAME = 14
DT_RPATH = 15
DT_SYMBOLIC = 16
DT_REL = 17
DT_RELSZ = 18
DT_RELENT = 19
DT_PLTREL = 20
DT_DEBUG = 21
DT_TEXTREL = 22
DT_JMPREL = 23
DT_BIND_NOW = 24
DT_INIT_ARRAY = 25
DT_FINI_ARRAY = 26
DT_INIT_ARRAYSZ = 27
DT_FINI_ARRAYSZ = 28
DT_RUNPATH = 29
DT_FLAGS = 30
DT_ENCODING = 32
DT_PREINIT_ARRAY = 32
DT_PREINIT_ARRAYSZ = 33
DT_MAXPOSTAGS = 34
DT_GNU_HASH = 0x6ffffef5

R_X86_64_JMP_SLOT = 7

SIZEOF_PROGRAM_HEADER = 56
SIZEOF_SECTION_HEADER = 64

macro BEGIN_PROGRAM_HEADERS
{
  CPROGRAM_HEADER = 0
}

macro PROGRAM_HEADER type,permissions,offset,virtual_address,\
                     physical_address,disk_size,mem_size,alignment
{
  ; Segment type - common types are PT_NULL = 0; PT_LOAD = 1;
  ; PT_DYNAMIC = 2; PT_INTERP = 3; PT_PHDR = 6.
  dd type
  ; Permissions - readable/writable/executable: an ORed combination
  ; of values from PF_R = 0x4; PF_W = 0x2; PF_X = 0x1.
  dd permissions
  dq offset ; Offset in file.
  dq virtual_address ; Offset at runtime.
  dq physical_address ; Unused; set to 0.
  dq disk_size
  dq mem_size
  dq alignment
  ; The following variable lets us count program headers as
  ; we declare them.
  CPROGRAM_HEADER = CPROGRAM_HEADER + 1
}

macro END_PROGRAM_HEADERS
{
  NUM_PROGRAM_HEADERS = CPROGRAM_HEADER
}

macro BEGIN_SECTION_HEADERS
{
  CSECTION_HEADER = 0
}

macro SECTION_HEADER name,name_string,type,flags,virtual_address,offset,size,link,info,alignment,entry_size
{
  dd name_string ; An index into .shstrtab giving this sections's name.

  ; Type - we will make use of the following section types:
  ; SHT_NULL = 0 ; initial null section
  ; SHT_PROGBITS = 1 ; .interp, .text, .plt, .data, .got.plt
  ; SHT_SYMTAB = 2, ; .symtab
  ; SHT_STRTAB = 3, ; .dynstr, .strtab, .shstrtab
  ; SHT_RELA = 4, ; .rela.plt
  ; SHT_DYNAMIC = 6, ; .dynamic
  ; SHT_NOBITS = 8, ; .bss
  ; SHT_DYNSYM = 11, ; .dynsym
  ; SHT_GNU_HASH = 0x6ffffff6 ; .gnu.hash
  dd type
  ; Flags - a combination of values from SHF_WRITE = 0x1,
  ; SHF_ALLOC = 0x2, SHF_EXECINSTR = 0x4 and SHF_STRINGS = 0x20.
  dq flags
  dq virtual_address ; Offset at runtime.
  dq offset ; Offset in file/
  dq size
  dd link ; The index of some other, related, section.
  dd info ; Usually 0 but can indicate another related section.
  dq alignment
  ; Entry size - for sections that contain a list of similarly-
  ; sized items, this gives the size. Otherwise 0.
  dq entry_size
  ; Link - so that we can refer to this section by its name.
  LINK_#name = CSECTION_HEADER
  ; The following variable lets us count section headers as
  ; we declare them .
  CSECTION_HEADER = CSECTION_HEADER + 1
}

macro END_SECTION_HEADERS
{
  NUM_SECTION_HEADERS = CSECTION_HEADER
}

macro STRING_TABLE
{
  STRCOFF = 1
  db 0
}

macro STRING id,value
{
  local s
  id = STRCOFF
  s db value,0
  STRCOFF = STRCOFF + ($ - s)
}

macro BEGIN_SYMBOLS
{
  CSYMBOL = 0
}

macro SYMBOL name,bind,type,other,index,value,size
{
  dd name
  db (bind shl 4) + (type and 0xf)
  db other
  dw index
  dq value
  dq size
  name#_index = CSYMBOL
  CSYMBOL = CSYMBOL + 1
}

macro EXPORT_OBJECT name,index,value
{
  dd name
  ; The symbol's visibility and type encoded in a byte:
  db (STB_GLOBAL shl 4) + (STT_OBJECT and 0xf)
  db 0 ; The "other" field is unused.
  dw index ; Section where our symbol resides.
  dq value ; Virtual address of symbol.
  dq 8 ; Symbol size.
  name#_index = CSYMBOL
  CSYMBOL = CSYMBOL + 1
}

macro IMPORT_FUNCTION name
{
  dd name
  db (STB_GLOBAL shl 4) + (STT_FUNC and 0xf) ; Scope and type.
  ; We're not providing any more information for this symbol
  ; as it is defined in another ELF object.
  db 0
  dw 0
  dq 0
  dq 0
  name#_index = CSYMBOL
  CSYMBOL = CSYMBOL + 1
}

macro EXPORT_FUNCTION name,index,value
{
  dd name
  ; The symbol's visibility and type encoded in a byte:
  db (STB_GLOBAL shl 4) + (STT_FUNC and 0xf)
  db 0 ; The "other" field is unused.
  dw index ; Section where our symbol resides.
  dq value ; Virtual address of symbol.
  dq 8 ; Symbol size.
  name#_index = CSYMBOL
  CSYMBOL = CSYMBOL + 1
}

macro NULL_SYMBOL
{
  rept 24 \{db 0\}
  CSYMBOL = CSYMBOL + 1
}

macro RELOCATION symbol_name,plane
{
  ; The address of the qword the linker must fill in:
  dq LOAD_BASE + plane + symbol_name#@got
  ; Symbol index and type, encoded in a single qword:
  dq (symbol_name#_index shl 32) or R_X86_64_JMP_SLOT
  dq 0 ; No addend.
}

macro BEGIN_PLT_LINKAGE
{
  CPLT = 0
}

macro PLT_LINKAGE symbol_name,plane
{
  symbol_name#@plt: ; Evaluates to puts@plt, exit@plt, etc.
  jmp qword [plane + symbol_name#@got] ; Likewise puts@got, etc.
  symbol_name#@plt2: ; Unresolved symbols cause a JMP to here.
  push CPLT ; Current symbol index.
  jmp stitchup
  CPLT = CPLT + 1
}

macro GOT_ENTRY symbol_name,plane
{
  symbol_name#@got: ; Evaluates to puts@got, etc.
  ; Placeholder until symbol resolution:
  dq LOAD_BASE + plane + symbol_name#@plt2
}

LOAD_BASE = 0x200000
PLANE1 = 0x1000
PLANE2 = 0x2000
PLANE3 = 0x3000

db 0x7f,"ELF" ; Magic.
db ELFCLASS64 ; Class (32- or 64-bit).
db ELFDATA2LSB ; Endian-ness (least significant bytes first).
db EV_CURRENT ; Version of the ELF spec.
; ABI (Application Binary Interface) -  we use
; ELFOSABI_LINUX = 3 or ELFOSABI_FREEBSD = 9
if OS eq "Linux"
  db ELFOSABI_LINUX
else if OS eq "FreeBSD"
  db ELFOSABI_FREEBSD
end if
db 0 ; ABI version (always 0).
rept 7 {db 0} ; Padding.
; Executable type (2) could also be ET_REL = 1 for
; a relocatable object or ET_DYN = 3 for a shared library.
dw ET_EXEC
dw EM_AMD64 ; Machine is x86-64.
dd EV_CURRENT ; File version (always set to EV_CURRENT = 1).
dq LOAD_BASE + PLANE1 + main ; Entry point.
dq PROGRAM_HEADERS ; Program headers offset.
dq SECTION_HEADERS ; Section headers offset.
dd 0 ; Flags (always 0).
dw ELF_HEADER_SIZE ; Size of this ELF header.
dw SIZEOF_PROGRAM_HEADER ; Size of one program header (56 bytes).
dw NUM_PROGRAM_HEADERS
dw SIZEOF_SECTION_HEADER ; Size of one section header (64 bytes).
dw NUM_SECTION_HEADERS
; This is the section header table index of the entry associated
; with the section name string table.
dw SHSTRTAB_INDEX
ELF_HEADER_SIZE = $

PROGRAM_HEADERS:

BEGIN_PROGRAM_HEADERS

PROGRAM_HEADER PT_PHDR,PF_R,PROGRAM_HEADERS,LOAD_BASE + ELF_HEADER_SIZE,0,PROGRAM_HEADERS_SIZE,PROGRAM_HEADERS_SIZE,0x8
PROGRAM_HEADER PT_INTERP,PF_R,SECTION_INTERP,LOAD_BASE + SECTION_INTERP,0,INTERP_SIZE,INTERP_SIZE,0x1
PROGRAM_HEADER PT_LOAD,PF_R,0,LOAD_BASE,0,SECTION_TEXT,SECTION_TEXT,0x1000
PROGRAM_HEADER PT_LOAD,PF_R or PF_X,SECTION_TEXT,LOAD_BASE + PLANE1 + SECTION_TEXT,0,TEXT_PLUS_PLT_SIZE,TEXT_PLUS_PLT_SIZE,0x1000
PROGRAM_HEADER PT_LOAD,PF_R or PF_W,SECTION_DATA,LOAD_BASE + PLANE2 + SECTION_DATA,0,DATA_PLUS_GOT_PLT_PLUS_BSS_SIZE,DATA_PLUS_GOT_PLT_PLUS_BSS_SIZE,0x1000
PROGRAM_HEADER PT_LOAD,PF_R or PF_W,SECTION_DYNAMIC,LOAD_BASE + PLANE3 + SECTION_DYNAMIC,0,DYNAMIC_SIZE,DYNAMIC_SIZE,0x1000
PROGRAM_HEADER PT_DYNAMIC,PF_R or PF_W,SECTION_DYNAMIC,LOAD_BASE + PLANE3 + SECTION_DYNAMIC,0,DYNAMIC_SIZE,DYNAMIC_SIZE,0x8

PROGRAM_HEADERS_SIZE = $ - PROGRAM_HEADERS

END_PROGRAM_HEADERS

SECTION_HEADERS:

BEGIN_SECTION_HEADERS

SECTION_HEADER NULL,SHSTRTAB.S0,SHT_NULL,0,0,0,0,0,0,0,0

SECTION_HEADER INTERP,SHSTRTAB.S1,SHT_PROGBITS,SHF_ALLOC,LOAD_BASE + SECTION_INTERP,SECTION_INTERP,INTERP_SIZE,0,0,0x1,0x0

SECTION_HEADER GNU_HASH,SHSTRTAB.S2,SHT_GNU_HASH,SHF_ALLOC,LOAD_BASE + SECTION_GNU_HASH,SECTION_GNU_HASH,GNU_HASH_SIZE,LINK_DYNSYM,0,0x8,0x0

SECTION_HEADER DYNSYM,SHSTRTAB.S3,SHT_DYNSYM,SHF_ALLOC,LOAD_BASE + SECTION_DYNSYM,SECTION_DYNSYM,DYNSYM_SIZE,LINK_DYNSTR,1,0x8,0x18

SECTION_HEADER DYNSTR,SHSTRTAB.S4,SHT_STRTAB,SHF_ALLOC or SHF_STRINGS,LOAD_BASE + SECTION_DYNSTR,SECTION_DYNSTR,DYNSTR_SIZE,0,0,0x1,0x0

SECTION_HEADER RELA_PLT,SHSTRTAB.S5,SHT_RELA,SHF_ALLOC,LOAD_BASE + SECTION_RELA_PLT,SECTION_RELA_PLT,RELA_PLT_SIZE,LINK_DYNSYM,LINK_GOT_PLT,0x8,0x18

SECTION_HEADER TEXT,SHSTRTAB.S6,SHT_PROGBITS,SHF_ALLOC or SHF_EXECINSTR,LOAD_BASE + PLANE1 + SECTION_TEXT,SECTION_TEXT,TEXT_SIZE,0,0,0x10,0x0

SECTION_HEADER PLT,SHSTRTAB.S7,SHT_PROGBITS,SHF_ALLOC or SHF_EXECINSTR,LOAD_BASE + PLANE1 + SECTION_PLT,SECTION_PLT,PLT_SIZE,0,0,0x10,0x0

SECTION_HEADER DATA,SHSTRTAB.S8,SHT_PROGBITS,SHF_ALLOC or SHF_WRITE,LOAD_BASE + PLANE2 + SECTION_DATA,SECTION_DATA,DATA_SIZE,0,0,0x8,0x0

SECTION_HEADER GOT_PLT,SHSTRTAB.S9,SHT_PROGBITS,SHF_ALLOC or SHF_WRITE,LOAD_BASE + PLANE2 + SECTION_GOT_PLT,SECTION_GOT_PLT,GOT_PLT_SIZE,0,0,0x8,0x0

SECTION_HEADER BSS,SHSTRTAB.S10,SHT_NOBITS,SHF_ALLOC or SHF_WRITE,LOAD_BASE + PLANE2 + SECTION_BSS,SECTION_BSS,BSS_SIZE,0,0,0x8,0x0

SECTION_HEADER DYNAMIC,SHSTRTAB.S11,SHT_DYNAMIC,SHF_ALLOC or SHF_WRITE,LOAD_BASE + PLANE3 + SECTION_DYNAMIC,SECTION_DYNAMIC,DYNAMIC_SIZE,LINK_DYNSTR,0,0x8,0x10

SECTION_HEADER SYMTAB,SHSTRTAB.S12,SHT_SYMTAB,0,0,SECTION_SYMTAB,SYMTAB_SIZE,LINK_STRTAB,0,0x8,0x18

SECTION_HEADER STRTAB,SHSTRTAB.S13,SHT_STRTAB,SHF_ALLOC,0,SECTION_STRTAB,STRTAB_SIZE,0,0,0x10,0x0

SECTION_HEADER SHSTRTAB,SHSTRTAB.S14,SHT_STRTAB,0,0,SECTION_SHSTRTAB,SHSTRTAB_SIZE,0,0,0x10,0x0

END_SECTION_HEADERS

SECTION_INTERP:

if OS eq "Linux"
  db "/lib64/ld-linux-x86-64.so.2",0
else if OS eq "FreeBSD"
  db "/libexec/ld-elf.so.1",0
end if

INTERP_SIZE = $ - SECTION_INTERP

align 0x8
SECTION_GNU_HASH:

dd 1 ; Number of buckets.
dd 1 ; Index of the first symbol from .dynsym to be included in the hash table.
dd 1 ; Number of maskwords.
dd 6 ; Shift.
dq 0xffffffffffffffff ; Bloom filter.
dd 1

dd 0x7c9c7b10 ; puts
dd 0x7c967e3e ; exit
dd 0x6ba3dda6 ; environ
dd 0x9e7650bd ; __progname
GNU_HASH_SIZE = $ - SECTION_GNU_HASH
INTERP_PLUS_GNU_HASH_SIZE = $ - SECTION_INTERP

align 0x8
SECTION_DYNSYM:

BEGIN_SYMBOLS

NULL_SYMBOL

IMPORT_FUNCTION puts
IMPORT_FUNCTION exit
EXPORT_OBJECT environ,LINK_BSS,LOAD_BASE + PLANE2 + SLOT_environ
EXPORT_OBJECT __progname,LINK_DATA,LOAD_BASE + PLANE2 + SLOT___progname

DYNSYM_SIZE = $ - SECTION_DYNSYM

SECTION_DYNSTR:

STRING_TABLE
STRING environ,"environ"
STRING puts, "puts"
STRING exit, "exit"
STRING __progname, "__progname"
if OS eq "Linux"
  STRING libc, "libc.so.6" 
else if OS eq "FreeBSD"
  STRING libc, "libc.so.7"
end if
STRING greeting,"Hello world!"

DYNSTR_SIZE = $ - SECTION_DYNSTR

align 8
SECTION_RELA_PLT:

RELOCATION puts,PLANE2
RELOCATION exit,PLANE2

RELA_PLT_SIZE = $ - SECTION_RELA_PLT

align 0x10
SECTION_TEXT:

main:

and rsp, -16 ; Align the stack (if needed) to prevent segfault.
mov rax, 0
; Place string pointer in RDI:
mov rdi, LOAD_BASE + SECTION_DYNSTR + greeting
call puts@plt ; Print our message.
mov rax, 0
mov rdi, 0
call exit@plt ; Exit, returning 0.

TEXT_SIZE = $ - SECTION_TEXT

align 0x10
SECTION_PLT:
; Instructions executed when the symbol is first resolved:
stitchup:
push qword [SECTION_GOT_PLT + PLANE1 + 8]
jmp qword [SECTION_GOT_PLT + PLANE1 + 16] ; Jump into linker.
; We list our imported functions here:
BEGIN_PLT_LINKAGE
PLT_LINKAGE puts,PLANE1
PLT_LINKAGE exit,PLANE1

PLT_SIZE = $ - SECTION_PLT

TEXT_PLUS_PLT_SIZE = $ - SECTION_TEXT

align 0x8
SECTION_DATA:
SLOT___progname rq 1

DATA_SIZE = $ - SECTION_DATA

align 0x8
SECTION_GOT_PLT:
dq LOAD_BASE + PLANE3 + SECTION_DYNAMIC ; For the linker.
; The linker fills these slots in:
dq 0
dq 0
; We list our imported functions here:
GOT_ENTRY puts,PLANE1
GOT_ENTRY exit,PLANE1

GOT_PLT_SIZE = $ - SECTION_GOT_PLT

align 0x8
SECTION_BSS:

SLOT_environ rq 1

BSS_SIZE = $ - SECTION_BSS

DATA_PLUS_GOT_PLT_PLUS_BSS_SIZE = $ - SECTION_DATA

align 0x8

SECTION_DYNAMIC:

dq DT_NEEDED,libc
dq DT_PLTGOT,LOAD_BASE + PLANE2 + SECTION_GOT_PLT
dq DT_DEBUG,0
dq DT_JMPREL,LOAD_BASE + SECTION_RELA_PLT
dq DT_PLTRELSZ,RELA_PLT_SIZE
dq DT_PLTREL,R_X86_64_JMP_SLOT
dq DT_SYMTAB,LOAD_BASE + SECTION_DYNSYM
dq DT_SYMENT,24
dq DT_STRTAB,LOAD_BASE + SECTION_DYNSTR
dq DT_STRSZ,DYNSTR_SIZE
dq DT_GNU_HASH,LOAD_BASE + SECTION_GNU_HASH
dq DT_NULL,0

DYNAMIC_SIZE = $ - SECTION_DYNAMIC

SECTION_SYMTAB:

BEGIN_SYMBOLS
NULL_SYMBOL
SYMBOL STRTAB_ENVIRON,STB_GLOBAL,STT_OBJECT,0,9,LOAD_BASE + PLANE2 + environ,8
SYMBOL STRTAB_PUTS,STB_GLOBAL,STT_FUNC,0,0,0,0

SYMTAB_SIZE = $ - SECTION_SYMTAB

SECTION_STRTAB:

STRING_TABLE

STRING STRTAB_PUTS,"puts"
STRING STRTAB_ENVIRON,"environ"

STRTAB_SIZE = $ - SECTION_STRTAB

SECTION_SHSTRTAB:

STRING_TABLE

STRING SHSTRTAB.S0, ""
STRING SHSTRTAB.S1,".interp"
STRING SHSTRTAB.S2,".gnu.hash"
STRING SHSTRTAB.S3,".dynsym"
STRING SHSTRTAB.S4,".dynstr"
STRING SHSTRTAB.S5,".rela.plt"
STRING SHSTRTAB.S6,".text"
STRING SHSTRTAB.S7,".plt"
STRING SHSTRTAB.S8,".data"
STRING SHSTRTAB.S9,".got.plt"
STRING SHSTRTAB.S10,".bss"
STRING SHSTRTAB.S11,".dynamic"
STRING SHSTRTAB.S12,".symtab"
STRING SHSTRTAB.S13,".strtab"
STRING SHSTRTAB.S14,".shstrtab"

SHSTRTAB_SIZE = $ - SECTION_SHSTRTAB

SHSTRTAB_INDEX = CSECTION_HEADER - 1

align 16
