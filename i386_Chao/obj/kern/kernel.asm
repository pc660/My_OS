
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 89 11 f0       	mov    $0xf0118970,%eax
f010004b:	2d 00 83 11 f0       	sub    $0xf0118300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 83 11 f0 	movl   $0xf0118300,(%esp)
f0100063:	e8 3d 3b 00 00       	call   f0103ba5 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 9a 04 00 00       	call   f0100507 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 e0 40 10 f0 	movl   $0xf01040e0,(%esp)
f010007c:	e8 91 2e 00 00       	call   f0102f12 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 66 12 00 00       	call   f01012ec <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 05 08 00 00       	call   f0100897 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 89 11 f0 00 	cmpl   $0x0,0xf0118960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 89 11 f0    	mov    %esi,0xf0118960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 fb 40 10 f0 	movl   $0xf01040fb,(%esp)
f01000c8:	e8 45 2e 00 00       	call   f0102f12 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 06 2e 00 00       	call   f0102edf <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 c6 4f 10 f0 	movl   $0xf0104fc6,(%esp)
f01000e0:	e8 2d 2e 00 00       	call   f0102f12 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 a6 07 00 00       	call   f0100897 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 13 41 10 f0 	movl   $0xf0104113,(%esp)
f0100112:	e8 fb 2d 00 00       	call   f0102f12 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 b9 2d 00 00       	call   f0102edf <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 c6 4f 10 f0 	movl   $0xf0104fc6,(%esp)
f010012d:	e8 e0 2d 00 00       	call   f0102f12 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
f0100138:	66 90                	xchg   %ax,%ax
f010013a:	66 90                	xchg   %ax,%ax
f010013c:	66 90                	xchg   %ax,%ax
f010013e:	66 90                	xchg   %ax,%ax

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100157:	a8 01                	test   $0x1,%al
f0100159:	74 08                	je     f0100163 <serial_proc_data+0x15>
f010015b:	b2 f8                	mov    $0xf8,%dl
f010015d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010015e:	0f b6 c0             	movzbl %al,%eax
f0100161:	eb 05                	jmp    f0100168 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100163:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 26                	jmp    f010019b <cons_intr+0x31>
		if (c == 0)
f0100175:	85 d2                	test   %edx,%edx
f0100177:	74 22                	je     f010019b <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	a1 24 85 11 f0       	mov    0xf0118524,%eax
f010017e:	88 90 20 83 11 f0    	mov    %dl,-0xfee7ce0(%eax)
f0100184:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f0100187:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f010018d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100192:	0f 44 d0             	cmove  %eax,%edx
f0100195:	89 15 24 85 11 f0    	mov    %edx,0xf0118524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019b:	ff d3                	call   *%ebx
f010019d:	89 c2                	mov    %eax,%edx
f010019f:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a2:	75 d1                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a4:	83 c4 04             	add    $0x4,%esp
f01001a7:	5b                   	pop    %ebx
f01001a8:	5d                   	pop    %ebp
f01001a9:	c3                   	ret    

f01001aa <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001aa:	55                   	push   %ebp
f01001ab:	89 e5                	mov    %esp,%ebp
f01001ad:	57                   	push   %edi
f01001ae:	56                   	push   %esi
f01001af:	53                   	push   %ebx
f01001b0:	83 ec 2c             	sub    $0x2c,%esp
f01001b3:	89 c7                	mov    %eax,%edi
f01001b5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001ba:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001bb:	a8 20                	test   $0x20,%al
f01001bd:	75 1b                	jne    f01001da <cons_putc+0x30>
f01001bf:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c4:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c9:	e8 72 ff ff ff       	call   f0100140 <delay>
f01001ce:	89 f2                	mov    %esi,%edx
f01001d0:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001d1:	a8 20                	test   $0x20,%al
f01001d3:	75 05                	jne    f01001da <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d5:	83 eb 01             	sub    $0x1,%ebx
f01001d8:	75 ef                	jne    f01001c9 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001da:	89 f8                	mov    %edi,%eax
f01001dc:	25 ff 00 00 00       	and    $0xff,%eax
f01001e1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001e4:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001ea:	b2 79                	mov    $0x79,%dl
f01001ec:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001ed:	84 c0                	test   %al,%al
f01001ef:	78 1b                	js     f010020c <cons_putc+0x62>
f01001f1:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f6:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001fb:	e8 40 ff ff ff       	call   f0100140 <delay>
f0100200:	89 f2                	mov    %esi,%edx
f0100202:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100203:	84 c0                	test   %al,%al
f0100205:	78 05                	js     f010020c <cons_putc+0x62>
f0100207:	83 eb 01             	sub    $0x1,%ebx
f010020a:	75 ef                	jne    f01001fb <cons_putc+0x51>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010020c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100211:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100215:	ee                   	out    %al,(%dx)
f0100216:	b2 7a                	mov    $0x7a,%dl
f0100218:	b8 0d 00 00 00       	mov    $0xd,%eax
f010021d:	ee                   	out    %al,(%dx)
f010021e:	b8 08 00 00 00       	mov    $0x8,%eax
f0100223:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100224:	89 fa                	mov    %edi,%edx
f0100226:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010022c:	89 f8                	mov    %edi,%eax
f010022e:	80 cc 07             	or     $0x7,%ah
f0100231:	85 d2                	test   %edx,%edx
f0100233:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100236:	89 f8                	mov    %edi,%eax
f0100238:	25 ff 00 00 00       	and    $0xff,%eax
f010023d:	83 f8 09             	cmp    $0x9,%eax
f0100240:	74 77                	je     f01002b9 <cons_putc+0x10f>
f0100242:	83 f8 09             	cmp    $0x9,%eax
f0100245:	7f 0b                	jg     f0100252 <cons_putc+0xa8>
f0100247:	83 f8 08             	cmp    $0x8,%eax
f010024a:	0f 85 9d 00 00 00    	jne    f01002ed <cons_putc+0x143>
f0100250:	eb 10                	jmp    f0100262 <cons_putc+0xb8>
f0100252:	83 f8 0a             	cmp    $0xa,%eax
f0100255:	74 3c                	je     f0100293 <cons_putc+0xe9>
f0100257:	83 f8 0d             	cmp    $0xd,%eax
f010025a:	0f 85 8d 00 00 00    	jne    f01002ed <cons_putc+0x143>
f0100260:	eb 39                	jmp    f010029b <cons_putc+0xf1>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e5 00 00 00    	je     f0100357 <cons_putc+0x1ad>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f0100284:	83 cf 20             	or     $0x20,%edi
f0100287:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f010028d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100291:	eb 77                	jmp    f010030a <cons_putc+0x160>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100293:	66 83 05 34 85 11 f0 	addw   $0x50,0xf0118534
f010029a:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029b:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f01002a2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a8:	c1 e8 16             	shr    $0x16,%eax
f01002ab:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ae:	c1 e0 04             	shl    $0x4,%eax
f01002b1:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
f01002b7:	eb 51                	jmp    f010030a <cons_putc+0x160>
		break;
	case '\t':
		cons_putc(' ');
f01002b9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002be:	e8 e7 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c8:	e8 dd fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d2:	e8 d3 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002d7:	b8 20 00 00 00       	mov    $0x20,%eax
f01002dc:	e8 c9 fe ff ff       	call   f01001aa <cons_putc>
		cons_putc(' ');
f01002e1:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e6:	e8 bf fe ff ff       	call   f01001aa <cons_putc>
f01002eb:	eb 1d                	jmp    f010030a <cons_putc+0x160>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ed:	0f b7 05 34 85 11 f0 	movzwl 0xf0118534,%eax
f01002f4:	0f b7 c8             	movzwl %ax,%ecx
f01002f7:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
f01002fd:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100301:	83 c0 01             	add    $0x1,%eax
f0100304:	66 a3 34 85 11 f0    	mov    %ax,0xf0118534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010030a:	66 81 3d 34 85 11 f0 	cmpw   $0x7cf,0xf0118534
f0100311:	cf 07 
f0100313:	76 42                	jbe    f0100357 <cons_putc+0x1ad>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100315:	a1 30 85 11 f0       	mov    0xf0118530,%eax
f010031a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100321:	00 
f0100322:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100328:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032c:	89 04 24             	mov    %eax,(%esp)
f010032f:	e8 cf 38 00 00       	call   f0103c03 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100334:	8b 15 30 85 11 f0    	mov    0xf0118530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010033a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100345:	83 c0 01             	add    $0x1,%eax
f0100348:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034d:	75 f0                	jne    f010033f <cons_putc+0x195>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034f:	66 83 2d 34 85 11 f0 	subw   $0x50,0xf0118534
f0100356:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100357:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f010035d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100362:	89 ca                	mov    %ecx,%edx
f0100364:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100365:	0f b7 1d 34 85 11 f0 	movzwl 0xf0118534,%ebx
f010036c:	8d 71 01             	lea    0x1(%ecx),%esi
f010036f:	89 d8                	mov    %ebx,%eax
f0100371:	66 c1 e8 08          	shr    $0x8,%ax
f0100375:	89 f2                	mov    %esi,%edx
f0100377:	ee                   	out    %al,(%dx)
f0100378:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037d:	89 ca                	mov    %ecx,%edx
f010037f:	ee                   	out    %al,(%dx)
f0100380:	89 d8                	mov    %ebx,%eax
f0100382:	89 f2                	mov    %esi,%edx
f0100384:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100385:	83 c4 2c             	add    $0x2c,%esp
f0100388:	5b                   	pop    %ebx
f0100389:	5e                   	pop    %esi
f010038a:	5f                   	pop    %edi
f010038b:	5d                   	pop    %ebp
f010038c:	c3                   	ret    

f010038d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038d:	55                   	push   %ebp
f010038e:	89 e5                	mov    %esp,%ebp
f0100390:	53                   	push   %ebx
f0100391:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100394:	ba 64 00 00 00       	mov    $0x64,%edx
f0100399:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039a:	a8 01                	test   $0x1,%al
f010039c:	0f 84 e5 00 00 00    	je     f0100487 <kbd_proc_data+0xfa>
f01003a2:	b2 60                	mov    $0x60,%dl
f01003a4:	ec                   	in     (%dx),%al
f01003a5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003a7:	3c e0                	cmp    $0xe0,%al
f01003a9:	75 11                	jne    f01003bc <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01003ab:	83 0d 28 85 11 f0 40 	orl    $0x40,0xf0118528
		return 0;
f01003b2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003b7:	e9 d0 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f01003bc:	84 c0                	test   %al,%al
f01003be:	79 37                	jns    f01003f7 <kbd_proc_data+0x6a>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c0:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003c6:	89 cb                	mov    %ecx,%ebx
f01003c8:	83 e3 40             	and    $0x40,%ebx
f01003cb:	83 e0 7f             	and    $0x7f,%eax
f01003ce:	85 db                	test   %ebx,%ebx
f01003d0:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d3:	0f b6 d2             	movzbl %dl,%edx
f01003d6:	0f b6 82 60 41 10 f0 	movzbl -0xfefbea0(%edx),%eax
f01003dd:	83 c8 40             	or     $0x40,%eax
f01003e0:	0f b6 c0             	movzbl %al,%eax
f01003e3:	f7 d0                	not    %eax
f01003e5:	21 c1                	and    %eax,%ecx
f01003e7:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
		return 0;
f01003ed:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f2:	e9 95 00 00 00       	jmp    f010048c <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f01003f7:	8b 0d 28 85 11 f0    	mov    0xf0118528,%ecx
f01003fd:	f6 c1 40             	test   $0x40,%cl
f0100400:	74 0e                	je     f0100410 <kbd_proc_data+0x83>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100402:	89 c2                	mov    %eax,%edx
f0100404:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100407:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040a:	89 0d 28 85 11 f0    	mov    %ecx,0xf0118528
	}

	shift |= shiftcode[data];
f0100410:	0f b6 d2             	movzbl %dl,%edx
f0100413:	0f b6 82 60 41 10 f0 	movzbl -0xfefbea0(%edx),%eax
f010041a:	0b 05 28 85 11 f0    	or     0xf0118528,%eax
	shift ^= togglecode[data];
f0100420:	0f b6 8a 60 42 10 f0 	movzbl -0xfefbda0(%edx),%ecx
f0100427:	31 c8                	xor    %ecx,%eax
f0100429:	a3 28 85 11 f0       	mov    %eax,0xf0118528

	c = charcode[shift & (CTL | SHIFT)][data];
f010042e:	89 c1                	mov    %eax,%ecx
f0100430:	83 e1 03             	and    $0x3,%ecx
f0100433:	8b 0c 8d 60 43 10 f0 	mov    -0xfefbca0(,%ecx,4),%ecx
f010043a:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010043e:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100441:	a8 08                	test   $0x8,%al
f0100443:	74 1b                	je     f0100460 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100445:	89 da                	mov    %ebx,%edx
f0100447:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010044a:	83 f9 19             	cmp    $0x19,%ecx
f010044d:	77 05                	ja     f0100454 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044f:	83 eb 20             	sub    $0x20,%ebx
f0100452:	eb 0c                	jmp    f0100460 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100454:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100457:	8d 4b 20             	lea    0x20(%ebx),%ecx
f010045a:	83 fa 19             	cmp    $0x19,%edx
f010045d:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100460:	f7 d0                	not    %eax
f0100462:	a8 06                	test   $0x6,%al
f0100464:	75 26                	jne    f010048c <kbd_proc_data+0xff>
f0100466:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046c:	75 1e                	jne    f010048c <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f010046e:	c7 04 24 2d 41 10 f0 	movl   $0xf010412d,(%esp)
f0100475:	e8 98 2a 00 00       	call   f0102f12 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010047a:	ba 92 00 00 00       	mov    $0x92,%edx
f010047f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100484:	ee                   	out    %al,(%dx)
f0100485:	eb 05                	jmp    f010048c <kbd_proc_data+0xff>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100487:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010048c:	89 d8                	mov    %ebx,%eax
f010048e:	83 c4 14             	add    $0x14,%esp
f0100491:	5b                   	pop    %ebx
f0100492:	5d                   	pop    %ebp
f0100493:	c3                   	ret    

f0100494 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100494:	80 3d 00 83 11 f0 00 	cmpb   $0x0,0xf0118300
f010049b:	74 11                	je     f01004ae <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010049d:	55                   	push   %ebp
f010049e:	89 e5                	mov    %esp,%ebp
f01004a0:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004a3:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a8:	e8 bd fc ff ff       	call   f010016a <cons_intr>
}
f01004ad:	c9                   	leave  
f01004ae:	f3 c3                	repz ret 

f01004b0 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b6:	b8 8d 03 10 f0       	mov    $0xf010038d,%eax
f01004bb:	e8 aa fc ff ff       	call   f010016a <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	c3                   	ret    

f01004c2 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c2:	55                   	push   %ebp
f01004c3:	89 e5                	mov    %esp,%ebp
f01004c5:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c8:	e8 c7 ff ff ff       	call   f0100494 <serial_intr>
	kbd_intr();
f01004cd:	e8 de ff ff ff       	call   f01004b0 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d2:	8b 15 20 85 11 f0    	mov    0xf0118520,%edx
f01004d8:	3b 15 24 85 11 f0    	cmp    0xf0118524,%edx
f01004de:	74 20                	je     f0100500 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f01004e0:	0f b6 82 20 83 11 f0 	movzbl -0xfee7ce0(%edx),%eax
f01004e7:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f01004ea:	81 fa 00 02 00 00    	cmp    $0x200,%edx
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
f01004f0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f5:	0f 44 d1             	cmove  %ecx,%edx
f01004f8:	89 15 20 85 11 f0    	mov    %edx,0xf0118520
f01004fe:	eb 05                	jmp    f0100505 <cons_getc+0x43>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100500:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	57                   	push   %edi
f010050b:	56                   	push   %esi
f010050c:	53                   	push   %ebx
f010050d:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100510:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100517:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010051e:	5a a5 
	if (*cp != 0xA55A) {
f0100520:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100527:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010052b:	74 11                	je     f010053e <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010052d:	c7 05 2c 85 11 f0 b4 	movl   $0x3b4,0xf011852c
f0100534:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100537:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010053c:	eb 16                	jmp    f0100554 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010053e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100545:	c7 05 2c 85 11 f0 d4 	movl   $0x3d4,0xf011852c
f010054c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010054f:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100554:	8b 0d 2c 85 11 f0    	mov    0xf011852c,%ecx
f010055a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010055f:	89 ca                	mov    %ecx,%edx
f0100561:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100562:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100565:	89 da                	mov    %ebx,%edx
f0100567:	ec                   	in     (%dx),%al
f0100568:	0f b6 f0             	movzbl %al,%esi
f010056b:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100573:	89 ca                	mov    %ecx,%edx
f0100575:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100576:	89 da                	mov    %ebx,%edx
f0100578:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100579:	89 3d 30 85 11 f0    	mov    %edi,0xf0118530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057f:	0f b6 d8             	movzbl %al,%ebx
f0100582:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100584:	66 89 35 34 85 11 f0 	mov    %si,0xf0118534
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010058b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100590:	b8 00 00 00 00       	mov    $0x0,%eax
f0100595:	89 f2                	mov    %esi,%edx
f0100597:	ee                   	out    %al,(%dx)
f0100598:	b2 fb                	mov    $0xfb,%dl
f010059a:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005a5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005aa:	89 da                	mov    %ebx,%edx
f01005ac:	ee                   	out    %al,(%dx)
f01005ad:	b2 f9                	mov    $0xf9,%dl
f01005af:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b4:	ee                   	out    %al,(%dx)
f01005b5:	b2 fb                	mov    $0xfb,%dl
f01005b7:	b8 03 00 00 00       	mov    $0x3,%eax
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fc                	mov    $0xfc,%dl
f01005bf:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cc:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cd:	b2 fd                	mov    $0xfd,%dl
f01005cf:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d0:	3c ff                	cmp    $0xff,%al
f01005d2:	0f 95 c1             	setne  %cl
f01005d5:	88 0d 00 83 11 f0    	mov    %cl,0xf0118300
f01005db:	89 f2                	mov    %esi,%edx
f01005dd:	ec                   	in     (%dx),%al
f01005de:	89 da                	mov    %ebx,%edx
f01005e0:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e1:	84 c9                	test   %cl,%cl
f01005e3:	75 0c                	jne    f01005f1 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005e5:	c7 04 24 39 41 10 f0 	movl   $0xf0104139,(%esp)
f01005ec:	e8 21 29 00 00       	call   f0102f12 <cprintf>
}
f01005f1:	83 c4 1c             	add    $0x1c,%esp
f01005f4:	5b                   	pop    %ebx
f01005f5:	5e                   	pop    %esi
f01005f6:	5f                   	pop    %edi
f01005f7:	5d                   	pop    %ebp
f01005f8:	c3                   	ret    

f01005f9 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f9:	55                   	push   %ebp
f01005fa:	89 e5                	mov    %esp,%ebp
f01005fc:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0100602:	e8 a3 fb ff ff       	call   f01001aa <cons_putc>
}
f0100607:	c9                   	leave  
f0100608:	c3                   	ret    

f0100609 <getchar>:

