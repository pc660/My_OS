
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 e0 1b 10 f0 	movl   $0xf0101be0,(%esp)
f0100055:	e8 78 09 00 00       	call   f01009d2 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 11 07 00 00       	call   f0100798 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 fc 1b 10 f0 	movl   $0xf0101bfc,(%esp)
f0100092:	e8 3b 09 00 00       	call   f01009d2 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 64 29 11 f0       	mov    $0xf0112964,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 d0 15 00 00       	call   f0101695 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9d 04 00 00       	call   f0100567 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 17 1c 10 f0 	movl   $0xf0101c17,(%esp)
f01000d9:	e8 f4 08 00 00       	call   f01009d2 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 60 07 00 00       	call   f0100856 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 60 29 11 f0 00 	cmpl   $0x0,0xf0112960
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 60 29 11 f0    	mov    %esi,0xf0112960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 32 1c 10 f0 	movl   $0xf0101c32,(%esp)
f010012c:	e8 a1 08 00 00       	call   f01009d2 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 62 08 00 00       	call   f010099f <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 6e 1c 10 f0 	movl   $0xf0101c6e,(%esp)
f0100144:	e8 89 08 00 00       	call   f01009d2 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 01 07 00 00       	call   f0100856 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 4a 1c 10 f0 	movl   $0xf0101c4a,(%esp)
f0100176:	e8 57 08 00 00       	call   f01009d2 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 15 08 00 00       	call   f010099f <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 6e 1c 10 f0 	movl   $0xf0101c6e,(%esp)
f0100191:	e8 3c 08 00 00       	call   f01009d2 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 2c             	sub    $0x2c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010021a:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010021b:	a8 20                	test   $0x20,%al
f010021d:	75 1b                	jne    f010023a <cons_putc+0x30>
f010021f:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100224:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100229:	e8 72 ff ff ff       	call   f01001a0 <delay>
f010022e:	89 f2                	mov    %esi,%edx
f0100230:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100231:	a8 20                	test   $0x20,%al
f0100233:	75 05                	jne    f010023a <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100235:	83 eb 01             	sub    $0x1,%ebx
f0100238:	75 ef                	jne    f0100229 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010023a:	89 f8                	mov    %edi,%eax
f010023c:	25 ff 00 00 00       	and    $0xff,%eax
f0100241:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100244:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100249:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010024a:	b2 79                	mov    $0x79,%dl
f010024c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024d:	84 c0                	test   %al,%al
f010024f:	78 1b                	js     f010026c <cons_putc+0x62>
f0100251:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100256:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f010025b:	e8 40 ff ff ff       	call   f01001a0 <delay>
f0100260:	89 f2                	mov    %esi,%edx
f0100262:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100263:	84 c0                	test   %al,%al
f0100265:	78 05                	js     f010026c <cons_putc+0x62>
f0100267:	83 eb 01             	sub    $0x1,%ebx
f010026a:	75 ef                	jne    f010025b <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010026c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100271:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100275:	ee                   	out    %al,(%dx)
f0100276:	b2 7a                	mov    $0x7a,%dl
f0100278:	b8 0d 00 00 00       	mov    $0xd,%eax
f010027d:	ee                   	out    %al,(%dx)
f010027e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100283:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100284:	89 fa                	mov    %edi,%edx
f0100286:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010028c:	89 f8                	mov    %edi,%eax
f010028e:	80 cc 07             	or     $0x7,%ah
f0100291:	85 d2                	test   %edx,%edx
f0100293:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100296:	89 f8                	mov    %edi,%eax
f0100298:	25 ff 00 00 00       	and    $0xff,%eax
f010029d:	83 f8 09             	cmp    $0x9,%eax
f01002a0:	74 77                	je     f0100319 <cons_putc+0x10f>
f01002a2:	83 f8 09             	cmp    $0x9,%eax
f01002a5:	7f 0b                	jg     f01002b2 <cons_putc+0xa8>
f01002a7:	83 f8 08             	cmp    $0x8,%eax
f01002aa:	0f 85 9d 00 00 00    	jne    f010034d <cons_putc+0x143>
f01002b0:	eb 10                	jmp    f01002c2 <cons_putc+0xb8>
f01002b2:	83 f8 0a             	cmp    $0xa,%eax
f01002b5:	74 3c                	je     f01002f3 <cons_putc+0xe9>
f01002b7:	83 f8 0d             	cmp    $0xd,%eax
f01002ba:	0f 85 8d 00 00 00    	jne    f010034d <cons_putc+0x143>
f01002c0:	eb 39                	jmp    f01002fb <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e5 00 00 00    	je     f01003b7 <cons_putc+0x1ad>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002e4:	83 cf 20             	or     $0x20,%edi
f01002e7:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002ed:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f1:	eb 77                	jmp    f010036a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f3:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002fa:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fb:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100302:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100308:	c1 e8 16             	shr    $0x16,%eax
f010030b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030e:	c1 e0 04             	shl    $0x4,%eax
f0100311:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100317:	eb 51                	jmp    f010036a <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e7 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 dd fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d3 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 c9 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100341:	b8 20 00 00 00       	mov    $0x20,%eax
f0100346:	e8 bf fe ff ff       	call   f010020a <cons_putc>
f010034b:	eb 1d                	jmp    f010036a <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034d:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100354:	0f b7 c8             	movzwl %ax,%ecx
f0100357:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010035d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100361:	83 c0 01             	add    $0x1,%eax
f0100364:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010036a:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100371:	cf 07 
f0100373:	76 42                	jbe    f01003b7 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100375:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f010037a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100381:	00 
f0100382:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100388:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038c:	89 04 24             	mov    %eax,(%esp)
f010038f:	e8 5f 13 00 00       	call   f01016f3 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100394:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a5:	83 c0 01             	add    $0x1,%eax
f01003a8:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ad:	75 f0                	jne    f010039f <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003af:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003b6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b7:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003bd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c2:	89 ca                	mov    %ecx,%edx
f01003c4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c5:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003cc:	8d 71 01             	lea    0x1(%ecx),%esi
f01003cf:	89 d8                	mov    %ebx,%eax
f01003d1:	66 c1 e8 08          	shr    $0x8,%ax
f01003d5:	89 f2                	mov    %esi,%edx
f01003d7:	ee                   	out    %al,(%dx)
f01003d8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dd:	89 ca                	mov    %ecx,%edx
f01003df:	ee                   	out    %al,(%dx)
f01003e0:	89 d8                	mov    %ebx,%eax
f01003e2:	89 f2                	mov    %esi,%edx
f01003e4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e5:	83 c4 2c             	add    $0x2c,%esp
f01003e8:	5b                   	pop    %ebx
f01003e9:	5e                   	pop    %esi
f01003ea:	5f                   	pop    %edi
f01003eb:	5d                   	pop    %ebp
f01003ec:	c3                   	ret    

f01003ed <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ed:	55                   	push   %ebp
f01003ee:	89 e5                	mov    %esp,%ebp
f01003f0:	53                   	push   %ebx
f01003f1:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f4:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f9:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fa:	a8 01                	test   $0x1,%al
f01003fc:	0f 84 e5 00 00 00    	je     f01004e7 <kbd_proc_data+0xfa>
f0100402:	b2 60                	mov    $0x60,%dl
f0100404:	ec                   	in     (%dx),%al
f0100405:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100407:	3c e0                	cmp    $0xe0,%al
f0100409:	75 11                	jne    f010041c <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f010040b:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100412:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100417:	e9 d0 00 00 00       	jmp    f01004ec <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f010041c:	84 c0                	test   %al,%al
f010041e:	79 37                	jns    f0100457 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100420:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100426:	89 cb                	mov    %ecx,%ebx
f0100428:	83 e3 40             	and    $0x40,%ebx
f010042b:	83 e0 7f             	and    $0x7f,%eax
f010042e:	85 db                	test   %ebx,%ebx
f0100430:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100433:	0f b6 d2             	movzbl %dl,%edx
f0100436:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f010043d:	83 c8 40             	or     $0x40,%eax
f0100440:	0f b6 c0             	movzbl %al,%eax
f0100443:	f7 d0                	not    %eax
f0100445:	21 c1                	and    %eax,%ecx
f0100447:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f010044d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100452:	e9 95 00 00 00       	jmp    f01004ec <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f0100457:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010045d:	f6 c1 40             	test   $0x40,%cl
f0100460:	74 0e                	je     f0100470 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100462:	89 c2                	mov    %eax,%edx
f0100464:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100467:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046a:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100470:	0f b6 d2             	movzbl %dl,%edx
f0100473:	0f b6 82 a0 1c 10 f0 	movzbl -0xfefe360(%edx),%eax
f010047a:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100480:	0f b6 8a a0 1d 10 f0 	movzbl -0xfefe260(%edx),%ecx
f0100487:	31 c8                	xor    %ecx,%eax
f0100489:	a3 28 25 11 f0       	mov    %eax,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f010048e:	89 c1                	mov    %eax,%ecx
f0100490:	83 e1 03             	and    $0x3,%ecx
f0100493:	8b 0c 8d a0 1e 10 f0 	mov    -0xfefe160(,%ecx,4),%ecx
f010049a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010049e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01004a1:	a8 08                	test   $0x8,%al
f01004a3:	74 1b                	je     f01004c0 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a5:	89 da                	mov    %ebx,%edx
f01004a7:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004aa:	83 f9 19             	cmp    $0x19,%ecx
f01004ad:	77 05                	ja     f01004b4 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004af:	83 eb 20             	sub    $0x20,%ebx
f01004b2:	eb 0c                	jmp    f01004c0 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b4:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004b7:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004ba:	83 fa 19             	cmp    $0x19,%edx
f01004bd:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004c0:	f7 d0                	not    %eax
f01004c2:	a8 06                	test   $0x6,%al
f01004c4:	75 26                	jne    f01004ec <kbd_proc_data+0xff>
f01004c6:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cc:	75 1e                	jne    f01004ec <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f01004ce:	c7 04 24 64 1c 10 f0 	movl   $0xf0101c64,(%esp)
f01004d5:	e8 f8 04 00 00       	call   f01009d2 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004da:	ba 92 00 00 00       	mov    $0x92,%edx
f01004df:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e4:	ee                   	out    %al,(%dx)
f01004e5:	eb 05                	jmp    f01004ec <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01004e7:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004ec:	89 d8                	mov    %ebx,%eax
f01004ee:	83 c4 14             	add    $0x14,%esp
f01004f1:	5b                   	pop    %ebx
f01004f2:	5d                   	pop    %ebp
f01004f3:	c3                   	ret    

f01004f4 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f4:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004fb:	74 11                	je     f010050e <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fd:	55                   	push   %ebp
f01004fe:	89 e5                	mov    %esp,%ebp
f0100500:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100503:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100508:	e8 bd fc ff ff       	call   f01001ca <cons_intr>
}
f010050d:	c9                   	leave  
f010050e:	f3 c3                	repz ret 

f0100510 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100510:	55                   	push   %ebp
f0100511:	89 e5                	mov    %esp,%ebp
f0100513:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100516:	b8 ed 03 10 f0       	mov    $0xf01003ed,%eax
f010051b:	e8 aa fc ff ff       	call   f01001ca <cons_intr>
}
f0100520:	c9                   	leave  
f0100521:	c3                   	ret    

f0100522 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100522:	55                   	push   %ebp
f0100523:	89 e5                	mov    %esp,%ebp
f0100525:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100528:	e8 c7 ff ff ff       	call   f01004f4 <serial_intr>
	kbd_intr();
f010052d:	e8 de ff ff ff       	call   f0100510 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100532:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f0100538:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010053e:	74 20                	je     f0100560 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100540:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100547:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f010054a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f0100550:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100555:	0f 44 d1             	cmove  %ecx,%edx
f0100558:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010055e:	eb 05                	jmp    f0100565 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100560:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100565:	c9                   	leave  
f0100566:	c3                   	ret    

