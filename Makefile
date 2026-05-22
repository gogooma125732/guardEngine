# 커널을 구성하는 객체파일(objective file, .o) 목록
# 메모리 관리, 파일 시스템, 프로세스 제어 등 OS 핵심 기능 포함
OBJS = \
	bio.o\
	console.o\
	exec.o\
	file.o\
	fs.o\
	ide.o\
	ioapic.o\
	kalloc.o\
	kbd.o\
	lapic.o\
	log.o\
	main.o\
	mp.o\
	picirq.o\
	pipe.o\
	proc.o\
	sleeplock.o\
	spinlock.o\
	string.o\
	swtch.o\
	syscall.o\
	sysfile.o\
	sysproc.o\
	trapasm.o\
	trap.o\
	uart.o\
	vectors.o\
	vm.o\

# ToolPrefix 감지: 시스템에 크로스 컴파일러가 있는지 확인함. 
# 일반적인 x86 리눅스 환경인지, 별도의 툴체인이 필요한 환경인지 판단함.
# Cross-compiling (e.g., on Mac OS X)
# TOOLPREFIX = i386-jos-elf

# Using native tools (e.g., on X86 Linux)
#TOOLPREFIX = 

# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if i386-jos-elf-objdump -i 2>&1 | grep '^elf32-i386$$' >/dev/null 2>&1; \
	then echo 'i386-jos-elf-'; \
	elif objdump -i 2>&1 | grep 'elf32-i386' >/dev/null 2>&1; \
	then echo ''; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find an i386-*-elf version of GCC/binutils." 1>&2; \
	echo "*** Is the directory with i386-jos-elf-gcc in your PATH?" 1>&2; \
	echo "*** If your i386-*-elf toolchain is installed with a command" 1>&2; \
	echo "*** prefix other than 'i386-jos-elf-', set your TOOLPREFIX" 1>&2; \
	echo "*** environment variable to that prefix and run 'make' again." 1>&2; \
	echo "*** To turn off this error, run 'gmake TOOLPREFIX= ...'." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

# qemu 감지: 설치된 퀴무의 실행 파일명을 자동으로 찾아 경로를 지정함.
# If the makefile can't find QEMU, specify its path here
# QEMU = qemu-system-i386

# Try to infer the correct QEMU
ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
	then echo qemu; exit; \
	elif which qemu-system-i386 > /dev/null; \
	then echo qemu-system-i386; exit; \
	elif which qemu-system-x86_64 > /dev/null; \
	then echo qemu-system-x86_64; exit; \
	else \
	qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
	if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
	echo "***" 1>&2; exit 1)
endif

CC = $(TOOLPREFIX)gcc
AS = $(TOOLPREFIX)gas
LD = $(TOOLPREFIX)ld
OBJCOPY = $(TOOLPREFIX)objcopy
OBJDUMP = $(TOOLPREFIX)objdump

# 컴파일 및 링커 플래그
# 운영체제 커널은 표준 라이브러리(libc)를 사용할 수 없으므로, 특수한 옵션이 필요함
# CFLAGS
# -fno-pic: 커널은 특정 메모리 주소에 직접 배치되어야 하기 때문에 PIC(위치 독립 코드)를 생성하지 않음.
# -static: 정적 링크 수행
# -fno-builtin: printf같은 표준 내장 함수를 사용하지 않고 직접 구현한 함수를 쓰게 함.
# -m32: 32비트 x86 아키텍처용으로 빌드함
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
CFLAGS += -Wno-stringop-overflow
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
# FreeBSD ld wants ``elf_i386_fbsd''
# LDFLAGS: 특정 엔디안 및 아키텍처(elf_i386) 형식으로 강제함
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)

# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif

# 시스템 구성 요소 빌드
# OS를 구성하는 세 가지 주요 파트: Boot, Kerenl, Userland 를 각각 빌드함
# bootblck: 컴퓨터가 켜질 때 가장 먼저 실행되는 512바이트 부트 로더. 0x7c00 주소에서 시작하도록 설정되어 있음.?? 이거 어디에서 확인하지?
# kernel: OBJS와 entry.o 등을 합쳐 실제 운영체제 핵심을 만듦. kernel.ld 링커 스크립트를 사용하여 메모리 배치를 결정함.
# UPROGS(User Programs): ls, cat, sh 와 같은 유저 모드에서 실행될 유틸리티 프로그램들
xv6.img: bootblock kernel
	dd if=/dev/zero of=xv6.img count=100000
	dd if=bootblock of=xv6.img conv=notrunc
	dd if=kernel of=xv6.img seek=1 conv=notrunc

xv6memfs.img: bootblock kernelmemfs
	dd if=/dev/zero of=xv6memfs.img count=10000
	dd if=bootblock of=xv6memfs.img conv=notrunc
	dd if=kernelmemfs of=xv6memfs.img seek=1 conv=notrunc

# 여기서 부트로더 시작 위치를 0x7c00로 명시함
# 아래는 bootblcok 빌드 규칙을 써놓은 덩어리인데, 이 중 링커(LD) 명령어 실행에 대해 언급하고 있음
# -Ttext 0x7C00: 링커에게 "이 프로그램의 시작 코드(.text 섹션)가 메모리의 0x7C00 번지에 로드될 것이라고 가정하고 주소를 계산해" 라고 지시함
# xv6 설정이 아니라, IBM PC 호환 기종의 레거시 바이오스(BIOS) 표준때문에 0x7C00라는 값이 필요함.
# 컴퓨터 전원이 켜지면 BIOS는 디스크의 첫 번째 섹터(부트 섹터)를 읽어서 메모리의 0x7C00 위치에 복사한 뒤, 
# CPU의 제어권을 그 주소로 넘기도록 설계되어 있음.

# bootblock 생성 과정
# CC 명령규칙) 소스 코드 컴파일
# bootasm.S: CPU를 16비트 Real Mode에서 32비트 Protected Mode로 전환하는 초기 어셈블리 코드임. <- 이거 어디서 확인하지?
# bootmain.c: 디스크에서 커널 이미지를 읽어와 메모리에 올리는 역할을 함. C언어로 작성됨. 

# LD 명령규칙) 링킹
# 두 오브젝트 파일을 합쳐 하나의 실행 파일(bootblock.o)를 만듦. 이때 위에서 언급한 것처럼 시작 주소를 0x7C00으로 고정함

# OBCOPY 명령규칙) 순수 바이너리 추출
# bootblock.o는 ELF 포맷으로, 실제 코드 외에도 헤더 등 메타데이터가 붙어 있음. BIOS는 이런 복잡한 포맷을 이해하지 못하므로, objcopy를 사용해 
# 실행 가능한 기계어 코드(.text)만 쏙 뽑아내어 bootblock 이라는 순수 바이너리 파일을 만듦

# signing) 512바이트 맞추기와 서명
# sign.pl이라는 Perl 스크립트가 실행됨
# bootblcok 파일 크기가 510바이트를 넘는지 검사함.(부트 섹터는 512바이트여야 하므로)
# 파일 끝부분을 0으로 채워 510바이트를 만든 뒤, 마지막 2바이트에 0xAA55라는 마법의 숫자(Magic Number)를 써넣음
# BIOS는 디스크 첫 섹터의 끝이 0x55, 0xAA로 끝나야만 "아, 이것은 부팅 가능한 장치구나!"라고 인식하고 코드를 실행함.


# 즉, LD로 시작 주소 지정, 512바이트 확인(sign.pl 스크립트가 크기를 맞추고 마지막에 0xAA55 서명을 추가함), 파일 정체(bootasm.S (모드전환)+ bootmain.c (커널 로드)가 합쳐져서 만들어짐)
# -e start:프로그램 진입점(entry point)을 start라는 심볼(보통 bootasm.S에 정의됨)로 설정함.
bootblock: bootasm.S bootmain.c
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -c bootmain.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o  
	$(OBJDUMP) -S bootblock.o > bootblock.asm
	$(OBJCOPY) -S -O binary -j .text bootblock.o bootblock
	./sign.pl bootblock