int
getchar(void)
{
f0100609:	55                   	push   %ebp
f010060a:	89 e5                	mov    %esp,%ebp
f010060c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010060f:	e8 ae fe ff ff       	call   f01004c2 <cons_getc>
f0100614:	85 c0                	test   %eax,%eax
f0100616:	74 f7                	je     f010060f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100618:	c9                   	leave  
f0100619:	c3                   	ret    

f010061a <iscons>:

int
iscons(int fdnum)
{
f010061a:	55                   	push   %ebp
f010061b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010061d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100622:	5d                   	pop    %ebp
f0100623:	c3                   	ret    
f0100624:	66 90                	xchg   %ax,%ax
f0100626:	66 90                	xchg   %ax,%ax
f0100628:	66 90                	xchg   %ax,%ax
f010062a:	66 90                	xchg   %ax,%ax
f010062c:	66 90                	xchg   %ax,%ax
f010062e:	66 90                	xchg   %ax,%ax

f0100630 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100636:	c7 04 24 70 43 10 f0 	movl   $0xf0104370,(%esp)
f010063d:	e8 d0 28 00 00       	call   f0102f12 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 2c 44 10 f0 	movl   $0xf010442c,(%esp)
f0100651:	e8 bc 28 00 00       	call   f0102f12 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 54 44 10 f0 	movl   $0xf0104454,(%esp)
f010066d:	e8 a0 28 00 00       	call   f0102f12 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 df 40 10 	movl   $0x1040df,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 df 40 10 	movl   $0xf01040df,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 78 44 10 f0 	movl   $0xf0104478,(%esp)
f0100689:	e8 84 28 00 00       	call   f0102f12 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 00 83 11 	movl   $0x118300,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 00 83 11 	movl   $0xf0118300,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 9c 44 10 f0 	movl   $0xf010449c,(%esp)
f01006a5:	e8 68 28 00 00       	call   f0102f12 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 70 89 11 	movl   $0x118970,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 70 89 11 	movl   $0xf0118970,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 c0 44 10 f0 	movl   $0xf01044c0,(%esp)
f01006c1:	e8 4c 28 00 00       	call   f0102f12 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 6f 8d 11 f0       	mov    $0xf0118d6f,%eax
f01006cb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006d0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006d5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006db:	85 c0                	test   %eax,%eax
f01006dd:	0f 48 c2             	cmovs  %edx,%eax
f01006e0:	c1 f8 0a             	sar    $0xa,%eax
f01006e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006e7:	c7 04 24 e4 44 10 f0 	movl   $0xf01044e4,(%esp)
f01006ee:	e8 1f 28 00 00       	call   f0102f12 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f8:	c9                   	leave  
f01006f9:	c3                   	ret    

f01006fa <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006fa:	55                   	push   %ebp
f01006fb:	89 e5                	mov    %esp,%ebp
f01006fd:	56                   	push   %esi
f01006fe:	53                   	push   %ebx
f01006ff:	83 ec 10             	sub    $0x10,%esp
f0100702:	bb c4 45 10 f0       	mov    $0xf01045c4,%ebx
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100707:	be e8 45 10 f0       	mov    $0xf01045e8,%esi
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010070c:	8b 03                	mov    (%ebx),%eax
f010070e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100712:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100715:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100719:	c7 04 24 89 43 10 f0 	movl   $0xf0104389,(%esp)
f0100720:	e8 ed 27 00 00       	call   f0102f12 <cprintf>
f0100725:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100728:	39 f3                	cmp    %esi,%ebx
f010072a:	75 e0                	jne    f010070c <mon_help+0x12>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	83 c4 10             	add    $0x10,%esp
f0100734:	5b                   	pop    %ebx
f0100735:	5e                   	pop    %esi
f0100736:	5d                   	pop    %ebp
f0100737:	c3                   	ret    

f0100738 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100738:	55                   	push   %ebp
f0100739:	89 e5                	mov    %esp,%ebp
f010073b:	57                   	push   %edi
f010073c:	56                   	push   %esi
f010073d:	53                   	push   %ebx
f010073e:	81 ec cc 01 00 00    	sub    $0x1cc,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100744:	89 e8                	mov    %ebp,%eax
f0100746:	89 85 54 fe ff ff    	mov    %eax,-0x1ac(%ebp)
	unsigned int ebp, eip;
	unsigned int  arg[100];
	int i = 0;
	int num = 0;
	ebp = read_ebp();
	eip = *((unsigned int*)(ebp + 4));
f010074c:	8b 58 04             	mov    0x4(%eax),%ebx
	  while ( ebp > 0 )
f010074f:	85 c0                	test   %eax,%eax
f0100751:	0f 84 30 01 00 00    	je     f0100887 <mon_backtrace+0x14f>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
f0100757:	8d bd 58 fe ff ff    	lea    -0x1a8(%ebp),%edi
	ebp = read_ebp();
	eip = *((unsigned int*)(ebp + 4));
	  while ( ebp > 0 )
	  {
	    	  
	    debuginfo_eip( (uintptr_t) eip, &info  );
f010075d:	c7 44 24 04 38 85 11 	movl   $0xf0118538,0x4(%esp)
f0100764:	f0 
f0100765:	89 1c 24             	mov    %ebx,(%esp)
f0100768:	e8 a0 28 00 00       	call   f010300d <debuginfo_eip>
	    num = info.eip_fn_narg;
f010076d:	8b 35 4c 85 11 f0    	mov    0xf011854c,%esi
	    for(i = 0; i< num;i++)
f0100773:	85 f6                	test   %esi,%esi
f0100775:	0f 8e e9 00 00 00    	jle    f0100864 <mon_backtrace+0x12c>
f010077b:	8b 85 54 fe ff ff    	mov    -0x1ac(%ebp),%eax
f0100781:	83 c0 08             	add    $0x8,%eax
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
f0100784:	8b 95 54 fe ff ff    	mov    -0x1ac(%ebp),%edx
f010078a:	8d 4c b2 08          	lea    0x8(%edx,%esi,4),%ecx
f010078e:	89 fa                	mov    %edi,%edx
f0100790:	2b 95 54 fe ff ff    	sub    -0x1ac(%ebp),%edx
f0100796:	89 9d 50 fe ff ff    	mov    %ebx,-0x1b0(%ebp)
	    	  
	    debuginfo_eip( (uintptr_t) eip, &info  );
	    num = info.eip_fn_narg;
	    for(i = 0; i< num;i++)
	      {
		arg[i] = *((unsigned int*)(ebp + (i+2)*4 ));
f010079c:	8b 18                	mov    (%eax),%ebx
f010079e:	89 5c 02 f8          	mov    %ebx,-0x8(%edx,%eax,1)
f01007a2:	83 c0 04             	add    $0x4,%eax
	  while ( ebp > 0 )
	  {
	    	  
	    debuginfo_eip( (uintptr_t) eip, &info  );
	    num = info.eip_fn_narg;
	    for(i = 0; i< num;i++)
f01007a5:	39 c8                	cmp    %ecx,%eax
f01007a7:	75 f3                	jne    f010079c <mon_backtrace+0x64>
f01007a9:	8b 9d 50 fe ff ff    	mov    -0x1b0(%ebp),%ebx
	      {
		arg[i] = *((unsigned int*)(ebp + (i+2)*4 ));
	      }
	    cprintf("ebp = %x eip = %x argNum: %d args:\n",ebp,eip, num);
f01007af:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01007b3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01007b7:	8b 9d 54 fe ff ff    	mov    -0x1ac(%ebp),%ebx
f01007bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007c1:	c7 04 24 10 45 10 f0 	movl   $0xf0104510,(%esp)
f01007c8:	e8 45 27 00 00       	call   f0102f12 <cprintf>
	    for(i = 0;i<num;i++)
f01007cd:	bb 00 00 00 00       	mov    $0x0,%ebx
	      cprintf("%x ", arg[i]);
f01007d2:	8b 04 9f             	mov    (%edi,%ebx,4),%eax
f01007d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d9:	c7 04 24 92 43 10 f0 	movl   $0xf0104392,(%esp)
f01007e0:	e8 2d 27 00 00       	call   f0102f12 <cprintf>
	    for(i = 0; i< num;i++)
	      {
		arg[i] = *((unsigned int*)(ebp + (i+2)*4 ));
	      }
	    cprintf("ebp = %x eip = %x argNum: %d args:\n",ebp,eip, num);
	    for(i = 0;i<num;i++)
f01007e5:	83 c3 01             	add    $0x1,%ebx
f01007e8:	39 f3                	cmp    %esi,%ebx
f01007ea:	75 e6                	jne    f01007d2 <mon_backtrace+0x9a>
	      cprintf("%x ", arg[i]);
	    cprintf("\n");
f01007ec:	c7 04 24 c6 4f 10 f0 	movl   $0xf0104fc6,(%esp)
f01007f3:	e8 1a 27 00 00       	call   f0102f12 <cprintf>
	    cprintf ("\n %s:%d:  %.*s\n",info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name);
f01007f8:	a1 40 85 11 f0       	mov    0xf0118540,%eax
f01007fd:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100801:	a1 44 85 11 f0       	mov    0xf0118544,%eax
f0100806:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010080a:	a1 3c 85 11 f0       	mov    0xf011853c,%eax
f010080f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100813:	a1 38 85 11 f0       	mov    0xf0118538,%eax
f0100818:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081c:	c7 04 24 96 43 10 f0 	movl   $0xf0104396,(%esp)
f0100823:	e8 ea 26 00 00       	call   f0102f12 <cprintf>

	    ebp =  *((unsigned int*)(ebp));
f0100828:	8b 9d 54 fe ff ff    	mov    -0x1ac(%ebp),%ebx
f010082e:	8b 1b                	mov    (%ebx),%ebx
f0100830:	89 9d 54 fe ff ff    	mov    %ebx,-0x1ac(%ebp)
	    eip = *((unsigned int*)(ebp + 4));
f0100836:	8b 5b 04             	mov    0x4(%ebx),%ebx
	    memset(&info, 0 , sizeof(info));
f0100839:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
f0100840:	00 
f0100841:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100848:	00 
f0100849:	c7 04 24 38 85 11 f0 	movl   $0xf0118538,(%esp)
f0100850:	e8 50 33 00 00       	call   f0103ba5 <memset>
	unsigned int  arg[100];
	int i = 0;
	int num = 0;
	ebp = read_ebp();
	eip = *((unsigned int*)(ebp + 4));
	  while ( ebp > 0 )
f0100855:	83 bd 54 fe ff ff 00 	cmpl   $0x0,-0x1ac(%ebp)
f010085c:	0f 85 fb fe ff ff    	jne    f010075d <mon_backtrace+0x25>
f0100862:	eb 23                	jmp    f0100887 <mon_backtrace+0x14f>
	    num = info.eip_fn_narg;
	    for(i = 0; i< num;i++)
	      {
		arg[i] = *((unsigned int*)(ebp + (i+2)*4 ));
	      }
	    cprintf("ebp = %x eip = %x argNum: %d args:\n",ebp,eip, num);
f0100864:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100868:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010086c:	8b 9d 54 fe ff ff    	mov    -0x1ac(%ebp),%ebx
f0100872:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100876:	c7 04 24 10 45 10 f0 	movl   $0xf0104510,(%esp)
f010087d:	e8 90 26 00 00       	call   f0102f12 <cprintf>
f0100882:	e9 65 ff ff ff       	jmp    f01007ec <mon_backtrace+0xb4>
	    eip = *((unsigned int*)(ebp + 4));
	    memset(&info, 0 , sizeof(info));
 
	  }
	return 0;
}
f0100887:	b8 00 00 00 00       	mov    $0x0,%eax
f010088c:	81 c4 cc 01 00 00    	add    $0x1cc,%esp
f0100892:	5b                   	pop    %ebx
f0100893:	5e                   	pop    %esi
f0100894:	5f                   	pop    %edi
f0100895:	5d                   	pop    %ebp
f0100896:	c3                   	ret    

f0100897 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100897:	55                   	push   %ebp
f0100898:	89 e5                	mov    %esp,%ebp
f010089a:	57                   	push   %edi
f010089b:	56                   	push   %esi
f010089c:	53                   	push   %ebx
f010089d:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008a0:	c7 04 24 34 45 10 f0 	movl   $0xf0104534,(%esp)
f01008a7:	e8 66 26 00 00       	call   f0102f12 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008ac:	c7 04 24 58 45 10 f0 	movl   $0xf0104558,(%esp)
f01008b3:	e8 5a 26 00 00       	call   f0102f12 <cprintf>


	while (1) {
		buf = readline("K> ");
f01008b8:	c7 04 24 a6 43 10 f0 	movl   $0xf01043a6,(%esp)
f01008bf:	e8 0c 30 00 00       	call   f01038d0 <readline>
f01008c4:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01008c6:	85 c0                	test   %eax,%eax
f01008c8:	74 ee                	je     f01008b8 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01008ca:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01008d1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008d6:	eb 06                	jmp    f01008de <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01008d8:	c6 06 00             	movb   $0x0,(%esi)
f01008db:	83 c6 01             	add    $0x1,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01008de:	0f b6 06             	movzbl (%esi),%eax
f01008e1:	84 c0                	test   %al,%al
f01008e3:	74 6a                	je     f010094f <monitor+0xb8>
f01008e5:	0f be c0             	movsbl %al,%eax
f01008e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008ec:	c7 04 24 aa 43 10 f0 	movl   $0xf01043aa,(%esp)
f01008f3:	e8 4d 32 00 00       	call   f0103b45 <strchr>
f01008f8:	85 c0                	test   %eax,%eax
f01008fa:	75 dc                	jne    f01008d8 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008fc:	80 3e 00             	cmpb   $0x0,(%esi)
f01008ff:	74 4e                	je     f010094f <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100901:	83 fb 0f             	cmp    $0xf,%ebx
f0100904:	75 16                	jne    f010091c <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100906:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010090d:	00 
f010090e:	c7 04 24 af 43 10 f0 	movl   $0xf01043af,(%esp)
f0100915:	e8 f8 25 00 00       	call   f0102f12 <cprintf>
f010091a:	eb 9c                	jmp    f01008b8 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010091c:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f0100920:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100923:	0f b6 06             	movzbl (%esi),%eax
f0100926:	84 c0                	test   %al,%al
f0100928:	75 0c                	jne    f0100936 <monitor+0x9f>
f010092a:	eb b2                	jmp    f01008de <monitor+0x47>
			buf++;
f010092c:	83 c6 01             	add    $0x1,%esi
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010092f:	0f b6 06             	movzbl (%esi),%eax
f0100932:	84 c0                	test   %al,%al
f0100934:	74 a8                	je     f01008de <monitor+0x47>
f0100936:	0f be c0             	movsbl %al,%eax
f0100939:	89 44 24 04          	mov    %eax,0x4(%esp)
f010093d:	c7 04 24 aa 43 10 f0 	movl   $0xf01043aa,(%esp)
f0100944:	e8 fc 31 00 00       	call   f0103b45 <strchr>
f0100949:	85 c0                	test   %eax,%eax
f010094b:	74 df                	je     f010092c <monitor+0x95>
f010094d:	eb 8f                	jmp    f01008de <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f010094f:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100956:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100957:	85 db                	test   %ebx,%ebx
f0100959:	0f 84 59 ff ff ff    	je     f01008b8 <monitor+0x21>
f010095f:	bf c0 45 10 f0       	mov    $0xf01045c0,%edi
f0100964:	be 00 00 00 00       	mov    $0x0,%esi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100969:	8b 07                	mov    (%edi),%eax
f010096b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010096f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100972:	89 04 24             	mov    %eax,(%esp)
f0100975:	e8 47 31 00 00       	call   f0103ac1 <strcmp>
f010097a:	85 c0                	test   %eax,%eax
f010097c:	75 24                	jne    f01009a2 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010097e:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100981:	8b 55 08             	mov    0x8(%ebp),%edx
f0100984:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100988:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010098b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010098f:	89 1c 24             	mov    %ebx,(%esp)
f0100992:	ff 14 85 c8 45 10 f0 	call   *-0xfefba38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100999:	85 c0                	test   %eax,%eax
f010099b:	78 28                	js     f01009c5 <monitor+0x12e>
f010099d:	e9 16 ff ff ff       	jmp    f01008b8 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009a2:	83 c6 01             	add    $0x1,%esi
f01009a5:	83 c7 0c             	add    $0xc,%edi
f01009a8:	83 fe 03             	cmp    $0x3,%esi
f01009ab:	75 bc                	jne    f0100969 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009ad:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01009b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b4:	c7 04 24 cc 43 10 f0 	movl   $0xf01043cc,(%esp)
f01009bb:	e8 52 25 00 00       	call   f0102f12 <cprintf>
f01009c0:	e9 f3 fe ff ff       	jmp    f01008b8 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01009c5:	83 c4 5c             	add    $0x5c,%esp
f01009c8:	5b                   	pop    %ebx
f01009c9:	5e                   	pop    %esi
f01009ca:	5f                   	pop    %edi
f01009cb:	5d                   	pop    %ebp
f01009cc:	c3                   	ret    
f01009cd:	66 90                	xchg   %ax,%ax
f01009cf:	90                   	nop

f01009d0 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009d0:	55                   	push   %ebp
f01009d1:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009d3:	83 3d 54 85 11 f0 00 	cmpl   $0x0,0xf0118554
f01009da:	75 11                	jne    f01009ed <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009dc:	ba 6f 99 11 f0       	mov    $0xf011996f,%edx
f01009e1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009e7:	89 15 54 85 11 f0    	mov    %edx,0xf0118554
	}
	result = nextfree;
f01009ed:	8b 15 54 85 11 f0    	mov    0xf0118554,%edx
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	nextfree = nextfree + ROUNDUP(n, PGSIZE);
f01009f3:	05 ff 0f 00 00       	add    $0xfff,%eax
f01009f8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009fd:	01 d0                	add    %edx,%eax
f01009ff:	a3 54 85 11 f0       	mov    %eax,0xf0118554
	
	return result;
}
f0100a04:	89 d0                	mov    %edx,%eax
f0100a06:	5d                   	pop    %ebp
f0100a07:	c3                   	ret    

f0100a08 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a08:	89 d1                	mov    %edx,%ecx
f0100a0a:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a0d:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a10:	a8 01                	test   $0x1,%al
f0100a12:	74 5d                	je     f0100a71 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a14:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a19:	89 c1                	mov    %eax,%ecx
f0100a1b:	c1 e9 0c             	shr    $0xc,%ecx
f0100a1e:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0100a24:	72 26                	jb     f0100a4c <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a26:	55                   	push   %ebp
f0100a27:	89 e5                	mov    %esp,%ebp
f0100a29:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a30:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0100a37:	f0 
f0100a38:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0100a3f:	00 
f0100a40:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100a47:	e8 48 f6 ff ff       	call   f0100094 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a4c:	c1 ea 0c             	shr    $0xc,%edx
f0100a4f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a55:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a5c:	89 c2                	mov    %eax,%edx
f0100a5e:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a61:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a66:	85 d2                	test   %edx,%edx
f0100a68:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a6d:	0f 44 c2             	cmove  %edx,%eax
f0100a70:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a71:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a76:	c3                   	ret    

f0100a77 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a77:	55                   	push   %ebp
f0100a78:	89 e5                	mov    %esp,%ebp
f0100a7a:	83 ec 18             	sub    $0x18,%esp
f0100a7d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a80:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a83:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a85:	89 04 24             	mov    %eax,(%esp)
f0100a88:	e8 13 24 00 00       	call   f0102ea0 <mc146818_read>
f0100a8d:	89 c6                	mov    %eax,%esi
f0100a8f:	83 c3 01             	add    $0x1,%ebx
f0100a92:	89 1c 24             	mov    %ebx,(%esp)
f0100a95:	e8 06 24 00 00       	call   f0102ea0 <mc146818_read>
f0100a9a:	c1 e0 08             	shl    $0x8,%eax
f0100a9d:	09 f0                	or     %esi,%eax
}
f0100a9f:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100aa2:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100aa5:	89 ec                	mov    %ebp,%esp
f0100aa7:	5d                   	pop    %ebp
f0100aa8:	c3                   	ret    

f0100aa9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100aa9:	55                   	push   %ebp
f0100aaa:	89 e5                	mov    %esp,%ebp
f0100aac:	57                   	push   %edi
f0100aad:	56                   	push   %esi
f0100aae:	53                   	push   %ebx
f0100aaf:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ab2:	84 c0                	test   %al,%al
f0100ab4:	0f 85 39 03 00 00    	jne    f0100df3 <check_page_free_list+0x34a>
f0100aba:	e9 46 03 00 00       	jmp    f0100e05 <check_page_free_list+0x35c>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100abf:	c7 44 24 08 08 46 10 	movl   $0xf0104608,0x8(%esp)
f0100ac6:	f0 
f0100ac7:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0100ace:	00 
f0100acf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100ad6:	e8 b9 f5 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100adb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ade:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ae1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ae4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ae7:	89 c2                	mov    %eax,%edx
f0100ae9:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100aef:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100af5:	0f 95 c2             	setne  %dl
f0100af8:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100afb:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100aff:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b01:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b05:	8b 00                	mov    (%eax),%eax
f0100b07:	85 c0                	test   %eax,%eax
f0100b09:	75 dc                	jne    f0100ae7 <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b0b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b0e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b1a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b1c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b1f:	a3 58 85 11 f0       	mov    %eax,0xf0118558
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b24:	89 c3                	mov    %eax,%ebx
f0100b26:	85 c0                	test   %eax,%eax
f0100b28:	74 6c                	je     f0100b96 <check_page_free_list+0xed>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b2a:	be 01 00 00 00       	mov    $0x1,%esi
f0100b2f:	89 d8                	mov    %ebx,%eax
f0100b31:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100b37:	c1 f8 03             	sar    $0x3,%eax
f0100b3a:	c1 e0 0c             	shl    $0xc,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b3d:	89 c2                	mov    %eax,%edx
f0100b3f:	c1 ea 16             	shr    $0x16,%edx
f0100b42:	39 f2                	cmp    %esi,%edx
f0100b44:	73 4a                	jae    f0100b90 <check_page_free_list+0xe7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b46:	89 c2                	mov    %eax,%edx
f0100b48:	c1 ea 0c             	shr    $0xc,%edx
f0100b4b:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100b51:	72 20                	jb     f0100b73 <check_page_free_list+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b53:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b57:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0100b5e:	f0 
f0100b5f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100b66:	00 
f0100b67:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0100b6e:	e8 21 f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b73:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b7a:	00 
f0100b7b:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b82:	00 
	return (void *)(pa + KERNBASE);
f0100b83:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b88:	89 04 24             	mov    %eax,(%esp)
f0100b8b:	e8 15 30 00 00       	call   f0103ba5 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b90:	8b 1b                	mov    (%ebx),%ebx
f0100b92:	85 db                	test   %ebx,%ebx
f0100b94:	75 99                	jne    f0100b2f <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b96:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b9b:	e8 30 fe ff ff       	call   f01009d0 <boot_alloc>
f0100ba0:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ba3:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f0100ba9:	85 d2                	test   %edx,%edx
f0100bab:	0f 84 f6 01 00 00    	je     f0100da7 <check_page_free_list+0x2fe>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb1:	8b 1d 6c 89 11 f0    	mov    0xf011896c,%ebx
f0100bb7:	39 da                	cmp    %ebx,%edx
f0100bb9:	72 4d                	jb     f0100c08 <check_page_free_list+0x15f>
		assert(pp < pages + npages);
f0100bbb:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f0100bc0:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100bc3:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100bc6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100bc9:	39 c2                	cmp    %eax,%edx
f0100bcb:	73 64                	jae    f0100c31 <check_page_free_list+0x188>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bcd:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100bd0:	89 d0                	mov    %edx,%eax
f0100bd2:	29 d8                	sub    %ebx,%eax
f0100bd4:	a8 07                	test   $0x7,%al
f0100bd6:	0f 85 82 00 00 00    	jne    f0100c5e <check_page_free_list+0x1b5>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100bdc:	c1 f8 03             	sar    $0x3,%eax
f0100bdf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100be2:	85 c0                	test   %eax,%eax
f0100be4:	0f 84 a2 00 00 00    	je     f0100c8c <check_page_free_list+0x1e3>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bea:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bef:	0f 84 c2 00 00 00    	je     f0100cb7 <check_page_free_list+0x20e>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bf5:	be 00 00 00 00       	mov    $0x0,%esi
f0100bfa:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bff:	e9 d7 00 00 00       	jmp    f0100cdb <check_page_free_list+0x232>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c04:	39 da                	cmp    %ebx,%edx
f0100c06:	73 24                	jae    f0100c2c <check_page_free_list+0x183>
f0100c08:	c7 44 24 0c 1a 4d 10 	movl   $0xf0104d1a,0xc(%esp)
f0100c0f:	f0 
f0100c10:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100c17:	f0 
f0100c18:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0100c1f:	00 
f0100c20:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100c27:	e8 68 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100c2c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c2f:	72 24                	jb     f0100c55 <check_page_free_list+0x1ac>
f0100c31:	c7 44 24 0c 3b 4d 10 	movl   $0xf0104d3b,0xc(%esp)
f0100c38:	f0 
f0100c39:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100c40:	f0 
f0100c41:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0100c48:	00 
f0100c49:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100c50:	e8 3f f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c55:	89 d0                	mov    %edx,%eax
f0100c57:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c5a:	a8 07                	test   $0x7,%al
f0100c5c:	74 24                	je     f0100c82 <check_page_free_list+0x1d9>
f0100c5e:	c7 44 24 0c 2c 46 10 	movl   $0xf010462c,0xc(%esp)
f0100c65:	f0 
f0100c66:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100c6d:	f0 
f0100c6e:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0100c75:	00 
f0100c76:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100c7d:	e8 12 f4 ff ff       	call   f0100094 <_panic>
f0100c82:	c1 f8 03             	sar    $0x3,%eax
f0100c85:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c88:	85 c0                	test   %eax,%eax
f0100c8a:	75 24                	jne    f0100cb0 <check_page_free_list+0x207>
f0100c8c:	c7 44 24 0c 4f 4d 10 	movl   $0xf0104d4f,0xc(%esp)
f0100c93:	f0 
f0100c94:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100c9b:	f0 
f0100c9c:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0100ca3:	00 
f0100ca4:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100cab:	e8 e4 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cb0:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cb5:	75 24                	jne    f0100cdb <check_page_free_list+0x232>
f0100cb7:	c7 44 24 0c 60 4d 10 	movl   $0xf0104d60,0xc(%esp)
f0100cbe:	f0 
f0100cbf:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100cc6:	f0 
f0100cc7:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0100cce:	00 
f0100ccf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100cd6:	e8 b9 f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cdb:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ce0:	75 24                	jne    f0100d06 <check_page_free_list+0x25d>
f0100ce2:	c7 44 24 0c 60 46 10 	movl   $0xf0104660,0xc(%esp)
f0100ce9:	f0 
f0100cea:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100cf1:	f0 
f0100cf2:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0100cf9:	00 
f0100cfa:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100d01:	e8 8e f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d06:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d0b:	75 24                	jne    f0100d31 <check_page_free_list+0x288>
f0100d0d:	c7 44 24 0c 79 4d 10 	movl   $0xf0104d79,0xc(%esp)
f0100d14:	f0 
f0100d15:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100d1c:	f0 
f0100d1d:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0100d24:	00 
f0100d25:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100d2c:	e8 63 f3 ff ff       	call   f0100094 <_panic>
f0100d31:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d33:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d38:	76 57                	jbe    f0100d91 <check_page_free_list+0x2e8>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d3a:	c1 e8 0c             	shr    $0xc,%eax
f0100d3d:	3b 45 cc             	cmp    -0x34(%ebp),%eax
f0100d40:	72 20                	jb     f0100d62 <check_page_free_list+0x2b9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d42:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d46:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0100d4d:	f0 
f0100d4e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d55:	00 
f0100d56:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0100d5d:	e8 32 f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100d62:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d68:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d6b:	76 29                	jbe    f0100d96 <check_page_free_list+0x2ed>
f0100d6d:	c7 44 24 0c 84 46 10 	movl   $0xf0104684,0xc(%esp)
f0100d74:	f0 
f0100d75:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100d7c:	f0 
f0100d7d:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0100d84:	00 
f0100d85:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100d8c:	e8 03 f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d91:	83 c7 01             	add    $0x1,%edi
f0100d94:	eb 03                	jmp    f0100d99 <check_page_free_list+0x2f0>
		else
			++nfree_extmem;
f0100d96:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d99:	8b 12                	mov    (%edx),%edx
f0100d9b:	85 d2                	test   %edx,%edx
f0100d9d:	0f 85 61 fe ff ff    	jne    f0100c04 <check_page_free_list+0x15b>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100da3:	85 ff                	test   %edi,%edi
f0100da5:	7f 24                	jg     f0100dcb <check_page_free_list+0x322>
f0100da7:	c7 44 24 0c 93 4d 10 	movl   $0xf0104d93,0xc(%esp)
f0100dae:	f0 
f0100daf:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100db6:	f0 
f0100db7:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0100dbe:	00 
f0100dbf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100dc6:	e8 c9 f2 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100dcb:	85 f6                	test   %esi,%esi
f0100dcd:	7f 53                	jg     f0100e22 <check_page_free_list+0x379>
f0100dcf:	c7 44 24 0c a5 4d 10 	movl   $0xf0104da5,0xc(%esp)
f0100dd6:	f0 
f0100dd7:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100dde:	f0 
f0100ddf:	c7 44 24 04 70 02 00 	movl   $0x270,0x4(%esp)
f0100de6:	00 
f0100de7:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100dee:	e8 a1 f2 ff ff       	call   f0100094 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100df3:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f0100df8:	85 c0                	test   %eax,%eax
f0100dfa:	0f 85 db fc ff ff    	jne    f0100adb <check_page_free_list+0x32>
f0100e00:	e9 ba fc ff ff       	jmp    f0100abf <check_page_free_list+0x16>
f0100e05:	83 3d 58 85 11 f0 00 	cmpl   $0x0,0xf0118558
f0100e0c:	0f 84 ad fc ff ff    	je     f0100abf <check_page_free_list+0x16>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100e12:	8b 1d 58 85 11 f0    	mov    0xf0118558,%ebx
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e18:	be 00 04 00 00       	mov    $0x400,%esi
f0100e1d:	e9 0d fd ff ff       	jmp    f0100b2f <check_page_free_list+0x86>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100e22:	83 c4 3c             	add    $0x3c,%esp
f0100e25:	5b                   	pop    %ebx
f0100e26:	5e                   	pop    %esi
f0100e27:	5f                   	pop    %edi
f0100e28:	5d                   	pop    %ebp
f0100e29:	c3                   	ret    

f0100e2a <page_init>:
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
  size_t i;
	for (i = 0; i < npages; i++) {
f0100e2a:	83 3d 64 89 11 f0 00 	cmpl   $0x0,0xf0118964
f0100e31:	0f 84 db 00 00 00    	je     f0100f12 <page_init+0xe8>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100e37:	55                   	push   %ebp
f0100e38:	89 e5                	mov    %esp,%ebp
f0100e3a:	56                   	push   %esi
f0100e3b:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
  size_t i;
	for (i = 0; i < npages; i++) {
f0100e3c:	be 00 00 00 00       	mov    $0x0,%esi
f0100e41:	bb 00 00 00 00       	mov    $0x0,%ebx
	  if ( i == 0)
f0100e46:	85 db                	test   %ebx,%ebx
f0100e48:	75 16                	jne    f0100e60 <page_init+0x36>
	    {
	      pages[i].pp_ref = 1;
f0100e4a:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100e4f:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	      pages[i].pp_link = NULL;
f0100e55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100e5b:	e9 9d 00 00 00       	jmp    f0100efd <page_init+0xd3>
	    }
	  else if (i < npages_basemem)
f0100e60:	39 1d 50 85 11 f0    	cmp    %ebx,0xf0118550
f0100e66:	76 23                	jbe    f0100e8b <page_init+0x61>
	    {
	      pages[i].pp_ref = 0;
f0100e68:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100e6d:	01 f0                	add    %esi,%eax
f0100e6f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	      pages[i].pp_link = page_free_list;
f0100e75:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f0100e7b:	89 10                	mov    %edx,(%eax)
	      page_free_list = &pages[i];
f0100e7d:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100e82:	01 f0                	add    %esi,%eax
f0100e84:	a3 58 85 11 f0       	mov    %eax,0xf0118558
f0100e89:	eb 72                	jmp    f0100efd <page_init+0xd3>
	    }
	  else if( i >= IOPHYSMEM/PGSIZE && i <= EXTPHYSMEM/PGSIZE)
f0100e8b:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100e91:	83 f8 60             	cmp    $0x60,%eax
f0100e94:	77 14                	ja     f0100eaa <page_init+0x80>
	    {
	      pages[i].pp_ref ++;
f0100e96:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100e9b:	01 f0                	add    %esi,%eax
f0100e9d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	      pages[i].pp_link = NULL;
f0100ea2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100ea8:	eb 53                	jmp    f0100efd <page_init+0xd3>
	    }
	  else if (i > EXTPHYSMEM/PGSIZE && i< ( (uint32_t) boot_alloc(0)- KERNBASE )/ PGSIZE )
f0100eaa:	81 fb 00 01 00 00    	cmp    $0x100,%ebx
f0100eb0:	76 2a                	jbe    f0100edc <page_init+0xb2>
f0100eb2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eb7:	e8 14 fb ff ff       	call   f01009d0 <boot_alloc>
f0100ebc:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ec1:	c1 e8 0c             	shr    $0xc,%eax
f0100ec4:	39 d8                	cmp    %ebx,%eax
f0100ec6:	76 14                	jbe    f0100edc <page_init+0xb2>
	    {
	      pages[i].pp_ref ++;
f0100ec8:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100ecd:	01 f0                	add    %esi,%eax
f0100ecf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	      pages[i].pp_link = NULL;
f0100ed4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100eda:	eb 21                	jmp    f0100efd <page_init+0xd3>
	    } 
	  else
	    {
	      pages[i].pp_ref = 0;
f0100edc:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100ee1:	01 f0                	add    %esi,%eax
f0100ee3:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	      pages[i].pp_link = page_free_list;
f0100ee9:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f0100eef:	89 10                	mov    %edx,(%eax)
	      page_free_list = &pages[i];
f0100ef1:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
f0100ef6:	01 f0                	add    %esi,%eax
f0100ef8:	a3 58 85 11 f0       	mov    %eax,0xf0118558
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
  size_t i;
	for (i = 0; i < npages; i++) {
f0100efd:	83 c3 01             	add    $0x1,%ebx
f0100f00:	83 c6 08             	add    $0x8,%esi
f0100f03:	39 1d 64 89 11 f0    	cmp    %ebx,0xf0118964
f0100f09:	0f 87 37 ff ff ff    	ja     f0100e46 <page_init+0x1c>
	      pages[i].pp_link = page_free_list;
	      page_free_list = &pages[i];
	    }
	  
	}
}
f0100f0f:	5b                   	pop    %ebx
f0100f10:	5e                   	pop    %esi
f0100f11:	5d                   	pop    %ebp
f0100f12:	f3 c3                	repz ret 

f0100f14 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100f14:	55                   	push   %ebp
f0100f15:	89 e5                	mov    %esp,%ebp
f0100f17:	53                   	push   %ebx
f0100f18:	83 ec 14             	sub    $0x14,%esp

	// Fill this function in
  struct PageInfo* pp = NULL;
  if(!page_free_list)
f0100f1b:	8b 1d 58 85 11 f0    	mov    0xf0118558,%ebx
f0100f21:	85 db                	test   %ebx,%ebx
f0100f23:	74 65                	je     f0100f8a <page_alloc+0x76>
    return NULL;
  //get the first free page
  pp = page_free_list;
  //set page_free_list = next free page
  page_free_list = page_free_list->pp_link;
f0100f25:	8b 03                	mov    (%ebx),%eax
f0100f27:	a3 58 85 11 f0       	mov    %eax,0xf0118558
  if (alloc_flags & ALLOC_ZERO)
f0100f2c:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f30:	74 58                	je     f0100f8a <page_alloc+0x76>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f32:	89 d8                	mov    %ebx,%eax
f0100f34:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0100f3a:	c1 f8 03             	sar    $0x3,%eax
f0100f3d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f40:	89 c2                	mov    %eax,%edx
f0100f42:	c1 ea 0c             	shr    $0xc,%edx
f0100f45:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0100f4b:	72 20                	jb     f0100f6d <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f4d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f51:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0100f58:	f0 
f0100f59:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f60:	00 
f0100f61:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0100f68:	e8 27 f1 ff ff       	call   f0100094 <_panic>
    memset(page2kva(pp), 0 , PGSIZE);
f0100f6d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f74:	00 
f0100f75:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f7c:	00 
	return (void *)(pa + KERNBASE);
f0100f7d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f82:	89 04 24             	mov    %eax,(%esp)
f0100f85:	e8 1b 2c 00 00       	call   f0103ba5 <memset>

  return pp;
}
f0100f8a:	89 d8                	mov    %ebx,%eax
f0100f8c:	83 c4 14             	add    $0x14,%esp
f0100f8f:	5b                   	pop    %ebx
f0100f90:	5d                   	pop    %ebp
f0100f91:	c3                   	ret    

f0100f92 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100f92:	55                   	push   %ebp
f0100f93:	89 e5                	mov    %esp,%ebp
f0100f95:	83 ec 18             	sub    $0x18,%esp
f0100f98:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
  assert(pp->pp_ref == 0);
f0100f9b:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100fa0:	74 24                	je     f0100fc6 <page_free+0x34>
f0100fa2:	c7 44 24 0c b6 4d 10 	movl   $0xf0104db6,0xc(%esp)
f0100fa9:	f0 
f0100faa:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0100fb1:	f0 
f0100fb2:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f0100fb9:	00 
f0100fba:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0100fc1:	e8 ce f0 ff ff       	call   f0100094 <_panic>
   
  pp->pp_link = page_free_list;
f0100fc6:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f0100fcc:	89 10                	mov    %edx,(%eax)
  page_free_list = pp;
f0100fce:	a3 58 85 11 f0       	mov    %eax,0xf0118558
   
}
f0100fd3:	c9                   	leave  
f0100fd4:	c3                   	ret    