f0100567 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100567:	55                   	push   %ebp
f0100568:	89 e5                	mov    %esp,%ebp
f010056a:	57                   	push   %edi
f010056b:	56                   	push   %esi
f010056c:	53                   	push   %ebx
f010056d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100570:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100577:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010057e:	5a a5 
	if (*cp != 0xA55A) {
f0100580:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100587:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058b:	74 11                	je     f010059e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058d:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100594:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100597:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010059c:	eb 16                	jmp    f01005b4 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010059e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a5:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005ac:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005af:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b4:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005ba:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005bf:	89 ca                	mov    %ecx,%edx
f01005c1:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c2:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c5:	89 da                	mov    %ebx,%edx
f01005c7:	ec                   	in     (%dx),%al
f01005c8:	0f b6 f0             	movzbl %al,%esi
f01005cb:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ce:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d3:	89 ca                	mov    %ecx,%edx
f01005d5:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d6:	89 da                	mov    %ebx,%edx
f01005d8:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d9:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005df:	0f b6 d8             	movzbl %al,%ebx
f01005e2:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e4:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005eb:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f5:	89 f2                	mov    %esi,%edx
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	b2 fb                	mov    $0xfb,%dl
f01005fa:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ff:	ee                   	out    %al,(%dx)
f0100600:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100605:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060a:	89 da                	mov    %ebx,%edx
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 f9                	mov    $0xf9,%dl
f010060f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fb                	mov    $0xfb,%dl
f0100617:	b8 03 00 00 00       	mov    $0x3,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 fc                	mov    $0xfc,%dl
f010061f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100624:	ee                   	out    %al,(%dx)
f0100625:	b2 f9                	mov    $0xf9,%dl
f0100627:	b8 01 00 00 00       	mov    $0x1,%eax
f010062c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010062d:	b2 fd                	mov    $0xfd,%dl
f010062f:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100630:	3c ff                	cmp    $0xff,%al
f0100632:	0f 95 c1             	setne  %cl
f0100635:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f010063b:	89 f2                	mov    %esi,%edx
f010063d:	ec                   	in     (%dx),%al
f010063e:	89 da                	mov    %ebx,%edx
f0100640:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100641:	84 c9                	test   %cl,%cl
f0100643:	75 0c                	jne    f0100651 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100645:	c7 04 24 70 1c 10 f0 	movl   $0xf0101c70,(%esp)
f010064c:	e8 81 03 00 00       	call   f01009d2 <cprintf>
}
f0100651:	83 c4 1c             	add    $0x1c,%esp
f0100654:	5b                   	pop    %ebx
f0100655:	5e                   	pop    %esi
f0100656:	5f                   	pop    %edi
f0100657:	5d                   	pop    %ebp
f0100658:	c3                   	ret    

f0100659 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
f010065c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100662:	e8 a3 fb ff ff       	call   f010020a <cons_putc>
}
f0100667:	c9                   	leave  
f0100668:	c3                   	ret    

f0100669 <getchar>:

int
getchar(void)
{
f0100669:	55                   	push   %ebp
f010066a:	89 e5                	mov    %esp,%ebp
f010066c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066f:	e8 ae fe ff ff       	call   f0100522 <cons_getc>
f0100674:	85 c0                	test   %eax,%eax
f0100676:	74 f7                	je     f010066f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <iscons>:

int
iscons(int fdnum)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100682:	5d                   	pop    %ebp
f0100683:	c3                   	ret    
f0100684:	66 90                	xchg   %ax,%ax
f0100686:	66 90                	xchg   %ax,%ax
f0100688:	66 90                	xchg   %ax,%ax
f010068a:	66 90                	xchg   %ax,%ax
f010068c:	66 90                	xchg   %ax,%ax
f010068e:	66 90                	xchg   %ax,%ax

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 b0 1e 10 f0 	movl   $0xf0101eb0,(%esp)
f010069d:	e8 30 03 00 00       	call   f01009d2 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 58 1f 10 f0 	movl   $0xf0101f58,(%esp)
f01006b1:	e8 1c 03 00 00       	call   f01009d2 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 80 1f 10 f0 	movl   $0xf0101f80,(%esp)
f01006cd:	e8 00 03 00 00       	call   f01009d2 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 cf 1b 10 	movl   $0x101bcf,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 cf 1b 10 	movl   $0xf0101bcf,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 a4 1f 10 f0 	movl   $0xf0101fa4,(%esp)
f01006e9:	e8 e4 02 00 00       	call   f01009d2 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 c8 1f 10 f0 	movl   $0xf0101fc8,(%esp)
f0100705:	e8 c8 02 00 00       	call   f01009d2 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 64 29 11 	movl   $0x112964,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 64 29 11 	movl   $0xf0112964,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 ec 1f 10 f0 	movl   $0xf0101fec,(%esp)
f0100721:	e8 ac 02 00 00       	call   f01009d2 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 63 2d 11 f0       	mov    $0xf0112d63,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 10 20 10 f0 	movl   $0xf0102010,(%esp)
f010074e:	e8 7f 02 00 00       	call   f01009d2 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	56                   	push   %esi
f010075e:	53                   	push   %ebx
f010075f:	83 ec 10             	sub    $0x10,%esp
f0100762:	bb e4 20 10 f0       	mov    $0xf01020e4,%ebx
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100767:	be 08 21 10 f0       	mov    $0xf0102108,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010076c:	8b 03                	mov    (%ebx),%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100775:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100779:	c7 04 24 c9 1e 10 f0 	movl   $0xf0101ec9,(%esp)
f0100780:	e8 4d 02 00 00       	call   f01009d2 <cprintf>
f0100785:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100788:	39 f3                	cmp    %esi,%ebx
f010078a:	75 e0                	jne    f010076c <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010078c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100791:	83 c4 10             	add    $0x10,%esp
f0100794:	5b                   	pop    %ebx
f0100795:	5e                   	pop    %esi
f0100796:	5d                   	pop    %ebp
f0100797:	c3                   	ret    

f0100798 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100798:	55                   	push   %ebp
f0100799:	89 e5                	mov    %esp,%ebp
f010079b:	57                   	push   %edi
f010079c:	56                   	push   %esi
f010079d:	53                   	push   %ebx
f010079e:	83 ec 3c             	sub    $0x3c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a1:	89 e8                	mov    %ebp,%eax
f01007a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01007a6:	89 c3                	mov    %eax,%ebx
	// Your code here.
	unsigned int ebp, eip;
	unsigned int  arg[5];
	int i = 0;
	ebp = read_ebp();
	eip = *((unsigned int*)(ebp + 4));
f01007a8:	8b 70 04             	mov    0x4(%eax),%esi
	arg[0] =  *((unsigned int*)(ebp + 8));
f01007ab:	8b 48 08             	mov    0x8(%eax),%ecx
	arg[1] =  *((unsigned int*)(ebp + 12));
f01007ae:	8b 50 0c             	mov    0xc(%eax),%edx
f01007b1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	arg[2] =  *((unsigned int*)(ebp + 16));
f01007b4:	8b 40 10             	mov    0x10(%eax),%eax
f01007b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	arg[3] =  *((unsigned int*)(ebp + 20));
f01007ba:	8b 7b 14             	mov    0x14(%ebx),%edi
	arg[4] =  *((unsigned int*)(ebp + 24));
f01007bd:	8b 43 18             	mov    0x18(%ebx),%eax
	while ( ebp >0)
f01007c0:	85 db                	test   %ebx,%ebx
f01007c2:	0f 84 81 00 00 00    	je     f0100849 <mon_backtrace+0xb1>
f01007c8:	8b 55 dc             	mov    -0x24(%ebp),%edx
	  {
	    cprintf("ebp = %x eip = %x arguments: %x %x %x %x %x\n", ebp, eip, arg[0],arg[1],arg[2],arg[3],arg[4]);
f01007cb:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007cf:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01007d3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007d6:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007da:	89 54 24 10          	mov    %edx,0x10(%esp)
f01007de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01007e2:	89 74 24 08          	mov    %esi,0x8(%esp)
f01007e6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007ea:	c7 04 24 3c 20 10 f0 	movl   $0xf010203c,(%esp)
f01007f1:	e8 dc 01 00 00       	call   f01009d2 <cprintf>
	    	debuginfo_eip( (uintptr_t) eip, &info  );
f01007f6:	c7 44 24 04 38 25 11 	movl   $0xf0112538,0x4(%esp)
f01007fd:	f0 
f01007fe:	89 34 24             	mov    %esi,(%esp)
f0100801:	e8 c7 02 00 00       	call   f0100acd <debuginfo_eip>
	    ebp =  *((unsigned int*)(ebp));
f0100806:	8b 1b                	mov    (%ebx),%ebx
	    eip = *((unsigned int*)(ebp + 4));
f0100808:	8b 73 04             	mov    0x4(%ebx),%esi
	    memset(&info, 0 , sizeof(info));
f010080b:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
f0100812:	00 
f0100813:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010081a:	00 
f010081b:	c7 04 24 38 25 11 f0 	movl   $0xf0112538,(%esp)
f0100822:	e8 6e 0e 00 00       	call   f0101695 <memset>
	    cprintf("\n");
f0100827:	c7 04 24 6e 1c 10 f0 	movl   $0xf0101c6e,(%esp)
f010082e:	e8 9f 01 00 00       	call   f01009d2 <cprintf>
	    arg[0] =  *((unsigned int*)(ebp + 8));
f0100833:	8b 4b 08             	mov    0x8(%ebx),%ecx
	    arg[1] =  *((unsigned int*)(ebp + 12));
f0100836:	8b 53 0c             	mov    0xc(%ebx),%edx
	    arg[2] =  *((unsigned int*)(ebp + 16));
f0100839:	8b 43 10             	mov    0x10(%ebx),%eax
f010083c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	    arg[3] =  *((unsigned int*)(ebp + 20));
f010083f:	8b 7b 14             	mov    0x14(%ebx),%edi
	    arg[4] =  *((unsigned int*)(ebp + 24));
f0100842:	8b 43 18             	mov    0x18(%ebx),%eax
	arg[0] =  *((unsigned int*)(ebp + 8));
	arg[1] =  *((unsigned int*)(ebp + 12));
	arg[2] =  *((unsigned int*)(ebp + 16));
	arg[3] =  *((unsigned int*)(ebp + 20));
	arg[4] =  *((unsigned int*)(ebp + 24));
	while ( ebp >0)
f0100845:	85 db                	test   %ebx,%ebx
f0100847:	75 82                	jne    f01007cb <mon_backtrace+0x33>
	    arg[3] =  *((unsigned int*)(ebp + 20));
	    arg[4] =  *((unsigned int*)(ebp + 24));
 
	  }
	return 0;
}
f0100849:	b8 00 00 00 00       	mov    $0x0,%eax
f010084e:	83 c4 3c             	add    $0x3c,%esp
f0100851:	5b                   	pop    %ebx
f0100852:	5e                   	pop    %esi
f0100853:	5f                   	pop    %edi
f0100854:	5d                   	pop    %ebp
f0100855:	c3                   	ret    

f0100856 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100856:	55                   	push   %ebp
f0100857:	89 e5                	mov    %esp,%ebp
f0100859:	57                   	push   %edi
f010085a:	56                   	push   %esi
f010085b:	53                   	push   %ebx
f010085c:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010085f:	c7 04 24 6c 20 10 f0 	movl   $0xf010206c,(%esp)
f0100866:	e8 67 01 00 00       	call   f01009d2 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010086b:	c7 04 24 90 20 10 f0 	movl   $0xf0102090,(%esp)
f0100872:	e8 5b 01 00 00       	call   f01009d2 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100877:	c7 04 24 d2 1e 10 f0 	movl   $0xf0101ed2,(%esp)
f010087e:	e8 3d 0b 00 00       	call   f01013c0 <readline>
f0100883:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100885:	85 c0                	test   %eax,%eax
f0100887:	74 ee                	je     f0100877 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100889:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100890:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100895:	eb 06                	jmp    f010089d <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100897:	c6 06 00             	movb   $0x0,(%esi)
f010089a:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010089d:	0f b6 06             	movzbl (%esi),%eax
f01008a0:	84 c0                	test   %al,%al
f01008a2:	74 6a                	je     f010090e <monitor+0xb8>
f01008a4:	0f be c0             	movsbl %al,%eax
f01008a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ab:	c7 04 24 d6 1e 10 f0 	movl   $0xf0101ed6,(%esp)
f01008b2:	e8 7e 0d 00 00       	call   f0101635 <strchr>
f01008b7:	85 c0                	test   %eax,%eax
f01008b9:	75 dc                	jne    f0100897 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008bb:	80 3e 00             	cmpb   $0x0,(%esi)
f01008be:	74 4e                	je     f010090e <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008c0:	83 fb 0f             	cmp    $0xf,%ebx
f01008c3:	75 16                	jne    f01008db <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008c5:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008cc:	00 
f01008cd:	c7 04 24 db 1e 10 f0 	movl   $0xf0101edb,(%esp)
f01008d4:	e8 f9 00 00 00       	call   f01009d2 <cprintf>
f01008d9:	eb 9c                	jmp    f0100877 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008db:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008df:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f01008e2:	0f b6 06             	movzbl (%esi),%eax
f01008e5:	84 c0                	test   %al,%al
f01008e7:	75 0c                	jne    f01008f5 <monitor+0x9f>
f01008e9:	eb b2                	jmp    f010089d <monitor+0x47>
			buf++;