entryother: entryother.S
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c entryother.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o bootblockother.o entryother.o
	$(OBJCOPY) -S -O binary -j .text bootblockother.o entryother
	$(OBJDUMP) -S bootblockother.o > entryother.asm

initcode: initcode.S
	$(CC) $(CFLAGS) -nostdinc -I. -c initcode.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o initcode.out initcode.o
	$(OBJCOPY) -S -O binary initcode.out initcode
	$(OBJDUMP) -S initcode.o > initcode.asm

kernel: $(OBJS) entry.o entryother initcode kernel.ld
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel entry.o $(OBJS) -b binary initcode entryother
	$(OBJDUMP) -S kernel > kernel.asm
	$(OBJDUMP) -t kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

# kernelmemfs is a copy of kernel that maintains the
# disk image in memory instead of writing to a disk.
# This is not so useful for testing persistent storage or
# exploring disk buffering implementations, but it is 
# great for testing the kernel on real hardware without
# needing a scratch disk.
MEMFSOBJS = $(filter-out ide.o,$(OBJS)) memide.o
kernelmemfs: $(MEMFSOBJS) entry.o entryother initcode kernel.ld fs.img
	$(LD) $(LDFLAGS) -T kernel.ld -o kernelmemfs entry.o  $(MEMFSOBJS) -b binary initcode entryother fs.img
	$(OBJDUMP) -S kernelmemfs > kernelmemfs.asm
	$(OBJDUMP) -t kernelmemfs | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernelmemfs.sym

tags: $(OBJS) entryother.S _init
	etags *.S *.c
	ctags *.S *.c

vectors.S: vectors.pl
	./vectors.pl > vectors.S

ULIB = ulib.o usys.o printf.o umalloc.o

_%: %.o $(ULIB)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^
	$(OBJDUMP) -S $@ > $*.asm
	$(OBJDUMP) -t $@ | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $*.sym

_forktest: forktest.o $(ULIB)
	# forktest has less library code linked in - needs to be small
	# in order to be able to max out the proc table.
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o _forktest forktest.o ulib.o usys.o
	$(OBJDUMP) -S _forktest > forktest.asm

mkfs: mkfs.c fs.h
	gcc -Werror -Wall -o mkfs mkfs.c

# Prevent deletion of intermediate files, e.g. cat.o, after first build, so
# that disk image changes after first build are persistent until clean.  More
# details:
# http://www.gnu.org/software/make/manual/html_node/Chained-Rules.html
.PRECIOUS: %.o
# UPROGS(User Programs): ls, cat, sh 와 같은 유저 모드에서 실행될 유틸리티 프로그램들
UPROGS=\
	_cat\
	_echo\
	_forktest\
	_grep\
	_init\
	_kill\
	_ln\
	_ls\
	_mkdir\
	_rm\
	_sh\
	_stressfs\
	_usertests\
	_wc\
	_zombie\
	_swaptest\


# 디스크 이미지 생성
# fs.img: mkfs 도구를 사용하여 유저 프로그램(UPROGS)들과 README 파일을 포함한 파일 시스템 이미지를 만듦
# xv6.img: dd 명령어를 사용하여 bootblock을 첫 번쨰 섹터에, kernel을 그 다음 섹터부터 배치하여 부팅 가능한 디스크 이미지를 생성함.
# dd 명령어로 연결되어 있는 걸 코드 어디 부분에서 확인하지?
# bootblcok과 kernel 을 섹터 배치하는 디스크 파티션에 대한 내용을 어디에서 확인하지?

fs.img: mkfs README $(UPROGS)
	./mkfs fs.img README $(UPROGS)

-include *.d

clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.asm *.sym vectors.S bootblock entryother \
	initcode initcode.out kernel xv6.img fs.img kernelmemfs \
	xv6memfs.img mkfs .gdbinit \
	$(UPROGS)

# make a printout
FILES = $(shell grep -v '^\#' runoff.list)
PRINT = runoff.list runoff.spec README toc.hdr toc.ftr $(FILES)

xv6.pdf: $(PRINT)
	./runoff
	ls -l xv6.pdf