f0100fd5 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100fd5:	55                   	push   %ebp
f0100fd6:	89 e5                	mov    %esp,%ebp
f0100fd8:	83 ec 18             	sub    $0x18,%esp
f0100fdb:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100fde:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100fe2:	83 ea 01             	sub    $0x1,%edx
f0100fe5:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fe9:	66 85 d2             	test   %dx,%dx
f0100fec:	75 08                	jne    f0100ff6 <page_decref+0x21>
		page_free(pp);
f0100fee:	89 04 24             	mov    %eax,(%esp)
f0100ff1:	e8 9c ff ff ff       	call   f0100f92 <page_free>
}
f0100ff6:	c9                   	leave  
f0100ff7:	c3                   	ret    

f0100ff8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100ff8:	55                   	push   %ebp
f0100ff9:	89 e5                	mov    %esp,%ebp
f0100ffb:	56                   	push   %esi
f0100ffc:	53                   	push   %ebx
f0100ffd:	83 ec 10             	sub    $0x10,%esp
f0101000:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
  pde_t *virtual = NULL; //virtual address point to phsical (in page table)
  pte_t *entry = NULL; //point to the VA in the page table entry
  pte_t *pgtable = NULL;
  struct PageInfo *pp = NULL;
  virtual = &pgdir[PDX(va)];
f0101003:	89 de                	mov    %ebx,%esi
f0101005:	c1 ee 16             	shr    $0x16,%esi
f0101008:	c1 e6 02             	shl    $0x2,%esi
f010100b:	03 75 08             	add    0x8(%ebp),%esi
  if ((*virtual && PTE_P ) != 0)
f010100e:	8b 06                	mov    (%esi),%eax
f0101010:	85 c0                	test   %eax,%eax
f0101012:	74 44                	je     f0101058 <pgdir_walk+0x60>
    {
      pgtable =(pte_t*) KADDR( PTE_ADDR(*virtual) );
f0101014:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101019:	89 c2                	mov    %eax,%edx
f010101b:	c1 ea 0c             	shr    $0xc,%edx
f010101e:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101024:	72 20                	jb     f0101046 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101026:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010102a:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0101031:	f0 
f0101032:	c7 44 24 04 76 01 00 	movl   $0x176,0x4(%esp)
f0101039:	00 
f010103a:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101041:	e8 4e f0 ff ff       	call   f0100094 <_panic>
      entry = &pgtable[ PTX(va) ];
f0101046:	c1 eb 0a             	shr    $0xa,%ebx
f0101049:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f010104f:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
      return entry;
f0101056:	eb 7c                	jmp    f01010d4 <pgdir_walk+0xdc>
    }
  else
    {
      if (create == 0)
f0101058:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010105c:	74 6a                	je     f01010c8 <pgdir_walk+0xd0>
	return NULL;
      else
	{
	  pp = page_alloc(ALLOC_ZERO);
f010105e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101065:	e8 aa fe ff ff       	call   f0100f14 <page_alloc>
	  if(pp == NULL)
f010106a:	85 c0                	test   %eax,%eax
f010106c:	74 61                	je     f01010cf <pgdir_walk+0xd7>
	    {
	      return NULL;
	    }
	  else
	    {
	      pp->pp_ref ++;
f010106e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101073:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0101079:	c1 f8 03             	sar    $0x3,%eax
f010107c:	c1 e0 0c             	shl    $0xc,%eax
	      pgdir[PDX(va)] = page2pa(pp) |PTE_U | PTE_P | PTE_W;
f010107f:	83 c8 07             	or     $0x7,%eax
f0101082:	89 06                	mov    %eax,(%esi)
	      pgtable =(pte_t*) KADDR(  PTE_ADDR(*virtual));
f0101084:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101089:	89 c2                	mov    %eax,%edx
f010108b:	c1 ea 0c             	shr    $0xc,%edx
f010108e:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0101094:	72 20                	jb     f01010b6 <pgdir_walk+0xbe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101096:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010109a:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f01010a1:	f0 
f01010a2:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
f01010a9:	00 
f01010aa:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01010b1:	e8 de ef ff ff       	call   f0100094 <_panic>
	      entry = &pgtable[PTX(va)];
f01010b6:	c1 eb 0a             	shr    $0xa,%ebx
f01010b9:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01010bf:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
	      return entry;
f01010c6:	eb 0c                	jmp    f01010d4 <pgdir_walk+0xdc>
      return entry;
    }
  else
    {
      if (create == 0)
	return NULL;
f01010c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01010cd:	eb 05                	jmp    f01010d4 <pgdir_walk+0xdc>
      else
	{
	  pp = page_alloc(ALLOC_ZERO);
	  if(pp == NULL)
	    {
	      return NULL;
f01010cf:	b8 00 00 00 00       	mov    $0x0,%eax
	}
    }
  
  
  return NULL;
}
f01010d4:	83 c4 10             	add    $0x10,%esp
f01010d7:	5b                   	pop    %ebx
f01010d8:	5e                   	pop    %esi
f01010d9:	5d                   	pop    %ebp
f01010da:	c3                   	ret    

f01010db <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010db:	55                   	push   %ebp
f01010dc:	89 e5                	mov    %esp,%ebp
f01010de:	57                   	push   %edi
f01010df:	56                   	push   %esi
f01010e0:	53                   	push   %ebx
f01010e1:	83 ec 2c             	sub    $0x2c,%esp
f01010e4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
  uint32_t num = size/PGSIZE;
f01010e7:	c1 e9 0c             	shr    $0xc,%ecx
f01010ea:	89 4d e0             	mov    %ecx,-0x20(%ebp)
  uint32_t i = 0 ;
  pte_t *pte;
  size = ROUNDUP(size, PGSIZE);
  va = ROUNDDOWN(va, PGSIZE);
f01010ed:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  pa = ROUNDDOWN(pa, PGSIZE);
f01010f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01010f6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t virtual = va;
  physaddr_t physical = pa;
  //  cprintf("pa 0x%x\n",pa);
  for (i =0 ;i<num ;i++)
f01010fb:	85 c9                	test   %ecx,%ecx
f01010fd:	74 4e                	je     f010114d <boot_map_region+0x72>
  uint32_t i = 0 ;
  pte_t *pte;
  size = ROUNDUP(size, PGSIZE);
  va = ROUNDDOWN(va, PGSIZE);
  pa = ROUNDDOWN(pa, PGSIZE);
  uintptr_t virtual = va;
f01010ff:	89 d3                	mov    %edx,%ebx
  physaddr_t physical = pa;
  //  cprintf("pa 0x%x\n",pa);
  for (i =0 ;i<num ;i++)
f0101101:	be 00 00 00 00       	mov    $0x0,%esi
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101106:	29 d0                	sub    %edx,%eax
f0101108:	89 45 d8             	mov    %eax,-0x28(%ebp)
  for (i =0 ;i<num ;i++)
    {
      pte = pgdir_walk(pgdir,(void *) virtual, 1);
      if(!pte)
	return ;
      *pte = (PTE_ADDR(physical) |perm| PTE_P);
f010110b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010110e:	83 c8 01             	or     $0x1,%eax
f0101111:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// above UTOP. As such, it should *not* change the pp_ref field on the
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
f0101114:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101117:	01 df                	add    %ebx,%edi
  uintptr_t virtual = va;
  physaddr_t physical = pa;
  //  cprintf("pa 0x%x\n",pa);
  for (i =0 ;i<num ;i++)
    {
      pte = pgdir_walk(pgdir,(void *) virtual, 1);
f0101119:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101120:	00 
f0101121:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101125:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101128:	89 04 24             	mov    %eax,(%esp)
f010112b:	e8 c8 fe ff ff       	call   f0100ff8 <pgdir_walk>
      if(!pte)
f0101130:	85 c0                	test   %eax,%eax
f0101132:	74 19                	je     f010114d <boot_map_region+0x72>
	return ;
      *pte = (PTE_ADDR(physical) |perm| PTE_P);
f0101134:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010113a:	0b 7d e4             	or     -0x1c(%ebp),%edi
f010113d:	89 38                	mov    %edi,(%eax)
      virtual += PGSIZE;
f010113f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
  va = ROUNDDOWN(va, PGSIZE);
  pa = ROUNDDOWN(pa, PGSIZE);
  uintptr_t virtual = va;
  physaddr_t physical = pa;
  //  cprintf("pa 0x%x\n",pa);
  for (i =0 ;i<num ;i++)
f0101145:	83 c6 01             	add    $0x1,%esi
f0101148:	3b 75 e0             	cmp    -0x20(%ebp),%esi
f010114b:	75 c7                	jne    f0101114 <boot_map_region+0x39>
      *pte = (PTE_ADDR(physical) |perm| PTE_P);
      virtual += PGSIZE;
      physical += PGSIZE;
    }
  
}
f010114d:	83 c4 2c             	add    $0x2c,%esp
f0101150:	5b                   	pop    %ebx
f0101151:	5e                   	pop    %esi
f0101152:	5f                   	pop    %edi
f0101153:	5d                   	pop    %ebp
f0101154:	c3                   	ret    

f0101155 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101155:	55                   	push   %ebp
f0101156:	89 e5                	mov    %esp,%ebp
f0101158:	53                   	push   %ebx
f0101159:	83 ec 14             	sub    $0x14,%esp
f010115c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
  pte_t *entry = pgdir_walk(pgdir, va, 0);
f010115f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101166:	00 
f0101167:	8b 45 0c             	mov    0xc(%ebp),%eax
f010116a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010116e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101171:	89 04 24             	mov    %eax,(%esp)
f0101174:	e8 7f fe ff ff       	call   f0100ff8 <pgdir_walk>
  if(!entry)
f0101179:	85 c0                	test   %eax,%eax
f010117b:	74 3a                	je     f01011b7 <page_lookup+0x62>
    return NULL;
  if(pte_store)
f010117d:	85 db                	test   %ebx,%ebx
f010117f:	74 02                	je     f0101183 <page_lookup+0x2e>
    {
      *pte_store = entry;
f0101181:	89 03                	mov    %eax,(%ebx)
    }
  //RETURN PAGE ADDRESS (transfer to physical address and return PGNUM(pa))
  return pa2page(  PTE_ADDR(*entry) );
f0101183:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101185:	c1 e8 0c             	shr    $0xc,%eax
f0101188:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f010118e:	72 1c                	jb     f01011ac <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101190:	c7 44 24 08 cc 46 10 	movl   $0xf01046cc,0x8(%esp)
f0101197:	f0 
f0101198:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010119f:	00 
f01011a0:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f01011a7:	e8 e8 ee ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01011ac:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f01011b2:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01011b5:	eb 05                	jmp    f01011bc <page_lookup+0x67>
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	// Fill this function in
  pte_t *entry = pgdir_walk(pgdir, va, 0);
  if(!entry)
    return NULL;
f01011b7:	b8 00 00 00 00       	mov    $0x0,%eax
    {
      *pte_store = entry;
    }
  //RETURN PAGE ADDRESS (transfer to physical address and return PGNUM(pa))
  return pa2page(  PTE_ADDR(*entry) );
}
f01011bc:	83 c4 14             	add    $0x14,%esp
f01011bf:	5b                   	pop    %ebx
f01011c0:	5d                   	pop    %ebp
f01011c1:	c3                   	ret    

f01011c2 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01011c2:	55                   	push   %ebp
f01011c3:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01011c5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c8:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01011cb:	5d                   	pop    %ebp
f01011cc:	c3                   	ret    

f01011cd <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01011cd:	55                   	push   %ebp
f01011ce:	89 e5                	mov    %esp,%ebp
f01011d0:	83 ec 28             	sub    $0x28,%esp
f01011d3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01011d6:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01011d9:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011dc:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
  pte_t *pte;
  pte_t **pte_store = &pte;
f01011df:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01011e2:	89 44 24 08          	mov    %eax,0x8(%esp)
  struct PageInfo *pp = page_lookup(pgdir, va, pte_store);
f01011e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01011ea:	89 1c 24             	mov    %ebx,(%esp)
f01011ed:	e8 63 ff ff ff       	call   f0101155 <page_lookup>
  if( pp == NULL )
f01011f2:	85 c0                	test   %eax,%eax
f01011f4:	74 1d                	je     f0101213 <page_remove+0x46>
    return ;
  page_decref(pp);
f01011f6:	89 04 24             	mov    %eax,(%esp)
f01011f9:	e8 d7 fd ff ff       	call   f0100fd5 <page_decref>
  **pte_store = 0;
f01011fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101201:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  tlb_invalidate(pgdir, va);
f0101207:	89 74 24 04          	mov    %esi,0x4(%esp)
f010120b:	89 1c 24             	mov    %ebx,(%esp)
f010120e:	e8 af ff ff ff       	call   f01011c2 <tlb_invalidate>
}
f0101213:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101216:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101219:	89 ec                	mov    %ebp,%esp
f010121b:	5d                   	pop    %ebp
f010121c:	c3                   	ret    

f010121d <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010121d:	55                   	push   %ebp
f010121e:	89 e5                	mov    %esp,%ebp
f0101220:	83 ec 28             	sub    $0x28,%esp
f0101223:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101226:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101229:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010122c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
  pte_t *pte = pgdir_walk(pgdir, va, 0 );
f010122f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101236:	00 
f0101237:	8b 45 10             	mov    0x10(%ebp),%eax
f010123a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010123e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101241:	89 04 24             	mov    %eax,(%esp)
f0101244:	e8 af fd ff ff       	call   f0100ff8 <pgdir_walk>
f0101249:	89 c6                	mov    %eax,%esi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010124b:	89 df                	mov    %ebx,%edi
f010124d:	2b 3d 6c 89 11 f0    	sub    0xf011896c,%edi
f0101253:	c1 ff 03             	sar    $0x3,%edi
f0101256:	c1 e7 0c             	shl    $0xc,%edi
  uint32_t physical = page2pa(pp);
  if( pte != NULL)
f0101259:	85 c0                	test   %eax,%eax
f010125b:	74 29                	je     f0101286 <page_insert+0x69>
    {
      //page already mapped
      //if present
      if(*pte & PTE_P)
f010125d:	f6 00 01             	testb  $0x1,(%eax)
f0101260:	74 12                	je     f0101274 <page_insert+0x57>
	page_remove(pgdir, va);
f0101262:	8b 45 10             	mov    0x10(%ebp),%eax
f0101265:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101269:	8b 45 08             	mov    0x8(%ebp),%eax
f010126c:	89 04 24             	mov    %eax,(%esp)
f010126f:	e8 59 ff ff ff       	call   f01011cd <page_remove>
      if (page_free_list == pp)
f0101274:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f0101279:	39 d8                	cmp    %ebx,%eax
f010127b:	75 3c                	jne    f01012b9 <page_insert+0x9c>
	page_free_list = page_free_list->pp_link;
f010127d:	8b 00                	mov    (%eax),%eax
f010127f:	a3 58 85 11 f0       	mov    %eax,0xf0118558
f0101284:	eb 33                	jmp    f01012b9 <page_insert+0x9c>
    }
  else
    {
      pte = pgdir_walk(pgdir, va, 1);
f0101286:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010128d:	00 
f010128e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101291:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101295:	8b 45 08             	mov    0x8(%ebp),%eax
f0101298:	89 04 24             	mov    %eax,(%esp)
f010129b:	e8 58 fd ff ff       	call   f0100ff8 <pgdir_walk>
f01012a0:	89 c6                	mov    %eax,%esi
      if( pte == NULL)
f01012a2:	85 c0                	test   %eax,%eax
f01012a4:	75 13                	jne    f01012b9 <page_insert+0x9c>
	{
	  cprintf("not enough memory\n");
f01012a6:	c7 04 24 c6 4d 10 f0 	movl   $0xf0104dc6,(%esp)
f01012ad:	e8 60 1c 00 00       	call   f0102f12 <cprintf>
	  return -E_NO_MEM;
f01012b2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01012b7:	eb 26                	jmp    f01012df <page_insert+0xc2>
	}      
    }
  //insert a page
  *pte = physical | PTE_P | perm;
f01012b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01012bc:	83 c8 01             	or     $0x1,%eax
f01012bf:	09 c7                	or     %eax,%edi
f01012c1:	89 3e                	mov    %edi,(%esi)
  pp->pp_ref ++;
f01012c3:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
  tlb_invalidate(pgdir, va);
f01012c8:	8b 45 10             	mov    0x10(%ebp),%eax
f01012cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d2:	89 04 24             	mov    %eax,(%esp)
f01012d5:	e8 e8 fe ff ff       	call   f01011c2 <tlb_invalidate>
  return 0;
f01012da:	b8 00 00 00 00       	mov    $0x0,%eax
					     
}
f01012df:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01012e2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01012e5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01012e8:	89 ec                	mov    %ebp,%esp
f01012ea:	5d                   	pop    %ebp
f01012eb:	c3                   	ret    

f01012ec <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01012ec:	55                   	push   %ebp
f01012ed:	89 e5                	mov    %esp,%ebp
f01012ef:	57                   	push   %edi
f01012f0:	56                   	push   %esi
f01012f1:	53                   	push   %ebx
f01012f2:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01012f5:	b8 15 00 00 00       	mov    $0x15,%eax
f01012fa:	e8 78 f7 ff ff       	call   f0100a77 <nvram_read>
f01012ff:	c1 e0 0a             	shl    $0xa,%eax
f0101302:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101308:	85 c0                	test   %eax,%eax
f010130a:	0f 48 c2             	cmovs  %edx,%eax
f010130d:	c1 f8 0c             	sar    $0xc,%eax
f0101310:	a3 50 85 11 f0       	mov    %eax,0xf0118550
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101315:	b8 17 00 00 00       	mov    $0x17,%eax
f010131a:	e8 58 f7 ff ff       	call   f0100a77 <nvram_read>
f010131f:	c1 e0 0a             	shl    $0xa,%eax
f0101322:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101328:	85 c0                	test   %eax,%eax
f010132a:	0f 48 c2             	cmovs  %edx,%eax
f010132d:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101330:	85 c0                	test   %eax,%eax
f0101332:	74 0e                	je     f0101342 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101334:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010133a:	89 15 64 89 11 f0    	mov    %edx,0xf0118964
f0101340:	eb 0c                	jmp    f010134e <mem_init+0x62>
	else
		npages = npages_basemem;
f0101342:	8b 15 50 85 11 f0    	mov    0xf0118550,%edx
f0101348:	89 15 64 89 11 f0    	mov    %edx,0xf0118964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010134e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101351:	c1 e8 0a             	shr    $0xa,%eax
f0101354:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101358:	a1 50 85 11 f0       	mov    0xf0118550,%eax
f010135d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101360:	c1 e8 0a             	shr    $0xa,%eax
f0101363:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101367:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f010136c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010136f:	c1 e8 0a             	shr    $0xa,%eax
f0101372:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101376:	c7 04 24 ec 46 10 f0 	movl   $0xf01046ec,(%esp)
f010137d:	e8 90 1b 00 00       	call   f0102f12 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101382:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101387:	e8 44 f6 ff ff       	call   f01009d0 <boot_alloc>
f010138c:	a3 68 89 11 f0       	mov    %eax,0xf0118968
	memset(kern_pgdir, 0, PGSIZE);
f0101391:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101398:	00 
f0101399:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013a0:	00 
f01013a1:	89 04 24             	mov    %eax,(%esp)
f01013a4:	e8 fc 27 00 00       	call   f0103ba5 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013a9:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013ae:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013b3:	77 20                	ja     f01013d5 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013b5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013b9:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f01013c0:	f0 
f01013c1:	c7 44 24 04 8c 00 00 	movl   $0x8c,0x4(%esp)
f01013c8:	00 
f01013c9:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01013d0:	e8 bf ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01013d5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01013db:	83 ca 05             	or     $0x5,%edx
f01013de:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(sizeof (struct PageInfo) * npages);
f01013e4:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f01013e9:	c1 e0 03             	shl    $0x3,%eax
f01013ec:	e8 df f5 ff ff       	call   f01009d0 <boot_alloc>
f01013f1:	a3 6c 89 11 f0       	mov    %eax,0xf011896c
	cprintf ("pages start at %x\n", (uint32_t) pages);
f01013f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013fa:	c7 04 24 d9 4d 10 f0 	movl   $0xf0104dd9,(%esp)
f0101401:	e8 0c 1b 00 00       	call   f0102f12 <cprintf>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101406:	e8 1f fa ff ff       	call   f0100e2a <page_init>

	check_page_free_list(1);
f010140b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101410:	e8 94 f6 ff ff       	call   f0100aa9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101415:	83 3d 6c 89 11 f0 00 	cmpl   $0x0,0xf011896c
f010141c:	75 1c                	jne    f010143a <mem_init+0x14e>
		panic("'pages' is a null pointer!");
f010141e:	c7 44 24 08 ec 4d 10 	movl   $0xf0104dec,0x8(%esp)
f0101425:	f0 
f0101426:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010142d:	00 
f010142e:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101435:	e8 5a ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010143a:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f010143f:	85 c0                	test   %eax,%eax
f0101441:	74 10                	je     f0101453 <mem_init+0x167>
f0101443:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;
f0101448:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010144b:	8b 00                	mov    (%eax),%eax
f010144d:	85 c0                	test   %eax,%eax
f010144f:	75 f7                	jne    f0101448 <mem_init+0x15c>
f0101451:	eb 05                	jmp    f0101458 <mem_init+0x16c>
f0101453:	bb 00 00 00 00       	mov    $0x0,%ebx
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101458:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010145f:	e8 b0 fa ff ff       	call   f0100f14 <page_alloc>
f0101464:	89 c7                	mov    %eax,%edi
f0101466:	85 c0                	test   %eax,%eax
f0101468:	75 24                	jne    f010148e <mem_init+0x1a2>
f010146a:	c7 44 24 0c 07 4e 10 	movl   $0xf0104e07,0xc(%esp)
f0101471:	f0 
f0101472:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101479:	f0 
f010147a:	c7 44 24 04 89 02 00 	movl   $0x289,0x4(%esp)
f0101481:	00 
f0101482:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101489:	e8 06 ec ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010148e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101495:	e8 7a fa ff ff       	call   f0100f14 <page_alloc>
f010149a:	89 c6                	mov    %eax,%esi
f010149c:	85 c0                	test   %eax,%eax
f010149e:	75 24                	jne    f01014c4 <mem_init+0x1d8>
f01014a0:	c7 44 24 0c 1d 4e 10 	movl   $0xf0104e1d,0xc(%esp)
f01014a7:	f0 
f01014a8:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01014af:	f0 
f01014b0:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f01014b7:	00 
f01014b8:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01014bf:	e8 d0 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01014c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014cb:	e8 44 fa ff ff       	call   f0100f14 <page_alloc>
f01014d0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014d3:	85 c0                	test   %eax,%eax
f01014d5:	75 24                	jne    f01014fb <mem_init+0x20f>
f01014d7:	c7 44 24 0c 33 4e 10 	movl   $0xf0104e33,0xc(%esp)
f01014de:	f0 
f01014df:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01014e6:	f0 
f01014e7:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f01014ee:	00 
f01014ef:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01014f6:	e8 99 eb ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01014fb:	39 f7                	cmp    %esi,%edi
f01014fd:	75 24                	jne    f0101523 <mem_init+0x237>
f01014ff:	c7 44 24 0c 49 4e 10 	movl   $0xf0104e49,0xc(%esp)
f0101506:	f0 
f0101507:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010150e:	f0 
f010150f:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f0101516:	00 
f0101517:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010151e:	e8 71 eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101523:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101526:	74 05                	je     f010152d <mem_init+0x241>
f0101528:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010152b:	75 24                	jne    f0101551 <mem_init+0x265>
f010152d:	c7 44 24 0c 4c 47 10 	movl   $0xf010474c,0xc(%esp)
f0101534:	f0 
f0101535:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010153c:	f0 
f010153d:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101544:	00 
f0101545:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010154c:	e8 43 eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101551:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101557:	a1 64 89 11 f0       	mov    0xf0118964,%eax
f010155c:	c1 e0 0c             	shl    $0xc,%eax
f010155f:	89 f9                	mov    %edi,%ecx
f0101561:	29 d1                	sub    %edx,%ecx
f0101563:	c1 f9 03             	sar    $0x3,%ecx
f0101566:	c1 e1 0c             	shl    $0xc,%ecx
f0101569:	39 c1                	cmp    %eax,%ecx
f010156b:	72 24                	jb     f0101591 <mem_init+0x2a5>
f010156d:	c7 44 24 0c 5b 4e 10 	movl   $0xf0104e5b,0xc(%esp)
f0101574:	f0 
f0101575:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010157c:	f0 
f010157d:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101584:	00 
f0101585:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010158c:	e8 03 eb ff ff       	call   f0100094 <_panic>
f0101591:	89 f1                	mov    %esi,%ecx
f0101593:	29 d1                	sub    %edx,%ecx
f0101595:	c1 f9 03             	sar    $0x3,%ecx
f0101598:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010159b:	39 c8                	cmp    %ecx,%eax
f010159d:	77 24                	ja     f01015c3 <mem_init+0x2d7>
f010159f:	c7 44 24 0c 78 4e 10 	movl   $0xf0104e78,0xc(%esp)
f01015a6:	f0 
f01015a7:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01015ae:	f0 
f01015af:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f01015b6:	00 
f01015b7:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01015be:	e8 d1 ea ff ff       	call   f0100094 <_panic>
f01015c3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015c6:	29 d1                	sub    %edx,%ecx
f01015c8:	89 ca                	mov    %ecx,%edx
f01015ca:	c1 fa 03             	sar    $0x3,%edx
f01015cd:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01015d0:	39 d0                	cmp    %edx,%eax
f01015d2:	77 24                	ja     f01015f8 <mem_init+0x30c>
f01015d4:	c7 44 24 0c 95 4e 10 	movl   $0xf0104e95,0xc(%esp)
f01015db:	f0 
f01015dc:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01015e3:	f0 
f01015e4:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f01015eb:	00 
f01015ec:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01015f3:	e8 9c ea ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01015f8:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f01015fd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101600:	c7 05 58 85 11 f0 00 	movl   $0x0,0xf0118558
f0101607:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010160a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101611:	e8 fe f8 ff ff       	call   f0100f14 <page_alloc>
f0101616:	85 c0                	test   %eax,%eax
f0101618:	74 24                	je     f010163e <mem_init+0x352>
f010161a:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f0101621:	f0 
f0101622:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101629:	f0 
f010162a:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101631:	00 
f0101632:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101639:	e8 56 ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010163e:	89 3c 24             	mov    %edi,(%esp)
f0101641:	e8 4c f9 ff ff       	call   f0100f92 <page_free>
	page_free(pp1);
f0101646:	89 34 24             	mov    %esi,(%esp)
f0101649:	e8 44 f9 ff ff       	call   f0100f92 <page_free>
	page_free(pp2);