f01008eb:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008ee:	0f b6 06             	movzbl (%esi),%eax
f01008f1:	84 c0                	test   %al,%al
f01008f3:	74 a8                	je     f010089d <monitor+0x47>
f01008f5:	0f be c0             	movsbl %al,%eax
f01008f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008fc:	c7 04 24 d6 1e 10 f0 	movl   $0xf0101ed6,(%esp)
f0100903:	e8 2d 0d 00 00       	call   f0101635 <strchr>
f0100908:	85 c0                	test   %eax,%eax
f010090a:	74 df                	je     f01008eb <monitor+0x95>
f010090c:	eb 8f                	jmp    f010089d <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010090e:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100915:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100916:	85 db                	test   %ebx,%ebx
f0100918:	0f 84 59 ff ff ff    	je     f0100877 <monitor+0x21>
f010091e:	bf e0 20 10 f0       	mov    $0xf01020e0,%edi
f0100923:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100928:	8b 07                	mov    (%edi),%eax
f010092a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 78 0c 00 00       	call   f01015b1 <strcmp>
f0100939:	85 c0                	test   %eax,%eax
f010093b:	75 24                	jne    f0100961 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010093d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100940:	8b 55 08             	mov    0x8(%ebp),%edx
f0100943:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100947:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010094a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010094e:	89 1c 24             	mov    %ebx,(%esp)
f0100951:	ff 14 85 e8 20 10 f0 	call   *-0xfefdf18(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100958:	85 c0                	test   %eax,%eax
f010095a:	78 28                	js     f0100984 <monitor+0x12e>
f010095c:	e9 16 ff ff ff       	jmp    f0100877 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100961:	83 c6 01             	add    $0x1,%esi
f0100964:	83 c7 0c             	add    $0xc,%edi
f0100967:	83 fe 03             	cmp    $0x3,%esi
f010096a:	75 bc                	jne    f0100928 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010096c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010096f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100973:	c7 04 24 f8 1e 10 f0 	movl   $0xf0101ef8,(%esp)
f010097a:	e8 53 00 00 00       	call   f01009d2 <cprintf>
f010097f:	e9 f3 fe ff ff       	jmp    f0100877 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100984:	83 c4 5c             	add    $0x5c,%esp
f0100987:	5b                   	pop    %ebx
f0100988:	5e                   	pop    %esi
f0100989:	5f                   	pop    %edi
f010098a:	5d                   	pop    %ebp
f010098b:	c3                   	ret    

f010098c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010098c:	55                   	push   %ebp
f010098d:	89 e5                	mov    %esp,%ebp
f010098f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100992:	8b 45 08             	mov    0x8(%ebp),%eax
f0100995:	89 04 24             	mov    %eax,(%esp)
f0100998:	e8 bc fc ff ff       	call   f0100659 <cputchar>
	*cnt++;
}
f010099d:	c9                   	leave  
f010099e:	c3                   	ret    

f010099f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010099f:	55                   	push   %ebp
f01009a0:	89 e5                	mov    %esp,%ebp
f01009a2:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009a5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009ac:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009ba:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009c1:	c7 04 24 8c 09 10 f0 	movl   $0xf010098c,(%esp)
f01009c8:	e8 45 05 00 00       	call   f0100f12 <vprintfmt>
	return cnt;
}
f01009cd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009d0:	c9                   	leave  
f01009d1:	c3                   	ret    

f01009d2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009d2:	55                   	push   %ebp
f01009d3:	89 e5                	mov    %esp,%ebp
f01009d5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009d8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009df:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e2:	89 04 24             	mov    %eax,(%esp)
f01009e5:	e8 b5 ff ff ff       	call   f010099f <vcprintf>
	va_end(ap);

	return cnt;
}
f01009ea:	c9                   	leave  
f01009eb:	c3                   	ret    
f01009ec:	66 90                	xchg   %ax,%ax
f01009ee:	66 90                	xchg   %ax,%ax

f01009f0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009f0:	55                   	push   %ebp
f01009f1:	89 e5                	mov    %esp,%ebp
f01009f3:	57                   	push   %edi
f01009f4:	56                   	push   %esi
f01009f5:	53                   	push   %ebx
f01009f6:	83 ec 10             	sub    $0x10,%esp
f01009f9:	89 c6                	mov    %eax,%esi
f01009fb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009fe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a01:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a04:	8b 1a                	mov    (%edx),%ebx
f0100a06:	8b 09                	mov    (%ecx),%ecx
f0100a08:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a0b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a12:	eb 77                	jmp    f0100a8b <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a14:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a17:	01 d8                	add    %ebx,%eax
f0100a19:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a1e:	99                   	cltd   
f0100a1f:	f7 f9                	idiv   %ecx
f0100a21:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a23:	eb 01                	jmp    f0100a26 <stab_binsearch+0x36>
			m--;
f0100a25:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a26:	39 d9                	cmp    %ebx,%ecx
f0100a28:	7c 1d                	jl     f0100a47 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a2a:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a32:	39 fa                	cmp    %edi,%edx
f0100a34:	75 ef                	jne    f0100a25 <stab_binsearch+0x35>
f0100a36:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a39:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a3c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a40:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a43:	73 18                	jae    f0100a5d <stab_binsearch+0x6d>
f0100a45:	eb 05                	jmp    f0100a4c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a47:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a4a:	eb 3f                	jmp    f0100a8b <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a4c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a4f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100a51:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a54:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a5b:	eb 2e                	jmp    f0100a8b <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a5d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a60:	73 15                	jae    f0100a77 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a62:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a65:	49                   	dec    %ecx
f0100a66:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a69:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a6c:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6e:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a75:	eb 14                	jmp    f0100a8b <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a77:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a7a:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a7d:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100a7f:	ff 45 0c             	incl   0xc(%ebp)
f0100a82:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a84:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a8b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a8e:	7e 84                	jle    f0100a14 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a90:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a94:	75 0d                	jne    f0100aa3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a96:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a99:	8b 02                	mov    (%edx),%eax
f0100a9b:	48                   	dec    %eax
f0100a9c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a9f:	89 01                	mov    %eax,(%ecx)
f0100aa1:	eb 22                	jmp    f0100ac5 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aa3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aa6:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aa8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aab:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aad:	eb 01                	jmp    f0100ab0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100aaf:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100ab0:	39 c1                	cmp    %eax,%ecx
f0100ab2:	7d 0c                	jge    f0100ac0 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ab4:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100ab7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100abc:	39 fa                	cmp    %edi,%edx
f0100abe:	75 ef                	jne    f0100aaf <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ac0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ac3:	89 02                	mov    %eax,(%edx)
	}
}
f0100ac5:	83 c4 10             	add    $0x10,%esp
f0100ac8:	5b                   	pop    %ebx
f0100ac9:	5e                   	pop    %esi
f0100aca:	5f                   	pop    %edi
f0100acb:	5d                   	pop    %ebp
f0100acc:	c3                   	ret    

f0100acd <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100acd:	55                   	push   %ebp
f0100ace:	89 e5                	mov    %esp,%ebp
f0100ad0:	83 ec 68             	sub    $0x68,%esp
f0100ad3:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100ad6:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ad9:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100adc:	8b 75 08             	mov    0x8(%ebp),%esi
f0100adf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ae2:	c7 03 04 21 10 f0    	movl   $0xf0102104,(%ebx)
	info->eip_line = 0;
f0100ae8:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100aef:	c7 43 08 04 21 10 f0 	movl   $0xf0102104,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100af6:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100afd:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b00:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b07:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b0d:	76 12                	jbe    f0100b21 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b0f:	b8 56 79 10 f0       	mov    $0xf0107956,%eax
f0100b14:	3d 29 60 10 f0       	cmp    $0xf0106029,%eax
f0100b19:	0f 86 39 02 00 00    	jbe    f0100d58 <debuginfo_eip+0x28b>
f0100b1f:	eb 1c                	jmp    f0100b3d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b21:	c7 44 24 08 0e 21 10 	movl   $0xf010210e,0x8(%esp)
f0100b28:	f0 
f0100b29:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b30:	00 
f0100b31:	c7 04 24 1b 21 10 f0 	movl   $0xf010211b,(%esp)
f0100b38:	e8 bb f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b3d:	80 3d 55 79 10 f0 00 	cmpb   $0x0,0xf0107955
f0100b44:	0f 85 15 02 00 00    	jne    f0100d5f <debuginfo_eip+0x292>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b4a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b51:	b8 28 60 10 f0       	mov    $0xf0106028,%eax
f0100b56:	2d 50 23 10 f0       	sub    $0xf0102350,%eax
f0100b5b:	c1 f8 02             	sar    $0x2,%eax
f0100b5e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b64:	83 e8 01             	sub    $0x1,%eax
f0100b67:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b6a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b6e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b75:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b78:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b7b:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100b80:	e8 6b fe ff ff       	call   f01009f0 <stab_binsearch>
	if (lfile == 0)
f0100b85:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b88:	85 c0                	test   %eax,%eax
f0100b8a:	0f 84 d6 01 00 00    	je     f0100d66 <debuginfo_eip+0x299>
		return -1;
	info->eip_file = stabstr + stabs[lfile].n_strx;