print: xv6.pdf

# run in emulators

bochs : fs.img xv6.img
	if [ ! -e .bochsrc ]; then ln -s dot-bochsrc .bochsrc; fi
	bochs -q

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
ifndef CPUS
CPUS := 1
endif
QEMUOPTS = -drive file=fs.img,index=1,media=disk,format=raw -drive file=xv6.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512 $(QEMUEXTRA)


# 실행 및 디버깅
# qemu, qemu-gdb: 생성된 이미지를 qemu 에뮬레이터에서 실행함. 
# 특히 qemu-gdb 는 gdb 디버거와 연결하여 커널 코드를 한 줄씩 분석할 수 있게 함.
qemu: fs.img xv6.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-memfs: xv6memfs.img
	$(QEMU) -drive file=xv6memfs.img,index=0,media=disk,format=raw -smp $(CPUS) -m 256

qemu-nox: fs.img xv6.img
	$(QEMU) -nographic $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

qemu-gdb: fs.img xv6.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

qemu-nox-gdb: fs.img xv6.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

# CUT HERE
# prepare dist for students
# after running make dist, probably want to
# rename it to rev0 or rev1 or so on and then
# check in that version.

EXTRA=\
	mkfs.c ulib.c user.h cat.c echo.c forktest.c grep.c kill.c\
	ln.c ls.c mkdir.c rm.c stressfs.c usertests.c wc.c zombie.c\
	printf.c umalloc.c swaptest.c\
	README dot-bochsrc *.pl toc.* runoff runoff1 runoff.list\
	.gdbinit.tmpl gdbutil\

dist:
	rm -rf dist
	mkdir dist
	for i in $(FILES); \
	do \
		grep -v PAGEBREAK $$i >dist/$$i; \
	done
	sed '/CUT HERE/,$$d' Makefile >dist/Makefile
	echo >dist/runoff.spec
	cp $(EXTRA) dist
	chmod +x dist/vectors.pl

dist-test:
	rm -rf dist
	make dist
	rm -rf dist-test
	mkdir dist-test
	cp dist/* dist-test
	cd dist-test; $(MAKE) print
	#cd dist-test; $(MAKE) bochs || true
	cd dist-test; $(MAKE) qemu-nox

# update this rule (change rev#) when it is time to
# make a new revision.
tar:
	rm -rf /tmp/xv6
	mkdir -p /tmp/xv6
	cp dist/* dist/.gdbinit.tmpl /tmp/xv6
	(cd /tmp; tar cf - xv6) | gzip >xv6-rev10.tar.gz  # the next one will be 10 (9/17)

submission:
	tar cvf xv6_submission.tar *.c *.h

.PHONY: dist-test dist submission


# 일반적인 application 전용 Makefile과 다른 점(xv6)

# 일반적인 makefile의 경우, 실행 결과 단일 exe file(or objective file)이지만, 
# xv6 makefile의 경우, 디스크 이미지 생성

# stdio.h등 표준 라이브러리를 사용하지 않고, -fno-builtin, -nostdinc로 표준 라이브러리 배제

# OS가 알아서 메모리 배치/적재/로드하는 게 아니라, Ttext 0x7c00 등 특정 물리 주소 직접 지정

# 네이티브 컴파일러 위주로 컴파일하는 게 아니라, 크로스 컴파일러(TOOLPREFIX) 의존도가 높음

# gcc, ld 위주의 도구를 사용하지만, dd(바이너리 배치), objcopy(순수 바이너리 추출) 등 활용

# OS 위에서 직접 실행하지 않고, qemu, bochs같은 하드웨어 에뮬레이터 필요

# 즉, 일반적인 Makefile은 이미 OS가 돌아가는 환경을 가정하지만, 이 Makefile은 아무것도 없는 하드웨어(Bare metal)에서 
# 스스로를 구동하기 위한 바이너리 구조를 설계함.
# 그래서 dd 명령어로 디스크 섹터 단위를 직접 제어하고, 링커 스크립트를 통해 메모리 주소를 정교하게 관리하는 로직이 포함되어 있음.