f010164e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101651:	89 04 24             	mov    %eax,(%esp)
f0101654:	e8 39 f9 ff ff       	call   f0100f92 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101659:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101660:	e8 af f8 ff ff       	call   f0100f14 <page_alloc>
f0101665:	89 c6                	mov    %eax,%esi
f0101667:	85 c0                	test   %eax,%eax
f0101669:	75 24                	jne    f010168f <mem_init+0x3a3>
f010166b:	c7 44 24 0c 07 4e 10 	movl   $0xf0104e07,0xc(%esp)
f0101672:	f0 
f0101673:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010167a:	f0 
f010167b:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0101682:	00 
f0101683:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010168a:	e8 05 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010168f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101696:	e8 79 f8 ff ff       	call   f0100f14 <page_alloc>
f010169b:	89 c7                	mov    %eax,%edi
f010169d:	85 c0                	test   %eax,%eax
f010169f:	75 24                	jne    f01016c5 <mem_init+0x3d9>
f01016a1:	c7 44 24 0c 1d 4e 10 	movl   $0xf0104e1d,0xc(%esp)
f01016a8:	f0 
f01016a9:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01016b0:	f0 
f01016b1:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f01016b8:	00 
f01016b9:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01016c0:	e8 cf e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01016c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016cc:	e8 43 f8 ff ff       	call   f0100f14 <page_alloc>
f01016d1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	75 24                	jne    f01016fc <mem_init+0x410>
f01016d8:	c7 44 24 0c 33 4e 10 	movl   $0xf0104e33,0xc(%esp)
f01016df:	f0 
f01016e0:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01016e7:	f0 
f01016e8:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f01016ef:	00 
f01016f0:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01016f7:	e8 98 e9 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016fc:	39 fe                	cmp    %edi,%esi
f01016fe:	75 24                	jne    f0101724 <mem_init+0x438>
f0101700:	c7 44 24 0c 49 4e 10 	movl   $0xf0104e49,0xc(%esp)
f0101707:	f0 
f0101708:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010170f:	f0 
f0101710:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0101717:	00 
f0101718:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010171f:	e8 70 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101724:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101727:	74 05                	je     f010172e <mem_init+0x442>
f0101729:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010172c:	75 24                	jne    f0101752 <mem_init+0x466>
f010172e:	c7 44 24 0c 4c 47 10 	movl   $0xf010474c,0xc(%esp)
f0101735:	f0 
f0101736:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010173d:	f0 
f010173e:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0101745:	00 
f0101746:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010174d:	e8 42 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101752:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101759:	e8 b6 f7 ff ff       	call   f0100f14 <page_alloc>
f010175e:	85 c0                	test   %eax,%eax
f0101760:	74 24                	je     f0101786 <mem_init+0x49a>
f0101762:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f0101769:	f0 
f010176a:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101771:	f0 
f0101772:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0101779:	00 
f010177a:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101781:	e8 0e e9 ff ff       	call   f0100094 <_panic>
f0101786:	89 f0                	mov    %esi,%eax
f0101788:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f010178e:	c1 f8 03             	sar    $0x3,%eax
f0101791:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101794:	89 c2                	mov    %eax,%edx
f0101796:	c1 ea 0c             	shr    $0xc,%edx
f0101799:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f010179f:	72 20                	jb     f01017c1 <mem_init+0x4d5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017a5:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f01017ac:	f0 
f01017ad:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017b4:	00 
f01017b5:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f01017bc:	e8 d3 e8 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01017c1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01017c8:	00 
f01017c9:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01017d0:	00 
	return (void *)(pa + KERNBASE);
f01017d1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01017d6:	89 04 24             	mov    %eax,(%esp)
f01017d9:	e8 c7 23 00 00       	call   f0103ba5 <memset>
	page_free(pp0);
f01017de:	89 34 24             	mov    %esi,(%esp)
f01017e1:	e8 ac f7 ff ff       	call   f0100f92 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01017e6:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01017ed:	e8 22 f7 ff ff       	call   f0100f14 <page_alloc>
f01017f2:	85 c0                	test   %eax,%eax
f01017f4:	75 24                	jne    f010181a <mem_init+0x52e>
f01017f6:	c7 44 24 0c c1 4e 10 	movl   $0xf0104ec1,0xc(%esp)
f01017fd:	f0 
f01017fe:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101805:	f0 
f0101806:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f010180d:	00 
f010180e:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101815:	e8 7a e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010181a:	39 c6                	cmp    %eax,%esi
f010181c:	74 24                	je     f0101842 <mem_init+0x556>
f010181e:	c7 44 24 0c df 4e 10 	movl   $0xf0104edf,0xc(%esp)
f0101825:	f0 
f0101826:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010182d:	f0 
f010182e:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f0101835:	00 
f0101836:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010183d:	e8 52 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101842:	89 f2                	mov    %esi,%edx
f0101844:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f010184a:	c1 fa 03             	sar    $0x3,%edx
f010184d:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101850:	89 d0                	mov    %edx,%eax
f0101852:	c1 e8 0c             	shr    $0xc,%eax
f0101855:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f010185b:	72 20                	jb     f010187d <mem_init+0x591>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010185d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101861:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0101868:	f0 
f0101869:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101870:	00 
f0101871:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0101878:	e8 17 e8 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010187d:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101884:	75 11                	jne    f0101897 <mem_init+0x5ab>
f0101886:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010188c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101892:	80 38 00             	cmpb   $0x0,(%eax)
f0101895:	74 24                	je     f01018bb <mem_init+0x5cf>
f0101897:	c7 44 24 0c ef 4e 10 	movl   $0xf0104eef,0xc(%esp)
f010189e:	f0 
f010189f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01018a6:	f0 
f01018a7:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f01018ae:	00 
f01018af:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01018b6:	e8 d9 e7 ff ff       	call   f0100094 <_panic>
f01018bb:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018be:	39 d0                	cmp    %edx,%eax
f01018c0:	75 d0                	jne    f0101892 <mem_init+0x5a6>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01018c2:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01018c5:	89 15 58 85 11 f0    	mov    %edx,0xf0118558

	// free the pages we took
	page_free(pp0);
f01018cb:	89 34 24             	mov    %esi,(%esp)
f01018ce:	e8 bf f6 ff ff       	call   f0100f92 <page_free>
	page_free(pp1);
f01018d3:	89 3c 24             	mov    %edi,(%esp)
f01018d6:	e8 b7 f6 ff ff       	call   f0100f92 <page_free>
	page_free(pp2);
f01018db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018de:	89 04 24             	mov    %eax,(%esp)
f01018e1:	e8 ac f6 ff ff       	call   f0100f92 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018e6:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f01018eb:	85 c0                	test   %eax,%eax
f01018ed:	74 09                	je     f01018f8 <mem_init+0x60c>
		--nfree;
f01018ef:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018f2:	8b 00                	mov    (%eax),%eax
f01018f4:	85 c0                	test   %eax,%eax
f01018f6:	75 f7                	jne    f01018ef <mem_init+0x603>
		--nfree;
	assert(nfree == 0);
f01018f8:	85 db                	test   %ebx,%ebx
f01018fa:	74 24                	je     f0101920 <mem_init+0x634>
f01018fc:	c7 44 24 0c f9 4e 10 	movl   $0xf0104ef9,0xc(%esp)
f0101903:	f0 
f0101904:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010190b:	f0 
f010190c:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0101913:	00 
f0101914:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010191b:	e8 74 e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101920:	c7 04 24 6c 47 10 f0 	movl   $0xf010476c,(%esp)
f0101927:	e8 e6 15 00 00       	call   f0102f12 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010192c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101933:	e8 dc f5 ff ff       	call   f0100f14 <page_alloc>
f0101938:	89 c6                	mov    %eax,%esi
f010193a:	85 c0                	test   %eax,%eax
f010193c:	75 24                	jne    f0101962 <mem_init+0x676>
f010193e:	c7 44 24 0c 07 4e 10 	movl   $0xf0104e07,0xc(%esp)
f0101945:	f0 
f0101946:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010194d:	f0 
f010194e:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101955:	00 
f0101956:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010195d:	e8 32 e7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101962:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101969:	e8 a6 f5 ff ff       	call   f0100f14 <page_alloc>
f010196e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101971:	85 c0                	test   %eax,%eax
f0101973:	75 24                	jne    f0101999 <mem_init+0x6ad>
f0101975:	c7 44 24 0c 1d 4e 10 	movl   $0xf0104e1d,0xc(%esp)
f010197c:	f0 
f010197d:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101984:	f0 
f0101985:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f010198c:	00 
f010198d:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101994:	e8 fb e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101999:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a0:	e8 6f f5 ff ff       	call   f0100f14 <page_alloc>
f01019a5:	89 c3                	mov    %eax,%ebx
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	75 24                	jne    f01019cf <mem_init+0x6e3>
f01019ab:	c7 44 24 0c 33 4e 10 	movl   $0xf0104e33,0xc(%esp)
f01019b2:	f0 
f01019b3:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01019ba:	f0 
f01019bb:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f01019c2:	00 
f01019c3:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01019ca:	e8 c5 e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019cf:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01019d2:	75 24                	jne    f01019f8 <mem_init+0x70c>
f01019d4:	c7 44 24 0c 49 4e 10 	movl   $0xf0104e49,0xc(%esp)
f01019db:	f0 
f01019dc:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01019e3:	f0 
f01019e4:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f01019eb:	00 
f01019ec:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01019f3:	e8 9c e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019f8:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019fb:	74 04                	je     f0101a01 <mem_init+0x715>
f01019fd:	39 c6                	cmp    %eax,%esi
f01019ff:	75 24                	jne    f0101a25 <mem_init+0x739>
f0101a01:	c7 44 24 0c 4c 47 10 	movl   $0xf010474c,0xc(%esp)
f0101a08:	f0 
f0101a09:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101a10:	f0 
f0101a11:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101a18:	00 
f0101a19:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101a20:	e8 6f e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a25:	8b 3d 58 85 11 f0    	mov    0xf0118558,%edi
f0101a2b:	89 7d c8             	mov    %edi,-0x38(%ebp)
	page_free_list = 0;
f0101a2e:	c7 05 58 85 11 f0 00 	movl   $0x0,0xf0118558
f0101a35:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a3f:	e8 d0 f4 ff ff       	call   f0100f14 <page_alloc>
f0101a44:	85 c0                	test   %eax,%eax
f0101a46:	74 24                	je     f0101a6c <mem_init+0x780>
f0101a48:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f0101a4f:	f0 
f0101a50:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101a57:	f0 
f0101a58:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0101a5f:	00 
f0101a60:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101a67:	e8 28 e6 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a6c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a6f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a73:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a7a:	00 
f0101a7b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101a80:	89 04 24             	mov    %eax,(%esp)
f0101a83:	e8 cd f6 ff ff       	call   f0101155 <page_lookup>
f0101a88:	85 c0                	test   %eax,%eax
f0101a8a:	74 24                	je     f0101ab0 <mem_init+0x7c4>
f0101a8c:	c7 44 24 0c 8c 47 10 	movl   $0xf010478c,0xc(%esp)
f0101a93:	f0 
f0101a94:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101a9b:	f0 
f0101a9c:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101aa3:	00 
f0101aa4:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101aab:	e8 e4 e5 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ab0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ab7:	00 
f0101ab8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101abf:	00 
f0101ac0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ac3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101ac7:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101acc:	89 04 24             	mov    %eax,(%esp)
f0101acf:	e8 49 f7 ff ff       	call   f010121d <page_insert>
f0101ad4:	85 c0                	test   %eax,%eax
f0101ad6:	78 24                	js     f0101afc <mem_init+0x810>
f0101ad8:	c7 44 24 0c c4 47 10 	movl   $0xf01047c4,0xc(%esp)
f0101adf:	f0 
f0101ae0:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101ae7:	f0 
f0101ae8:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101aef:	00 
f0101af0:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101af7:	e8 98 e5 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101afc:	89 34 24             	mov    %esi,(%esp)
f0101aff:	e8 8e f4 ff ff       	call   f0100f92 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b04:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b0b:	00 
f0101b0c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b13:	00 
f0101b14:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b1b:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101b20:	89 04 24             	mov    %eax,(%esp)
f0101b23:	e8 f5 f6 ff ff       	call   f010121d <page_insert>
f0101b28:	85 c0                	test   %eax,%eax
f0101b2a:	74 24                	je     f0101b50 <mem_init+0x864>
f0101b2c:	c7 44 24 0c f4 47 10 	movl   $0xf01047f4,0xc(%esp)
f0101b33:	f0 
f0101b34:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101b43:	00 
f0101b44:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101b4b:	e8 44 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b50:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b56:	8b 15 6c 89 11 f0    	mov    0xf011896c,%edx
f0101b5c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101b5f:	8b 17                	mov    (%edi),%edx
f0101b61:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b67:	89 f0                	mov    %esi,%eax
f0101b69:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101b6c:	c1 f8 03             	sar    $0x3,%eax
f0101b6f:	c1 e0 0c             	shl    $0xc,%eax
f0101b72:	39 c2                	cmp    %eax,%edx
f0101b74:	74 24                	je     f0101b9a <mem_init+0x8ae>
f0101b76:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f0101b7d:	f0 
f0101b7e:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101b85:	f0 
f0101b86:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101b8d:	00 
f0101b8e:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101b95:	e8 fa e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b9a:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b9f:	89 f8                	mov    %edi,%eax
f0101ba1:	e8 62 ee ff ff       	call   f0100a08 <check_va2pa>
f0101ba6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ba9:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101bac:	c1 fa 03             	sar    $0x3,%edx
f0101baf:	c1 e2 0c             	shl    $0xc,%edx
f0101bb2:	39 d0                	cmp    %edx,%eax
f0101bb4:	74 24                	je     f0101bda <mem_init+0x8ee>
f0101bb6:	c7 44 24 0c 4c 48 10 	movl   $0xf010484c,0xc(%esp)
f0101bbd:	f0 
f0101bbe:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101bc5:	f0 
f0101bc6:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0101bcd:	00 
f0101bce:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101bd5:	e8 ba e4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101bda:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bdd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101be2:	74 24                	je     f0101c08 <mem_init+0x91c>
f0101be4:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f0101beb:	f0 
f0101bec:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101bf3:	f0 
f0101bf4:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101bfb:	00 
f0101bfc:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101c03:	e8 8c e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101c08:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c0d:	74 24                	je     f0101c33 <mem_init+0x947>
f0101c0f:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0101c16:	f0 
f0101c17:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101c1e:	f0 
f0101c1f:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101c26:	00 
f0101c27:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101c2e:	e8 61 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c33:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c3a:	00 
f0101c3b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c42:	00 
f0101c43:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101c47:	89 3c 24             	mov    %edi,(%esp)
f0101c4a:	e8 ce f5 ff ff       	call   f010121d <page_insert>
f0101c4f:	85 c0                	test   %eax,%eax
f0101c51:	74 24                	je     f0101c77 <mem_init+0x98b>
f0101c53:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0101c5a:	f0 
f0101c5b:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101c62:	f0 
f0101c63:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101c6a:	00 
f0101c6b:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101c72:	e8 1d e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c77:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c7c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101c81:	e8 82 ed ff ff       	call   f0100a08 <check_va2pa>
f0101c86:	89 da                	mov    %ebx,%edx
f0101c88:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101c8e:	c1 fa 03             	sar    $0x3,%edx
f0101c91:	c1 e2 0c             	shl    $0xc,%edx
f0101c94:	39 d0                	cmp    %edx,%eax
f0101c96:	74 24                	je     f0101cbc <mem_init+0x9d0>
f0101c98:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f0101c9f:	f0 
f0101ca0:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101ca7:	f0 
f0101ca8:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101caf:	00 
f0101cb0:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101cb7:	e8 d8 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cbc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101cc1:	74 24                	je     f0101ce7 <mem_init+0x9fb>
f0101cc3:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0101cca:	f0 
f0101ccb:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101cd2:	f0 
f0101cd3:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101cda:	00 
f0101cdb:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101ce2:	e8 ad e3 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101ce7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cee:	e8 21 f2 ff ff       	call   f0100f14 <page_alloc>
f0101cf3:	85 c0                	test   %eax,%eax
f0101cf5:	74 24                	je     f0101d1b <mem_init+0xa2f>
f0101cf7:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101d06:	f0 
f0101d07:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101d0e:	00 
f0101d0f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101d16:	e8 79 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d1b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d22:	00 
f0101d23:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d2a:	00 
f0101d2b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d2f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d34:	89 04 24             	mov    %eax,(%esp)
f0101d37:	e8 e1 f4 ff ff       	call   f010121d <page_insert>
f0101d3c:	85 c0                	test   %eax,%eax
f0101d3e:	74 24                	je     f0101d64 <mem_init+0xa78>
f0101d40:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0101d47:	f0 
f0101d48:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101d4f:	f0 
f0101d50:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101d57:	00 
f0101d58:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101d5f:	e8 30 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d64:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d69:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101d6e:	e8 95 ec ff ff       	call   f0100a08 <check_va2pa>
f0101d73:	89 da                	mov    %ebx,%edx
f0101d75:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101d7b:	c1 fa 03             	sar    $0x3,%edx
f0101d7e:	c1 e2 0c             	shl    $0xc,%edx
f0101d81:	39 d0                	cmp    %edx,%eax
f0101d83:	74 24                	je     f0101da9 <mem_init+0xabd>
f0101d85:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f0101d8c:	f0 
f0101d8d:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101d94:	f0 
f0101d95:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101d9c:	00 
f0101d9d:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101da4:	e8 eb e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101da9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dae:	74 24                	je     f0101dd4 <mem_init+0xae8>
f0101db0:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0101db7:	f0 
f0101db8:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101dbf:	f0 
f0101dc0:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f0101dc7:	00 
f0101dc8:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101dcf:	e8 c0 e2 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101dd4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ddb:	e8 34 f1 ff ff       	call   f0100f14 <page_alloc>
f0101de0:	85 c0                	test   %eax,%eax
f0101de2:	74 24                	je     f0101e08 <mem_init+0xb1c>
f0101de4:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f0101deb:	f0 
f0101dec:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101df3:	f0 
f0101df4:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0101dfb:	00 
f0101dfc:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101e03:	e8 8c e2 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e08:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0101e0e:	8b 02                	mov    (%edx),%eax
f0101e10:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e15:	89 c1                	mov    %eax,%ecx
f0101e17:	c1 e9 0c             	shr    $0xc,%ecx
f0101e1a:	3b 0d 64 89 11 f0    	cmp    0xf0118964,%ecx
f0101e20:	72 20                	jb     f0101e42 <mem_init+0xb56>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e22:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e26:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0101e2d:	f0 
f0101e2e:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101e35:	00 
f0101e36:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101e3d:	e8 52 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101e42:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e47:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e4a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e51:	00 
f0101e52:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e59:	00 
f0101e5a:	89 14 24             	mov    %edx,(%esp)
f0101e5d:	e8 96 f1 ff ff       	call   f0100ff8 <pgdir_walk>
f0101e62:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101e65:	83 c2 04             	add    $0x4,%edx
f0101e68:	39 d0                	cmp    %edx,%eax
f0101e6a:	74 24                	je     f0101e90 <mem_init+0xba4>
f0101e6c:	c7 44 24 0c e8 48 10 	movl   $0xf01048e8,0xc(%esp)
f0101e73:	f0 
f0101e74:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101e7b:	f0 
f0101e7c:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0101e83:	00 
f0101e84:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101e8b:	e8 04 e2 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e90:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101e97:	00 
f0101e98:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e9f:	00 
f0101ea0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101ea4:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101ea9:	89 04 24             	mov    %eax,(%esp)
f0101eac:	e8 6c f3 ff ff       	call   f010121d <page_insert>
f0101eb1:	85 c0                	test   %eax,%eax
f0101eb3:	74 24                	je     f0101ed9 <mem_init+0xbed>
f0101eb5:	c7 44 24 0c 28 49 10 	movl   $0xf0104928,0xc(%esp)
f0101ebc:	f0 
f0101ebd:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101ec4:	f0 
f0101ec5:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0101ecc:	00 
f0101ecd:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101ed4:	e8 bb e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ed9:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0101edf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ee4:	89 f8                	mov    %edi,%eax
f0101ee6:	e8 1d eb ff ff       	call   f0100a08 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101eeb:	89 da                	mov    %ebx,%edx
f0101eed:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0101ef3:	c1 fa 03             	sar    $0x3,%edx
f0101ef6:	c1 e2 0c             	shl    $0xc,%edx
f0101ef9:	39 d0                	cmp    %edx,%eax
f0101efb:	74 24                	je     f0101f21 <mem_init+0xc35>
f0101efd:	c7 44 24 0c b8 48 10 	movl   $0xf01048b8,0xc(%esp)
f0101f04:	f0 
f0101f05:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101f0c:	f0 
f0101f0d:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101f14:	00 
f0101f15:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101f1c:	e8 73 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f21:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f26:	74 24                	je     f0101f4c <mem_init+0xc60>
f0101f28:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0101f2f:	f0 
f0101f30:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101f37:	f0 
f0101f38:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101f3f:	00 
f0101f40:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101f47:	e8 48 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f4c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f53:	00 
f0101f54:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f5b:	00 
f0101f5c:	89 3c 24             	mov    %edi,(%esp)
f0101f5f:	e8 94 f0 ff ff       	call   f0100ff8 <pgdir_walk>
f0101f64:	f6 00 04             	testb  $0x4,(%eax)
f0101f67:	75 24                	jne    f0101f8d <mem_init+0xca1>
f0101f69:	c7 44 24 0c 68 49 10 	movl   $0xf0104968,0xc(%esp)
f0101f70:	f0 
f0101f71:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101f78:	f0 
f0101f79:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101f80:	00 
f0101f81:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101f88:	e8 07 e1 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101f8d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0101f92:	f6 00 04             	testb  $0x4,(%eax)
f0101f95:	75 24                	jne    f0101fbb <mem_init+0xccf>
f0101f97:	c7 44 24 0c 37 4f 10 	movl   $0xf0104f37,0xc(%esp)
f0101f9e:	f0 
f0101f9f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101fa6:	f0 
f0101fa7:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0101fae:	00 
f0101faf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101fb6:	e8 d9 e0 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101fbb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fc2:	00 
f0101fc3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fca:	00 
f0101fcb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fcf:	89 04 24             	mov    %eax,(%esp)
f0101fd2:	e8 46 f2 ff ff       	call   f010121d <page_insert>
f0101fd7:	85 c0                	test   %eax,%eax
f0101fd9:	74 24                	je     f0101fff <mem_init+0xd13>
f0101fdb:	c7 44 24 0c 7c 48 10 	movl   $0xf010487c,0xc(%esp)
f0101fe2:	f0 
f0101fe3:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0101fea:	f0 
f0101feb:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101ff2:	00 
f0101ff3:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0101ffa:	e8 95 e0 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101fff:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102006:	00 
f0102007:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010200e:	00 
f010200f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102014:	89 04 24             	mov    %eax,(%esp)
f0102017:	e8 dc ef ff ff       	call   f0100ff8 <pgdir_walk>
f010201c:	f6 00 02             	testb  $0x2,(%eax)
f010201f:	75 24                	jne    f0102045 <mem_init+0xd59>
f0102021:	c7 44 24 0c 9c 49 10 	movl   $0xf010499c,0xc(%esp)
f0102028:	f0 
f0102029:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102030:	f0 
f0102031:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102038:	00 
f0102039:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102040:	e8 4f e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102045:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010204c:	00 
f010204d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102054:	00 
f0102055:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010205a:	89 04 24             	mov    %eax,(%esp)
f010205d:	e8 96 ef ff ff       	call   f0100ff8 <pgdir_walk>
f0102062:	f6 00 04             	testb  $0x4,(%eax)
f0102065:	74 24                	je     f010208b <mem_init+0xd9f>
f0102067:	c7 44 24 0c d0 49 10 	movl   $0xf01049d0,0xc(%esp)
f010206e:	f0 
f010206f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102076:	f0 
f0102077:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010207e:	00 
f010207f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102086:	e8 09 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010208b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102092:	00 
f0102093:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010209a:	00 
f010209b:	89 74 24 04          	mov    %esi,0x4(%esp)
f010209f:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020a4:	89 04 24             	mov    %eax,(%esp)
f01020a7:	e8 71 f1 ff ff       	call   f010121d <page_insert>
f01020ac:	85 c0                	test   %eax,%eax
f01020ae:	78 24                	js     f01020d4 <mem_init+0xde8>
f01020b0:	c7 44 24 0c 08 4a 10 	movl   $0xf0104a08,0xc(%esp)
f01020b7:	f0 
f01020b8:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01020bf:	f0 
f01020c0:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f01020c7:	00 
f01020c8:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01020cf:	e8 c0 df ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01020d4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020db:	00 
f01020dc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020e3:	00 
f01020e4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01020eb:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01020f0:	89 04 24             	mov    %eax,(%esp)
f01020f3:	e8 25 f1 ff ff       	call   f010121d <page_insert>
f01020f8:	85 c0                	test   %eax,%eax
f01020fa:	74 24                	je     f0102120 <mem_init+0xe34>
f01020fc:	c7 44 24 0c 40 4a 10 	movl   $0xf0104a40,0xc(%esp)
f0102103:	f0 
f0102104:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010210b:	f0 
f010210c:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f0102113:	00 
f0102114:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010211b:	e8 74 df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102120:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102127:	00 
f0102128:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010212f:	00 
f0102130:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102135:	89 04 24             	mov    %eax,(%esp)
f0102138:	e8 bb ee ff ff       	call   f0100ff8 <pgdir_walk>
f010213d:	f6 00 04             	testb  $0x4,(%eax)
f0102140:	74 24                	je     f0102166 <mem_init+0xe7a>
f0102142:	c7 44 24 0c d0 49 10 	movl   $0xf01049d0,0xc(%esp)
f0102149:	f0 
f010214a:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102151:	f0 
f0102152:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102159:	00 
f010215a:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102161:	e8 2e df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102166:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f010216c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102171:	89 f8                	mov    %edi,%eax
f0102173:	e8 90 e8 ff ff       	call   f0100a08 <check_va2pa>
f0102178:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010217b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010217e:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102184:	c1 f8 03             	sar    $0x3,%eax
f0102187:	c1 e0 0c             	shl    $0xc,%eax
f010218a:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010218d:	74 24                	je     f01021b3 <mem_init+0xec7>
f010218f:	c7 44 24 0c 7c 4a 10 	movl   $0xf0104a7c,0xc(%esp)
f0102196:	f0 
f0102197:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010219e:	f0 
f010219f:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01021a6:	00 
f01021a7:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01021ae:	e8 e1 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021b3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021b8:	89 f8                	mov    %edi,%eax
f01021ba:	e8 49 e8 ff ff       	call   f0100a08 <check_va2pa>
f01021bf:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01021c2:	74 24                	je     f01021e8 <mem_init+0xefc>
f01021c4:	c7 44 24 0c a8 4a 10 	movl   $0xf0104aa8,0xc(%esp)
f01021cb:	f0 
f01021cc:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01021d3:	f0 
f01021d4:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01021db:	00 
f01021dc:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01021e3:	e8 ac de ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01021e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021eb:	66 83 78 04 02       	cmpw   $0x2,0x4(%eax)
f01021f0:	74 24                	je     f0102216 <mem_init+0xf2a>
f01021f2:	c7 44 24 0c 4d 4f 10 	movl   $0xf0104f4d,0xc(%esp)
f01021f9:	f0 
f01021fa:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102201:	f0 
f0102202:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102209:	00 
f010220a:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102211:	e8 7e de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102216:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010221b:	74 24                	je     f0102241 <mem_init+0xf55>
f010221d:	c7 44 24 0c 5e 4f 10 	movl   $0xf0104f5e,0xc(%esp)
f0102224:	f0 
f0102225:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010222c:	f0 
f010222d:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0102234:	00 
f0102235:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010223c:	e8 53 de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102241:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102248:	e8 c7 ec ff ff       	call   f0100f14 <page_alloc>
f010224d:	85 c0                	test   %eax,%eax
f010224f:	74 04                	je     f0102255 <mem_init+0xf69>
f0102251:	39 c3                	cmp    %eax,%ebx
f0102253:	74 24                	je     f0102279 <mem_init+0xf8d>
f0102255:	c7 44 24 0c d8 4a 10 	movl   $0xf0104ad8,0xc(%esp)
f010225c:	f0 
f010225d:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102264:	f0 
f0102265:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f010226c:	00 
f010226d:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102274:	e8 1b de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102279:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102280:	00 
f0102281:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102286:	89 04 24             	mov    %eax,(%esp)
f0102289:	e8 3f ef ff ff       	call   f01011cd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010228e:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f0102294:	ba 00 00 00 00       	mov    $0x0,%edx
f0102299:	89 f8                	mov    %edi,%eax
f010229b:	e8 68 e7 ff ff       	call   f0100a08 <check_va2pa>
f01022a0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022a3:	74 24                	je     f01022c9 <mem_init+0xfdd>
f01022a5:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f01022ac:	f0 
f01022ad:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01022b4:	f0 
f01022b5:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f01022bc:	00 
f01022bd:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01022c4:	e8 cb dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022c9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022ce:	89 f8                	mov    %edi,%eax
f01022d0:	e8 33 e7 ff ff       	call   f0100a08 <check_va2pa>
f01022d5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01022d8:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01022de:	c1 fa 03             	sar    $0x3,%edx
f01022e1:	c1 e2 0c             	shl    $0xc,%edx
f01022e4:	39 d0                	cmp    %edx,%eax
f01022e6:	74 24                	je     f010230c <mem_init+0x1020>
f01022e8:	c7 44 24 0c a8 4a 10 	movl   $0xf0104aa8,0xc(%esp)
f01022ef:	f0 
f01022f0:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01022f7:	f0 
f01022f8:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01022ff:	00 
f0102300:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102307:	e8 88 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010230c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010230f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102314:	74 24                	je     f010233a <mem_init+0x104e>
f0102316:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f010231d:	f0 
f010231e:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102325:	f0 
f0102326:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f010232d:	00 
f010232e:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102335:	e8 5a dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010233a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010233f:	74 24                	je     f0102365 <mem_init+0x1079>
f0102341:	c7 44 24 0c 5e 4f 10 	movl   $0xf0104f5e,0xc(%esp)
f0102348:	f0 
f0102349:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102350:	f0 
f0102351:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0102358:	00 
f0102359:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102360:	e8 2f dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102365:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010236c:	00 
f010236d:	89 3c 24             	mov    %edi,(%esp)
f0102370:	e8 58 ee ff ff       	call   f01011cd <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102375:	8b 3d 68 89 11 f0    	mov    0xf0118968,%edi
f010237b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102380:	89 f8                	mov    %edi,%eax
f0102382:	e8 81 e6 ff ff       	call   f0100a08 <check_va2pa>
f0102387:	83 f8 ff             	cmp    $0xffffffff,%eax
f010238a:	74 24                	je     f01023b0 <mem_init+0x10c4>
f010238c:	c7 44 24 0c fc 4a 10 	movl   $0xf0104afc,0xc(%esp)
f0102393:	f0 
f0102394:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010239b:	f0 
f010239c:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f01023a3:	00 
f01023a4:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01023ab:	e8 e4 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01023b0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023b5:	89 f8                	mov    %edi,%eax
f01023b7:	e8 4c e6 ff ff       	call   f0100a08 <check_va2pa>
f01023bc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023bf:	74 24                	je     f01023e5 <mem_init+0x10f9>
f01023c1:	c7 44 24 0c 20 4b 10 	movl   $0xf0104b20,0xc(%esp)
f01023c8:	f0 
f01023c9:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01023d0:	f0 
f01023d1:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f01023d8:	00 
f01023d9:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01023e0:	e8 af dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01023e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023e8:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01023ed:	74 24                	je     f0102413 <mem_init+0x1127>
f01023ef:	c7 44 24 0c 6f 4f 10 	movl   $0xf0104f6f,0xc(%esp)
f01023f6:	f0 
f01023f7:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01023fe:	f0 
f01023ff:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0102406:	00 
f0102407:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010240e:	e8 81 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102413:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102418:	74 24                	je     f010243e <mem_init+0x1152>
f010241a:	c7 44 24 0c 5e 4f 10 	movl   $0xf0104f5e,0xc(%esp)
f0102421:	f0 
f0102422:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102429:	f0 
f010242a:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0102431:	00 
f0102432:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102439:	e8 56 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010243e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102445:	e8 ca ea ff ff       	call   f0100f14 <page_alloc>
f010244a:	85 c0                	test   %eax,%eax
f010244c:	74 05                	je     f0102453 <mem_init+0x1167>
f010244e:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0102451:	74 24                	je     f0102477 <mem_init+0x118b>
f0102453:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f010245a:	f0 
f010245b:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102462:	f0 
f0102463:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f010246a:	00 
f010246b:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102472:	e8 1d dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102477:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010247e:	e8 91 ea ff ff       	call   f0100f14 <page_alloc>
f0102483:	85 c0                	test   %eax,%eax
f0102485:	74 24                	je     f01024ab <mem_init+0x11bf>
f0102487:	c7 44 24 0c b2 4e 10 	movl   $0xf0104eb2,0xc(%esp)
f010248e:	f0 
f010248f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102496:	f0 
f0102497:	c7 44 24 04 78 03 00 	movl   $0x378,0x4(%esp)
f010249e:	00 
f010249f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01024a6:	e8 e9 db ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01024ab:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01024b0:	8b 08                	mov    (%eax),%ecx
f01024b2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01024b8:	89 f2                	mov    %esi,%edx
f01024ba:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f01024c0:	c1 fa 03             	sar    $0x3,%edx
f01024c3:	c1 e2 0c             	shl    $0xc,%edx
f01024c6:	39 d1                	cmp    %edx,%ecx
f01024c8:	74 24                	je     f01024ee <mem_init+0x1202>
f01024ca:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f01024d1:	f0 
f01024d2:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01024d9:	f0 
f01024da:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f01024e1:	00 
f01024e2:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01024e9:	e8 a6 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01024ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024f4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01024f9:	74 24                	je     f010251f <mem_init+0x1233>
f01024fb:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0102502:	f0 
f0102503:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010250a:	f0 
f010250b:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0102512:	00 
f0102513:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010251a:	e8 75 db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010251f:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102525:	89 34 24             	mov    %esi,(%esp)
f0102528:	e8 65 ea ff ff       	call   f0100f92 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010252d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102534:	00 
f0102535:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010253c:	00 
f010253d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102542:	89 04 24             	mov    %eax,(%esp)
f0102545:	e8 ae ea ff ff       	call   f0100ff8 <pgdir_walk>
f010254a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010254d:	8b 15 68 89 11 f0    	mov    0xf0118968,%edx
f0102553:	8b 4a 04             	mov    0x4(%edx),%ecx
f0102556:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010255c:	89 4d cc             	mov    %ecx,-0x34(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010255f:	8b 0d 64 89 11 f0    	mov    0xf0118964,%ecx
f0102565:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102568:	c1 ef 0c             	shr    $0xc,%edi
f010256b:	39 cf                	cmp    %ecx,%edi
f010256d:	72 23                	jb     f0102592 <mem_init+0x12a6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010256f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102572:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102576:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010258d:	e8 02 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102592:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0102595:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f010259b:	39 f8                	cmp    %edi,%eax
f010259d:	74 24                	je     f01025c3 <mem_init+0x12d7>
f010259f:	c7 44 24 0c 80 4f 10 	movl   $0xf0104f80,0xc(%esp)
f01025a6:	f0 
f01025a7:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01025ae:	f0 
f01025af:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01025b6:	00 
f01025b7:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01025be:	e8 d1 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01025c3:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01025ca:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01025d0:	89 f0                	mov    %esi,%eax
f01025d2:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f01025d8:	c1 f8 03             	sar    $0x3,%eax
f01025db:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025de:	89 c2                	mov    %eax,%edx
f01025e0:	c1 ea 0c             	shr    $0xc,%edx
f01025e3:	39 d1                	cmp    %edx,%ecx
f01025e5:	77 20                	ja     f0102607 <mem_init+0x131b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025e7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025eb:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f01025f2:	f0 
f01025f3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025fa:	00 
f01025fb:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0102602:	e8 8d da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102607:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010260e:	00 
f010260f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102616:	00 
	return (void *)(pa + KERNBASE);
f0102617:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010261c:	89 04 24             	mov    %eax,(%esp)
f010261f:	e8 81 15 00 00       	call   f0103ba5 <memset>
	page_free(pp0);
f0102624:	89 34 24             	mov    %esi,(%esp)
f0102627:	e8 66 e9 ff ff       	call   f0100f92 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f010262c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102633:	00 
f0102634:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010263b:	00 
f010263c:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102641:	89 04 24             	mov    %eax,(%esp)
f0102644:	e8 af e9 ff ff       	call   f0100ff8 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102649:	89 f2                	mov    %esi,%edx
f010264b:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102651:	c1 fa 03             	sar    $0x3,%edx
f0102654:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102657:	89 d0                	mov    %edx,%eax
f0102659:	c1 e8 0c             	shr    $0xc,%eax
f010265c:	3b 05 64 89 11 f0    	cmp    0xf0118964,%eax
f0102662:	72 20                	jb     f0102684 <mem_init+0x1398>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102664:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102668:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f010266f:	f0 
f0102670:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102677:	00 
f0102678:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f010267f:	e8 10 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102684:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010268a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010268d:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102694:	75 11                	jne    f01026a7 <mem_init+0x13bb>
f0102696:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010269c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01026a2:	f6 00 01             	testb  $0x1,(%eax)
f01026a5:	74 24                	je     f01026cb <mem_init+0x13df>
f01026a7:	c7 44 24 0c 98 4f 10 	movl   $0xf0104f98,0xc(%esp)
f01026ae:	f0 
f01026af:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01026b6:	f0 
f01026b7:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f01026be:	00 
f01026bf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01026c6:	e8 c9 d9 ff ff       	call   f0100094 <_panic>
f01026cb:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f01026ce:	39 d0                	cmp    %edx,%eax
f01026d0:	75 d0                	jne    f01026a2 <mem_init+0x13b6>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01026d2:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01026d7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026dd:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f01026e3:	8b 7d c8             	mov    -0x38(%ebp),%edi
f01026e6:	89 3d 58 85 11 f0    	mov    %edi,0xf0118558

	// free the pages we took
	page_free(pp0);
f01026ec:	89 34 24             	mov    %esi,(%esp)
f01026ef:	e8 9e e8 ff ff       	call   f0100f92 <page_free>
	page_free(pp1);
f01026f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026f7:	89 04 24             	mov    %eax,(%esp)
f01026fa:	e8 93 e8 ff ff       	call   f0100f92 <page_free>
	page_free(pp2);
f01026ff:	89 1c 24             	mov    %ebx,(%esp)
f0102702:	e8 8b e8 ff ff       	call   f0100f92 <page_free>

	cprintf("check_page() succeeded!\n");
f0102707:	c7 04 24 af 4f 10 f0 	movl   $0xf0104faf,(%esp)
f010270e:	e8 ff 07 00 00       	call   f0102f12 <cprintf>
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	//	cprintf("123\n");
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP((sizeof(struct PageInfo)* npages), PGSIZE), PADDR(pages), PTE_U|PTE_P);
f0102713:	a1 6c 89 11 f0       	mov    0xf011896c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102718:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010271d:	77 20                	ja     f010273f <mem_init+0x1453>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010271f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102723:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f010272a:	f0 
f010272b:	c7 44 24 04 ae 00 00 	movl   $0xae,0x4(%esp)
f0102732:	00 
f0102733:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010273a:	e8 55 d9 ff ff       	call   f0100094 <_panic>
f010273f:	8b 15 64 89 11 f0    	mov    0xf0118964,%edx
f0102745:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f010274c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102752:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102759:	00 
	return (physaddr_t)kva - KERNBASE;