f0100b90:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100b93:	8b 92 50 23 10 f0    	mov    -0xfefdcb0(%edx),%edx
f0100b99:	81 c2 29 60 10 f0    	add    $0xf0106029,%edx
f0100b9f:	89 13                	mov    %edx,(%ebx)
      	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ba1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ba4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ba7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100baa:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bae:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bb5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bb8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bbb:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100bc0:	e8 2b fe ff ff       	call   f01009f0 <stab_binsearch>

	if (lfun <= rfun) {
f0100bc5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100bc8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100bcb:	39 d0                	cmp    %edx,%eax
f0100bcd:	7f 3d                	jg     f0100c0c <debuginfo_eip+0x13f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bcf:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100bd2:	8d b9 50 23 10 f0    	lea    -0xfefdcb0(%ecx),%edi
f0100bd8:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100bdb:	8b 89 50 23 10 f0    	mov    -0xfefdcb0(%ecx),%ecx
f0100be1:	bf 56 79 10 f0       	mov    $0xf0107956,%edi
f0100be6:	81 ef 29 60 10 f0    	sub    $0xf0106029,%edi
f0100bec:	39 f9                	cmp    %edi,%ecx
f0100bee:	73 09                	jae    f0100bf9 <debuginfo_eip+0x12c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bf0:	81 c1 29 60 10 f0    	add    $0xf0106029,%ecx
f0100bf6:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bf9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100bfc:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bff:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c02:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c04:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c07:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c0a:	eb 0f                	jmp    f0100c1b <debuginfo_eip+0x14e>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100c0c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c12:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c15:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c18:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c1b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c22:	00 
f0100c23:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c26:	89 04 24             	mov    %eax,(%esp)
f0100c29:	e8 3d 0a 00 00       	call   f010166b <strfind>
f0100c2e:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c31:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100c34:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c38:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c3f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c42:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c45:	b8 50 23 10 f0       	mov    $0xf0102350,%eax
f0100c4a:	e8 a1 fd ff ff       	call   f01009f0 <stab_binsearch>
	if( lline <= rline)
f0100c4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c52:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c55:	0f 8f 12 01 00 00    	jg     f0100d6d <debuginfo_eip+0x2a0>
	{
		info->eip_line = stabs[lline].n_desc;
f0100c5b:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c5e:	0f b7 80 56 23 10 f0 	movzwl -0xfefdcaa(%eax),%eax
f0100c65:	89 43 04             	mov    %eax,0x4(%ebx)
	}
	else
		return -1;

		cprintf ("\n\t %s:%d:  %.*s+%d",info->eip_file, info->eip_line, info->eip_fn_namelen, info->eip_fn_name, addr == info->eip_fn_addr ? 0 :addr);
f0100c68:	39 73 10             	cmp    %esi,0x10(%ebx)
f0100c6b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100c70:	0f 44 f2             	cmove  %edx,%esi
f0100c73:	89 74 24 14          	mov    %esi,0x14(%esp)
f0100c77:	8b 53 08             	mov    0x8(%ebx),%edx
f0100c7a:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100c7e:	8b 53 0c             	mov    0xc(%ebx),%edx
f0100c81:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c89:	8b 03                	mov    (%ebx),%eax
f0100c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8f:	c7 04 24 29 21 10 f0 	movl   $0xf0102129,(%esp)
f0100c96:	e8 37 fd ff ff       	call   f01009d2 <cprintf>
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c9e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ca1:	39 f0                	cmp    %esi,%eax
f0100ca3:	7c 63                	jl     f0100d08 <debuginfo_eip+0x23b>
	       && stabs[lline].n_type != N_SOL
f0100ca5:	6b f8 0c             	imul   $0xc,%eax,%edi
f0100ca8:	81 c7 50 23 10 f0    	add    $0xf0102350,%edi
f0100cae:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f0100cb2:	80 f9 84             	cmp    $0x84,%cl
f0100cb5:	74 32                	je     f0100ce9 <debuginfo_eip+0x21c>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100cb7:	8d 50 ff             	lea    -0x1(%eax),%edx
f0100cba:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100cbd:	81 c2 50 23 10 f0    	add    $0xf0102350,%edx
f0100cc3:	eb 15                	jmp    f0100cda <debuginfo_eip+0x20d>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cc5:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cc8:	39 f0                	cmp    %esi,%eax
f0100cca:	7c 3c                	jl     f0100d08 <debuginfo_eip+0x23b>
	       && stabs[lline].n_type != N_SOL
f0100ccc:	89 d7                	mov    %edx,%edi
f0100cce:	83 ea 0c             	sub    $0xc,%edx
f0100cd1:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f0100cd5:	80 f9 84             	cmp    $0x84,%cl
f0100cd8:	74 0f                	je     f0100ce9 <debuginfo_eip+0x21c>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cda:	80 f9 64             	cmp    $0x64,%cl
f0100cdd:	75 e6                	jne    f0100cc5 <debuginfo_eip+0x1f8>
f0100cdf:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f0100ce3:	74 e0                	je     f0100cc5 <debuginfo_eip+0x1f8>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ce5:	39 c6                	cmp    %eax,%esi
f0100ce7:	7f 1f                	jg     f0100d08 <debuginfo_eip+0x23b>
f0100ce9:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100cec:	8b 80 50 23 10 f0    	mov    -0xfefdcb0(%eax),%eax
f0100cf2:	ba 56 79 10 f0       	mov    $0xf0107956,%edx
f0100cf7:	81 ea 29 60 10 f0    	sub    $0xf0106029,%edx
f0100cfd:	39 d0                	cmp    %edx,%eax
f0100cff:	73 07                	jae    f0100d08 <debuginfo_eip+0x23b>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d01:	05 29 60 10 f0       	add    $0xf0106029,%eax
f0100d06:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d08:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d0b:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d0e:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d13:	39 ca                	cmp    %ecx,%edx
f0100d15:	7d 70                	jge    f0100d87 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
f0100d17:	8d 42 01             	lea    0x1(%edx),%eax
f0100d1a:	39 c1                	cmp    %eax,%ecx
f0100d1c:	7e 56                	jle    f0100d74 <debuginfo_eip+0x2a7>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d1e:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d21:	80 b8 54 23 10 f0 a0 	cmpb   $0xa0,-0xfefdcac(%eax)
f0100d28:	75 51                	jne    f0100d7b <debuginfo_eip+0x2ae>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100d2a:	8d 42 02             	lea    0x2(%edx),%eax
f0100d2d:	6b d2 0c             	imul   $0xc,%edx,%edx
f0100d30:	81 c2 50 23 10 f0    	add    $0xf0102350,%edx
f0100d36:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d38:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d3c:	39 f8                	cmp    %edi,%eax
f0100d3e:	74 42                	je     f0100d82 <debuginfo_eip+0x2b5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d40:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0100d44:	83 c0 01             	add    $0x1,%eax
f0100d47:	83 c2 0c             	add    $0xc,%edx
f0100d4a:	89 f1                	mov    %esi,%ecx
f0100d4c:	80 f9 a0             	cmp    $0xa0,%cl
f0100d4f:	74 e7                	je     f0100d38 <debuginfo_eip+0x26b>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d51:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d56:	eb 2f                	jmp    f0100d87 <debuginfo_eip+0x2ba>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d58:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d5d:	eb 28                	jmp    f0100d87 <debuginfo_eip+0x2ba>
f0100d5f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d64:	eb 21                	jmp    f0100d87 <debuginfo_eip+0x2ba>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d66:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d6b:	eb 1a                	jmp    f0100d87 <debuginfo_eip+0x2ba>
	if( lline <= rline)
	{
		info->eip_line = stabs[lline].n_desc;
	}
	else
		return -1;
f0100d6d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d72:	eb 13                	jmp    f0100d87 <debuginfo_eip+0x2ba>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d74:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d79:	eb 0c                	jmp    f0100d87 <debuginfo_eip+0x2ba>
f0100d7b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d80:	eb 05                	jmp    f0100d87 <debuginfo_eip+0x2ba>
f0100d82:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d87:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100d8a:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100d8d:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100d90:	89 ec                	mov    %ebp,%esp
f0100d92:	5d                   	pop    %ebp
f0100d93:	c3                   	ret    
f0100d94:	66 90                	xchg   %ax,%ax
f0100d96:	66 90                	xchg   %ax,%ax
f0100d98:	66 90                	xchg   %ax,%ax
f0100d9a:	66 90                	xchg   %ax,%ax
f0100d9c:	66 90                	xchg   %ax,%ax
f0100d9e:	66 90                	xchg   %ax,%ax

f0100da0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100da0:	55                   	push   %ebp
f0100da1:	89 e5                	mov    %esp,%ebp
f0100da3:	57                   	push   %edi
f0100da4:	56                   	push   %esi
f0100da5:	53                   	push   %ebx
f0100da6:	83 ec 4c             	sub    $0x4c,%esp
f0100da9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100dac:	89 d7                	mov    %edx,%edi
f0100dae:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100db1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100db4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100db7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100dba:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dbf:	39 d8                	cmp    %ebx,%eax
f0100dc1:	72 17                	jb     f0100dda <printnum+0x3a>
f0100dc3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100dc6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100dc9:	76 0f                	jbe    f0100dda <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100dcb:	8b 75 14             	mov    0x14(%ebp),%esi
f0100dce:	83 ee 01             	sub    $0x1,%esi
f0100dd1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100dd4:	85 f6                	test   %esi,%esi
f0100dd6:	7f 63                	jg     f0100e3b <printnum+0x9b>
f0100dd8:	eb 75                	jmp    f0100e4f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dda:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100ddd:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100de1:	8b 45 14             	mov    0x14(%ebp),%eax
f0100de4:	83 e8 01             	sub    $0x1,%eax
f0100de7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100deb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dee:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100df2:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100df6:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100dfa:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100dfd:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100e00:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e07:	00 
f0100e08:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100e0b:	89 1c 24             	mov    %ebx,(%esp)
f0100e0e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e11:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e15:	e8 d6 0a 00 00       	call   f01018f0 <__udivdi3>
f0100e1a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100e1d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100e20:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e24:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e28:	89 04 24             	mov    %eax,(%esp)
f0100e2b:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e2f:	89 fa                	mov    %edi,%edx
f0100e31:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e34:	e8 67 ff ff ff       	call   f0100da0 <printnum>
f0100e39:	eb 14                	jmp    f0100e4f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e3b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e3f:	8b 45 18             	mov    0x18(%ebp),%eax
f0100e42:	89 04 24             	mov    %eax,(%esp)
f0100e45:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e47:	83 ee 01             	sub    $0x1,%esi
f0100e4a:	75 ef                	jne    f0100e3b <printnum+0x9b>
f0100e4c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e4f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e53:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100e57:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100e5a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e5e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e65:	00 
f0100e66:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100e69:	89 1c 24             	mov    %ebx,(%esp)
f0100e6c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100e6f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e73:	e8 c8 0b 00 00       	call   f0101a40 <__umoddi3>
f0100e78:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7c:	0f be 80 3c 21 10 f0 	movsbl -0xfefdec4(%eax),%eax
f0100e83:	89 04 24             	mov    %eax,(%esp)
f0100e86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e89:	ff d0                	call   *%eax
}
f0100e8b:	83 c4 4c             	add    $0x4c,%esp
f0100e8e:	5b                   	pop    %ebx
f0100e8f:	5e                   	pop    %esi
f0100e90:	5f                   	pop    %edi
f0100e91:	5d                   	pop    %ebp
f0100e92:	c3                   	ret    

f0100e93 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100e93:	55                   	push   %ebp
f0100e94:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100e96:	83 fa 01             	cmp    $0x1,%edx
f0100e99:	7e 0e                	jle    f0100ea9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100e9b:	8b 10                	mov    (%eax),%edx
f0100e9d:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100ea0:	89 08                	mov    %ecx,(%eax)
f0100ea2:	8b 02                	mov    (%edx),%eax
f0100ea4:	8b 52 04             	mov    0x4(%edx),%edx
f0100ea7:	eb 22                	jmp    f0100ecb <getuint+0x38>
	else if (lflag)
f0100ea9:	85 d2                	test   %edx,%edx
f0100eab:	74 10                	je     f0100ebd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ead:	8b 10                	mov    (%eax),%edx
f0100eaf:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100eb2:	89 08                	mov    %ecx,(%eax)
f0100eb4:	8b 02                	mov    (%edx),%eax
f0100eb6:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ebb:	eb 0e                	jmp    f0100ecb <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100ebd:	8b 10                	mov    (%eax),%edx
f0100ebf:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ec2:	89 08                	mov    %ecx,(%eax)
f0100ec4:	8b 02                	mov    (%edx),%eax
f0100ec6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100ecb:	5d                   	pop    %ebp
f0100ecc:	c3                   	ret    

f0100ecd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ecd:	55                   	push   %ebp
f0100ece:	89 e5                	mov    %esp,%ebp
f0100ed0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ed3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ed7:	8b 10                	mov    (%eax),%edx
f0100ed9:	3b 50 04             	cmp    0x4(%eax),%edx
f0100edc:	73 0a                	jae    f0100ee8 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ede:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100ee1:	88 0a                	mov    %cl,(%edx)
f0100ee3:	83 c2 01             	add    $0x1,%edx
f0100ee6:	89 10                	mov    %edx,(%eax)
}
f0100ee8:	5d                   	pop    %ebp
f0100ee9:	c3                   	ret    

f0100eea <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eea:	55                   	push   %ebp
f0100eeb:	89 e5                	mov    %esp,%ebp
f0100eed:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ef0:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100ef3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef7:	8b 45 10             	mov    0x10(%ebp),%eax
f0100efa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100efe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f05:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f08:	89 04 24             	mov    %eax,(%esp)
f0100f0b:	e8 02 00 00 00       	call   f0100f12 <vprintfmt>
	va_end(ap);
}
f0100f10:	c9                   	leave  
f0100f11:	c3                   	ret    

f0100f12 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f12:	55                   	push   %ebp
f0100f13:	89 e5                	mov    %esp,%ebp
f0100f15:	57                   	push   %edi
f0100f16:	56                   	push   %esi
f0100f17:	53                   	push   %ebx
f0100f18:	83 ec 4c             	sub    $0x4c,%esp
f0100f1b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f1e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100f21:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f24:	eb 11                	jmp    f0100f37 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100f26:	85 c0                	test   %eax,%eax
f0100f28:	0f 84 ff 03 00 00    	je     f010132d <vprintfmt+0x41b>
				return;
			putch(ch, putdat);
