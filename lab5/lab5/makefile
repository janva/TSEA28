CROSS_COMPILER=/sw/xilinx/ise_14.4i/14.4/ISE_DS/EDK/gnu/arm/lin/bin/arm-xilinx-eabi-
CC=gcc

all: rotate hello assoc insnfetch
#@ signals don't output to screen? 
rotate: rotate.dis rotate.hex 
	@true

hello: hello.hex hello.dis
	@true

assoc: assoc.hex assoc.dis
	@true

insnfetch: insnfetch.hex insnfetch.dis
	@true

test_rotate: test_rotate.c util.h memorymap.h config.h
%.o: %.c
	$(CC) -Wall -Wextra  -c $<  -o $@

%.o: %.S
	$(CC) -Wall -Wextra -c $<  -o $@


# #include dependencies
helloworld.o: helloworld.c util.h
util.o: util.c util.h memorymap.h
rotate.o: rotate.c util.h memorymap.h config.h
insnfetch.o: insnfetch.c util.h
fetchtest.o: fetchtest.c util.h
assoc.o: assoc.c util.h
line.o:  line.S asmutil.h
find_associativity.o: find_associativity.S asmutil.h


# Some generic rules % matches filename
%.o: %.c
	$(CROSS_COMPILER)gcc -Wall -O2 -g3 -c $<  -o $@

%.o: %.S
	$(CROSS_COMPILER)gcc -Wall -O2 -g3 -c $<  -o $@

%.hex: %.elf
	$(CROSS_COMPILER)objcopy $< -O ihex $@

%.dis: %.elf
	$(CROSS_COMPILER)objdump -d $< > $@	


hello.elf: helloworld.o util.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o hello.elf  helloworld.o util.o 

rotate.elf: rotate.o util.o sintable.o line.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o rotate.elf  rotate.o util.o line.o sintable.o

assoc.elf: util.o assoc.o find_associativity.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o assoc.elf  assoc.o find_associativity.o util.o 

insnfetch.elf: insnfetch.o util.o fetchtest.o
	$(CROSS_COMPILER)gcc -Wl,-T -Wl,lscript.ld  -o insnfetch.elf  insnfetch.o util.o fetchtest.o

clean:
	rm -f *.o *.elf *.hex *~ *.dis