f010275a:	05 00 00 00 10       	add    $0x10000000,%eax
f010275f:	89 04 24             	mov    %eax,(%esp)
f0102762:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102767:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f010276c:	e8 6a e9 ff ff       	call   f01010db <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102771:	ba 00 e0 10 f0       	mov    $0xf010e000,%edx
f0102776:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010277c:	77 20                	ja     f010279e <mem_init+0x14b2>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010277e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102782:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f0102789:	f0 
f010278a:	c7 44 24 04 bc 00 00 	movl   $0xbc,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102799:	e8 f6 d8 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010279e:	c7 45 cc 00 e0 10 00 	movl   $0x10e000,-0x34(%ebp)
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	//printf("123");
	//cprintf("asd\n");
	boot_map_region(kern_pgdir,KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W );
f01027a5:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027ac:	00 
f01027ad:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f01027b4:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027b9:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01027be:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027c3:	e8 13 e9 ff ff       	call   f01010db <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE,0xFFFFFFFF - KERNBASE+1 ,0x0, PTE_W|PTE_P );
f01027c8:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f01027cf:	00 
f01027d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027d7:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027dc:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027e1:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f01027e6:	e8 f0 e8 ff ff       	call   f01010db <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027eb:	8b 1d 68 89 11 f0    	mov    0xf0118968,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027f1:	8b 35 64 89 11 f0    	mov    0xf0118964,%esi
f01027f7:	89 75 d0             	mov    %esi,-0x30(%ebp)
f01027fa:	8d 04 f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%eax
	for (i = 0; i < n; i += PGSIZE)
f0102801:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102806:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102809:	74 7f                	je     f010288a <mem_init+0x159e>
	  {
	    //    cprintf("pa 0x%x\n", PADDR(pages));
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
f010280b:	8b 35 6c 89 11 f0    	mov    0xf011896c,%esi
f0102811:	8d be 00 00 00 10    	lea    0x10000000(%esi),%edi
f0102817:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010281c:	89 d8                	mov    %ebx,%eax
f010281e:	e8 e5 e1 ff ff       	call   f0100a08 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102823:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102829:	77 20                	ja     f010284b <mem_init+0x155f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010282b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010282f:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f0102836:	f0 
f0102837:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f010283e:	00 
f010283f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102846:	e8 49 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010284b:	ba 00 00 00 00       	mov    $0x0,%edx
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102850:	8d 0c 17             	lea    (%edi,%edx,1),%ecx
	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
	  {
	    //    cprintf("pa 0x%x\n", PADDR(pages));
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
f0102853:	39 c1                	cmp    %eax,%ecx
f0102855:	74 24                	je     f010287b <mem_init+0x158f>
f0102857:	c7 44 24 0c 6c 4b 10 	movl   $0xf0104b6c,0xc(%esp)
f010285e:	f0 
f010285f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102866:	f0 
f0102867:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f010286e:	00 
f010286f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102876:	e8 19 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010287b:	8d b2 00 10 00 00    	lea    0x1000(%edx),%esi
f0102881:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0102884:	0f 87 f8 05 00 00    	ja     f0102e82 <mem_init+0x1b96>
	    //    cprintf("pa 0x%x\n", PADDR(pages));
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
	  }

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010288a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010288d:	c1 e7 0c             	shl    $0xc,%edi
f0102890:	85 ff                	test   %edi,%edi
f0102892:	0f 84 c3 05 00 00    	je     f0102e5b <mem_init+0x1b6f>
f0102898:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010289d:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
	  }

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01028a3:	89 d8                	mov    %ebx,%eax
f01028a5:	e8 5e e1 ff ff       	call   f0100a08 <check_va2pa>
f01028aa:	39 c6                	cmp    %eax,%esi
f01028ac:	74 24                	je     f01028d2 <mem_init+0x15e6>
f01028ae:	c7 44 24 0c a0 4b 10 	movl   $0xf0104ba0,0xc(%esp)
f01028b5:	f0 
f01028b6:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01028bd:	f0 
f01028be:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f01028c5:	00 
f01028c6:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01028cd:	e8 c2 d7 ff ff       	call   f0100094 <_panic>
	    //    cprintf("pa 0x%x\n", PADDR(pages));
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
	  }

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028d2:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028d8:	39 fe                	cmp    %edi,%esi
f01028da:	72 c1                	jb     f010289d <mem_init+0x15b1>
f01028dc:	e9 7a 05 00 00       	jmp    f0102e5b <mem_init+0x1b6f>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01028e1:	39 c3                	cmp    %eax,%ebx
f01028e3:	74 24                	je     f0102909 <mem_init+0x161d>
f01028e5:	c7 44 24 0c c8 4b 10 	movl   $0xf0104bc8,0xc(%esp)
f01028ec:	f0 
f01028ed:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01028f4:	f0 
f01028f5:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f01028fc:	00 
f01028fd:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102904:	e8 8b d7 ff ff       	call   f0100094 <_panic>
f0102909:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010290f:	39 f3                	cmp    %esi,%ebx
f0102911:	0f 85 34 05 00 00    	jne    f0102e4b <mem_init+0x1b5f>
f0102917:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010291a:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f010291f:	89 d8                	mov    %ebx,%eax
f0102921:	e8 e2 e0 ff ff       	call   f0100a08 <check_va2pa>
f0102926:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102929:	74 24                	je     f010294f <mem_init+0x1663>
f010292b:	c7 44 24 0c 10 4c 10 	movl   $0xf0104c10,0xc(%esp)
f0102932:	f0 
f0102933:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f010293a:	f0 
f010293b:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f0102942:	00 
f0102943:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f010294a:	e8 45 d7 ff ff       	call   f0100094 <_panic>
f010294f:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102954:	ba 01 00 00 00       	mov    $0x1,%edx
f0102959:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f010295f:	83 f9 03             	cmp    $0x3,%ecx
f0102962:	77 39                	ja     f010299d <mem_init+0x16b1>
f0102964:	89 d7                	mov    %edx,%edi
f0102966:	d3 e7                	shl    %cl,%edi
f0102968:	89 f9                	mov    %edi,%ecx
f010296a:	f6 c1 0b             	test   $0xb,%cl
f010296d:	74 2e                	je     f010299d <mem_init+0x16b1>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010296f:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102973:	0f 85 aa 00 00 00    	jne    f0102a23 <mem_init+0x1737>
f0102979:	c7 44 24 0c c8 4f 10 	movl   $0xf0104fc8,0xc(%esp)
f0102980:	f0 
f0102981:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102988:	f0 
f0102989:	c7 44 24 04 e8 02 00 	movl   $0x2e8,0x4(%esp)
f0102990:	00 
f0102991:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102998:	e8 f7 d6 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010299d:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029a2:	76 55                	jbe    f01029f9 <mem_init+0x170d>
				assert(pgdir[i] & PTE_P);
f01029a4:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f01029a7:	f6 c1 01             	test   $0x1,%cl
f01029aa:	75 24                	jne    f01029d0 <mem_init+0x16e4>
f01029ac:	c7 44 24 0c c8 4f 10 	movl   $0xf0104fc8,0xc(%esp)
f01029b3:	f0 
f01029b4:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01029bb:	f0 
f01029bc:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f01029c3:	00 
f01029c4:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01029cb:	e8 c4 d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f01029d0:	f6 c1 02             	test   $0x2,%cl
f01029d3:	75 4e                	jne    f0102a23 <mem_init+0x1737>
f01029d5:	c7 44 24 0c d9 4f 10 	movl   $0xf0104fd9,0xc(%esp)
f01029dc:	f0 
f01029dd:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f01029e4:	f0 
f01029e5:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f01029ec:	00 
f01029ed:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f01029f4:	e8 9b d6 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01029f9:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01029fd:	74 24                	je     f0102a23 <mem_init+0x1737>
f01029ff:	c7 44 24 0c ea 4f 10 	movl   $0xf0104fea,0xc(%esp)
f0102a06:	f0 
f0102a07:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102a0e:	f0 
f0102a0f:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0102a16:	00 
f0102a17:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102a1e:	e8 71 d6 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a23:	83 c0 01             	add    $0x1,%eax
f0102a26:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102a2b:	0f 85 28 ff ff ff    	jne    f0102959 <mem_init+0x166d>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102a31:	c7 04 24 40 4c 10 f0 	movl   $0xf0104c40,(%esp)
f0102a38:	e8 d5 04 00 00       	call   f0102f12 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102a3d:	a1 68 89 11 f0       	mov    0xf0118968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102a42:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a47:	77 20                	ja     f0102a69 <mem_init+0x177d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102a49:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a4d:	c7 44 24 08 28 47 10 	movl   $0xf0104728,0x8(%esp)
f0102a54:	f0 
f0102a55:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0102a5c:	00 
f0102a5d:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102a64:	e8 2b d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102a69:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102a6e:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102a71:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a76:	e8 2e e0 ff ff       	call   f0100aa9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102a7b:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102a7e:	83 e0 f3             	and    $0xfffffff3,%eax
f0102a81:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102a86:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102a89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a90:	e8 7f e4 ff ff       	call   f0100f14 <page_alloc>
f0102a95:	89 c3                	mov    %eax,%ebx
f0102a97:	85 c0                	test   %eax,%eax
f0102a99:	75 24                	jne    f0102abf <mem_init+0x17d3>
f0102a9b:	c7 44 24 0c 07 4e 10 	movl   $0xf0104e07,0xc(%esp)
f0102aa2:	f0 
f0102aa3:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102aaa:	f0 
f0102aab:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102ab2:	00 
f0102ab3:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102aba:	e8 d5 d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102abf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ac6:	e8 49 e4 ff ff       	call   f0100f14 <page_alloc>
f0102acb:	89 c7                	mov    %eax,%edi
f0102acd:	85 c0                	test   %eax,%eax
f0102acf:	75 24                	jne    f0102af5 <mem_init+0x1809>
f0102ad1:	c7 44 24 0c 1d 4e 10 	movl   $0xf0104e1d,0xc(%esp)
f0102ad8:	f0 
f0102ad9:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102ae0:	f0 
f0102ae1:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102ae8:	00 
f0102ae9:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102af0:	e8 9f d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102af5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102afc:	e8 13 e4 ff ff       	call   f0100f14 <page_alloc>
f0102b01:	89 c6                	mov    %eax,%esi
f0102b03:	85 c0                	test   %eax,%eax
f0102b05:	75 24                	jne    f0102b2b <mem_init+0x183f>
f0102b07:	c7 44 24 0c 33 4e 10 	movl   $0xf0104e33,0xc(%esp)
f0102b0e:	f0 
f0102b0f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102b16:	f0 
f0102b17:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f0102b1e:	00 
f0102b1f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102b26:	e8 69 d5 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102b2b:	89 1c 24             	mov    %ebx,(%esp)
f0102b2e:	e8 5f e4 ff ff       	call   f0100f92 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b33:	89 f8                	mov    %edi,%eax
f0102b35:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102b3b:	c1 f8 03             	sar    $0x3,%eax
f0102b3e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b41:	89 c2                	mov    %eax,%edx
f0102b43:	c1 ea 0c             	shr    $0xc,%edx
f0102b46:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102b4c:	72 20                	jb     f0102b6e <mem_init+0x1882>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b52:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0102b59:	f0 
f0102b5a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b61:	00 
f0102b62:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0102b69:	e8 26 d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102b6e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b75:	00 
f0102b76:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102b7d:	00 
	return (void *)(pa + KERNBASE);
f0102b7e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b83:	89 04 24             	mov    %eax,(%esp)
f0102b86:	e8 1a 10 00 00       	call   f0103ba5 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b8b:	89 f0                	mov    %esi,%eax
f0102b8d:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102b93:	c1 f8 03             	sar    $0x3,%eax
f0102b96:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b99:	89 c2                	mov    %eax,%edx
f0102b9b:	c1 ea 0c             	shr    $0xc,%edx
f0102b9e:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102ba4:	72 20                	jb     f0102bc6 <mem_init+0x18da>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ba6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102baa:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0102bb1:	f0 
f0102bb2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102bb9:	00 
f0102bba:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0102bc1:	e8 ce d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bc6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bcd:	00 
f0102bce:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102bd5:	00 
	return (void *)(pa + KERNBASE);
f0102bd6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bdb:	89 04 24             	mov    %eax,(%esp)
f0102bde:	e8 c2 0f 00 00       	call   f0103ba5 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102be3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bea:	00 
f0102beb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bf2:	00 
f0102bf3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102bf7:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102bfc:	89 04 24             	mov    %eax,(%esp)
f0102bff:	e8 19 e6 ff ff       	call   f010121d <page_insert>
	assert(pp1->pp_ref == 1);
f0102c04:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c09:	74 24                	je     f0102c2f <mem_init+0x1943>
f0102c0b:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f0102c12:	f0 
f0102c13:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102c1a:	f0 
f0102c1b:	c7 44 24 04 b1 03 00 	movl   $0x3b1,0x4(%esp)
f0102c22:	00 
f0102c23:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102c2a:	e8 65 d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c2f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c36:	01 01 01 
f0102c39:	74 24                	je     f0102c5f <mem_init+0x1973>
f0102c3b:	c7 44 24 0c 60 4c 10 	movl   $0xf0104c60,0xc(%esp)
f0102c42:	f0 
f0102c43:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102c4a:	f0 
f0102c4b:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0102c52:	00 
f0102c53:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102c5a:	e8 35 d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c5f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c66:	00 
f0102c67:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c6e:	00 
f0102c6f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c73:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102c78:	89 04 24             	mov    %eax,(%esp)
f0102c7b:	e8 9d e5 ff ff       	call   f010121d <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c80:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c87:	02 02 02 
f0102c8a:	74 24                	je     f0102cb0 <mem_init+0x19c4>
f0102c8c:	c7 44 24 0c 84 4c 10 	movl   $0xf0104c84,0xc(%esp)
f0102c93:	f0 
f0102c94:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102c9b:	f0 
f0102c9c:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102ca3:	00 
f0102ca4:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102cab:	e8 e4 d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102cb0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cb5:	74 24                	je     f0102cdb <mem_init+0x19ef>
f0102cb7:	c7 44 24 0c 26 4f 10 	movl   $0xf0104f26,0xc(%esp)
f0102cbe:	f0 
f0102cbf:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102cc6:	f0 
f0102cc7:	c7 44 24 04 b5 03 00 	movl   $0x3b5,0x4(%esp)
f0102cce:	00 
f0102ccf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102cd6:	e8 b9 d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102cdb:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102ce0:	74 24                	je     f0102d06 <mem_init+0x1a1a>
f0102ce2:	c7 44 24 0c 6f 4f 10 	movl   $0xf0104f6f,0xc(%esp)
f0102ce9:	f0 
f0102cea:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102cf1:	f0 
f0102cf2:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0102cf9:	00 
f0102cfa:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102d01:	e8 8e d3 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d06:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d0d:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d10:	89 f0                	mov    %esi,%eax
f0102d12:	2b 05 6c 89 11 f0    	sub    0xf011896c,%eax
f0102d18:	c1 f8 03             	sar    $0x3,%eax
f0102d1b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d1e:	89 c2                	mov    %eax,%edx
f0102d20:	c1 ea 0c             	shr    $0xc,%edx
f0102d23:	3b 15 64 89 11 f0    	cmp    0xf0118964,%edx
f0102d29:	72 20                	jb     f0102d4b <mem_init+0x1a5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d2f:	c7 44 24 08 e4 45 10 	movl   $0xf01045e4,0x8(%esp)
f0102d36:	f0 
f0102d37:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d3e:	00 
f0102d3f:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0102d46:	e8 49 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d4b:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d52:	03 03 03 
f0102d55:	74 24                	je     f0102d7b <mem_init+0x1a8f>
f0102d57:	c7 44 24 0c a8 4c 10 	movl   $0xf0104ca8,0xc(%esp)
f0102d5e:	f0 
f0102d5f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102d66:	f0 
f0102d67:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f0102d6e:	00 
f0102d6f:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102d76:	e8 19 d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d7b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d82:	00 
f0102d83:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102d88:	89 04 24             	mov    %eax,(%esp)
f0102d8b:	e8 3d e4 ff ff       	call   f01011cd <page_remove>
	assert(pp2->pp_ref == 0);