f0100f2e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f32:	89 04 24             	mov    %eax,(%esp)
f0100f35:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100f37:	0f b6 07             	movzbl (%edi),%eax
f0100f3a:	83 c7 01             	add    $0x1,%edi
f0100f3d:	83 f8 25             	cmp    $0x25,%eax
f0100f40:	75 e4                	jne    f0100f26 <vprintfmt+0x14>
f0100f42:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100f46:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100f4d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100f54:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100f5b:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f60:	eb 2b                	jmp    f0100f8d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f62:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100f65:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100f69:	eb 22                	jmp    f0100f8d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100f6e:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0100f72:	eb 19                	jmp    f0100f8d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f74:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100f77:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100f7e:	eb 0d                	jmp    f0100f8d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100f80:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100f83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100f86:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8d:	0f b6 0f             	movzbl (%edi),%ecx
f0100f90:	8d 47 01             	lea    0x1(%edi),%eax
f0100f93:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f96:	0f b6 07             	movzbl (%edi),%eax
f0100f99:	83 e8 23             	sub    $0x23,%eax
f0100f9c:	3c 55                	cmp    $0x55,%al
f0100f9e:	0f 87 64 03 00 00    	ja     f0101308 <vprintfmt+0x3f6>
f0100fa4:	0f b6 c0             	movzbl %al,%eax
f0100fa7:	ff 24 85 cc 21 10 f0 	jmp    *-0xfefde34(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100fae:	83 e9 30             	sub    $0x30,%ecx
f0100fb1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f0100fb4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f0100fb8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100fbb:	83 f9 09             	cmp    $0x9,%ecx
f0100fbe:	77 57                	ja     f0101017 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fc3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100fc6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100fc9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100fcc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100fcf:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100fd3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100fd6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100fd9:	83 f9 09             	cmp    $0x9,%ecx
f0100fdc:	76 eb                	jbe    f0100fc9 <vprintfmt+0xb7>
f0100fde:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100fe1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100fe4:	eb 34                	jmp    f010101a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100fe6:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe9:	8d 48 04             	lea    0x4(%eax),%ecx
f0100fec:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100fef:	8b 00                	mov    (%eax),%eax
f0100ff1:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ff7:	eb 21                	jmp    f010101a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0100ff9:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100ffd:	0f 88 71 ff ff ff    	js     f0100f74 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101003:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101006:	eb 85                	jmp    f0100f8d <vprintfmt+0x7b>
f0101008:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010100b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0101012:	e9 76 ff ff ff       	jmp    f0100f8d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101017:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010101a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010101e:	0f 89 69 ff ff ff    	jns    f0100f8d <vprintfmt+0x7b>
f0101024:	e9 57 ff ff ff       	jmp    f0100f80 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101029:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010102c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010102f:	e9 59 ff ff ff       	jmp    f0100f8d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101034:	8b 45 14             	mov    0x14(%ebp),%eax
f0101037:	8d 50 04             	lea    0x4(%eax),%edx
f010103a:	89 55 14             	mov    %edx,0x14(%ebp)
f010103d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101041:	8b 00                	mov    (%eax),%eax
f0101043:	89 04 24             	mov    %eax,(%esp)
f0101046:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101048:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010104b:	e9 e7 fe ff ff       	jmp    f0100f37 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101050:	8b 45 14             	mov    0x14(%ebp),%eax
f0101053:	8d 50 04             	lea    0x4(%eax),%edx
f0101056:	89 55 14             	mov    %edx,0x14(%ebp)
f0101059:	8b 00                	mov    (%eax),%eax
f010105b:	89 c2                	mov    %eax,%edx
f010105d:	c1 fa 1f             	sar    $0x1f,%edx
f0101060:	31 d0                	xor    %edx,%eax
f0101062:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101064:	83 f8 06             	cmp    $0x6,%eax
f0101067:	7f 0b                	jg     f0101074 <vprintfmt+0x162>
f0101069:	8b 14 85 24 23 10 f0 	mov    -0xfefdcdc(,%eax,4),%edx
f0101070:	85 d2                	test   %edx,%edx
f0101072:	75 20                	jne    f0101094 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0101074:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101078:	c7 44 24 08 54 21 10 	movl   $0xf0102154,0x8(%esp)
f010107f:	f0 
f0101080:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101084:	89 34 24             	mov    %esi,(%esp)
f0101087:	e8 5e fe ff ff       	call   f0100eea <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010108c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010108f:	e9 a3 fe ff ff       	jmp    f0100f37 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0101094:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101098:	c7 44 24 08 5d 21 10 	movl   $0xf010215d,0x8(%esp)
f010109f:	f0 
f01010a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a4:	89 34 24             	mov    %esi,(%esp)
f01010a7:	e8 3e fe ff ff       	call   f0100eea <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010af:	e9 83 fe ff ff       	jmp    f0100f37 <vprintfmt+0x25>
f01010b4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01010b7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01010ba:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01010bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c0:	8d 50 04             	lea    0x4(%eax),%edx
f01010c3:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01010c8:	85 ff                	test   %edi,%edi
f01010ca:	b8 4d 21 10 f0       	mov    $0xf010214d,%eax
f01010cf:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01010d2:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01010d6:	74 06                	je     f01010de <vprintfmt+0x1cc>
f01010d8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01010dc:	7f 16                	jg     f01010f4 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010de:	0f b6 17             	movzbl (%edi),%edx
f01010e1:	0f be c2             	movsbl %dl,%eax
f01010e4:	83 c7 01             	add    $0x1,%edi
f01010e7:	85 c0                	test   %eax,%eax
f01010e9:	0f 85 9f 00 00 00    	jne    f010118e <vprintfmt+0x27c>
f01010ef:	e9 8b 00 00 00       	jmp    f010117f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01010f4:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01010f8:	89 3c 24             	mov    %edi,(%esp)
f01010fb:	e8 b2 03 00 00       	call   f01014b2 <strnlen>
f0101100:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101103:	29 c2                	sub    %eax,%edx
f0101105:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0101108:	85 d2                	test   %edx,%edx
f010110a:	7e d2                	jle    f01010de <vprintfmt+0x1cc>
					putch(padc, putdat);
f010110c:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f0101110:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101113:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0101116:	89 d7                	mov    %edx,%edi
f0101118:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010111c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010111f:	89 04 24             	mov    %eax,(%esp)
f0101122:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101124:	83 ef 01             	sub    $0x1,%edi
f0101127:	75 ef                	jne    f0101118 <vprintfmt+0x206>
f0101129:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010112c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010112f:	eb ad                	jmp    f01010de <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101131:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101135:	74 20                	je     f0101157 <vprintfmt+0x245>
f0101137:	0f be d2             	movsbl %dl,%edx
f010113a:	83 ea 20             	sub    $0x20,%edx
f010113d:	83 fa 5e             	cmp    $0x5e,%edx
f0101140:	76 15                	jbe    f0101157 <vprintfmt+0x245>
					putch('?', putdat);
f0101142:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101145:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101149:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101150:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101153:	ff d1                	call   *%ecx
f0101155:	eb 0f                	jmp    f0101166 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0101157:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010115a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010115e:	89 04 24             	mov    %eax,(%esp)
f0101161:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101164:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101166:	83 eb 01             	sub    $0x1,%ebx
f0101169:	0f b6 17             	movzbl (%edi),%edx
f010116c:	0f be c2             	movsbl %dl,%eax
f010116f:	83 c7 01             	add    $0x1,%edi
f0101172:	85 c0                	test   %eax,%eax
f0101174:	75 24                	jne    f010119a <vprintfmt+0x288>
f0101176:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0101179:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010117c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010117f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101182:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101186:	0f 8e ab fd ff ff    	jle    f0100f37 <vprintfmt+0x25>
f010118c:	eb 20                	jmp    f01011ae <vprintfmt+0x29c>
f010118e:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0101191:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101194:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101197:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010119a:	85 f6                	test   %esi,%esi
f010119c:	78 93                	js     f0101131 <vprintfmt+0x21f>
f010119e:	83 ee 01             	sub    $0x1,%esi
f01011a1:	79 8e                	jns    f0101131 <vprintfmt+0x21f>
f01011a3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01011a6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01011a9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01011ac:	eb d1                	jmp    f010117f <vprintfmt+0x26d>
f01011ae:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01011b1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011b5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01011bc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01011be:	83 ef 01             	sub    $0x1,%edi
f01011c1:	75 ee                	jne    f01011b1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01011c6:	e9 6c fd ff ff       	jmp    f0100f37 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01011cb:	83 fa 01             	cmp    $0x1,%edx
f01011ce:	66 90                	xchg   %ax,%ax
f01011d0:	7e 16                	jle    f01011e8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f01011d2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d5:	8d 50 08             	lea    0x8(%eax),%edx
f01011d8:	89 55 14             	mov    %edx,0x14(%ebp)
f01011db:	8b 10                	mov    (%eax),%edx
f01011dd:	8b 48 04             	mov    0x4(%eax),%ecx
f01011e0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01011e3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01011e6:	eb 32                	jmp    f010121a <vprintfmt+0x308>
	else if (lflag)
f01011e8:	85 d2                	test   %edx,%edx
f01011ea:	74 18                	je     f0101204 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f01011ec:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ef:	8d 50 04             	lea    0x4(%eax),%edx
f01011f2:	89 55 14             	mov    %edx,0x14(%ebp)
f01011f5:	8b 00                	mov    (%eax),%eax
f01011f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01011fa:	89 c1                	mov    %eax,%ecx
f01011fc:	c1 f9 1f             	sar    $0x1f,%ecx
f01011ff:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101202:	eb 16                	jmp    f010121a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0101204:	8b 45 14             	mov    0x14(%ebp),%eax
f0101207:	8d 50 04             	lea    0x4(%eax),%edx
f010120a:	89 55 14             	mov    %edx,0x14(%ebp)
f010120d:	8b 00                	mov    (%eax),%eax
f010120f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101212:	89 c7                	mov    %eax,%edi
f0101214:	c1 ff 1f             	sar    $0x1f,%edi
f0101217:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010121a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010121d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101220:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101225:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101229:	0f 89 9d 00 00 00    	jns    f01012cc <vprintfmt+0x3ba>
				putch('-', putdat);
f010122f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101233:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010123a:	ff d6                	call   *%esi
				num = -(long long) num;
f010123c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010123f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101242:	f7 d8                	neg    %eax
f0101244:	83 d2 00             	adc    $0x0,%edx
f0101247:	f7 da                	neg    %edx
			}
			base = 10;
f0101249:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010124e:	eb 7c                	jmp    f01012cc <vprintfmt+0x3ba>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101250:	8d 45 14             	lea    0x14(%ebp),%eax
f0101253:	e8 3b fc ff ff       	call   f0100e93 <getuint>
			base = 10;
f0101258:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010125d:	eb 6d                	jmp    f01012cc <vprintfmt+0x3ba>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010125f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101263:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010126a:	ff d6                	call   *%esi
			putch('X', putdat);
f010126c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101270:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101277:	ff d6                	call   *%esi
			putch('X', putdat);
f0101279:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010127d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0101284:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101286:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0101289:	e9 a9 fc ff ff       	jmp    f0100f37 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010128e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101292:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101299:	ff d6                	call   *%esi
			putch('x', putdat);
f010129b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010129f:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01012a6:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ab:	8d 50 04             	lea    0x4(%eax),%edx
f01012ae:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01012b1:	8b 00                	mov    (%eax),%eax
f01012b3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01012b8:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01012bd:	eb 0d                	jmp    f01012cc <vprintfmt+0x3ba>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01012bf:	8d 45 14             	lea    0x14(%ebp),%eax
f01012c2:	e8 cc fb ff ff       	call   f0100e93 <getuint>
			base = 16;
f01012c7:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012cc:	0f be 7d e0          	movsbl -0x20(%ebp),%edi
f01012d0:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01012d4:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01012d7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012db:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01012df:	89 04 24             	mov    %eax,(%esp)
f01012e2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01012e6:	89 da                	mov    %ebx,%edx
f01012e8:	89 f0                	mov    %esi,%eax
f01012ea:	e8 b1 fa ff ff       	call   f0100da0 <printnum>
			break;
f01012ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01012f2:	e9 40 fc ff ff       	jmp    f0100f37 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012fb:	89 0c 24             	mov    %ecx,(%esp)
f01012fe:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101300:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101303:	e9 2f fc ff ff       	jmp    f0100f37 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101308:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010130c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101313:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101315:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101319:	0f 84 18 fc ff ff    	je     f0100f37 <vprintfmt+0x25>
f010131f:	83 ef 01             	sub    $0x1,%edi
f0101322:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101326:	75 f7                	jne    f010131f <vprintfmt+0x40d>
f0101328:	e9 0a fc ff ff       	jmp    f0100f37 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010132d:	83 c4 4c             	add    $0x4c,%esp
f0101330:	5b                   	pop    %ebx
f0101331:	5e                   	pop    %esi
f0101332:	5f                   	pop    %edi
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	83 ec 28             	sub    $0x28,%esp
f010133b:	8b 45 08             	mov    0x8(%ebp),%eax
f010133e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101341:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101344:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101348:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010134b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101352:	85 d2                	test   %edx,%edx
f0101354:	7e 30                	jle    f0101386 <vsnprintf+0x51>
f0101356:	85 c0                	test   %eax,%eax
f0101358:	74 2c                	je     f0101386 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010135a:	8b 45 14             	mov    0x14(%ebp),%eax
f010135d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101361:	8b 45 10             	mov    0x10(%ebp),%eax
f0101364:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101368:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010136b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010136f:	c7 04 24 cd 0e 10 f0 	movl   $0xf0100ecd,(%esp)
f0101376:	e8 97 fb ff ff       	call   f0100f12 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010137b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010137e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101381:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101384:	eb 05                	jmp    f010138b <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101386:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010138b:	c9                   	leave  
f010138c:	c3                   	ret    

f010138d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010138d:	55                   	push   %ebp
f010138e:	89 e5                	mov    %esp,%ebp
f0101390:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101393:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101396:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010139a:	8b 45 10             	mov    0x10(%ebp),%eax
f010139d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013a1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ab:	89 04 24             	mov    %eax,(%esp)
f01013ae:	e8 82 ff ff ff       	call   f0101335 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013b3:	c9                   	leave  
f01013b4:	c3                   	ret    
f01013b5:	66 90                	xchg   %ax,%ax
f01013b7:	66 90                	xchg   %ax,%ax
f01013b9:	66 90                	xchg   %ax,%ax
f01013bb:	66 90                	xchg   %ax,%ax
f01013bd:	66 90                	xchg   %ax,%ax
f01013bf:	90                   	nop

f01013c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013c0:	55                   	push   %ebp
f01013c1:	89 e5                	mov    %esp,%ebp
f01013c3:	57                   	push   %edi
f01013c4:	56                   	push   %esi
f01013c5:	53                   	push   %ebx
f01013c6:	83 ec 1c             	sub    $0x1c,%esp
f01013c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013cc:	85 c0                	test   %eax,%eax
f01013ce:	74 10                	je     f01013e0 <readline+0x20>
		cprintf("%s", prompt);
f01013d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013d4:	c7 04 24 5d 21 10 f0 	movl   $0xf010215d,(%esp)
f01013db:	e8 f2 f5 ff ff       	call   f01009d2 <cprintf>

	i = 0;
	echoing = iscons(0);
f01013e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013e7:	e8 8e f2 ff ff       	call   f010067a <iscons>
f01013ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013f3:	e8 71 f2 ff ff       	call   f0100669 <getchar>
f01013f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013fa:	85 c0                	test   %eax,%eax
f01013fc:	79 17                	jns    f0101415 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101402:	c7 04 24 40 23 10 f0 	movl   $0xf0102340,(%esp)
f0101409:	e8 c4 f5 ff ff       	call   f01009d2 <cprintf>
			return NULL;
f010140e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101413:	eb 6d                	jmp    f0101482 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101415:	83 f8 7f             	cmp    $0x7f,%eax
f0101418:	74 05                	je     f010141f <readline+0x5f>
f010141a:	83 f8 08             	cmp    $0x8,%eax
f010141d:	75 19                	jne    f0101438 <readline+0x78>
f010141f:	85 f6                	test   %esi,%esi
f0101421:	7e 15                	jle    f0101438 <readline+0x78>
			if (echoing)
f0101423:	85 ff                	test   %edi,%edi
f0101425:	74 0c                	je     f0101433 <readline+0x73>
				cputchar('\b');
f0101427:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010142e:	e8 26 f2 ff ff       	call   f0100659 <cputchar>
			i--;
f0101433:	83 ee 01             	sub    $0x1,%esi
f0101436:	eb bb                	jmp    f01013f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101438:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010143e:	7f 1c                	jg     f010145c <readline+0x9c>
f0101440:	83 fb 1f             	cmp    $0x1f,%ebx
f0101443:	7e 17                	jle    f010145c <readline+0x9c>
			if (echoing)
f0101445:	85 ff                	test   %edi,%edi
f0101447:	74 08                	je     f0101451 <readline+0x91>
				cputchar(c);
f0101449:	89 1c 24             	mov    %ebx,(%esp)
f010144c:	e8 08 f2 ff ff       	call   f0100659 <cputchar>
			buf[i++] = c;
f0101451:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101457:	83 c6 01             	add    $0x1,%esi
f010145a:	eb 97                	jmp    f01013f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010145c:	83 fb 0d             	cmp    $0xd,%ebx
f010145f:	74 05                	je     f0101466 <readline+0xa6>
f0101461:	83 fb 0a             	cmp    $0xa,%ebx
f0101464:	75 8d                	jne    f01013f3 <readline+0x33>
			if (echoing)
f0101466:	85 ff                	test   %edi,%edi
f0101468:	74 0c                	je     f0101476 <readline+0xb6>
				cputchar('\n');
f010146a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101471:	e8 e3 f1 ff ff       	call   f0100659 <cputchar>
			buf[i] = 0;
f0101476:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010147d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101482:	83 c4 1c             	add    $0x1c,%esp
f0101485:	5b                   	pop    %ebx
f0101486:	5e                   	pop    %esi
f0101487:	5f                   	pop    %edi
f0101488:	5d                   	pop    %ebp
f0101489:	c3                   	ret    
f010148a:	66 90                	xchg   %ax,%ax
f010148c:	66 90                	xchg   %ax,%ax
f010148e:	66 90                	xchg   %ax,%ax

f0101490 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101490:	55                   	push   %ebp
f0101491:	89 e5                	mov    %esp,%ebp
f0101493:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101496:	80 3a 00             	cmpb   $0x0,(%edx)
f0101499:	74 10                	je     f01014ab <strlen+0x1b>
f010149b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01014a0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014a3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014a7:	75 f7                	jne    f01014a0 <strlen+0x10>
f01014a9:	eb 05                	jmp    f01014b0 <strlen+0x20>
f01014ab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    

f01014b2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014b2:	55                   	push   %ebp
f01014b3:	89 e5                	mov    %esp,%ebp
f01014b5:	53                   	push   %ebx
f01014b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014b9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014bc:	85 c9                	test   %ecx,%ecx
f01014be:	74 1c                	je     f01014dc <strnlen+0x2a>
f01014c0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014c3:	74 1e                	je     f01014e3 <strnlen+0x31>
f01014c5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01014ca:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014cc:	39 ca                	cmp    %ecx,%edx
f01014ce:	74 18                	je     f01014e8 <strnlen+0x36>
f01014d0:	83 c2 01             	add    $0x1,%edx
f01014d3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01014d8:	75 f0                	jne    f01014ca <strnlen+0x18>
f01014da:	eb 0c                	jmp    f01014e8 <strnlen+0x36>
f01014dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01014e1:	eb 05                	jmp    f01014e8 <strnlen+0x36>
f01014e3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01014e8:	5b                   	pop    %ebx
f01014e9:	5d                   	pop    %ebp
f01014ea:	c3                   	ret    

f01014eb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014eb:	55                   	push   %ebp
f01014ec:	89 e5                	mov    %esp,%ebp
f01014ee:	53                   	push   %ebx
f01014ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014f5:	89 c2                	mov    %eax,%edx
f01014f7:	0f b6 19             	movzbl (%ecx),%ebx
f01014fa:	88 1a                	mov    %bl,(%edx)
f01014fc:	83 c2 01             	add    $0x1,%edx
f01014ff:	83 c1 01             	add    $0x1,%ecx
f0101502:	84 db                	test   %bl,%bl
f0101504:	75 f1                	jne    f01014f7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101506:	5b                   	pop    %ebx
f0101507:	5d                   	pop    %ebp
f0101508:	c3                   	ret    

f0101509 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101509:	55                   	push   %ebp
f010150a:	89 e5                	mov    %esp,%ebp
f010150c:	53                   	push   %ebx
f010150d:	83 ec 08             	sub    $0x8,%esp
f0101510:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101513:	89 1c 24             	mov    %ebx,(%esp)
f0101516:	e8 75 ff ff ff       	call   f0101490 <strlen>
	strcpy(dst + len, src);
f010151b:	8b 55 0c             	mov    0xc(%ebp),%edx
f010151e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101522:	01 d8                	add    %ebx,%eax
f0101524:	89 04 24             	mov    %eax,(%esp)
f0101527:	e8 bf ff ff ff       	call   f01014eb <strcpy>
	return dst;
}
f010152c:	89 d8                	mov    %ebx,%eax
f010152e:	83 c4 08             	add    $0x8,%esp
f0101531:	5b                   	pop    %ebx
f0101532:	5d                   	pop    %ebp
f0101533:	c3                   	ret    

f0101534 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101534:	55                   	push   %ebp
f0101535:	89 e5                	mov    %esp,%ebp
f0101537:	56                   	push   %esi
f0101538:	53                   	push   %ebx
f0101539:	8b 75 08             	mov    0x8(%ebp),%esi
f010153c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010153f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101542:	85 db                	test   %ebx,%ebx
f0101544:	74 16                	je     f010155c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0101546:	01 f3                	add    %esi,%ebx
f0101548:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f010154a:	0f b6 02             	movzbl (%edx),%eax
f010154d:	88 01                	mov    %al,(%ecx)
f010154f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101552:	80 3a 01             	cmpb   $0x1,(%edx)
f0101555:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101558:	39 d9                	cmp    %ebx,%ecx
f010155a:	75 ee                	jne    f010154a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f010155c:	89 f0                	mov    %esi,%eax
f010155e:	5b                   	pop    %ebx
f010155f:	5e                   	pop    %esi
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    

f0101562 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101562:	55                   	push   %ebp
f0101563:	89 e5                	mov    %esp,%ebp
f0101565:	57                   	push   %edi
f0101566:	56                   	push   %esi
f0101567:	53                   	push   %ebx
f0101568:	8b 7d 08             	mov    0x8(%ebp),%edi
f010156b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010156e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101571:	89 f8                	mov    %edi,%eax
f0101573:	85 f6                	test   %esi,%esi
f0101575:	74 33                	je     f01015aa <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0101577:	83 fe 01             	cmp    $0x1,%esi
f010157a:	74 25                	je     f01015a1 <strlcpy+0x3f>
f010157c:	0f b6 0b             	movzbl (%ebx),%ecx
f010157f:	84 c9                	test   %cl,%cl
f0101581:	74 22                	je     f01015a5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101583:	83 ee 02             	sub    $0x2,%esi
f0101586:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010158b:	88 08                	mov    %cl,(%eax)
f010158d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101590:	39 f2                	cmp    %esi,%edx
f0101592:	74 13                	je     f01015a7 <strlcpy+0x45>
f0101594:	83 c2 01             	add    $0x1,%edx
f0101597:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010159b:	84 c9                	test   %cl,%cl
f010159d:	75 ec                	jne    f010158b <strlcpy+0x29>
f010159f:	eb 06                	jmp    f01015a7 <strlcpy+0x45>
f01015a1:	89 f8                	mov    %edi,%eax
f01015a3:	eb 02                	jmp    f01015a7 <strlcpy+0x45>
f01015a5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f01015a7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015aa:	29 f8                	sub    %edi,%eax
}
f01015ac:	5b                   	pop    %ebx
f01015ad:	5e                   	pop    %esi
f01015ae:	5f                   	pop    %edi
f01015af:	5d                   	pop    %ebp
f01015b0:	c3                   	ret    

f01015b1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015b1:	55                   	push   %ebp
f01015b2:	89 e5                	mov    %esp,%ebp
f01015b4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015ba:	0f b6 01             	movzbl (%ecx),%eax
f01015bd:	84 c0                	test   %al,%al
f01015bf:	74 15                	je     f01015d6 <strcmp+0x25>
f01015c1:	3a 02                	cmp    (%edx),%al
f01015c3:	75 11                	jne    f01015d6 <strcmp+0x25>
		p++, q++;
f01015c5:	83 c1 01             	add    $0x1,%ecx
f01015c8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015cb:	0f b6 01             	movzbl (%ecx),%eax
f01015ce:	84 c0                	test   %al,%al
f01015d0:	74 04                	je     f01015d6 <strcmp+0x25>
f01015d2:	3a 02                	cmp    (%edx),%al
f01015d4:	74 ef                	je     f01015c5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015d6:	0f b6 c0             	movzbl %al,%eax
f01015d9:	0f b6 12             	movzbl (%edx),%edx
f01015dc:	29 d0                	sub    %edx,%eax
}
f01015de:	5d                   	pop    %ebp
f01015df:	c3                   	ret    

f01015e0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015e0:	55                   	push   %ebp
f01015e1:	89 e5                	mov    %esp,%ebp
f01015e3:	56                   	push   %esi
f01015e4:	53                   	push   %ebx
f01015e5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015eb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01015ee:	85 f6                	test   %esi,%esi
f01015f0:	74 29                	je     f010161b <strncmp+0x3b>
f01015f2:	0f b6 03             	movzbl (%ebx),%eax
f01015f5:	84 c0                	test   %al,%al
f01015f7:	74 30                	je     f0101629 <strncmp+0x49>
f01015f9:	3a 02                	cmp    (%edx),%al
f01015fb:	75 2c                	jne    f0101629 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f01015fd:	8d 43 01             	lea    0x1(%ebx),%eax
f0101600:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0101602:	89 c3                	mov    %eax,%ebx
f0101604:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101607:	39 f0                	cmp    %esi,%eax
f0101609:	74 17                	je     f0101622 <strncmp+0x42>
f010160b:	0f b6 08             	movzbl (%eax),%ecx
f010160e:	84 c9                	test   %cl,%cl
f0101610:	74 17                	je     f0101629 <strncmp+0x49>
f0101612:	83 c0 01             	add    $0x1,%eax
f0101615:	3a 0a                	cmp    (%edx),%cl
f0101617:	74 e9                	je     f0101602 <strncmp+0x22>
f0101619:	eb 0e                	jmp    f0101629 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010161b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101620:	eb 0f                	jmp    f0101631 <strncmp+0x51>
f0101622:	b8 00 00 00 00       	mov    $0x0,%eax
f0101627:	eb 08                	jmp    f0101631 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101629:	0f b6 03             	movzbl (%ebx),%eax
f010162c:	0f b6 12             	movzbl (%edx),%edx
f010162f:	29 d0                	sub    %edx,%eax
}
f0101631:	5b                   	pop    %ebx
f0101632:	5e                   	pop    %esi
f0101633:	5d                   	pop    %ebp
f0101634:	c3                   	ret    

f0101635 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101635:	55                   	push   %ebp
f0101636:	89 e5                	mov    %esp,%ebp
f0101638:	53                   	push   %ebx
f0101639:	8b 45 08             	mov    0x8(%ebp),%eax
f010163c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010163f:	0f b6 18             	movzbl (%eax),%ebx
f0101642:	84 db                	test   %bl,%bl
f0101644:	74 1d                	je     f0101663 <strchr+0x2e>
f0101646:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101648:	38 d3                	cmp    %dl,%bl
f010164a:	75 06                	jne    f0101652 <strchr+0x1d>
f010164c:	eb 1a                	jmp    f0101668 <strchr+0x33>
f010164e:	38 ca                	cmp    %cl,%dl
f0101650:	74 16                	je     f0101668 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101652:	83 c0 01             	add    $0x1,%eax
f0101655:	0f b6 10             	movzbl (%eax),%edx
f0101658:	84 d2                	test   %dl,%dl
f010165a:	75 f2                	jne    f010164e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f010165c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101661:	eb 05                	jmp    f0101668 <strchr+0x33>
f0101663:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101668:	5b                   	pop    %ebx
f0101669:	5d                   	pop    %ebp
f010166a:	c3                   	ret    