f0102d90:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d95:	74 24                	je     f0102dbb <mem_init+0x1acf>
f0102d97:	c7 44 24 0c 5e 4f 10 	movl   $0xf0104f5e,0xc(%esp)
f0102d9e:	f0 
f0102d9f:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102da6:	f0 
f0102da7:	c7 44 24 04 ba 03 00 	movl   $0x3ba,0x4(%esp)
f0102dae:	00 
f0102daf:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102db6:	e8 d9 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102dbb:	a1 68 89 11 f0       	mov    0xf0118968,%eax
f0102dc0:	8b 08                	mov    (%eax),%ecx
f0102dc2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102dc8:	89 da                	mov    %ebx,%edx
f0102dca:	2b 15 6c 89 11 f0    	sub    0xf011896c,%edx
f0102dd0:	c1 fa 03             	sar    $0x3,%edx
f0102dd3:	c1 e2 0c             	shl    $0xc,%edx
f0102dd6:	39 d1                	cmp    %edx,%ecx
f0102dd8:	74 24                	je     f0102dfe <mem_init+0x1b12>
f0102dda:	c7 44 24 0c 24 48 10 	movl   $0xf0104824,0xc(%esp)
f0102de1:	f0 
f0102de2:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102de9:	f0 
f0102dea:	c7 44 24 04 bd 03 00 	movl   $0x3bd,0x4(%esp)
f0102df1:	00 
f0102df2:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102df9:	e8 96 d2 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102dfe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e04:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e09:	74 24                	je     f0102e2f <mem_init+0x1b43>
f0102e0b:	c7 44 24 0c 15 4f 10 	movl   $0xf0104f15,0xc(%esp)
f0102e12:	f0 
f0102e13:	c7 44 24 08 26 4d 10 	movl   $0xf0104d26,0x8(%esp)
f0102e1a:	f0 
f0102e1b:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102e22:	00 
f0102e23:	c7 04 24 00 4d 10 f0 	movl   $0xf0104d00,(%esp)
f0102e2a:	e8 65 d2 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102e2f:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e35:	89 1c 24             	mov    %ebx,(%esp)
f0102e38:	e8 55 e1 ff ff       	call   f0100f92 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e3d:	c7 04 24 d4 4c 10 f0 	movl   $0xf0104cd4,(%esp)
f0102e44:	e8 c9 00 00 00       	call   f0102f12 <cprintf>
f0102e49:	eb 4b                	jmp    f0102e96 <mem_init+0x1baa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e4b:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102e4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e51:	e8 b2 db ff ff       	call   f0100a08 <check_va2pa>
f0102e56:	e9 86 fa ff ff       	jmp    f01028e1 <mem_init+0x15f5>
f0102e5b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e60:	89 d8                	mov    %ebx,%eax
f0102e62:	e8 a1 db ff ff       	call   f0100a08 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102e67:	be 00 60 11 00       	mov    $0x116000,%esi
f0102e6c:	bf 00 80 ff df       	mov    $0xdfff8000,%edi
f0102e71:	81 ef 00 e0 10 f0    	sub    $0xf010e000,%edi
f0102e77:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0102e7a:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0102e7d:	e9 5f fa ff ff       	jmp    f01028e1 <mem_init+0x15f5>
f0102e82:	81 ea 00 f0 ff 10    	sub    $0x10fff000,%edx
	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
	  {
	    //    cprintf("pa 0x%x\n", PADDR(pages));
	    assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i );
f0102e88:	89 d8                	mov    %ebx,%eax
f0102e8a:	e8 79 db ff ff       	call   f0100a08 <check_va2pa>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102e8f:	89 f2                	mov    %esi,%edx
f0102e91:	e9 ba f9 ff ff       	jmp    f0102850 <mem_init+0x1564>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e96:	83 c4 3c             	add    $0x3c,%esp
f0102e99:	5b                   	pop    %ebx
f0102e9a:	5e                   	pop    %esi
f0102e9b:	5f                   	pop    %edi
f0102e9c:	5d                   	pop    %ebp
f0102e9d:	c3                   	ret    
f0102e9e:	66 90                	xchg   %ax,%ax

f0102ea0 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102ea0:	55                   	push   %ebp
f0102ea1:	89 e5                	mov    %esp,%ebp
void
mc146818_write(unsigned reg, unsigned datum)
{
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102ea3:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ea7:	ba 70 00 00 00       	mov    $0x70,%edx
f0102eac:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ead:	b2 71                	mov    $0x71,%dl
f0102eaf:	ec                   	in     (%dx),%al

unsigned
mc146818_read(unsigned reg)
{
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102eb0:	0f b6 c0             	movzbl %al,%eax
}
f0102eb3:	5d                   	pop    %ebp
f0102eb4:	c3                   	ret    

f0102eb5 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102eb5:	55                   	push   %ebp
f0102eb6:	89 e5                	mov    %esp,%ebp
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102eb8:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ebc:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ec1:	ee                   	out    %al,(%dx)
f0102ec2:	0f b6 45 0c          	movzbl 0xc(%ebp),%eax
f0102ec6:	b2 71                	mov    $0x71,%dl
f0102ec8:	ee                   	out    %al,(%dx)
f0102ec9:	5d                   	pop    %ebp
f0102eca:	c3                   	ret    
f0102ecb:	90                   	nop

f0102ecc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102ecc:	55                   	push   %ebp
f0102ecd:	89 e5                	mov    %esp,%ebp
f0102ecf:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102ed2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ed5:	89 04 24             	mov    %eax,(%esp)
f0102ed8:	e8 1c d7 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0102edd:	c9                   	leave  
f0102ede:	c3                   	ret    

f0102edf <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102edf:	55                   	push   %ebp
f0102ee0:	89 e5                	mov    %esp,%ebp
f0102ee2:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102ee5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102eec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ef3:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ef6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102efa:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102efd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f01:	c7 04 24 cc 2e 10 f0 	movl   $0xf0102ecc,(%esp)
f0102f08:	e8 15 05 00 00       	call   f0103422 <vprintfmt>
	return cnt;
}
f0102f0d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f10:	c9                   	leave  
f0102f11:	c3                   	ret    

f0102f12 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f12:	55                   	push   %ebp
f0102f13:	89 e5                	mov    %esp,%ebp
f0102f15:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f18:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f1b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f1f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f22:	89 04 24             	mov    %eax,(%esp)
f0102f25:	e8 b5 ff ff ff       	call   f0102edf <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f2a:	c9                   	leave  
f0102f2b:	c3                   	ret    
f0102f2c:	66 90                	xchg   %ax,%ax
f0102f2e:	66 90                	xchg   %ax,%ax

f0102f30 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f30:	55                   	push   %ebp
f0102f31:	89 e5                	mov    %esp,%ebp
f0102f33:	57                   	push   %edi
f0102f34:	56                   	push   %esi
f0102f35:	53                   	push   %ebx
f0102f36:	83 ec 10             	sub    $0x10,%esp
f0102f39:	89 c6                	mov    %eax,%esi
f0102f3b:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102f3e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102f41:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102f44:	8b 1a                	mov    (%edx),%ebx
f0102f46:	8b 09                	mov    (%ecx),%ecx
f0102f48:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102f4b:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102f52:	eb 77                	jmp    f0102fcb <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0102f54:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102f57:	01 d8                	add    %ebx,%eax
f0102f59:	b9 02 00 00 00       	mov    $0x2,%ecx
f0102f5e:	99                   	cltd   
f0102f5f:	f7 f9                	idiv   %ecx
f0102f61:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f63:	eb 01                	jmp    f0102f66 <stab_binsearch+0x36>
			m--;
f0102f65:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f66:	39 d9                	cmp    %ebx,%ecx
f0102f68:	7c 1d                	jl     f0102f87 <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102f6a:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102f6d:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102f72:	39 fa                	cmp    %edi,%edx
f0102f74:	75 ef                	jne    f0102f65 <stab_binsearch+0x35>
f0102f76:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102f79:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0102f7c:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0102f80:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102f83:	73 18                	jae    f0102f9d <stab_binsearch+0x6d>
f0102f85:	eb 05                	jmp    f0102f8c <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102f87:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0102f8a:	eb 3f                	jmp    f0102fcb <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102f8c:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f8f:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0102f91:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102f94:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102f9b:	eb 2e                	jmp    f0102fcb <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102f9d:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0102fa0:	73 15                	jae    f0102fb7 <stab_binsearch+0x87>
			*region_right = m - 1;
f0102fa2:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0102fa5:	49                   	dec    %ecx
f0102fa6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0102fa9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fac:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fae:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102fb5:	eb 14                	jmp    f0102fcb <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102fb7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102fba:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102fbd:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0102fbf:	ff 45 0c             	incl   0xc(%ebp)
f0102fc2:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fc4:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102fcb:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0102fce:	7e 84                	jle    f0102f54 <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102fd0:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102fd4:	75 0d                	jne    f0102fe3 <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0102fd6:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102fd9:	8b 02                	mov    (%edx),%eax
f0102fdb:	48                   	dec    %eax
f0102fdc:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102fdf:	89 01                	mov    %eax,(%ecx)
f0102fe1:	eb 22                	jmp    f0103005 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fe3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102fe6:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102fe8:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102feb:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102fed:	eb 01                	jmp    f0102ff0 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102fef:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102ff0:	39 c1                	cmp    %eax,%ecx
f0102ff2:	7d 0c                	jge    f0103000 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102ff4:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102ff7:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0102ffc:	39 fa                	cmp    %edi,%edx
f0102ffe:	75 ef                	jne    f0102fef <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103000:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103003:	89 02                	mov    %eax,(%edx)
	}
}
f0103005:	83 c4 10             	add    $0x10,%esp
f0103008:	5b                   	pop    %ebx
f0103009:	5e                   	pop    %esi
f010300a:	5f                   	pop    %edi
f010300b:	5d                   	pop    %ebp
f010300c:	c3                   	ret    

f010300d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010300d:	55                   	push   %ebp
f010300e:	89 e5                	mov    %esp,%ebp
f0103010:	83 ec 58             	sub    $0x58,%esp
f0103013:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103016:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103019:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010301c:	8b 75 08             	mov    0x8(%ebp),%esi
f010301f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103022:	c7 03 f8 4f 10 f0    	movl   $0xf0104ff8,(%ebx)
	info->eip_line = 0;
f0103028:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010302f:	c7 43 08 f8 4f 10 f0 	movl   $0xf0104ff8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103036:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010303d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103040:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103047:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010304d:	76 12                	jbe    f0103061 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010304f:	b8 bb d2 10 f0       	mov    $0xf010d2bb,%eax
f0103054:	3d b5 b4 10 f0       	cmp    $0xf010b4b5,%eax
f0103059:	0f 86 06 02 00 00    	jbe    f0103265 <debuginfo_eip+0x258>
f010305f:	eb 1c                	jmp    f010307d <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103061:	c7 44 24 08 02 50 10 	movl   $0xf0105002,0x8(%esp)
f0103068:	f0 
f0103069:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103070:	00 
f0103071:	c7 04 24 0f 50 10 f0 	movl   $0xf010500f,(%esp)
f0103078:	e8 17 d0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010307d:	80 3d ba d2 10 f0 00 	cmpb   $0x0,0xf010d2ba
f0103084:	0f 85 e2 01 00 00    	jne    f010326c <debuginfo_eip+0x25f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010308a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103091:	b8 b4 b4 10 f0       	mov    $0xf010b4b4,%eax
f0103096:	2d 2c 52 10 f0       	sub    $0xf010522c,%eax
f010309b:	c1 f8 02             	sar    $0x2,%eax
f010309e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01030a4:	83 e8 01             	sub    $0x1,%eax
f01030a7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01030aa:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030ae:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01030b5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01030b8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01030bb:	b8 2c 52 10 f0       	mov    $0xf010522c,%eax
f01030c0:	e8 6b fe ff ff       	call   f0102f30 <stab_binsearch>
	if (lfile == 0)
f01030c5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030c8:	85 c0                	test   %eax,%eax
f01030ca:	0f 84 a3 01 00 00    	je     f0103273 <debuginfo_eip+0x266>
		return -1;
	info->eip_file = stabstr + stabs[lfile].n_strx;
f01030d0:	6b d0 0c             	imul   $0xc,%eax,%edx
f01030d3:	8b 92 2c 52 10 f0    	mov    -0xfefadd4(%edx),%edx
f01030d9:	81 c2 b5 b4 10 f0    	add    $0xf010b4b5,%edx
f01030df:	89 13                	mov    %edx,(%ebx)
      	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01030e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01030e4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01030ea:	89 74 24 04          	mov    %esi,0x4(%esp)
f01030ee:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01030f5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01030f8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01030fb:	b8 2c 52 10 f0       	mov    $0xf010522c,%eax
f0103100:	e8 2b fe ff ff       	call   f0102f30 <stab_binsearch>

	if (lfun <= rfun) {
f0103105:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103108:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010310b:	39 d0                	cmp    %edx,%eax
f010310d:	7f 3d                	jg     f010314c <debuginfo_eip+0x13f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010310f:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103112:	8d b9 2c 52 10 f0    	lea    -0xfefadd4(%ecx),%edi
f0103118:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010311b:	8b 89 2c 52 10 f0    	mov    -0xfefadd4(%ecx),%ecx
f0103121:	bf bb d2 10 f0       	mov    $0xf010d2bb,%edi
f0103126:	81 ef b5 b4 10 f0    	sub    $0xf010b4b5,%edi
f010312c:	39 f9                	cmp    %edi,%ecx
f010312e:	73 09                	jae    f0103139 <debuginfo_eip+0x12c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103130:	81 c1 b5 b4 10 f0    	add    $0xf010b4b5,%ecx
f0103136:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103139:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010313c:	8b 4f 08             	mov    0x8(%edi),%ecx
f010313f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103142:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103144:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103147:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010314a:	eb 0f                	jmp    f010315b <debuginfo_eip+0x14e>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010314c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010314f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103152:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103155:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103158:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010315b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103162:	00 
f0103163:	8b 43 08             	mov    0x8(%ebx),%eax
f0103166:	89 04 24             	mov    %eax,(%esp)
f0103169:	e8 0d 0a 00 00       	call   f0103b7b <strfind>
f010316e:	2b 43 08             	sub    0x8(%ebx),%eax
f0103171:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103174:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103178:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010317f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103182:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103185:	b8 2c 52 10 f0       	mov    $0xf010522c,%eax
f010318a:	e8 a1 fd ff ff       	call   f0102f30 <stab_binsearch>
	if( lline <= rline)
f010318f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103192:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103195:	0f 8f df 00 00 00    	jg     f010327a <debuginfo_eip+0x26d>
	{
		info->eip_line = stabs[lline].n_desc;
f010319b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010319e:	0f b7 80 32 52 10 f0 	movzwl -0xfefadce(%eax),%eax
f01031a5:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031ab:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01031ae:	39 f0                	cmp    %esi,%eax
f01031b0:	7c 63                	jl     f0103215 <debuginfo_eip+0x208>
	       && stabs[lline].n_type != N_SOL
f01031b2:	6b f8 0c             	imul   $0xc,%eax,%edi
f01031b5:	81 c7 2c 52 10 f0    	add    $0xf010522c,%edi
f01031bb:	0f b6 4f 04          	movzbl 0x4(%edi),%ecx
f01031bf:	80 f9 84             	cmp    $0x84,%cl
f01031c2:	74 32                	je     f01031f6 <debuginfo_eip+0x1e9>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f01031c4:	8d 50 ff             	lea    -0x1(%eax),%edx
f01031c7:	6b d2 0c             	imul   $0xc,%edx,%edx
f01031ca:	81 c2 2c 52 10 f0    	add    $0xf010522c,%edx
f01031d0:	eb 15                	jmp    f01031e7 <debuginfo_eip+0x1da>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01031d2:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01031d5:	39 f0                	cmp    %esi,%eax
f01031d7:	7c 3c                	jl     f0103215 <debuginfo_eip+0x208>
	       && stabs[lline].n_type != N_SOL
f01031d9:	89 d7                	mov    %edx,%edi
f01031db:	83 ea 0c             	sub    $0xc,%edx
f01031de:	0f b6 4a 10          	movzbl 0x10(%edx),%ecx
f01031e2:	80 f9 84             	cmp    $0x84,%cl
f01031e5:	74 0f                	je     f01031f6 <debuginfo_eip+0x1e9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01031e7:	80 f9 64             	cmp    $0x64,%cl
f01031ea:	75 e6                	jne    f01031d2 <debuginfo_eip+0x1c5>
f01031ec:	83 7f 08 00          	cmpl   $0x0,0x8(%edi)
f01031f0:	74 e0                	je     f01031d2 <debuginfo_eip+0x1c5>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01031f2:	39 c6                	cmp    %eax,%esi
f01031f4:	7f 1f                	jg     f0103215 <debuginfo_eip+0x208>
f01031f6:	6b c0 0c             	imul   $0xc,%eax,%eax
f01031f9:	8b 80 2c 52 10 f0    	mov    -0xfefadd4(%eax),%eax
f01031ff:	ba bb d2 10 f0       	mov    $0xf010d2bb,%edx
f0103204:	81 ea b5 b4 10 f0    	sub    $0xf010b4b5,%edx
f010320a:	39 d0                	cmp    %edx,%eax
f010320c:	73 07                	jae    f0103215 <debuginfo_eip+0x208>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010320e:	05 b5 b4 10 f0       	add    $0xf010b4b5,%eax
f0103213:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103215:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103218:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	

	return 0;
f010321b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103220:	39 ca                	cmp    %ecx,%edx
f0103222:	7d 70                	jge    f0103294 <debuginfo_eip+0x287>
		for (lline = lfun + 1;
f0103224:	8d 42 01             	lea    0x1(%edx),%eax
f0103227:	39 c1                	cmp    %eax,%ecx
f0103229:	7e 56                	jle    f0103281 <debuginfo_eip+0x274>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010322b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010322e:	80 b8 30 52 10 f0 a0 	cmpb   $0xa0,-0xfefadd0(%eax)
f0103235:	75 51                	jne    f0103288 <debuginfo_eip+0x27b>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103237:	8d 42 02             	lea    0x2(%edx),%eax
f010323a:	6b d2 0c             	imul   $0xc,%edx,%edx
f010323d:	81 c2 2c 52 10 f0    	add    $0xf010522c,%edx
f0103243:	89 cf                	mov    %ecx,%edi
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103245:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103249:	39 f8                	cmp    %edi,%eax
f010324b:	74 42                	je     f010328f <debuginfo_eip+0x282>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010324d:	0f b6 72 1c          	movzbl 0x1c(%edx),%esi
f0103251:	83 c0 01             	add    $0x1,%eax
f0103254:	83 c2 0c             	add    $0xc,%edx
f0103257:	89 f1                	mov    %esi,%ecx
f0103259:	80 f9 a0             	cmp    $0xa0,%cl
f010325c:	74 e7                	je     f0103245 <debuginfo_eip+0x238>
		     lline++)
			info->eip_fn_narg++;
	

	return 0;
f010325e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103263:	eb 2f                	jmp    f0103294 <debuginfo_eip+0x287>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103265:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010326a:	eb 28                	jmp    f0103294 <debuginfo_eip+0x287>
f010326c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103271:	eb 21                	jmp    f0103294 <debuginfo_eip+0x287>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0103273:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103278:	eb 1a                	jmp    f0103294 <debuginfo_eip+0x287>
	if( lline <= rline)
	{
		info->eip_line = stabs[lline].n_desc;
	}
	else
		return -1;
f010327a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010327f:	eb 13                	jmp    f0103294 <debuginfo_eip+0x287>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	

	return 0;
f0103281:	b8 00 00 00 00       	mov    $0x0,%eax
f0103286:	eb 0c                	jmp    f0103294 <debuginfo_eip+0x287>
f0103288:	b8 00 00 00 00       	mov    $0x0,%eax
f010328d:	eb 05                	jmp    f0103294 <debuginfo_eip+0x287>
f010328f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103294:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103297:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010329a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010329d:	89 ec                	mov    %ebp,%esp
f010329f:	5d                   	pop    %ebp
f01032a0:	c3                   	ret    
f01032a1:	66 90                	xchg   %ax,%ax
f01032a3:	66 90                	xchg   %ax,%ax
f01032a5:	66 90                	xchg   %ax,%ax
f01032a7:	66 90                	xchg   %ax,%ax
f01032a9:	66 90                	xchg   %ax,%ax
f01032ab:	66 90                	xchg   %ax,%ax
f01032ad:	66 90                	xchg   %ax,%ax
f01032af:	90                   	nop

f01032b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032b0:	55                   	push   %ebp
f01032b1:	89 e5                	mov    %esp,%ebp
f01032b3:	57                   	push   %edi
f01032b4:	56                   	push   %esi
f01032b5:	53                   	push   %ebx
f01032b6:	83 ec 4c             	sub    $0x4c,%esp
f01032b9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01032bc:	89 d7                	mov    %edx,%edi
f01032be:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01032c1:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01032c4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01032c7:	89 5d dc             	mov    %ebx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01032ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01032cf:	39 d8                	cmp    %ebx,%eax
f01032d1:	72 17                	jb     f01032ea <printnum+0x3a>
f01032d3:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01032d6:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f01032d9:	76 0f                	jbe    f01032ea <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01032db:	8b 75 14             	mov    0x14(%ebp),%esi
f01032de:	83 ee 01             	sub    $0x1,%esi
f01032e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032e4:	85 f6                	test   %esi,%esi
f01032e6:	7f 63                	jg     f010334b <printnum+0x9b>
f01032e8:	eb 75                	jmp    f010335f <printnum+0xaf>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01032ea:	8b 5d 18             	mov    0x18(%ebp),%ebx
f01032ed:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01032f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01032f4:	83 e8 01             	sub    $0x1,%eax
f01032f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01032fe:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103302:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103306:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010330a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010330d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103310:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103317:	00 
f0103318:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010331b:	89 1c 24             	mov    %ebx,(%esp)
f010331e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103321:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103325:	e8 d6 0a 00 00       	call   f0103e00 <__udivdi3>
f010332a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010332d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103330:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103334:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103338:	89 04 24             	mov    %eax,(%esp)
f010333b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010333f:	89 fa                	mov    %edi,%edx
f0103341:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103344:	e8 67 ff ff ff       	call   f01032b0 <printnum>
f0103349:	eb 14                	jmp    f010335f <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010334b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010334f:	8b 45 18             	mov    0x18(%ebp),%eax
f0103352:	89 04 24             	mov    %eax,(%esp)
f0103355:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103357:	83 ee 01             	sub    $0x1,%esi
f010335a:	75 ef                	jne    f010334b <printnum+0x9b>
f010335c:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010335f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103363:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103367:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010336a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010336e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103375:	00 
f0103376:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0103379:	89 1c 24             	mov    %ebx,(%esp)
f010337c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010337f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103383:	e8 c8 0b 00 00       	call   f0103f50 <__umoddi3>
f0103388:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010338c:	0f be 80 1d 50 10 f0 	movsbl -0xfefafe3(%eax),%eax
f0103393:	89 04 24             	mov    %eax,(%esp)
f0103396:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103399:	ff d0                	call   *%eax
}
f010339b:	83 c4 4c             	add    $0x4c,%esp
f010339e:	5b                   	pop    %ebx
f010339f:	5e                   	pop    %esi
f01033a0:	5f                   	pop    %edi
f01033a1:	5d                   	pop    %ebp
f01033a2:	c3                   	ret    

f01033a3 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01033a3:	55                   	push   %ebp
f01033a4:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01033a6:	83 fa 01             	cmp    $0x1,%edx
f01033a9:	7e 0e                	jle    f01033b9 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01033ab:	8b 10                	mov    (%eax),%edx
f01033ad:	8d 4a 08             	lea    0x8(%edx),%ecx
f01033b0:	89 08                	mov    %ecx,(%eax)
f01033b2:	8b 02                	mov    (%edx),%eax
f01033b4:	8b 52 04             	mov    0x4(%edx),%edx
f01033b7:	eb 22                	jmp    f01033db <getuint+0x38>
	else if (lflag)
f01033b9:	85 d2                	test   %edx,%edx
f01033bb:	74 10                	je     f01033cd <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01033bd:	8b 10                	mov    (%eax),%edx
f01033bf:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033c2:	89 08                	mov    %ecx,(%eax)
f01033c4:	8b 02                	mov    (%edx),%eax
f01033c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01033cb:	eb 0e                	jmp    f01033db <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01033cd:	8b 10                	mov    (%eax),%edx
f01033cf:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033d2:	89 08                	mov    %ecx,(%eax)
f01033d4:	8b 02                	mov    (%edx),%eax
f01033d6:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01033db:	5d                   	pop    %ebp
f01033dc:	c3                   	ret    

f01033dd <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033dd:	55                   	push   %ebp
f01033de:	89 e5                	mov    %esp,%ebp
f01033e0:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01033e3:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033e7:	8b 10                	mov    (%eax),%edx
f01033e9:	3b 50 04             	cmp    0x4(%eax),%edx
f01033ec:	73 0a                	jae    f01033f8 <sprintputch+0x1b>
		*b->buf++ = ch;
f01033ee:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01033f1:	88 0a                	mov    %cl,(%edx)
f01033f3:	83 c2 01             	add    $0x1,%edx
f01033f6:	89 10                	mov    %edx,(%eax)
}
f01033f8:	5d                   	pop    %ebp
f01033f9:	c3                   	ret    

f01033fa <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01033fa:	55                   	push   %ebp
f01033fb:	89 e5                	mov    %esp,%ebp
f01033fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103400:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103403:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103407:	8b 45 10             	mov    0x10(%ebp),%eax
f010340a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010340e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103411:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103415:	8b 45 08             	mov    0x8(%ebp),%eax
f0103418:	89 04 24             	mov    %eax,(%esp)
f010341b:	e8 02 00 00 00       	call   f0103422 <vprintfmt>
	va_end(ap);
}
f0103420:	c9                   	leave  
f0103421:	c3                   	ret    

f0103422 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103422:	55                   	push   %ebp
f0103423:	89 e5                	mov    %esp,%ebp
f0103425:	57                   	push   %edi
f0103426:	56                   	push   %esi
f0103427:	53                   	push   %ebx
f0103428:	83 ec 4c             	sub    $0x4c,%esp
f010342b:	8b 75 08             	mov    0x8(%ebp),%esi
f010342e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103431:	8b 7d 10             	mov    0x10(%ebp),%edi
f0103434:	eb 11                	jmp    f0103447 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103436:	85 c0                	test   %eax,%eax
f0103438:	0f 84 ff 03 00 00    	je     f010383d <vprintfmt+0x41b>
				return;
			putch(ch, putdat);