f010166b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010166b:	55                   	push   %ebp
f010166c:	89 e5                	mov    %esp,%ebp
f010166e:	53                   	push   %ebx
f010166f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101672:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101675:	0f b6 18             	movzbl (%eax),%ebx
f0101678:	84 db                	test   %bl,%bl
f010167a:	74 16                	je     f0101692 <strfind+0x27>
f010167c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f010167e:	38 d3                	cmp    %dl,%bl
f0101680:	75 06                	jne    f0101688 <strfind+0x1d>
f0101682:	eb 0e                	jmp    f0101692 <strfind+0x27>
f0101684:	38 ca                	cmp    %cl,%dl
f0101686:	74 0a                	je     f0101692 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101688:	83 c0 01             	add    $0x1,%eax
f010168b:	0f b6 10             	movzbl (%eax),%edx
f010168e:	84 d2                	test   %dl,%dl
f0101690:	75 f2                	jne    f0101684 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0101692:	5b                   	pop    %ebx
f0101693:	5d                   	pop    %ebp
f0101694:	c3                   	ret    

f0101695 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101695:	55                   	push   %ebp
f0101696:	89 e5                	mov    %esp,%ebp
f0101698:	83 ec 0c             	sub    $0xc,%esp
f010169b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010169e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016a1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016a4:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016a7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016aa:	85 c9                	test   %ecx,%ecx
f01016ac:	74 36                	je     f01016e4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016ae:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016b4:	75 28                	jne    f01016de <memset+0x49>
f01016b6:	f6 c1 03             	test   $0x3,%cl
f01016b9:	75 23                	jne    f01016de <memset+0x49>
		c &= 0xFF;
f01016bb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016bf:	89 d3                	mov    %edx,%ebx
f01016c1:	c1 e3 08             	shl    $0x8,%ebx
f01016c4:	89 d6                	mov    %edx,%esi
f01016c6:	c1 e6 18             	shl    $0x18,%esi
f01016c9:	89 d0                	mov    %edx,%eax
f01016cb:	c1 e0 10             	shl    $0x10,%eax
f01016ce:	09 f0                	or     %esi,%eax
f01016d0:	09 c2                	or     %eax,%edx
f01016d2:	89 d0                	mov    %edx,%eax
f01016d4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01016d6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01016d9:	fc                   	cld    
f01016da:	f3 ab                	rep stos %eax,%es:(%edi)
f01016dc:	eb 06                	jmp    f01016e4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016de:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016e1:	fc                   	cld    
f01016e2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016e4:	89 f8                	mov    %edi,%eax
f01016e6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01016e9:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016ec:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016ef:	89 ec                	mov    %ebp,%esp
f01016f1:	5d                   	pop    %ebp
f01016f2:	c3                   	ret    

f01016f3 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016f3:	55                   	push   %ebp
f01016f4:	89 e5                	mov    %esp,%ebp
f01016f6:	83 ec 08             	sub    $0x8,%esp
f01016f9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016fc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0101702:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101705:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101708:	39 c6                	cmp    %eax,%esi
f010170a:	73 36                	jae    f0101742 <memmove+0x4f>
f010170c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010170f:	39 d0                	cmp    %edx,%eax
f0101711:	73 2f                	jae    f0101742 <memmove+0x4f>
		s += n;
		d += n;
f0101713:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101716:	f6 c2 03             	test   $0x3,%dl
f0101719:	75 1b                	jne    f0101736 <memmove+0x43>
f010171b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101721:	75 13                	jne    f0101736 <memmove+0x43>
f0101723:	f6 c1 03             	test   $0x3,%cl
f0101726:	75 0e                	jne    f0101736 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101728:	83 ef 04             	sub    $0x4,%edi
f010172b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010172e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101731:	fd                   	std    
f0101732:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101734:	eb 09                	jmp    f010173f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101736:	83 ef 01             	sub    $0x1,%edi
f0101739:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010173c:	fd                   	std    
f010173d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010173f:	fc                   	cld    
f0101740:	eb 20                	jmp    f0101762 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101742:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101748:	75 13                	jne    f010175d <memmove+0x6a>
f010174a:	a8 03                	test   $0x3,%al
f010174c:	75 0f                	jne    f010175d <memmove+0x6a>
f010174e:	f6 c1 03             	test   $0x3,%cl
f0101751:	75 0a                	jne    f010175d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101753:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101756:	89 c7                	mov    %eax,%edi
f0101758:	fc                   	cld    
f0101759:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010175b:	eb 05                	jmp    f0101762 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010175d:	89 c7                	mov    %eax,%edi
f010175f:	fc                   	cld    
f0101760:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101762:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101765:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101768:	89 ec                	mov    %ebp,%esp
f010176a:	5d                   	pop    %ebp
f010176b:	c3                   	ret    

f010176c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010176c:	55                   	push   %ebp
f010176d:	89 e5                	mov    %esp,%ebp
f010176f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101772:	8b 45 10             	mov    0x10(%ebp),%eax
f0101775:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101779:	8b 45 0c             	mov    0xc(%ebp),%eax
f010177c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101780:	8b 45 08             	mov    0x8(%ebp),%eax
f0101783:	89 04 24             	mov    %eax,(%esp)
f0101786:	e8 68 ff ff ff       	call   f01016f3 <memmove>
}
f010178b:	c9                   	leave  
f010178c:	c3                   	ret    

f010178d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010178d:	55                   	push   %ebp
f010178e:	89 e5                	mov    %esp,%ebp
f0101790:	57                   	push   %edi
f0101791:	56                   	push   %esi
f0101792:	53                   	push   %ebx
f0101793:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101796:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101799:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010179c:	8d 78 ff             	lea    -0x1(%eax),%edi
f010179f:	85 c0                	test   %eax,%eax
f01017a1:	74 36                	je     f01017d9 <memcmp+0x4c>
		if (*s1 != *s2)
f01017a3:	0f b6 03             	movzbl (%ebx),%eax
f01017a6:	0f b6 0e             	movzbl (%esi),%ecx
f01017a9:	38 c8                	cmp    %cl,%al
f01017ab:	75 17                	jne    f01017c4 <memcmp+0x37>
f01017ad:	ba 00 00 00 00       	mov    $0x0,%edx
f01017b2:	eb 1a                	jmp    f01017ce <memcmp+0x41>
f01017b4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01017b9:	83 c2 01             	add    $0x1,%edx
f01017bc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01017c0:	38 c8                	cmp    %cl,%al
f01017c2:	74 0a                	je     f01017ce <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01017c4:	0f b6 c0             	movzbl %al,%eax
f01017c7:	0f b6 c9             	movzbl %cl,%ecx
f01017ca:	29 c8                	sub    %ecx,%eax
f01017cc:	eb 10                	jmp    f01017de <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017ce:	39 fa                	cmp    %edi,%edx
f01017d0:	75 e2                	jne    f01017b4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017d2:	b8 00 00 00 00       	mov    $0x0,%eax
f01017d7:	eb 05                	jmp    f01017de <memcmp+0x51>
f01017d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017de:	5b                   	pop    %ebx
f01017df:	5e                   	pop    %esi
f01017e0:	5f                   	pop    %edi
f01017e1:	5d                   	pop    %ebp
f01017e2:	c3                   	ret    

f01017e3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017e3:	55                   	push   %ebp
f01017e4:	89 e5                	mov    %esp,%ebp
f01017e6:	53                   	push   %ebx
f01017e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01017ed:	89 c2                	mov    %eax,%edx
f01017ef:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017f2:	39 d0                	cmp    %edx,%eax
f01017f4:	73 13                	jae    f0101809 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017f6:	89 d9                	mov    %ebx,%ecx
f01017f8:	38 18                	cmp    %bl,(%eax)
f01017fa:	75 06                	jne    f0101802 <memfind+0x1f>
f01017fc:	eb 0b                	jmp    f0101809 <memfind+0x26>
f01017fe:	38 08                	cmp    %cl,(%eax)
f0101800:	74 07                	je     f0101809 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101802:	83 c0 01             	add    $0x1,%eax
f0101805:	39 d0                	cmp    %edx,%eax
f0101807:	75 f5                	jne    f01017fe <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101809:	5b                   	pop    %ebx
f010180a:	5d                   	pop    %ebp
f010180b:	c3                   	ret    

f010180c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010180c:	55                   	push   %ebp
f010180d:	89 e5                	mov    %esp,%ebp
f010180f:	57                   	push   %edi
f0101810:	56                   	push   %esi
f0101811:	53                   	push   %ebx
f0101812:	83 ec 04             	sub    $0x4,%esp
f0101815:	8b 55 08             	mov    0x8(%ebp),%edx
f0101818:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010181b:	0f b6 02             	movzbl (%edx),%eax
f010181e:	3c 09                	cmp    $0x9,%al
f0101820:	74 04                	je     f0101826 <strtol+0x1a>
f0101822:	3c 20                	cmp    $0x20,%al
f0101824:	75 0e                	jne    f0101834 <strtol+0x28>
		s++;
f0101826:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101829:	0f b6 02             	movzbl (%edx),%eax
f010182c:	3c 09                	cmp    $0x9,%al
f010182e:	74 f6                	je     f0101826 <strtol+0x1a>
f0101830:	3c 20                	cmp    $0x20,%al
f0101832:	74 f2                	je     f0101826 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101834:	3c 2b                	cmp    $0x2b,%al
f0101836:	75 0a                	jne    f0101842 <strtol+0x36>
		s++;
f0101838:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010183b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101840:	eb 10                	jmp    f0101852 <strtol+0x46>
f0101842:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101847:	3c 2d                	cmp    $0x2d,%al
f0101849:	75 07                	jne    f0101852 <strtol+0x46>
		s++, neg = 1;
f010184b:	83 c2 01             	add    $0x1,%edx
f010184e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101852:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101858:	75 15                	jne    f010186f <strtol+0x63>
f010185a:	80 3a 30             	cmpb   $0x30,(%edx)
f010185d:	75 10                	jne    f010186f <strtol+0x63>
f010185f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101863:	75 0a                	jne    f010186f <strtol+0x63>
		s += 2, base = 16;
f0101865:	83 c2 02             	add    $0x2,%edx
f0101868:	bb 10 00 00 00       	mov    $0x10,%ebx
f010186d:	eb 10                	jmp    f010187f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f010186f:	85 db                	test   %ebx,%ebx
f0101871:	75 0c                	jne    f010187f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101873:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101875:	80 3a 30             	cmpb   $0x30,(%edx)
f0101878:	75 05                	jne    f010187f <strtol+0x73>
		s++, base = 8;
f010187a:	83 c2 01             	add    $0x1,%edx
f010187d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010187f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101884:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101887:	0f b6 0a             	movzbl (%edx),%ecx
f010188a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010188d:	89 f3                	mov    %esi,%ebx
f010188f:	80 fb 09             	cmp    $0x9,%bl
f0101892:	77 08                	ja     f010189c <strtol+0x90>
			dig = *s - '0';
f0101894:	0f be c9             	movsbl %cl,%ecx
f0101897:	83 e9 30             	sub    $0x30,%ecx
f010189a:	eb 22                	jmp    f01018be <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f010189c:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010189f:	89 f3                	mov    %esi,%ebx
f01018a1:	80 fb 19             	cmp    $0x19,%bl
f01018a4:	77 08                	ja     f01018ae <strtol+0xa2>
			dig = *s - 'a' + 10;
f01018a6:	0f be c9             	movsbl %cl,%ecx
f01018a9:	83 e9 57             	sub    $0x57,%ecx
f01018ac:	eb 10                	jmp    f01018be <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f01018ae:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01018b1:	89 f3                	mov    %esi,%ebx
f01018b3:	80 fb 19             	cmp    $0x19,%bl
f01018b6:	77 16                	ja     f01018ce <strtol+0xc2>
			dig = *s - 'A' + 10;
f01018b8:	0f be c9             	movsbl %cl,%ecx
f01018bb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01018be:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01018c1:	7d 0f                	jge    f01018d2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f01018c3:	83 c2 01             	add    $0x1,%edx
f01018c6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f01018ca:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01018cc:	eb b9                	jmp    f0101887 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01018ce:	89 c1                	mov    %eax,%ecx
f01018d0:	eb 02                	jmp    f01018d4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018d2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01018d4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018d8:	74 05                	je     f01018df <strtol+0xd3>
		*endptr = (char *) s;