f010343e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103442:	89 04 24             	mov    %eax,(%esp)
f0103445:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103447:	0f b6 07             	movzbl (%edi),%eax
f010344a:	83 c7 01             	add    $0x1,%edi
f010344d:	83 f8 25             	cmp    $0x25,%eax
f0103450:	75 e4                	jne    f0103436 <vprintfmt+0x14>
f0103452:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0103456:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f010345d:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0103464:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f010346b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103470:	eb 2b                	jmp    f010349d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103472:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103475:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0103479:	eb 22                	jmp    f010349d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010347b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010347e:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0103482:	eb 19                	jmp    f010349d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103484:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103487:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f010348e:	eb 0d                	jmp    f010349d <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103490:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103493:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103496:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010349d:	0f b6 0f             	movzbl (%edi),%ecx
f01034a0:	8d 47 01             	lea    0x1(%edi),%eax
f01034a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034a6:	0f b6 07             	movzbl (%edi),%eax
f01034a9:	83 e8 23             	sub    $0x23,%eax
f01034ac:	3c 55                	cmp    $0x55,%al
f01034ae:	0f 87 64 03 00 00    	ja     f0103818 <vprintfmt+0x3f6>
f01034b4:	0f b6 c0             	movzbl %al,%eax
f01034b7:	ff 24 85 a8 50 10 f0 	jmp    *-0xfefaf58(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01034be:	83 e9 30             	sub    $0x30,%ecx
f01034c1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				ch = *fmt;
f01034c4:	0f be 47 01          	movsbl 0x1(%edi),%eax
				if (ch < '0' || ch > '9')
f01034c8:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01034cb:	83 f9 09             	cmp    $0x9,%ecx
f01034ce:	77 57                	ja     f0103527 <vprintfmt+0x105>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01034d3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01034d6:	8b 55 dc             	mov    -0x24(%ebp),%edx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01034d9:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01034dc:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01034df:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01034e3:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f01034e6:	8d 48 d0             	lea    -0x30(%eax),%ecx
f01034e9:	83 f9 09             	cmp    $0x9,%ecx
f01034ec:	76 eb                	jbe    f01034d9 <vprintfmt+0xb7>
f01034ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01034f1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034f4:	eb 34                	jmp    f010352a <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01034f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01034f9:	8d 48 04             	lea    0x4(%eax),%ecx
f01034fc:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01034ff:	8b 00                	mov    (%eax),%eax
f0103501:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103504:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103507:	eb 21                	jmp    f010352a <vprintfmt+0x108>

		case '.':
			if (width < 0)
f0103509:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010350d:	0f 88 71 ff ff ff    	js     f0103484 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103513:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103516:	eb 85                	jmp    f010349d <vprintfmt+0x7b>
f0103518:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010351b:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0103522:	e9 76 ff ff ff       	jmp    f010349d <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103527:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f010352a:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010352e:	0f 89 69 ff ff ff    	jns    f010349d <vprintfmt+0x7b>
f0103534:	e9 57 ff ff ff       	jmp    f0103490 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103539:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010353c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010353f:	e9 59 ff ff ff       	jmp    f010349d <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103544:	8b 45 14             	mov    0x14(%ebp),%eax
f0103547:	8d 50 04             	lea    0x4(%eax),%edx
f010354a:	89 55 14             	mov    %edx,0x14(%ebp)
f010354d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103551:	8b 00                	mov    (%eax),%eax
f0103553:	89 04 24             	mov    %eax,(%esp)
f0103556:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103558:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010355b:	e9 e7 fe ff ff       	jmp    f0103447 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103560:	8b 45 14             	mov    0x14(%ebp),%eax
f0103563:	8d 50 04             	lea    0x4(%eax),%edx
f0103566:	89 55 14             	mov    %edx,0x14(%ebp)
f0103569:	8b 00                	mov    (%eax),%eax
f010356b:	89 c2                	mov    %eax,%edx
f010356d:	c1 fa 1f             	sar    $0x1f,%edx
f0103570:	31 d0                	xor    %edx,%eax
f0103572:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103574:	83 f8 06             	cmp    $0x6,%eax
f0103577:	7f 0b                	jg     f0103584 <vprintfmt+0x162>
f0103579:	8b 14 85 00 52 10 f0 	mov    -0xfefae00(,%eax,4),%edx
f0103580:	85 d2                	test   %edx,%edx
f0103582:	75 20                	jne    f01035a4 <vprintfmt+0x182>
				printfmt(putch, putdat, "error %d", err);
f0103584:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103588:	c7 44 24 08 35 50 10 	movl   $0xf0105035,0x8(%esp)
f010358f:	f0 
f0103590:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103594:	89 34 24             	mov    %esi,(%esp)
f0103597:	e8 5e fe ff ff       	call   f01033fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010359c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010359f:	e9 a3 fe ff ff       	jmp    f0103447 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01035a4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035a8:	c7 44 24 08 38 4d 10 	movl   $0xf0104d38,0x8(%esp)
f01035af:	f0 
f01035b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035b4:	89 34 24             	mov    %esi,(%esp)
f01035b7:	e8 3e fe ff ff       	call   f01033fa <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035bc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01035bf:	e9 83 fe ff ff       	jmp    f0103447 <vprintfmt+0x25>
f01035c4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01035c7:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01035ca:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01035cd:	8b 45 14             	mov    0x14(%ebp),%eax
f01035d0:	8d 50 04             	lea    0x4(%eax),%edx
f01035d3:	89 55 14             	mov    %edx,0x14(%ebp)
f01035d6:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01035d8:	85 ff                	test   %edi,%edi
f01035da:	b8 2e 50 10 f0       	mov    $0xf010502e,%eax
f01035df:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01035e2:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f01035e6:	74 06                	je     f01035ee <vprintfmt+0x1cc>
f01035e8:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f01035ec:	7f 16                	jg     f0103604 <vprintfmt+0x1e2>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035ee:	0f b6 17             	movzbl (%edi),%edx
f01035f1:	0f be c2             	movsbl %dl,%eax
f01035f4:	83 c7 01             	add    $0x1,%edi
f01035f7:	85 c0                	test   %eax,%eax
f01035f9:	0f 85 9f 00 00 00    	jne    f010369e <vprintfmt+0x27c>
f01035ff:	e9 8b 00 00 00       	jmp    f010368f <vprintfmt+0x26d>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103604:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103608:	89 3c 24             	mov    %edi,(%esp)
f010360b:	e8 b2 03 00 00       	call   f01039c2 <strnlen>
f0103610:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0103613:	29 c2                	sub    %eax,%edx
f0103615:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103618:	85 d2                	test   %edx,%edx
f010361a:	7e d2                	jle    f01035ee <vprintfmt+0x1cc>
					putch(padc, putdat);
f010361c:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f0103620:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103623:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0103626:	89 d7                	mov    %edx,%edi
f0103628:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010362c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010362f:	89 04 24             	mov    %eax,(%esp)
f0103632:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103634:	83 ef 01             	sub    $0x1,%edi
f0103637:	75 ef                	jne    f0103628 <vprintfmt+0x206>
f0103639:	89 7d d8             	mov    %edi,-0x28(%ebp)
f010363c:	8b 7d cc             	mov    -0x34(%ebp),%edi
f010363f:	eb ad                	jmp    f01035ee <vprintfmt+0x1cc>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103641:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0103645:	74 20                	je     f0103667 <vprintfmt+0x245>
f0103647:	0f be d2             	movsbl %dl,%edx
f010364a:	83 ea 20             	sub    $0x20,%edx
f010364d:	83 fa 5e             	cmp    $0x5e,%edx
f0103650:	76 15                	jbe    f0103667 <vprintfmt+0x245>
					putch('?', putdat);
f0103652:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103655:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103659:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103660:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103663:	ff d1                	call   *%ecx
f0103665:	eb 0f                	jmp    f0103676 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0103667:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010366a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010366e:	89 04 24             	mov    %eax,(%esp)
f0103671:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103674:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103676:	83 eb 01             	sub    $0x1,%ebx
f0103679:	0f b6 17             	movzbl (%edi),%edx
f010367c:	0f be c2             	movsbl %dl,%eax
f010367f:	83 c7 01             	add    $0x1,%edi
f0103682:	85 c0                	test   %eax,%eax
f0103684:	75 24                	jne    f01036aa <vprintfmt+0x288>
f0103686:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0103689:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010368c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010368f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103692:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0103696:	0f 8e ab fd ff ff    	jle    f0103447 <vprintfmt+0x25>
f010369c:	eb 20                	jmp    f01036be <vprintfmt+0x29c>
f010369e:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01036a1:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01036a4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01036a7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01036aa:	85 f6                	test   %esi,%esi
f01036ac:	78 93                	js     f0103641 <vprintfmt+0x21f>
f01036ae:	83 ee 01             	sub    $0x1,%esi
f01036b1:	79 8e                	jns    f0103641 <vprintfmt+0x21f>
f01036b3:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01036b6:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01036b9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01036bc:	eb d1                	jmp    f010368f <vprintfmt+0x26d>
f01036be:	8b 7d d8             	mov    -0x28(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01036c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036c5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01036cc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01036ce:	83 ef 01             	sub    $0x1,%edi
f01036d1:	75 ee                	jne    f01036c1 <vprintfmt+0x29f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036d3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01036d6:	e9 6c fd ff ff       	jmp    f0103447 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01036db:	83 fa 01             	cmp    $0x1,%edx
f01036de:	66 90                	xchg   %ax,%ax
f01036e0:	7e 16                	jle    f01036f8 <vprintfmt+0x2d6>
		return va_arg(*ap, long long);
f01036e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e5:	8d 50 08             	lea    0x8(%eax),%edx
f01036e8:	89 55 14             	mov    %edx,0x14(%ebp)
f01036eb:	8b 10                	mov    (%eax),%edx
f01036ed:	8b 48 04             	mov    0x4(%eax),%ecx
f01036f0:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01036f3:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01036f6:	eb 32                	jmp    f010372a <vprintfmt+0x308>
	else if (lflag)
f01036f8:	85 d2                	test   %edx,%edx
f01036fa:	74 18                	je     f0103714 <vprintfmt+0x2f2>
		return va_arg(*ap, long);
f01036fc:	8b 45 14             	mov    0x14(%ebp),%eax
f01036ff:	8d 50 04             	lea    0x4(%eax),%edx
f0103702:	89 55 14             	mov    %edx,0x14(%ebp)
f0103705:	8b 00                	mov    (%eax),%eax
f0103707:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010370a:	89 c1                	mov    %eax,%ecx
f010370c:	c1 f9 1f             	sar    $0x1f,%ecx
f010370f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0103712:	eb 16                	jmp    f010372a <vprintfmt+0x308>
	else
		return va_arg(*ap, int);
f0103714:	8b 45 14             	mov    0x14(%ebp),%eax
f0103717:	8d 50 04             	lea    0x4(%eax),%edx
f010371a:	89 55 14             	mov    %edx,0x14(%ebp)
f010371d:	8b 00                	mov    (%eax),%eax
f010371f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103722:	89 c7                	mov    %eax,%edi
f0103724:	c1 ff 1f             	sar    $0x1f,%edi
f0103727:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010372a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010372d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103730:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103735:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103739:	0f 89 9d 00 00 00    	jns    f01037dc <vprintfmt+0x3ba>
				putch('-', putdat);
f010373f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103743:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010374a:	ff d6                	call   *%esi
				num = -(long long) num;
f010374c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010374f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103752:	f7 d8                	neg    %eax
f0103754:	83 d2 00             	adc    $0x0,%edx
f0103757:	f7 da                	neg    %edx
			}
			base = 10;
f0103759:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010375e:	eb 7c                	jmp    f01037dc <vprintfmt+0x3ba>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103760:	8d 45 14             	lea    0x14(%ebp),%eax
f0103763:	e8 3b fc ff ff       	call   f01033a3 <getuint>
			base = 10;
f0103768:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f010376d:	eb 6d                	jmp    f01037dc <vprintfmt+0x3ba>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f010376f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103773:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010377a:	ff d6                	call   *%esi
			putch('X', putdat);
f010377c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103780:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0103787:	ff d6                	call   *%esi
			putch('X', putdat);
f0103789:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010378d:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0103794:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103796:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103799:	e9 a9 fc ff ff       	jmp    f0103447 <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f010379e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037a2:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01037a9:	ff d6                	call   *%esi
			putch('x', putdat);
f01037ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037af:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01037b6:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01037b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01037bb:	8d 50 04             	lea    0x4(%eax),%edx
f01037be:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01037c1:	8b 00                	mov    (%eax),%eax
f01037c3:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01037c8:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01037cd:	eb 0d                	jmp    f01037dc <vprintfmt+0x3ba>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01037cf:	8d 45 14             	lea    0x14(%ebp),%eax
f01037d2:	e8 cc fb ff ff       	call   f01033a3 <getuint>
			base = 16;
f01037d7:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01037dc:	0f be 7d e0          	movsbl -0x20(%ebp),%edi
f01037e0:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01037e4:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01037e7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01037eb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01037ef:	89 04 24             	mov    %eax,(%esp)
f01037f2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037f6:	89 da                	mov    %ebx,%edx
f01037f8:	89 f0                	mov    %esi,%eax
f01037fa:	e8 b1 fa ff ff       	call   f01032b0 <printnum>
			break;
f01037ff:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103802:	e9 40 fc ff ff       	jmp    f0103447 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103807:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010380b:	89 0c 24             	mov    %ecx,(%esp)
f010380e:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103810:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103813:	e9 2f fc ff ff       	jmp    f0103447 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103818:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010381c:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103823:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103825:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103829:	0f 84 18 fc ff ff    	je     f0103447 <vprintfmt+0x25>
f010382f:	83 ef 01             	sub    $0x1,%edi
f0103832:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0103836:	75 f7                	jne    f010382f <vprintfmt+0x40d>
f0103838:	e9 0a fc ff ff       	jmp    f0103447 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010383d:	83 c4 4c             	add    $0x4c,%esp
f0103840:	5b                   	pop    %ebx
f0103841:	5e                   	pop    %esi
f0103842:	5f                   	pop    %edi
f0103843:	5d                   	pop    %ebp
f0103844:	c3                   	ret    

f0103845 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103845:	55                   	push   %ebp
f0103846:	89 e5                	mov    %esp,%ebp
f0103848:	83 ec 28             	sub    $0x28,%esp
f010384b:	8b 45 08             	mov    0x8(%ebp),%eax
f010384e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103851:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103854:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103858:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010385b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103862:	85 d2                	test   %edx,%edx
f0103864:	7e 30                	jle    f0103896 <vsnprintf+0x51>
f0103866:	85 c0                	test   %eax,%eax
f0103868:	74 2c                	je     f0103896 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010386a:	8b 45 14             	mov    0x14(%ebp),%eax
f010386d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103871:	8b 45 10             	mov    0x10(%ebp),%eax
f0103874:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103878:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010387b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010387f:	c7 04 24 dd 33 10 f0 	movl   $0xf01033dd,(%esp)
f0103886:	e8 97 fb ff ff       	call   f0103422 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010388b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010388e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103891:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103894:	eb 05                	jmp    f010389b <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103896:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010389b:	c9                   	leave  
f010389c:	c3                   	ret    

f010389d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010389d:	55                   	push   %ebp
f010389e:	89 e5                	mov    %esp,%ebp
f01038a0:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01038a3:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01038a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038aa:	8b 45 10             	mov    0x10(%ebp),%eax
f01038ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038bb:	89 04 24             	mov    %eax,(%esp)
f01038be:	e8 82 ff ff ff       	call   f0103845 <vsnprintf>
	va_end(ap);

	return rc;
}
f01038c3:	c9                   	leave  
f01038c4:	c3                   	ret    
f01038c5:	66 90                	xchg   %ax,%ax
f01038c7:	66 90                	xchg   %ax,%ax
f01038c9:	66 90                	xchg   %ax,%ax
f01038cb:	66 90                	xchg   %ax,%ax
f01038cd:	66 90                	xchg   %ax,%ax
f01038cf:	90                   	nop

f01038d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01038d0:	55                   	push   %ebp
f01038d1:	89 e5                	mov    %esp,%ebp
f01038d3:	57                   	push   %edi
f01038d4:	56                   	push   %esi
f01038d5:	53                   	push   %ebx
f01038d6:	83 ec 1c             	sub    $0x1c,%esp
f01038d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01038dc:	85 c0                	test   %eax,%eax
f01038de:	74 10                	je     f01038f0 <readline+0x20>
		cprintf("%s", prompt);
f01038e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038e4:	c7 04 24 38 4d 10 f0 	movl   $0xf0104d38,(%esp)
f01038eb:	e8 22 f6 ff ff       	call   f0102f12 <cprintf>

	i = 0;
	echoing = iscons(0);
f01038f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01038f7:	e8 1e cd ff ff       	call   f010061a <iscons>
f01038fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01038fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103903:	e8 01 cd ff ff       	call   f0100609 <getchar>
f0103908:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010390a:	85 c0                	test   %eax,%eax
f010390c:	79 17                	jns    f0103925 <readline+0x55>
			cprintf("read error: %e\n", c);
f010390e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103912:	c7 04 24 1c 52 10 f0 	movl   $0xf010521c,(%esp)
f0103919:	e8 f4 f5 ff ff       	call   f0102f12 <cprintf>
			return NULL;
f010391e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103923:	eb 6d                	jmp    f0103992 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103925:	83 f8 7f             	cmp    $0x7f,%eax
f0103928:	74 05                	je     f010392f <readline+0x5f>
f010392a:	83 f8 08             	cmp    $0x8,%eax
f010392d:	75 19                	jne    f0103948 <readline+0x78>
f010392f:	85 f6                	test   %esi,%esi
f0103931:	7e 15                	jle    f0103948 <readline+0x78>
			if (echoing)
f0103933:	85 ff                	test   %edi,%edi
f0103935:	74 0c                	je     f0103943 <readline+0x73>
				cputchar('\b');
f0103937:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010393e:	e8 b6 cc ff ff       	call   f01005f9 <cputchar>
			i--;
f0103943:	83 ee 01             	sub    $0x1,%esi
f0103946:	eb bb                	jmp    f0103903 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103948:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010394e:	7f 1c                	jg     f010396c <readline+0x9c>
f0103950:	83 fb 1f             	cmp    $0x1f,%ebx
f0103953:	7e 17                	jle    f010396c <readline+0x9c>
			if (echoing)
f0103955:	85 ff                	test   %edi,%edi
f0103957:	74 08                	je     f0103961 <readline+0x91>
				cputchar(c);
f0103959:	89 1c 24             	mov    %ebx,(%esp)
f010395c:	e8 98 cc ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103961:	88 9e 60 85 11 f0    	mov    %bl,-0xfee7aa0(%esi)
f0103967:	83 c6 01             	add    $0x1,%esi
f010396a:	eb 97                	jmp    f0103903 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010396c:	83 fb 0d             	cmp    $0xd,%ebx
f010396f:	74 05                	je     f0103976 <readline+0xa6>
f0103971:	83 fb 0a             	cmp    $0xa,%ebx
f0103974:	75 8d                	jne    f0103903 <readline+0x33>
			if (echoing)
f0103976:	85 ff                	test   %edi,%edi
f0103978:	74 0c                	je     f0103986 <readline+0xb6>
				cputchar('\n');
f010397a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103981:	e8 73 cc ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103986:	c6 86 60 85 11 f0 00 	movb   $0x0,-0xfee7aa0(%esi)
			return buf;
f010398d:	b8 60 85 11 f0       	mov    $0xf0118560,%eax
		}
	}
}
f0103992:	83 c4 1c             	add    $0x1c,%esp
f0103995:	5b                   	pop    %ebx
f0103996:	5e                   	pop    %esi
f0103997:	5f                   	pop    %edi
f0103998:	5d                   	pop    %ebp
f0103999:	c3                   	ret    
f010399a:	66 90                	xchg   %ax,%ax
f010399c:	66 90                	xchg   %ax,%ax
f010399e:	66 90                	xchg   %ax,%ax

f01039a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01039a0:	55                   	push   %ebp
f01039a1:	89 e5                	mov    %esp,%ebp
f01039a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01039a6:	80 3a 00             	cmpb   $0x0,(%edx)
f01039a9:	74 10                	je     f01039bb <strlen+0x1b>
f01039ab:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f01039b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01039b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01039b7:	75 f7                	jne    f01039b0 <strlen+0x10>
f01039b9:	eb 05                	jmp    f01039c0 <strlen+0x20>
f01039bb:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01039c0:	5d                   	pop    %ebp
f01039c1:	c3                   	ret    

f01039c2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01039c2:	55                   	push   %ebp
f01039c3:	89 e5                	mov    %esp,%ebp
f01039c5:	53                   	push   %ebx
f01039c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01039c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039cc:	85 c9                	test   %ecx,%ecx
f01039ce:	74 1c                	je     f01039ec <strnlen+0x2a>
f01039d0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01039d3:	74 1e                	je     f01039f3 <strnlen+0x31>
f01039d5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01039da:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01039dc:	39 ca                	cmp    %ecx,%edx
f01039de:	74 18                	je     f01039f8 <strnlen+0x36>
f01039e0:	83 c2 01             	add    $0x1,%edx
f01039e3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01039e8:	75 f0                	jne    f01039da <strnlen+0x18>
f01039ea:	eb 0c                	jmp    f01039f8 <strnlen+0x36>
f01039ec:	b8 00 00 00 00       	mov    $0x0,%eax
f01039f1:	eb 05                	jmp    f01039f8 <strnlen+0x36>
f01039f3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01039f8:	5b                   	pop    %ebx
f01039f9:	5d                   	pop    %ebp
f01039fa:	c3                   	ret    

f01039fb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01039fb:	55                   	push   %ebp
f01039fc:	89 e5                	mov    %esp,%ebp
f01039fe:	53                   	push   %ebx
f01039ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a05:	89 c2                	mov    %eax,%edx
f0103a07:	0f b6 19             	movzbl (%ecx),%ebx
f0103a0a:	88 1a                	mov    %bl,(%edx)
f0103a0c:	83 c2 01             	add    $0x1,%edx
f0103a0f:	83 c1 01             	add    $0x1,%ecx
f0103a12:	84 db                	test   %bl,%bl
f0103a14:	75 f1                	jne    f0103a07 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0103a16:	5b                   	pop    %ebx
f0103a17:	5d                   	pop    %ebp
f0103a18:	c3                   	ret    

f0103a19 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a19:	55                   	push   %ebp
f0103a1a:	89 e5                	mov    %esp,%ebp
f0103a1c:	53                   	push   %ebx
f0103a1d:	83 ec 08             	sub    $0x8,%esp
f0103a20:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a23:	89 1c 24             	mov    %ebx,(%esp)
f0103a26:	e8 75 ff ff ff       	call   f01039a0 <strlen>
	strcpy(dst + len, src);
f0103a2b:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a2e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103a32:	01 d8                	add    %ebx,%eax
f0103a34:	89 04 24             	mov    %eax,(%esp)
f0103a37:	e8 bf ff ff ff       	call   f01039fb <strcpy>
	return dst;
}
f0103a3c:	89 d8                	mov    %ebx,%eax
f0103a3e:	83 c4 08             	add    $0x8,%esp
f0103a41:	5b                   	pop    %ebx
f0103a42:	5d                   	pop    %ebp
f0103a43:	c3                   	ret    

f0103a44 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a44:	55                   	push   %ebp
f0103a45:	89 e5                	mov    %esp,%ebp
f0103a47:	56                   	push   %esi
f0103a48:	53                   	push   %ebx
f0103a49:	8b 75 08             	mov    0x8(%ebp),%esi
f0103a4c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a4f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a52:	85 db                	test   %ebx,%ebx
f0103a54:	74 16                	je     f0103a6c <strncpy+0x28>
	strcpy(dst + len, src);
	return dst;
}

char *
strncpy(char *dst, const char *src, size_t size) {
f0103a56:	01 f3                	add    %esi,%ebx
f0103a58:	89 f1                	mov    %esi,%ecx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
f0103a5a:	0f b6 02             	movzbl (%edx),%eax
f0103a5d:	88 01                	mov    %al,(%ecx)
f0103a5f:	83 c1 01             	add    $0x1,%ecx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a62:	80 3a 01             	cmpb   $0x1,(%edx)
f0103a65:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a68:	39 d9                	cmp    %ebx,%ecx
f0103a6a:	75 ee                	jne    f0103a5a <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103a6c:	89 f0                	mov    %esi,%eax
f0103a6e:	5b                   	pop    %ebx
f0103a6f:	5e                   	pop    %esi
f0103a70:	5d                   	pop    %ebp
f0103a71:	c3                   	ret    

f0103a72 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a72:	55                   	push   %ebp
f0103a73:	89 e5                	mov    %esp,%ebp
f0103a75:	57                   	push   %edi
f0103a76:	56                   	push   %esi
f0103a77:	53                   	push   %ebx
f0103a78:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a7b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a7e:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a81:	89 f8                	mov    %edi,%eax
f0103a83:	85 f6                	test   %esi,%esi
f0103a85:	74 33                	je     f0103aba <strlcpy+0x48>
		while (--size > 0 && *src != '\0')
f0103a87:	83 fe 01             	cmp    $0x1,%esi
f0103a8a:	74 25                	je     f0103ab1 <strlcpy+0x3f>
f0103a8c:	0f b6 0b             	movzbl (%ebx),%ecx
f0103a8f:	84 c9                	test   %cl,%cl
f0103a91:	74 22                	je     f0103ab5 <strlcpy+0x43>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103a93:	83 ee 02             	sub    $0x2,%esi
f0103a96:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103a9b:	88 08                	mov    %cl,(%eax)
f0103a9d:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103aa0:	39 f2                	cmp    %esi,%edx
f0103aa2:	74 13                	je     f0103ab7 <strlcpy+0x45>
f0103aa4:	83 c2 01             	add    $0x1,%edx
f0103aa7:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103aab:	84 c9                	test   %cl,%cl
f0103aad:	75 ec                	jne    f0103a9b <strlcpy+0x29>
f0103aaf:	eb 06                	jmp    f0103ab7 <strlcpy+0x45>
f0103ab1:	89 f8                	mov    %edi,%eax
f0103ab3:	eb 02                	jmp    f0103ab7 <strlcpy+0x45>
f0103ab5:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0103ab7:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103aba:	29 f8                	sub    %edi,%eax
}
f0103abc:	5b                   	pop    %ebx
f0103abd:	5e                   	pop    %esi
f0103abe:	5f                   	pop    %edi
f0103abf:	5d                   	pop    %ebp
f0103ac0:	c3                   	ret    

f0103ac1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103ac1:	55                   	push   %ebp
f0103ac2:	89 e5                	mov    %esp,%ebp
f0103ac4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ac7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103aca:	0f b6 01             	movzbl (%ecx),%eax
f0103acd:	84 c0                	test   %al,%al
f0103acf:	74 15                	je     f0103ae6 <strcmp+0x25>
f0103ad1:	3a 02                	cmp    (%edx),%al
f0103ad3:	75 11                	jne    f0103ae6 <strcmp+0x25>
		p++, q++;
f0103ad5:	83 c1 01             	add    $0x1,%ecx
f0103ad8:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103adb:	0f b6 01             	movzbl (%ecx),%eax
f0103ade:	84 c0                	test   %al,%al
f0103ae0:	74 04                	je     f0103ae6 <strcmp+0x25>
f0103ae2:	3a 02                	cmp    (%edx),%al
f0103ae4:	74 ef                	je     f0103ad5 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103ae6:	0f b6 c0             	movzbl %al,%eax
f0103ae9:	0f b6 12             	movzbl (%edx),%edx
f0103aec:	29 d0                	sub    %edx,%eax
}
f0103aee:	5d                   	pop    %ebp
f0103aef:	c3                   	ret    

f0103af0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103af0:	55                   	push   %ebp
f0103af1:	89 e5                	mov    %esp,%ebp
f0103af3:	56                   	push   %esi
f0103af4:	53                   	push   %ebx
f0103af5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103af8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103afb:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0103afe:	85 f6                	test   %esi,%esi
f0103b00:	74 29                	je     f0103b2b <strncmp+0x3b>
f0103b02:	0f b6 03             	movzbl (%ebx),%eax
f0103b05:	84 c0                	test   %al,%al
f0103b07:	74 30                	je     f0103b39 <strncmp+0x49>
f0103b09:	3a 02                	cmp    (%edx),%al
f0103b0b:	75 2c                	jne    f0103b39 <strncmp+0x49>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f0103b0d:	8d 43 01             	lea    0x1(%ebx),%eax
f0103b10:	01 de                	add    %ebx,%esi
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0103b12:	89 c3                	mov    %eax,%ebx
f0103b14:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b17:	39 f0                	cmp    %esi,%eax
f0103b19:	74 17                	je     f0103b32 <strncmp+0x42>
f0103b1b:	0f b6 08             	movzbl (%eax),%ecx
f0103b1e:	84 c9                	test   %cl,%cl
f0103b20:	74 17                	je     f0103b39 <strncmp+0x49>
f0103b22:	83 c0 01             	add    $0x1,%eax
f0103b25:	3a 0a                	cmp    (%edx),%cl
f0103b27:	74 e9                	je     f0103b12 <strncmp+0x22>
f0103b29:	eb 0e                	jmp    f0103b39 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b30:	eb 0f                	jmp    f0103b41 <strncmp+0x51>
f0103b32:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b37:	eb 08                	jmp    f0103b41 <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b39:	0f b6 03             	movzbl (%ebx),%eax
f0103b3c:	0f b6 12             	movzbl (%edx),%edx
f0103b3f:	29 d0                	sub    %edx,%eax
}
f0103b41:	5b                   	pop    %ebx
f0103b42:	5e                   	pop    %esi
f0103b43:	5d                   	pop    %ebp
f0103b44:	c3                   	ret    