f01018da:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018dd:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01018df:	89 ca                	mov    %ecx,%edx
f01018e1:	f7 da                	neg    %edx
f01018e3:	85 ff                	test   %edi,%edi
f01018e5:	0f 45 c2             	cmovne %edx,%eax
}
f01018e8:	83 c4 04             	add    $0x4,%esp
f01018eb:	5b                   	pop    %ebx
f01018ec:	5e                   	pop    %esi
f01018ed:	5f                   	pop    %edi
f01018ee:	5d                   	pop    %ebp
f01018ef:	c3                   	ret    

f01018f0 <__udivdi3>:
f01018f0:	83 ec 1c             	sub    $0x1c,%esp
f01018f3:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f01018f7:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018fb:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01018ff:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101903:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101907:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010190b:	85 c0                	test   %eax,%eax
f010190d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101911:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101915:	89 ea                	mov    %ebp,%edx
f0101917:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010191b:	75 33                	jne    f0101950 <__udivdi3+0x60>
f010191d:	39 e9                	cmp    %ebp,%ecx
f010191f:	77 6f                	ja     f0101990 <__udivdi3+0xa0>
f0101921:	85 c9                	test   %ecx,%ecx
f0101923:	89 ce                	mov    %ecx,%esi
f0101925:	75 0b                	jne    f0101932 <__udivdi3+0x42>
f0101927:	b8 01 00 00 00       	mov    $0x1,%eax
f010192c:	31 d2                	xor    %edx,%edx
f010192e:	f7 f1                	div    %ecx
f0101930:	89 c6                	mov    %eax,%esi
f0101932:	31 d2                	xor    %edx,%edx
f0101934:	89 e8                	mov    %ebp,%eax
f0101936:	f7 f6                	div    %esi
f0101938:	89 c5                	mov    %eax,%ebp
f010193a:	89 f8                	mov    %edi,%eax
f010193c:	f7 f6                	div    %esi
f010193e:	89 ea                	mov    %ebp,%edx
f0101940:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101944:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101948:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010194c:	83 c4 1c             	add    $0x1c,%esp
f010194f:	c3                   	ret    
f0101950:	39 e8                	cmp    %ebp,%eax
f0101952:	77 24                	ja     f0101978 <__udivdi3+0x88>
f0101954:	0f bd c8             	bsr    %eax,%ecx
f0101957:	83 f1 1f             	xor    $0x1f,%ecx
f010195a:	89 0c 24             	mov    %ecx,(%esp)
f010195d:	75 49                	jne    f01019a8 <__udivdi3+0xb8>
f010195f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101963:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0101967:	0f 86 ab 00 00 00    	jbe    f0101a18 <__udivdi3+0x128>
f010196d:	39 e8                	cmp    %ebp,%eax
f010196f:	0f 82 a3 00 00 00    	jb     f0101a18 <__udivdi3+0x128>
f0101975:	8d 76 00             	lea    0x0(%esi),%esi
f0101978:	31 d2                	xor    %edx,%edx
f010197a:	31 c0                	xor    %eax,%eax
f010197c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101980:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101984:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101988:	83 c4 1c             	add    $0x1c,%esp
f010198b:	c3                   	ret    
f010198c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101990:	89 f8                	mov    %edi,%eax
f0101992:	f7 f1                	div    %ecx
f0101994:	31 d2                	xor    %edx,%edx
f0101996:	8b 74 24 10          	mov    0x10(%esp),%esi
f010199a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010199e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019a2:	83 c4 1c             	add    $0x1c,%esp
f01019a5:	c3                   	ret    
f01019a6:	66 90                	xchg   %ax,%ax
f01019a8:	0f b6 0c 24          	movzbl (%esp),%ecx
f01019ac:	89 c6                	mov    %eax,%esi
f01019ae:	b8 20 00 00 00       	mov    $0x20,%eax
f01019b3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f01019b7:	2b 04 24             	sub    (%esp),%eax
f01019ba:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01019be:	d3 e6                	shl    %cl,%esi
f01019c0:	89 c1                	mov    %eax,%ecx
f01019c2:	d3 ed                	shr    %cl,%ebp
f01019c4:	0f b6 0c 24          	movzbl (%esp),%ecx
f01019c8:	09 f5                	or     %esi,%ebp
f01019ca:	8b 74 24 04          	mov    0x4(%esp),%esi
f01019ce:	d3 e6                	shl    %cl,%esi
f01019d0:	89 c1                	mov    %eax,%ecx
f01019d2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019d6:	89 d6                	mov    %edx,%esi
f01019d8:	d3 ee                	shr    %cl,%esi
f01019da:	0f b6 0c 24          	movzbl (%esp),%ecx
f01019de:	d3 e2                	shl    %cl,%edx
f01019e0:	89 c1                	mov    %eax,%ecx
f01019e2:	d3 ef                	shr    %cl,%edi
f01019e4:	09 d7                	or     %edx,%edi
f01019e6:	89 f2                	mov    %esi,%edx
f01019e8:	89 f8                	mov    %edi,%eax
f01019ea:	f7 f5                	div    %ebp
f01019ec:	89 d6                	mov    %edx,%esi
f01019ee:	89 c7                	mov    %eax,%edi
f01019f0:	f7 64 24 04          	mull   0x4(%esp)
f01019f4:	39 d6                	cmp    %edx,%esi
f01019f6:	72 30                	jb     f0101a28 <__udivdi3+0x138>
f01019f8:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01019fc:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101a00:	d3 e5                	shl    %cl,%ebp
f0101a02:	39 c5                	cmp    %eax,%ebp
f0101a04:	73 04                	jae    f0101a0a <__udivdi3+0x11a>
f0101a06:	39 d6                	cmp    %edx,%esi
f0101a08:	74 1e                	je     f0101a28 <__udivdi3+0x138>
f0101a0a:	89 f8                	mov    %edi,%eax
f0101a0c:	31 d2                	xor    %edx,%edx
f0101a0e:	e9 69 ff ff ff       	jmp    f010197c <__udivdi3+0x8c>
f0101a13:	90                   	nop
f0101a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	31 d2                	xor    %edx,%edx
f0101a1a:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a1f:	e9 58 ff ff ff       	jmp    f010197c <__udivdi3+0x8c>
f0101a24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a28:	8d 47 ff             	lea    -0x1(%edi),%eax
f0101a2b:	31 d2                	xor    %edx,%edx
f0101a2d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a31:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a35:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a39:	83 c4 1c             	add    $0x1c,%esp
f0101a3c:	c3                   	ret    
f0101a3d:	66 90                	xchg   %ax,%ax
f0101a3f:	90                   	nop

f0101a40 <__umoddi3>:
f0101a40:	83 ec 2c             	sub    $0x2c,%esp
f0101a43:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0101a47:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0101a4b:	89 74 24 20          	mov    %esi,0x20(%esp)
f0101a4f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0101a53:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0101a57:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0101a5b:	85 c0                	test   %eax,%eax
f0101a5d:	89 c2                	mov    %eax,%edx
f0101a5f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0101a63:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0101a67:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a6b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a6f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101a73:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101a77:	75 1f                	jne    f0101a98 <__umoddi3+0x58>
f0101a79:	39 fe                	cmp    %edi,%esi
f0101a7b:	76 63                	jbe    f0101ae0 <__umoddi3+0xa0>
f0101a7d:	89 c8                	mov    %ecx,%eax
f0101a7f:	89 fa                	mov    %edi,%edx
f0101a81:	f7 f6                	div    %esi
f0101a83:	89 d0                	mov    %edx,%eax
f0101a85:	31 d2                	xor    %edx,%edx
f0101a87:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101a8b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101a8f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101a93:	83 c4 2c             	add    $0x2c,%esp
f0101a96:	c3                   	ret    
f0101a97:	90                   	nop
f0101a98:	39 f8                	cmp    %edi,%eax
f0101a9a:	77 64                	ja     f0101b00 <__umoddi3+0xc0>
f0101a9c:	0f bd e8             	bsr    %eax,%ebp
f0101a9f:	83 f5 1f             	xor    $0x1f,%ebp
f0101aa2:	75 74                	jne    f0101b18 <__umoddi3+0xd8>
f0101aa4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101aa8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0101aac:	0f 87 0e 01 00 00    	ja     f0101bc0 <__umoddi3+0x180>
f0101ab2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101ab6:	29 f1                	sub    %esi,%ecx
f0101ab8:	19 c7                	sbb    %eax,%edi
f0101aba:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0101abe:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101ac2:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101ac6:	8b 54 24 18          	mov    0x18(%esp),%edx
f0101aca:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101ace:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101ad2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101ad6:	83 c4 2c             	add    $0x2c,%esp
f0101ad9:	c3                   	ret    
f0101ada:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ae0:	85 f6                	test   %esi,%esi
f0101ae2:	89 f5                	mov    %esi,%ebp
f0101ae4:	75 0b                	jne    f0101af1 <__umoddi3+0xb1>
f0101ae6:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aeb:	31 d2                	xor    %edx,%edx
f0101aed:	f7 f6                	div    %esi
f0101aef:	89 c5                	mov    %eax,%ebp
f0101af1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101af5:	31 d2                	xor    %edx,%edx
f0101af7:	f7 f5                	div    %ebp
f0101af9:	89 c8                	mov    %ecx,%eax
f0101afb:	f7 f5                	div    %ebp
f0101afd:	eb 84                	jmp    f0101a83 <__umoddi3+0x43>
f0101aff:	90                   	nop
f0101b00:	89 c8                	mov    %ecx,%eax
f0101b02:	89 fa                	mov    %edi,%edx
f0101b04:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101b08:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101b0c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101b10:	83 c4 2c             	add    $0x2c,%esp
f0101b13:	c3                   	ret    
f0101b14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b18:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101b1c:	be 20 00 00 00       	mov    $0x20,%esi
f0101b21:	89 e9                	mov    %ebp,%ecx
f0101b23:	29 ee                	sub    %ebp,%esi
f0101b25:	d3 e2                	shl    %cl,%edx
f0101b27:	89 f1                	mov    %esi,%ecx
f0101b29:	d3 e8                	shr    %cl,%eax
f0101b2b:	89 e9                	mov    %ebp,%ecx
f0101b2d:	09 d0                	or     %edx,%eax
f0101b2f:	89 fa                	mov    %edi,%edx
f0101b31:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b35:	8b 44 24 10          	mov    0x10(%esp),%eax
f0101b39:	d3 e0                	shl    %cl,%eax
f0101b3b:	89 f1                	mov    %esi,%ecx
f0101b3d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0101b41:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0101b45:	d3 ea                	shr    %cl,%edx
f0101b47:	89 e9                	mov    %ebp,%ecx
f0101b49:	d3 e7                	shl    %cl,%edi
f0101b4b:	89 f1                	mov    %esi,%ecx
f0101b4d:	d3 e8                	shr    %cl,%eax
f0101b4f:	89 e9                	mov    %ebp,%ecx
f0101b51:	09 f8                	or     %edi,%eax
f0101b53:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0101b57:	f7 74 24 0c          	divl   0xc(%esp)
f0101b5b:	d3 e7                	shl    %cl,%edi
f0101b5d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101b61:	89 d7                	mov    %edx,%edi
f0101b63:	f7 64 24 10          	mull   0x10(%esp)
f0101b67:	39 d7                	cmp    %edx,%edi
f0101b69:	89 c1                	mov    %eax,%ecx
f0101b6b:	89 54 24 14          	mov    %edx,0x14(%esp)
f0101b6f:	72 3b                	jb     f0101bac <__umoddi3+0x16c>
f0101b71:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0101b75:	72 31                	jb     f0101ba8 <__umoddi3+0x168>
f0101b77:	8b 44 24 18          	mov    0x18(%esp),%eax
f0101b7b:	29 c8                	sub    %ecx,%eax
f0101b7d:	19 d7                	sbb    %edx,%edi
f0101b7f:	89 e9                	mov    %ebp,%ecx
f0101b81:	89 fa                	mov    %edi,%edx
f0101b83:	d3 e8                	shr    %cl,%eax
f0101b85:	89 f1                	mov    %esi,%ecx
f0101b87:	d3 e2                	shl    %cl,%edx
f0101b89:	89 e9                	mov    %ebp,%ecx
f0101b8b:	09 d0                	or     %edx,%eax
f0101b8d:	89 fa                	mov    %edi,%edx
f0101b8f:	d3 ea                	shr    %cl,%edx
f0101b91:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101b95:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101b99:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101b9d:	83 c4 2c             	add    $0x2c,%esp
f0101ba0:	c3                   	ret    
f0101ba1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ba8:	39 d7                	cmp    %edx,%edi
f0101baa:	75 cb                	jne    f0101b77 <__umoddi3+0x137>
f0101bac:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101bb0:	89 c1                	mov    %eax,%ecx
f0101bb2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101bb6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101bba:	eb bb                	jmp    f0101b77 <__umoddi3+0x137>
f0101bbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101bc0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101bc4:	0f 82 e8 fe ff ff    	jb     f0101ab2 <__umoddi3+0x72>
f0101bca:	e9 f3 fe ff ff       	jmp    f0101ac2 <__umoddi3+0x82>