f0103b45 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103b45:	55                   	push   %ebp
f0103b46:	89 e5                	mov    %esp,%ebp
f0103b48:	53                   	push   %ebx
f0103b49:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b4c:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0103b4f:	0f b6 18             	movzbl (%eax),%ebx
f0103b52:	84 db                	test   %bl,%bl
f0103b54:	74 1d                	je     f0103b73 <strchr+0x2e>
f0103b56:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103b58:	38 d3                	cmp    %dl,%bl
f0103b5a:	75 06                	jne    f0103b62 <strchr+0x1d>
f0103b5c:	eb 1a                	jmp    f0103b78 <strchr+0x33>
f0103b5e:	38 ca                	cmp    %cl,%dl
f0103b60:	74 16                	je     f0103b78 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b62:	83 c0 01             	add    $0x1,%eax
f0103b65:	0f b6 10             	movzbl (%eax),%edx
f0103b68:	84 d2                	test   %dl,%dl
f0103b6a:	75 f2                	jne    f0103b5e <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b6c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b71:	eb 05                	jmp    f0103b78 <strchr+0x33>
f0103b73:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b78:	5b                   	pop    %ebx
f0103b79:	5d                   	pop    %ebp
f0103b7a:	c3                   	ret    

f0103b7b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b7b:	55                   	push   %ebp
f0103b7c:	89 e5                	mov    %esp,%ebp
f0103b7e:	53                   	push   %ebx
f0103b7f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b82:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0103b85:	0f b6 18             	movzbl (%eax),%ebx
f0103b88:	84 db                	test   %bl,%bl
f0103b8a:	74 16                	je     f0103ba2 <strfind+0x27>
f0103b8c:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0103b8e:	38 d3                	cmp    %dl,%bl
f0103b90:	75 06                	jne    f0103b98 <strfind+0x1d>
f0103b92:	eb 0e                	jmp    f0103ba2 <strfind+0x27>
f0103b94:	38 ca                	cmp    %cl,%dl
f0103b96:	74 0a                	je     f0103ba2 <strfind+0x27>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103b98:	83 c0 01             	add    $0x1,%eax
f0103b9b:	0f b6 10             	movzbl (%eax),%edx
f0103b9e:	84 d2                	test   %dl,%dl
f0103ba0:	75 f2                	jne    f0103b94 <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f0103ba2:	5b                   	pop    %ebx
f0103ba3:	5d                   	pop    %ebp
f0103ba4:	c3                   	ret    

f0103ba5 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103ba5:	55                   	push   %ebp
f0103ba6:	89 e5                	mov    %esp,%ebp
f0103ba8:	83 ec 0c             	sub    $0xc,%esp
f0103bab:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103bae:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103bb1:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103bb4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bb7:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103bba:	85 c9                	test   %ecx,%ecx
f0103bbc:	74 36                	je     f0103bf4 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103bbe:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bc4:	75 28                	jne    f0103bee <memset+0x49>
f0103bc6:	f6 c1 03             	test   $0x3,%cl
f0103bc9:	75 23                	jne    f0103bee <memset+0x49>
		c &= 0xFF;
f0103bcb:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103bcf:	89 d3                	mov    %edx,%ebx
f0103bd1:	c1 e3 08             	shl    $0x8,%ebx
f0103bd4:	89 d6                	mov    %edx,%esi
f0103bd6:	c1 e6 18             	shl    $0x18,%esi
f0103bd9:	89 d0                	mov    %edx,%eax
f0103bdb:	c1 e0 10             	shl    $0x10,%eax
f0103bde:	09 f0                	or     %esi,%eax
f0103be0:	09 c2                	or     %eax,%edx
f0103be2:	89 d0                	mov    %edx,%eax
f0103be4:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103be6:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103be9:	fc                   	cld    
f0103bea:	f3 ab                	rep stos %eax,%es:(%edi)
f0103bec:	eb 06                	jmp    f0103bf4 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103bee:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bf1:	fc                   	cld    
f0103bf2:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103bf4:	89 f8                	mov    %edi,%eax
f0103bf6:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103bf9:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103bfc:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103bff:	89 ec                	mov    %ebp,%esp
f0103c01:	5d                   	pop    %ebp
f0103c02:	c3                   	ret    

f0103c03 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c03:	55                   	push   %ebp
f0103c04:	89 e5                	mov    %esp,%ebp
f0103c06:	83 ec 08             	sub    $0x8,%esp
f0103c09:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103c0c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103c0f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c12:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c15:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c18:	39 c6                	cmp    %eax,%esi
f0103c1a:	73 36                	jae    f0103c52 <memmove+0x4f>
f0103c1c:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c1f:	39 d0                	cmp    %edx,%eax
f0103c21:	73 2f                	jae    f0103c52 <memmove+0x4f>
		s += n;
		d += n;
f0103c23:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c26:	f6 c2 03             	test   $0x3,%dl
f0103c29:	75 1b                	jne    f0103c46 <memmove+0x43>
f0103c2b:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c31:	75 13                	jne    f0103c46 <memmove+0x43>
f0103c33:	f6 c1 03             	test   $0x3,%cl
f0103c36:	75 0e                	jne    f0103c46 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c38:	83 ef 04             	sub    $0x4,%edi
f0103c3b:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c3e:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103c41:	fd                   	std    
f0103c42:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c44:	eb 09                	jmp    f0103c4f <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c46:	83 ef 01             	sub    $0x1,%edi
f0103c49:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103c4c:	fd                   	std    
f0103c4d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103c4f:	fc                   	cld    
f0103c50:	eb 20                	jmp    f0103c72 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c52:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103c58:	75 13                	jne    f0103c6d <memmove+0x6a>
f0103c5a:	a8 03                	test   $0x3,%al
f0103c5c:	75 0f                	jne    f0103c6d <memmove+0x6a>
f0103c5e:	f6 c1 03             	test   $0x3,%cl
f0103c61:	75 0a                	jne    f0103c6d <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103c63:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103c66:	89 c7                	mov    %eax,%edi
f0103c68:	fc                   	cld    
f0103c69:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c6b:	eb 05                	jmp    f0103c72 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c6d:	89 c7                	mov    %eax,%edi
f0103c6f:	fc                   	cld    
f0103c70:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c72:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103c75:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103c78:	89 ec                	mov    %ebp,%esp
f0103c7a:	5d                   	pop    %ebp
f0103c7b:	c3                   	ret    

f0103c7c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c7c:	55                   	push   %ebp
f0103c7d:	89 e5                	mov    %esp,%ebp
f0103c7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103c82:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c85:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c89:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c8c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c90:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c93:	89 04 24             	mov    %eax,(%esp)
f0103c96:	e8 68 ff ff ff       	call   f0103c03 <memmove>
}
f0103c9b:	c9                   	leave  
f0103c9c:	c3                   	ret    

f0103c9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c9d:	55                   	push   %ebp
f0103c9e:	89 e5                	mov    %esp,%ebp
f0103ca0:	57                   	push   %edi
f0103ca1:	56                   	push   %esi
f0103ca2:	53                   	push   %ebx
f0103ca3:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103ca6:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103ca9:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103cac:	8d 78 ff             	lea    -0x1(%eax),%edi
f0103caf:	85 c0                	test   %eax,%eax
f0103cb1:	74 36                	je     f0103ce9 <memcmp+0x4c>
		if (*s1 != *s2)
f0103cb3:	0f b6 03             	movzbl (%ebx),%eax
f0103cb6:	0f b6 0e             	movzbl (%esi),%ecx
f0103cb9:	38 c8                	cmp    %cl,%al
f0103cbb:	75 17                	jne    f0103cd4 <memcmp+0x37>
f0103cbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0103cc2:	eb 1a                	jmp    f0103cde <memcmp+0x41>
f0103cc4:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103cc9:	83 c2 01             	add    $0x1,%edx
f0103ccc:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103cd0:	38 c8                	cmp    %cl,%al
f0103cd2:	74 0a                	je     f0103cde <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0103cd4:	0f b6 c0             	movzbl %al,%eax
f0103cd7:	0f b6 c9             	movzbl %cl,%ecx
f0103cda:	29 c8                	sub    %ecx,%eax
f0103cdc:	eb 10                	jmp    f0103cee <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103cde:	39 fa                	cmp    %edi,%edx
f0103ce0:	75 e2                	jne    f0103cc4 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103ce2:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ce7:	eb 05                	jmp    f0103cee <memcmp+0x51>
f0103ce9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103cee:	5b                   	pop    %ebx
f0103cef:	5e                   	pop    %esi
f0103cf0:	5f                   	pop    %edi
f0103cf1:	5d                   	pop    %ebp
f0103cf2:	c3                   	ret    

f0103cf3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103cf3:	55                   	push   %ebp
f0103cf4:	89 e5                	mov    %esp,%ebp
f0103cf6:	53                   	push   %ebx
f0103cf7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cfa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f0103cfd:	89 c2                	mov    %eax,%edx
f0103cff:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103d02:	39 d0                	cmp    %edx,%eax
f0103d04:	73 13                	jae    f0103d19 <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d06:	89 d9                	mov    %ebx,%ecx
f0103d08:	38 18                	cmp    %bl,(%eax)
f0103d0a:	75 06                	jne    f0103d12 <memfind+0x1f>
f0103d0c:	eb 0b                	jmp    f0103d19 <memfind+0x26>
f0103d0e:	38 08                	cmp    %cl,(%eax)
f0103d10:	74 07                	je     f0103d19 <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d12:	83 c0 01             	add    $0x1,%eax
f0103d15:	39 d0                	cmp    %edx,%eax
f0103d17:	75 f5                	jne    f0103d0e <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d19:	5b                   	pop    %ebx
f0103d1a:	5d                   	pop    %ebp
f0103d1b:	c3                   	ret    

f0103d1c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d1c:	55                   	push   %ebp
f0103d1d:	89 e5                	mov    %esp,%ebp
f0103d1f:	57                   	push   %edi
f0103d20:	56                   	push   %esi
f0103d21:	53                   	push   %ebx
f0103d22:	83 ec 04             	sub    $0x4,%esp
f0103d25:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d28:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d2b:	0f b6 02             	movzbl (%edx),%eax
f0103d2e:	3c 09                	cmp    $0x9,%al
f0103d30:	74 04                	je     f0103d36 <strtol+0x1a>
f0103d32:	3c 20                	cmp    $0x20,%al
f0103d34:	75 0e                	jne    f0103d44 <strtol+0x28>
		s++;
f0103d36:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d39:	0f b6 02             	movzbl (%edx),%eax
f0103d3c:	3c 09                	cmp    $0x9,%al
f0103d3e:	74 f6                	je     f0103d36 <strtol+0x1a>
f0103d40:	3c 20                	cmp    $0x20,%al
f0103d42:	74 f2                	je     f0103d36 <strtol+0x1a>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d44:	3c 2b                	cmp    $0x2b,%al
f0103d46:	75 0a                	jne    f0103d52 <strtol+0x36>
		s++;
f0103d48:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103d4b:	bf 00 00 00 00       	mov    $0x0,%edi
f0103d50:	eb 10                	jmp    f0103d62 <strtol+0x46>
f0103d52:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103d57:	3c 2d                	cmp    $0x2d,%al
f0103d59:	75 07                	jne    f0103d62 <strtol+0x46>
		s++, neg = 1;
f0103d5b:	83 c2 01             	add    $0x1,%edx
f0103d5e:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103d62:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0103d68:	75 15                	jne    f0103d7f <strtol+0x63>
f0103d6a:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d6d:	75 10                	jne    f0103d7f <strtol+0x63>
f0103d6f:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103d73:	75 0a                	jne    f0103d7f <strtol+0x63>
		s += 2, base = 16;
f0103d75:	83 c2 02             	add    $0x2,%edx
f0103d78:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d7d:	eb 10                	jmp    f0103d8f <strtol+0x73>
	else if (base == 0 && s[0] == '0')
f0103d7f:	85 db                	test   %ebx,%ebx
f0103d81:	75 0c                	jne    f0103d8f <strtol+0x73>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d83:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d85:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d88:	75 05                	jne    f0103d8f <strtol+0x73>
		s++, base = 8;
f0103d8a:	83 c2 01             	add    $0x1,%edx
f0103d8d:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103d8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d94:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103d97:	0f b6 0a             	movzbl (%edx),%ecx
f0103d9a:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0103d9d:	89 f3                	mov    %esi,%ebx
f0103d9f:	80 fb 09             	cmp    $0x9,%bl
f0103da2:	77 08                	ja     f0103dac <strtol+0x90>
			dig = *s - '0';
f0103da4:	0f be c9             	movsbl %cl,%ecx
f0103da7:	83 e9 30             	sub    $0x30,%ecx
f0103daa:	eb 22                	jmp    f0103dce <strtol+0xb2>
		else if (*s >= 'a' && *s <= 'z')
f0103dac:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0103daf:	89 f3                	mov    %esi,%ebx
f0103db1:	80 fb 19             	cmp    $0x19,%bl
f0103db4:	77 08                	ja     f0103dbe <strtol+0xa2>
			dig = *s - 'a' + 10;
f0103db6:	0f be c9             	movsbl %cl,%ecx
f0103db9:	83 e9 57             	sub    $0x57,%ecx
f0103dbc:	eb 10                	jmp    f0103dce <strtol+0xb2>
		else if (*s >= 'A' && *s <= 'Z')
f0103dbe:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0103dc1:	89 f3                	mov    %esi,%ebx
f0103dc3:	80 fb 19             	cmp    $0x19,%bl
f0103dc6:	77 16                	ja     f0103dde <strtol+0xc2>
			dig = *s - 'A' + 10;
f0103dc8:	0f be c9             	movsbl %cl,%ecx
f0103dcb:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103dce:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103dd1:	7d 0f                	jge    f0103de2 <strtol+0xc6>
			break;
		s++, val = (val * base) + dig;
f0103dd3:	83 c2 01             	add    $0x1,%edx
f0103dd6:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0103dda:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103ddc:	eb b9                	jmp    f0103d97 <strtol+0x7b>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103dde:	89 c1                	mov    %eax,%ecx
f0103de0:	eb 02                	jmp    f0103de4 <strtol+0xc8>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103de2:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103de4:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103de8:	74 05                	je     f0103def <strtol+0xd3>
		*endptr = (char *) s;
f0103dea:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ded:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103def:	89 ca                	mov    %ecx,%edx
f0103df1:	f7 da                	neg    %edx
f0103df3:	85 ff                	test   %edi,%edi
f0103df5:	0f 45 c2             	cmovne %edx,%eax
}
f0103df8:	83 c4 04             	add    $0x4,%esp
f0103dfb:	5b                   	pop    %ebx
f0103dfc:	5e                   	pop    %esi
f0103dfd:	5f                   	pop    %edi
f0103dfe:	5d                   	pop    %ebp
f0103dff:	c3                   	ret    

f0103e00 <__udivdi3>:
f0103e00:	83 ec 1c             	sub    $0x1c,%esp
f0103e03:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0103e07:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103e0b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103e0f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103e13:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0103e17:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f0103e1b:	85 c0                	test   %eax,%eax
f0103e1d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103e21:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0103e25:	89 ea                	mov    %ebp,%edx
f0103e27:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e2b:	75 33                	jne    f0103e60 <__udivdi3+0x60>
f0103e2d:	39 e9                	cmp    %ebp,%ecx
f0103e2f:	77 6f                	ja     f0103ea0 <__udivdi3+0xa0>
f0103e31:	85 c9                	test   %ecx,%ecx
f0103e33:	89 ce                	mov    %ecx,%esi
f0103e35:	75 0b                	jne    f0103e42 <__udivdi3+0x42>
f0103e37:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e3c:	31 d2                	xor    %edx,%edx
f0103e3e:	f7 f1                	div    %ecx
f0103e40:	89 c6                	mov    %eax,%esi
f0103e42:	31 d2                	xor    %edx,%edx
f0103e44:	89 e8                	mov    %ebp,%eax
f0103e46:	f7 f6                	div    %esi
f0103e48:	89 c5                	mov    %eax,%ebp
f0103e4a:	89 f8                	mov    %edi,%eax
f0103e4c:	f7 f6                	div    %esi
f0103e4e:	89 ea                	mov    %ebp,%edx
f0103e50:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e54:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e58:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e5c:	83 c4 1c             	add    $0x1c,%esp
f0103e5f:	c3                   	ret    
f0103e60:	39 e8                	cmp    %ebp,%eax
f0103e62:	77 24                	ja     f0103e88 <__udivdi3+0x88>
f0103e64:	0f bd c8             	bsr    %eax,%ecx
f0103e67:	83 f1 1f             	xor    $0x1f,%ecx
f0103e6a:	89 0c 24             	mov    %ecx,(%esp)
f0103e6d:	75 49                	jne    f0103eb8 <__udivdi3+0xb8>
f0103e6f:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103e73:	39 74 24 04          	cmp    %esi,0x4(%esp)
f0103e77:	0f 86 ab 00 00 00    	jbe    f0103f28 <__udivdi3+0x128>
f0103e7d:	39 e8                	cmp    %ebp,%eax
f0103e7f:	0f 82 a3 00 00 00    	jb     f0103f28 <__udivdi3+0x128>
f0103e85:	8d 76 00             	lea    0x0(%esi),%esi
f0103e88:	31 d2                	xor    %edx,%edx
f0103e8a:	31 c0                	xor    %eax,%eax
f0103e8c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e90:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e94:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e98:	83 c4 1c             	add    $0x1c,%esp
f0103e9b:	c3                   	ret    
f0103e9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103ea0:	89 f8                	mov    %edi,%eax
f0103ea2:	f7 f1                	div    %ecx
f0103ea4:	31 d2                	xor    %edx,%edx
f0103ea6:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103eaa:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103eae:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103eb2:	83 c4 1c             	add    $0x1c,%esp
f0103eb5:	c3                   	ret    
f0103eb6:	66 90                	xchg   %ax,%ax
f0103eb8:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103ebc:	89 c6                	mov    %eax,%esi
f0103ebe:	b8 20 00 00 00       	mov    $0x20,%eax
f0103ec3:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0103ec7:	2b 04 24             	sub    (%esp),%eax
f0103eca:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0103ece:	d3 e6                	shl    %cl,%esi
f0103ed0:	89 c1                	mov    %eax,%ecx
f0103ed2:	d3 ed                	shr    %cl,%ebp
f0103ed4:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103ed8:	09 f5                	or     %esi,%ebp
f0103eda:	8b 74 24 04          	mov    0x4(%esp),%esi
f0103ede:	d3 e6                	shl    %cl,%esi
f0103ee0:	89 c1                	mov    %eax,%ecx
f0103ee2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103ee6:	89 d6                	mov    %edx,%esi
f0103ee8:	d3 ee                	shr    %cl,%esi
f0103eea:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103eee:	d3 e2                	shl    %cl,%edx
f0103ef0:	89 c1                	mov    %eax,%ecx
f0103ef2:	d3 ef                	shr    %cl,%edi
f0103ef4:	09 d7                	or     %edx,%edi
f0103ef6:	89 f2                	mov    %esi,%edx
f0103ef8:	89 f8                	mov    %edi,%eax
f0103efa:	f7 f5                	div    %ebp
f0103efc:	89 d6                	mov    %edx,%esi
f0103efe:	89 c7                	mov    %eax,%edi
f0103f00:	f7 64 24 04          	mull   0x4(%esp)
f0103f04:	39 d6                	cmp    %edx,%esi
f0103f06:	72 30                	jb     f0103f38 <__udivdi3+0x138>
f0103f08:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103f0c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0103f10:	d3 e5                	shl    %cl,%ebp
f0103f12:	39 c5                	cmp    %eax,%ebp
f0103f14:	73 04                	jae    f0103f1a <__udivdi3+0x11a>
f0103f16:	39 d6                	cmp    %edx,%esi
f0103f18:	74 1e                	je     f0103f38 <__udivdi3+0x138>
f0103f1a:	89 f8                	mov    %edi,%eax
f0103f1c:	31 d2                	xor    %edx,%edx
f0103f1e:	e9 69 ff ff ff       	jmp    f0103e8c <__udivdi3+0x8c>
f0103f23:	90                   	nop
f0103f24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f28:	31 d2                	xor    %edx,%edx
f0103f2a:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f2f:	e9 58 ff ff ff       	jmp    f0103e8c <__udivdi3+0x8c>
f0103f34:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f38:	8d 47 ff             	lea    -0x1(%edi),%eax
f0103f3b:	31 d2                	xor    %edx,%edx
f0103f3d:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f41:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f45:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f49:	83 c4 1c             	add    $0x1c,%esp
f0103f4c:	c3                   	ret    
f0103f4d:	66 90                	xchg   %ax,%ax
f0103f4f:	90                   	nop

f0103f50 <__umoddi3>:
f0103f50:	83 ec 2c             	sub    $0x2c,%esp
f0103f53:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0103f57:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0103f5b:	89 74 24 20          	mov    %esi,0x20(%esp)
f0103f5f:	8b 74 24 38          	mov    0x38(%esp),%esi
f0103f63:	89 7c 24 24          	mov    %edi,0x24(%esp)
f0103f67:	8b 7c 24 34          	mov    0x34(%esp),%edi
f0103f6b:	85 c0                	test   %eax,%eax
f0103f6d:	89 c2                	mov    %eax,%edx
f0103f6f:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f0103f73:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0103f77:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103f7b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103f7f:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103f83:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103f87:	75 1f                	jne    f0103fa8 <__umoddi3+0x58>
f0103f89:	39 fe                	cmp    %edi,%esi
f0103f8b:	76 63                	jbe    f0103ff0 <__umoddi3+0xa0>
f0103f8d:	89 c8                	mov    %ecx,%eax
f0103f8f:	89 fa                	mov    %edi,%edx
f0103f91:	f7 f6                	div    %esi
f0103f93:	89 d0                	mov    %edx,%eax
f0103f95:	31 d2                	xor    %edx,%edx
f0103f97:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103f9b:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103f9f:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103fa3:	83 c4 2c             	add    $0x2c,%esp
f0103fa6:	c3                   	ret    
f0103fa7:	90                   	nop
f0103fa8:	39 f8                	cmp    %edi,%eax
f0103faa:	77 64                	ja     f0104010 <__umoddi3+0xc0>
f0103fac:	0f bd e8             	bsr    %eax,%ebp
f0103faf:	83 f5 1f             	xor    $0x1f,%ebp
f0103fb2:	75 74                	jne    f0104028 <__umoddi3+0xd8>
f0103fb4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103fb8:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f0103fbc:	0f 87 0e 01 00 00    	ja     f01040d0 <__umoddi3+0x180>
f0103fc2:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0103fc6:	29 f1                	sub    %esi,%ecx
f0103fc8:	19 c7                	sbb    %eax,%edi
f0103fca:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0103fce:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0103fd2:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103fd6:	8b 54 24 18          	mov    0x18(%esp),%edx
f0103fda:	8b 74 24 20          	mov    0x20(%esp),%esi
f0103fde:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0103fe2:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0103fe6:	83 c4 2c             	add    $0x2c,%esp
f0103fe9:	c3                   	ret    
f0103fea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ff0:	85 f6                	test   %esi,%esi
f0103ff2:	89 f5                	mov    %esi,%ebp
f0103ff4:	75 0b                	jne    f0104001 <__umoddi3+0xb1>
f0103ff6:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ffb:	31 d2                	xor    %edx,%edx
f0103ffd:	f7 f6                	div    %esi
f0103fff:	89 c5                	mov    %eax,%ebp
f0104001:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104005:	31 d2                	xor    %edx,%edx
f0104007:	f7 f5                	div    %ebp
f0104009:	89 c8                	mov    %ecx,%eax
f010400b:	f7 f5                	div    %ebp
f010400d:	eb 84                	jmp    f0103f93 <__umoddi3+0x43>
f010400f:	90                   	nop
f0104010:	89 c8                	mov    %ecx,%eax
f0104012:	89 fa                	mov    %edi,%edx
f0104014:	8b 74 24 20          	mov    0x20(%esp),%esi
f0104018:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010401c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0104020:	83 c4 2c             	add    $0x2c,%esp
f0104023:	c3                   	ret    
f0104024:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104028:	8b 44 24 10          	mov    0x10(%esp),%eax
f010402c:	be 20 00 00 00       	mov    $0x20,%esi
f0104031:	89 e9                	mov    %ebp,%ecx
f0104033:	29 ee                	sub    %ebp,%esi
f0104035:	d3 e2                	shl    %cl,%edx
f0104037:	89 f1                	mov    %esi,%ecx
f0104039:	d3 e8                	shr    %cl,%eax
f010403b:	89 e9                	mov    %ebp,%ecx
f010403d:	09 d0                	or     %edx,%eax
f010403f:	89 fa                	mov    %edi,%edx
f0104041:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104045:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104049:	d3 e0                	shl    %cl,%eax
f010404b:	89 f1                	mov    %esi,%ecx
f010404d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104051:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0104055:	d3 ea                	shr    %cl,%edx
f0104057:	89 e9                	mov    %ebp,%ecx
f0104059:	d3 e7                	shl    %cl,%edi
f010405b:	89 f1                	mov    %esi,%ecx
f010405d:	d3 e8                	shr    %cl,%eax
f010405f:	89 e9                	mov    %ebp,%ecx
f0104061:	09 f8                	or     %edi,%eax
f0104063:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104067:	f7 74 24 0c          	divl   0xc(%esp)
f010406b:	d3 e7                	shl    %cl,%edi
f010406d:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0104071:	89 d7                	mov    %edx,%edi
f0104073:	f7 64 24 10          	mull   0x10(%esp)
f0104077:	39 d7                	cmp    %edx,%edi
f0104079:	89 c1                	mov    %eax,%ecx
f010407b:	89 54 24 14          	mov    %edx,0x14(%esp)
f010407f:	72 3b                	jb     f01040bc <__umoddi3+0x16c>
f0104081:	39 44 24 18          	cmp    %eax,0x18(%esp)
f0104085:	72 31                	jb     f01040b8 <__umoddi3+0x168>
f0104087:	8b 44 24 18          	mov    0x18(%esp),%eax
f010408b:	29 c8                	sub    %ecx,%eax
f010408d:	19 d7                	sbb    %edx,%edi
f010408f:	89 e9                	mov    %ebp,%ecx
f0104091:	89 fa                	mov    %edi,%edx
f0104093:	d3 e8                	shr    %cl,%eax
f0104095:	89 f1                	mov    %esi,%ecx
f0104097:	d3 e2                	shl    %cl,%edx
f0104099:	89 e9                	mov    %ebp,%ecx
f010409b:	09 d0                	or     %edx,%eax
f010409d:	89 fa                	mov    %edi,%edx
f010409f:	d3 ea                	shr    %cl,%edx
f01040a1:	8b 74 24 20          	mov    0x20(%esp),%esi
f01040a5:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01040a9:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f01040ad:	83 c4 2c             	add    $0x2c,%esp
f01040b0:	c3                   	ret    
f01040b1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040b8:	39 d7                	cmp    %edx,%edi
f01040ba:	75 cb                	jne    f0104087 <__umoddi3+0x137>
f01040bc:	8b 54 24 14          	mov    0x14(%esp),%edx
f01040c0:	89 c1                	mov    %eax,%ecx
f01040c2:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f01040c6:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f01040ca:	eb bb                	jmp    f0104087 <__umoddi3+0x137>
f01040cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040d0:	3b 44 24 18          	cmp    0x18(%esp),%eax
f01040d4:	0f 82 e8 fe ff ff    	jb     f0103fc2 <__umoddi3+0x72>
f01040da:	e9 f3 fe ff ff       	jmp    f0103fd2 <__umoddi3+0x82>
