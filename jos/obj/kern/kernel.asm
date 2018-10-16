
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
f010000b:	e4                   	.byte 0xe4

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
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

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
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 20 19 10 f0       	push   $0xf0101920
f0100050:	e8 ff 08 00 00       	call   f0100954 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(0, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 00                	push   $0x0
f0100076:	e8 0a 07 00 00       	call   f0100785 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 3c 19 10 f0       	push   $0xf010193c
f0100087:	e8 c8 08 00 00       	call   f0100954 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 db 13 00 00       	call   f010148c <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 9d 04 00 00       	call   f0100553 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 57 19 10 f0       	push   $0xf0101957
f01000c3:	e8 8c 08 00 00       	call   f0100954 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 06 07 00 00       	call   f01007e7 <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 72 19 10 f0       	push   $0xf0101972
f0100110:	e8 3f 08 00 00       	call   f0100954 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 0f 08 00 00       	call   f010092e <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f0100126:	e8 29 08 00 00       	call   f0100954 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 af 06 00 00       	call   f01007e7 <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 8a 19 10 f0       	push   $0xf010198a
f0100152:	e8 fd 07 00 00       	call   f0100954 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 cb 07 00 00       	call   f010092e <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ae 19 10 f0 	movl   $0xf01019ae,(%esp)
f010016a:	e8 e5 07 00 00       	call   f0100954 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f8 00 00 00    	je     f01002df <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01001e7:	a8 20                	test   $0x20,%al
f01001e9:	0f 85 f6 00 00 00    	jne    f01002e5 <kbd_proc_data+0x10c>
f01001ef:	ba 60 00 00 00       	mov    $0x60,%edx
f01001f4:	ec                   	in     (%dx),%al
f01001f5:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001f7:	3c e0                	cmp    $0xe0,%al
f01001f9:	75 0d                	jne    f0100208 <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001fb:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100202:	b8 00 00 00 00       	mov    $0x0,%eax
f0100207:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100208:	55                   	push   %ebp
f0100209:	89 e5                	mov    %esp,%ebp
f010020b:	53                   	push   %ebx
f010020c:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010020f:	84 c0                	test   %al,%al
f0100211:	79 36                	jns    f0100249 <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100213:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100219:	89 cb                	mov    %ecx,%ebx
f010021b:	83 e3 40             	and    $0x40,%ebx
f010021e:	83 e0 7f             	and    $0x7f,%eax
f0100221:	85 db                	test   %ebx,%ebx
f0100223:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100226:	0f b6 d2             	movzbl %dl,%edx
f0100229:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100230:	83 c8 40             	or     $0x40,%eax
f0100233:	0f b6 c0             	movzbl %al,%eax
f0100236:	f7 d0                	not    %eax
f0100238:	21 c8                	and    %ecx,%eax
f010023a:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f010023f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100244:	e9 a4 00 00 00       	jmp    f01002ed <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f0100249:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010024f:	f6 c1 40             	test   $0x40,%cl
f0100252:	74 0e                	je     f0100262 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100254:	83 c8 80             	or     $0xffffff80,%eax
f0100257:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100259:	83 e1 bf             	and    $0xffffffbf,%ecx
f010025c:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100262:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f0100265:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f010026c:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f0100272:	0f b6 8a 00 1a 10 f0 	movzbl -0xfefe600(%edx),%ecx
f0100279:	31 c8                	xor    %ecx,%eax
f010027b:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100280:	89 c1                	mov    %eax,%ecx
f0100282:	83 e1 03             	and    $0x3,%ecx
f0100285:	8b 0c 8d e0 19 10 f0 	mov    -0xfefe620(,%ecx,4),%ecx
f010028c:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100290:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100293:	a8 08                	test   $0x8,%al
f0100295:	74 1b                	je     f01002b2 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f0100297:	89 da                	mov    %ebx,%edx
f0100299:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010029c:	83 f9 19             	cmp    $0x19,%ecx
f010029f:	77 05                	ja     f01002a6 <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f01002a1:	83 eb 20             	sub    $0x20,%ebx
f01002a4:	eb 0c                	jmp    f01002b2 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01002a6:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a9:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002ac:	83 fa 19             	cmp    $0x19,%edx
f01002af:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002b2:	f7 d0                	not    %eax
f01002b4:	a8 06                	test   $0x6,%al
f01002b6:	75 33                	jne    f01002eb <kbd_proc_data+0x112>
f01002b8:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002be:	75 2b                	jne    f01002eb <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f01002c0:	83 ec 0c             	sub    $0xc,%esp
f01002c3:	68 a4 19 10 f0       	push   $0xf01019a4
f01002c8:	e8 87 06 00 00       	call   f0100954 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002cd:	ba 92 00 00 00       	mov    $0x92,%edx
f01002d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002d7:	ee                   	out    %al,(%dx)
f01002d8:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002db:	89 d8                	mov    %ebx,%eax
f01002dd:	eb 0e                	jmp    f01002ed <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002e4:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01002e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002ea:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002eb:	89 d8                	mov    %ebx,%eax
}
f01002ed:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002f0:	c9                   	leave  
f01002f1:	c3                   	ret    

f01002f2 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002f2:	55                   	push   %ebp
f01002f3:	89 e5                	mov    %esp,%ebp
f01002f5:	57                   	push   %edi
f01002f6:	56                   	push   %esi
f01002f7:	53                   	push   %ebx
f01002f8:	83 ec 1c             	sub    $0x1c,%esp
f01002fb:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002fd:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100302:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100307:	b9 84 00 00 00       	mov    $0x84,%ecx
f010030c:	eb 09                	jmp    f0100317 <cons_putc+0x25>
f010030e:	89 ca                	mov    %ecx,%edx
f0100310:	ec                   	in     (%dx),%al
f0100311:	ec                   	in     (%dx),%al
f0100312:	ec                   	in     (%dx),%al
f0100313:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100314:	83 c3 01             	add    $0x1,%ebx
f0100317:	89 f2                	mov    %esi,%edx
f0100319:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010031a:	a8 20                	test   $0x20,%al
f010031c:	75 08                	jne    f0100326 <cons_putc+0x34>
f010031e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100324:	7e e8                	jle    f010030e <cons_putc+0x1c>
f0100326:	89 f8                	mov    %edi,%eax
f0100328:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010032b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100330:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100331:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100336:	be 79 03 00 00       	mov    $0x379,%esi
f010033b:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100340:	eb 09                	jmp    f010034b <cons_putc+0x59>
f0100342:	89 ca                	mov    %ecx,%edx
f0100344:	ec                   	in     (%dx),%al
f0100345:	ec                   	in     (%dx),%al
f0100346:	ec                   	in     (%dx),%al
f0100347:	ec                   	in     (%dx),%al
f0100348:	83 c3 01             	add    $0x1,%ebx
f010034b:	89 f2                	mov    %esi,%edx
f010034d:	ec                   	in     (%dx),%al
f010034e:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100354:	7f 04                	jg     f010035a <cons_putc+0x68>
f0100356:	84 c0                	test   %al,%al
f0100358:	79 e8                	jns    f0100342 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010035a:	ba 78 03 00 00       	mov    $0x378,%edx
f010035f:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100363:	ee                   	out    %al,(%dx)
f0100364:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100369:	b8 0d 00 00 00       	mov    $0xd,%eax
f010036e:	ee                   	out    %al,(%dx)
f010036f:	b8 08 00 00 00       	mov    $0x8,%eax
f0100374:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100375:	89 fa                	mov    %edi,%edx
f0100377:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010037d:	89 f8                	mov    %edi,%eax
f010037f:	80 cc 07             	or     $0x7,%ah
f0100382:	85 d2                	test   %edx,%edx
f0100384:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100387:	89 f8                	mov    %edi,%eax
f0100389:	0f b6 c0             	movzbl %al,%eax
f010038c:	83 f8 09             	cmp    $0x9,%eax
f010038f:	74 74                	je     f0100405 <cons_putc+0x113>
f0100391:	83 f8 09             	cmp    $0x9,%eax
f0100394:	7f 0a                	jg     f01003a0 <cons_putc+0xae>
f0100396:	83 f8 08             	cmp    $0x8,%eax
f0100399:	74 14                	je     f01003af <cons_putc+0xbd>
f010039b:	e9 99 00 00 00       	jmp    f0100439 <cons_putc+0x147>
f01003a0:	83 f8 0a             	cmp    $0xa,%eax
f01003a3:	74 3a                	je     f01003df <cons_putc+0xed>
f01003a5:	83 f8 0d             	cmp    $0xd,%eax
f01003a8:	74 3d                	je     f01003e7 <cons_putc+0xf5>
f01003aa:	e9 8a 00 00 00       	jmp    f0100439 <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003af:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003b6:	66 85 c0             	test   %ax,%ax
f01003b9:	0f 84 e6 00 00 00    	je     f01004a5 <cons_putc+0x1b3>
			crt_pos--;
f01003bf:	83 e8 01             	sub    $0x1,%eax
f01003c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003c8:	0f b7 c0             	movzwl %ax,%eax
f01003cb:	66 81 e7 00 ff       	and    $0xff00,%di
f01003d0:	83 cf 20             	or     $0x20,%edi
f01003d3:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003d9:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003dd:	eb 78                	jmp    f0100457 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003df:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003e7:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003f4:	c1 e8 16             	shr    $0x16,%eax
f01003f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003fa:	c1 e0 04             	shl    $0x4,%eax
f01003fd:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100403:	eb 52                	jmp    f0100457 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f0100405:	b8 20 00 00 00       	mov    $0x20,%eax
f010040a:	e8 e3 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010040f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100414:	e8 d9 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100419:	b8 20 00 00 00       	mov    $0x20,%eax
f010041e:	e8 cf fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f0100423:	b8 20 00 00 00       	mov    $0x20,%eax
f0100428:	e8 c5 fe ff ff       	call   f01002f2 <cons_putc>
		cons_putc(' ');
f010042d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100432:	e8 bb fe ff ff       	call   f01002f2 <cons_putc>
f0100437:	eb 1e                	jmp    f0100457 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100439:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100440:	8d 50 01             	lea    0x1(%eax),%edx
f0100443:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010044a:	0f b7 c0             	movzwl %ax,%eax
f010044d:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100453:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100457:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010045e:	cf 07 
f0100460:	76 43                	jbe    f01004a5 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100462:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100467:	83 ec 04             	sub    $0x4,%esp
f010046a:	68 00 0f 00 00       	push   $0xf00
f010046f:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100475:	52                   	push   %edx
f0100476:	50                   	push   %eax
f0100477:	e8 5d 10 00 00       	call   f01014d9 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010047c:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100482:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100488:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010048e:	83 c4 10             	add    $0x10,%esp
f0100491:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100496:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100499:	39 d0                	cmp    %edx,%eax
f010049b:	75 f4                	jne    f0100491 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010049d:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004a4:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004a5:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004ab:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004b0:	89 ca                	mov    %ecx,%edx
f01004b2:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004b3:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ba:	8d 71 01             	lea    0x1(%ecx),%esi
f01004bd:	89 d8                	mov    %ebx,%eax
f01004bf:	66 c1 e8 08          	shr    $0x8,%ax
f01004c3:	89 f2                	mov    %esi,%edx
f01004c5:	ee                   	out    %al,(%dx)
f01004c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004cb:	89 ca                	mov    %ecx,%edx
f01004cd:	ee                   	out    %al,(%dx)
f01004ce:	89 d8                	mov    %ebx,%eax
f01004d0:	89 f2                	mov    %esi,%edx
f01004d2:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004d3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5e                   	pop    %esi
f01004d8:	5f                   	pop    %edi
f01004d9:	5d                   	pop    %ebp
f01004da:	c3                   	ret    

f01004db <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004db:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004e2:	74 11                	je     f01004f5 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004ea:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004ef:	e8 a2 fc ff ff       	call   f0100196 <cons_intr>
}
f01004f4:	c9                   	leave  
f01004f5:	f3 c3                	repz ret 

f01004f7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004f7:	55                   	push   %ebp
f01004f8:	89 e5                	mov    %esp,%ebp
f01004fa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004fd:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f0100502:	e8 8f fc ff ff       	call   f0100196 <cons_intr>
}
f0100507:	c9                   	leave  
f0100508:	c3                   	ret    

f0100509 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100509:	55                   	push   %ebp
f010050a:	89 e5                	mov    %esp,%ebp
f010050c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010050f:	e8 c7 ff ff ff       	call   f01004db <serial_intr>
	kbd_intr();
f0100514:	e8 de ff ff ff       	call   f01004f7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100519:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010051e:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100524:	74 26                	je     f010054c <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100526:	8d 50 01             	lea    0x1(%eax),%edx
f0100529:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010052f:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100536:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100538:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010053e:	75 11                	jne    f0100551 <cons_getc+0x48>
			cons.rpos = 0;
f0100540:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100547:	00 00 00 
f010054a:	eb 05                	jmp    f0100551 <cons_getc+0x48>
		return c;
	}
	return 0;
f010054c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100551:	c9                   	leave  
f0100552:	c3                   	ret    

f0100553 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100553:	55                   	push   %ebp
f0100554:	89 e5                	mov    %esp,%ebp
f0100556:	57                   	push   %edi
f0100557:	56                   	push   %esi
f0100558:	53                   	push   %ebx
f0100559:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055c:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100563:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056a:	5a a5 
	if (*cp != 0xA55A) {
f010056c:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100573:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100577:	74 11                	je     f010058a <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100579:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100580:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100583:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100588:	eb 16                	jmp    f01005a0 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058a:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100591:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f0100598:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059b:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a0:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f01005a6:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ab:	89 fa                	mov    %edi,%edx
f01005ad:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ae:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b1:	89 da                	mov    %ebx,%edx
f01005b3:	ec                   	in     (%dx),%al
f01005b4:	0f b6 c8             	movzbl %al,%ecx
f01005b7:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ba:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005bf:	89 fa                	mov    %edi,%edx
f01005c1:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c5:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005cb:	0f b6 c0             	movzbl %al,%eax
f01005ce:	09 c8                	or     %ecx,%eax
f01005d0:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d6:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005db:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e0:	89 f2                	mov    %esi,%edx
f01005e2:	ee                   	out    %al,(%dx)
f01005e3:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005e8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005f3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f8:	89 da                	mov    %ebx,%edx
f01005fa:	ee                   	out    %al,(%dx)
f01005fb:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100600:	b8 00 00 00 00       	mov    $0x0,%eax
f0100605:	ee                   	out    %al,(%dx)
f0100606:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010060b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100610:	ee                   	out    %al,(%dx)
f0100611:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100616:	b8 00 00 00 00       	mov    $0x0,%eax
f010061b:	ee                   	out    %al,(%dx)
f010061c:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100621:	b8 01 00 00 00       	mov    $0x1,%eax
f0100626:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100627:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062f:	3c ff                	cmp    $0xff,%al
f0100631:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f0100638:	89 f2                	mov    %esi,%edx
f010063a:	ec                   	in     (%dx),%al
f010063b:	89 da                	mov    %ebx,%edx
f010063d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063e:	80 f9 ff             	cmp    $0xff,%cl
f0100641:	75 10                	jne    f0100653 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100643:	83 ec 0c             	sub    $0xc,%esp
f0100646:	68 b0 19 10 f0       	push   $0xf01019b0
f010064b:	e8 04 03 00 00       	call   f0100954 <cprintf>
f0100650:	83 c4 10             	add    $0x10,%esp
}
f0100653:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100656:	5b                   	pop    %ebx
f0100657:	5e                   	pop    %esi
f0100658:	5f                   	pop    %edi
f0100659:	5d                   	pop    %ebp
f010065a:	c3                   	ret    

f010065b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065b:	55                   	push   %ebp
f010065c:	89 e5                	mov    %esp,%ebp
f010065e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100661:	8b 45 08             	mov    0x8(%ebp),%eax
f0100664:	e8 89 fc ff ff       	call   f01002f2 <cons_putc>
}
f0100669:	c9                   	leave  
f010066a:	c3                   	ret    

f010066b <getchar>:

int
getchar(void)
{
f010066b:	55                   	push   %ebp
f010066c:	89 e5                	mov    %esp,%ebp
f010066e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100671:	e8 93 fe ff ff       	call   f0100509 <cons_getc>
f0100676:	85 c0                	test   %eax,%eax
f0100678:	74 f7                	je     f0100671 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010067a:	c9                   	leave  
f010067b:	c3                   	ret    

f010067c <iscons>:

int
iscons(int fdnum)
{
f010067c:	55                   	push   %ebp
f010067d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100684:	5d                   	pop    %ebp
f0100685:	c3                   	ret    

f0100686 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010068c:	68 00 1c 10 f0       	push   $0xf0101c00
f0100691:	68 1e 1c 10 f0       	push   $0xf0101c1e
f0100696:	68 23 1c 10 f0       	push   $0xf0101c23
f010069b:	e8 b4 02 00 00       	call   f0100954 <cprintf>
f01006a0:	83 c4 0c             	add    $0xc,%esp
f01006a3:	68 cc 1c 10 f0       	push   $0xf0101ccc
f01006a8:	68 2c 1c 10 f0       	push   $0xf0101c2c
f01006ad:	68 23 1c 10 f0       	push   $0xf0101c23
f01006b2:	e8 9d 02 00 00       	call   f0100954 <cprintf>
f01006b7:	83 c4 0c             	add    $0xc,%esp
f01006ba:	68 35 1c 10 f0       	push   $0xf0101c35
f01006bf:	68 49 1c 10 f0       	push   $0xf0101c49
f01006c4:	68 23 1c 10 f0       	push   $0xf0101c23
f01006c9:	e8 86 02 00 00       	call   f0100954 <cprintf>
	return 0;
}
f01006ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01006d3:	c9                   	leave  
f01006d4:	c3                   	ret    

f01006d5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006d5:	55                   	push   %ebp
f01006d6:	89 e5                	mov    %esp,%ebp
f01006d8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006db:	68 53 1c 10 f0       	push   $0xf0101c53
f01006e0:	e8 6f 02 00 00       	call   f0100954 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006e5:	83 c4 08             	add    $0x8,%esp
f01006e8:	68 0c 00 10 00       	push   $0x10000c
f01006ed:	68 f4 1c 10 f0       	push   $0xf0101cf4
f01006f2:	e8 5d 02 00 00       	call   f0100954 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006f7:	83 c4 0c             	add    $0xc,%esp
f01006fa:	68 0c 00 10 00       	push   $0x10000c
f01006ff:	68 0c 00 10 f0       	push   $0xf010000c
f0100704:	68 1c 1d 10 f0       	push   $0xf0101d1c
f0100709:	e8 46 02 00 00       	call   f0100954 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010070e:	83 c4 0c             	add    $0xc,%esp
f0100711:	68 11 19 10 00       	push   $0x101911
f0100716:	68 11 19 10 f0       	push   $0xf0101911
f010071b:	68 40 1d 10 f0       	push   $0xf0101d40
f0100720:	e8 2f 02 00 00       	call   f0100954 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100725:	83 c4 0c             	add    $0xc,%esp
f0100728:	68 00 23 11 00       	push   $0x112300
f010072d:	68 00 23 11 f0       	push   $0xf0112300
f0100732:	68 64 1d 10 f0       	push   $0xf0101d64
f0100737:	e8 18 02 00 00       	call   f0100954 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010073c:	83 c4 0c             	add    $0xc,%esp
f010073f:	68 44 29 11 00       	push   $0x112944
f0100744:	68 44 29 11 f0       	push   $0xf0112944
f0100749:	68 88 1d 10 f0       	push   $0xf0101d88
f010074e:	e8 01 02 00 00       	call   f0100954 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100753:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f0100758:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010075d:	83 c4 08             	add    $0x8,%esp
f0100760:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100765:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010076b:	85 c0                	test   %eax,%eax
f010076d:	0f 48 c2             	cmovs  %edx,%eax
f0100770:	c1 f8 0a             	sar    $0xa,%eax
f0100773:	50                   	push   %eax
f0100774:	68 ac 1d 10 f0       	push   $0xf0101dac
f0100779:	e8 d6 01 00 00       	call   f0100954 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
f0100788:	57                   	push   %edi
f0100789:	56                   	push   %esi
f010078a:	53                   	push   %ebx
f010078b:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010078e:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp, eip, args[5];
	struct Eipdebuginfo eip_dbinfo;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100790:	68 6c 1c 10 f0       	push   $0xf0101c6c
f0100795:	e8 ba 01 00 00       	call   f0100954 <cprintf>
f010079a:	83 c4 10             	add    $0x10,%esp

	do {
		eip = *(((uint32_t *) ebp) + 1);

		if(!debuginfo_eip(eip, &eip_dbinfo)) {
f010079d:	8d 7d d0             	lea    -0x30(%ebp),%edi
	struct Eipdebuginfo eip_dbinfo;
	ebp = read_ebp();
	cprintf("Stack backtrace:\n");

	do {
		eip = *(((uint32_t *) ebp) + 1);
f01007a0:	8b 73 04             	mov    0x4(%ebx),%esi

		if(!debuginfo_eip(eip, &eip_dbinfo)) {
f01007a3:	83 ec 08             	sub    $0x8,%esp
f01007a6:	57                   	push   %edi
f01007a7:	56                   	push   %esi
f01007a8:	e8 b1 02 00 00       	call   f0100a5e <debuginfo_eip>
f01007ad:	83 c4 10             	add    $0x10,%esp
f01007b0:	85 c0                	test   %eax,%eax
f01007b2:	75 20                	jne    f01007d4 <mon_backtrace+0x4f>
			cprintf("%s:%d %.*s+%d\n", eip_dbinfo.eip_file, eip_dbinfo.eip_line, eip_dbinfo.eip_fn_namelen, eip_dbinfo.eip_fn_name, eip - eip_dbinfo.eip_fn_addr);
f01007b4:	83 ec 08             	sub    $0x8,%esp
f01007b7:	2b 75 e0             	sub    -0x20(%ebp),%esi
f01007ba:	56                   	push   %esi
f01007bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01007be:	ff 75 dc             	pushl  -0x24(%ebp)
f01007c1:	ff 75 d4             	pushl  -0x2c(%ebp)
f01007c4:	ff 75 d0             	pushl  -0x30(%ebp)
f01007c7:	68 7e 1c 10 f0       	push   $0xf0101c7e
f01007cc:	e8 83 01 00 00       	call   f0100954 <cprintf>
f01007d1:	83 c4 20             	add    $0x20,%esp
		}

	ebp = *((uint32_t *) ebp);
f01007d4:	8b 1b                	mov    (%ebx),%ebx
	} while(ebp);
f01007d6:	85 db                	test   %ebx,%ebx
f01007d8:	75 c6                	jne    f01007a0 <mon_backtrace+0x1b>
	return 0;
}
f01007da:	b8 00 00 00 00       	mov    $0x0,%eax
f01007df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007e2:	5b                   	pop    %ebx
f01007e3:	5e                   	pop    %esi
f01007e4:	5f                   	pop    %edi
f01007e5:	5d                   	pop    %ebp
f01007e6:	c3                   	ret    

f01007e7 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007e7:	55                   	push   %ebp
f01007e8:	89 e5                	mov    %esp,%ebp
f01007ea:	57                   	push   %edi
f01007eb:	56                   	push   %esi
f01007ec:	53                   	push   %ebx
f01007ed:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007f0:	68 d8 1d 10 f0       	push   $0xf0101dd8
f01007f5:	e8 5a 01 00 00       	call   f0100954 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007fa:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f0100801:	e8 4e 01 00 00       	call   f0100954 <cprintf>
f0100806:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100809:	83 ec 0c             	sub    $0xc,%esp
f010080c:	68 8d 1c 10 f0       	push   $0xf0101c8d
f0100811:	e8 1f 0a 00 00       	call   f0101235 <readline>
f0100816:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100818:	83 c4 10             	add    $0x10,%esp
f010081b:	85 c0                	test   %eax,%eax
f010081d:	74 ea                	je     f0100809 <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010081f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100826:	be 00 00 00 00       	mov    $0x0,%esi
f010082b:	eb 0a                	jmp    f0100837 <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010082d:	c6 03 00             	movb   $0x0,(%ebx)
f0100830:	89 f7                	mov    %esi,%edi
f0100832:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100835:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100837:	0f b6 03             	movzbl (%ebx),%eax
f010083a:	84 c0                	test   %al,%al
f010083c:	74 63                	je     f01008a1 <monitor+0xba>
f010083e:	83 ec 08             	sub    $0x8,%esp
f0100841:	0f be c0             	movsbl %al,%eax
f0100844:	50                   	push   %eax
f0100845:	68 91 1c 10 f0       	push   $0xf0101c91
f010084a:	e8 00 0c 00 00       	call   f010144f <strchr>
f010084f:	83 c4 10             	add    $0x10,%esp
f0100852:	85 c0                	test   %eax,%eax
f0100854:	75 d7                	jne    f010082d <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f0100856:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100859:	74 46                	je     f01008a1 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010085b:	83 fe 0f             	cmp    $0xf,%esi
f010085e:	75 14                	jne    f0100874 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100860:	83 ec 08             	sub    $0x8,%esp
f0100863:	6a 10                	push   $0x10
f0100865:	68 96 1c 10 f0       	push   $0xf0101c96
f010086a:	e8 e5 00 00 00       	call   f0100954 <cprintf>
f010086f:	83 c4 10             	add    $0x10,%esp
f0100872:	eb 95                	jmp    f0100809 <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100874:	8d 7e 01             	lea    0x1(%esi),%edi
f0100877:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f010087b:	eb 03                	jmp    f0100880 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010087d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100880:	0f b6 03             	movzbl (%ebx),%eax
f0100883:	84 c0                	test   %al,%al
f0100885:	74 ae                	je     f0100835 <monitor+0x4e>
f0100887:	83 ec 08             	sub    $0x8,%esp
f010088a:	0f be c0             	movsbl %al,%eax
f010088d:	50                   	push   %eax
f010088e:	68 91 1c 10 f0       	push   $0xf0101c91
f0100893:	e8 b7 0b 00 00       	call   f010144f <strchr>
f0100898:	83 c4 10             	add    $0x10,%esp
f010089b:	85 c0                	test   %eax,%eax
f010089d:	74 de                	je     f010087d <monitor+0x96>
f010089f:	eb 94                	jmp    f0100835 <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f01008a1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a9:	85 f6                	test   %esi,%esi
f01008ab:	0f 84 58 ff ff ff    	je     f0100809 <monitor+0x22>
f01008b1:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008b6:	83 ec 08             	sub    $0x8,%esp
f01008b9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008bc:	ff 34 85 40 1e 10 f0 	pushl  -0xfefe1c0(,%eax,4)
f01008c3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008c6:	e8 26 0b 00 00       	call   f01013f1 <strcmp>
f01008cb:	83 c4 10             	add    $0x10,%esp
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	75 21                	jne    f01008f3 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008d2:	83 ec 04             	sub    $0x4,%esp
f01008d5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008d8:	ff 75 08             	pushl  0x8(%ebp)
f01008db:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008de:	52                   	push   %edx
f01008df:	56                   	push   %esi
f01008e0:	ff 14 85 48 1e 10 f0 	call   *-0xfefe1b8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008e7:	83 c4 10             	add    $0x10,%esp
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	78 25                	js     f0100913 <monitor+0x12c>
f01008ee:	e9 16 ff ff ff       	jmp    f0100809 <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008f3:	83 c3 01             	add    $0x1,%ebx
f01008f6:	83 fb 03             	cmp    $0x3,%ebx
f01008f9:	75 bb                	jne    f01008b6 <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008fb:	83 ec 08             	sub    $0x8,%esp
f01008fe:	ff 75 a8             	pushl  -0x58(%ebp)
f0100901:	68 b3 1c 10 f0       	push   $0xf0101cb3
f0100906:	e8 49 00 00 00       	call   f0100954 <cprintf>
f010090b:	83 c4 10             	add    $0x10,%esp
f010090e:	e9 f6 fe ff ff       	jmp    f0100809 <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100913:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100916:	5b                   	pop    %ebx
f0100917:	5e                   	pop    %esi
f0100918:	5f                   	pop    %edi
f0100919:	5d                   	pop    %ebp
f010091a:	c3                   	ret    

f010091b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010091b:	55                   	push   %ebp
f010091c:	89 e5                	mov    %esp,%ebp
f010091e:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100921:	ff 75 08             	pushl  0x8(%ebp)
f0100924:	e8 32 fd ff ff       	call   f010065b <cputchar>
	*cnt++;
}
f0100929:	83 c4 10             	add    $0x10,%esp
f010092c:	c9                   	leave  
f010092d:	c3                   	ret    

f010092e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010092e:	55                   	push   %ebp
f010092f:	89 e5                	mov    %esp,%ebp
f0100931:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100934:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010093b:	ff 75 0c             	pushl  0xc(%ebp)
f010093e:	ff 75 08             	pushl  0x8(%ebp)
f0100941:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100944:	50                   	push   %eax
f0100945:	68 1b 09 10 f0       	push   $0xf010091b
f010094a:	e8 18 04 00 00       	call   f0100d67 <vprintfmt>
	return cnt;
}
f010094f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100952:	c9                   	leave  
f0100953:	c3                   	ret    

f0100954 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100954:	55                   	push   %ebp
f0100955:	89 e5                	mov    %esp,%ebp
f0100957:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010095a:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010095d:	50                   	push   %eax
f010095e:	ff 75 08             	pushl  0x8(%ebp)
f0100961:	e8 c8 ff ff ff       	call   f010092e <vcprintf>
	va_end(ap);

	return cnt;
}
f0100966:	c9                   	leave  
f0100967:	c3                   	ret    

f0100968 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100968:	55                   	push   %ebp
f0100969:	89 e5                	mov    %esp,%ebp
f010096b:	57                   	push   %edi
f010096c:	56                   	push   %esi
f010096d:	53                   	push   %ebx
f010096e:	83 ec 14             	sub    $0x14,%esp
f0100971:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100974:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100977:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010097a:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010097d:	8b 1a                	mov    (%edx),%ebx
f010097f:	8b 01                	mov    (%ecx),%eax
f0100981:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100984:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f010098b:	eb 7f                	jmp    f0100a0c <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f010098d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100990:	01 d8                	add    %ebx,%eax
f0100992:	89 c6                	mov    %eax,%esi
f0100994:	c1 ee 1f             	shr    $0x1f,%esi
f0100997:	01 c6                	add    %eax,%esi
f0100999:	d1 fe                	sar    %esi
f010099b:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010099e:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009a1:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01009a4:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009a6:	eb 03                	jmp    f01009ab <stab_binsearch+0x43>
			m--;
f01009a8:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009ab:	39 c3                	cmp    %eax,%ebx
f01009ad:	7f 0d                	jg     f01009bc <stab_binsearch+0x54>
f01009af:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01009b3:	83 ea 0c             	sub    $0xc,%edx
f01009b6:	39 f9                	cmp    %edi,%ecx
f01009b8:	75 ee                	jne    f01009a8 <stab_binsearch+0x40>
f01009ba:	eb 05                	jmp    f01009c1 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01009bc:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01009bf:	eb 4b                	jmp    f0100a0c <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01009c1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01009c4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009c7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01009cb:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009ce:	76 11                	jbe    f01009e1 <stab_binsearch+0x79>
			*region_left = m;
f01009d0:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009d3:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01009d5:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009d8:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009df:	eb 2b                	jmp    f0100a0c <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009e1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009e4:	73 14                	jae    f01009fa <stab_binsearch+0x92>
			*region_right = m - 1;
f01009e6:	83 e8 01             	sub    $0x1,%eax
f01009e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01009ef:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009f1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01009f8:	eb 12                	jmp    f0100a0c <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009fa:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01009fd:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01009ff:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100a03:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a05:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a0c:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a0f:	0f 8e 78 ff ff ff    	jle    f010098d <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a15:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100a19:	75 0f                	jne    f0100a2a <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100a1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a1e:	8b 00                	mov    (%eax),%eax
f0100a20:	83 e8 01             	sub    $0x1,%eax
f0100a23:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100a26:	89 06                	mov    %eax,(%esi)
f0100a28:	eb 2c                	jmp    f0100a56 <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a2a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a2d:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a2f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a32:	8b 0e                	mov    (%esi),%ecx
f0100a34:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100a37:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100a3a:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a3d:	eb 03                	jmp    f0100a42 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a3f:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a42:	39 c8                	cmp    %ecx,%eax
f0100a44:	7e 0b                	jle    f0100a51 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100a46:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100a4a:	83 ea 0c             	sub    $0xc,%edx
f0100a4d:	39 df                	cmp    %ebx,%edi
f0100a4f:	75 ee                	jne    f0100a3f <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a51:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100a54:	89 06                	mov    %eax,(%esi)
	}
}
f0100a56:	83 c4 14             	add    $0x14,%esp
f0100a59:	5b                   	pop    %ebx
f0100a5a:	5e                   	pop    %esi
f0100a5b:	5f                   	pop    %edi
f0100a5c:	5d                   	pop    %ebp
f0100a5d:	c3                   	ret    

f0100a5e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a5e:	55                   	push   %ebp
f0100a5f:	89 e5                	mov    %esp,%ebp
f0100a61:	57                   	push   %edi
f0100a62:	56                   	push   %esi
f0100a63:	53                   	push   %ebx
f0100a64:	83 ec 3c             	sub    $0x3c,%esp
f0100a67:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a6a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a6d:	c7 03 64 1e 10 f0    	movl   $0xf0101e64,(%ebx)
	info->eip_line = 0;
f0100a73:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a7a:	c7 43 08 64 1e 10 f0 	movl   $0xf0101e64,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a81:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a88:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a8b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a92:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a98:	76 11                	jbe    f0100aab <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a9a:	b8 62 73 10 f0       	mov    $0xf0107362,%eax
f0100a9f:	3d 69 5a 10 f0       	cmp    $0xf0105a69,%eax
f0100aa4:	77 19                	ja     f0100abf <debuginfo_eip+0x61>
f0100aa6:	e9 aa 01 00 00       	jmp    f0100c55 <debuginfo_eip+0x1f7>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100aab:	83 ec 04             	sub    $0x4,%esp
f0100aae:	68 6e 1e 10 f0       	push   $0xf0101e6e
f0100ab3:	6a 7f                	push   $0x7f
f0100ab5:	68 7b 1e 10 f0       	push   $0xf0101e7b
f0100aba:	e8 27 f6 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100abf:	80 3d 61 73 10 f0 00 	cmpb   $0x0,0xf0107361
f0100ac6:	0f 85 90 01 00 00    	jne    f0100c5c <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100acc:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100ad3:	b8 68 5a 10 f0       	mov    $0xf0105a68,%eax
f0100ad8:	2d 9c 20 10 f0       	sub    $0xf010209c,%eax
f0100add:	c1 f8 02             	sar    $0x2,%eax
f0100ae0:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100ae6:	83 e8 01             	sub    $0x1,%eax
f0100ae9:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100aec:	83 ec 08             	sub    $0x8,%esp
f0100aef:	56                   	push   %esi
f0100af0:	6a 64                	push   $0x64
f0100af2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100af5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100af8:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100afd:	e8 66 fe ff ff       	call   f0100968 <stab_binsearch>
	if (lfile == 0)
f0100b02:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b05:	83 c4 10             	add    $0x10,%esp
f0100b08:	85 c0                	test   %eax,%eax
f0100b0a:	0f 84 53 01 00 00    	je     f0100c63 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b10:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b16:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b19:	83 ec 08             	sub    $0x8,%esp
f0100b1c:	56                   	push   %esi
f0100b1d:	6a 24                	push   $0x24
f0100b1f:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b22:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b25:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100b2a:	e8 39 fe ff ff       	call   f0100968 <stab_binsearch>

	if (lfun <= rfun) {
f0100b2f:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b32:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b35:	83 c4 10             	add    $0x10,%esp
f0100b38:	39 d0                	cmp    %edx,%eax
f0100b3a:	7f 40                	jg     f0100b7c <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b3c:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100b3f:	c1 e1 02             	shl    $0x2,%ecx
f0100b42:	8d b9 9c 20 10 f0    	lea    -0xfefdf64(%ecx),%edi
f0100b48:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b4b:	8b b9 9c 20 10 f0    	mov    -0xfefdf64(%ecx),%edi
f0100b51:	b9 62 73 10 f0       	mov    $0xf0107362,%ecx
f0100b56:	81 e9 69 5a 10 f0    	sub    $0xf0105a69,%ecx
f0100b5c:	39 cf                	cmp    %ecx,%edi
f0100b5e:	73 09                	jae    f0100b69 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b60:	81 c7 69 5a 10 f0    	add    $0xf0105a69,%edi
f0100b66:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b69:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100b6c:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100b6f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100b72:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100b74:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100b77:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100b7a:	eb 0f                	jmp    f0100b8b <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b7c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b7f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b82:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100b85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b88:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b8b:	83 ec 08             	sub    $0x8,%esp
f0100b8e:	6a 3a                	push   $0x3a
f0100b90:	ff 73 08             	pushl  0x8(%ebx)
f0100b93:	e8 d8 08 00 00       	call   f0101470 <strfind>
f0100b98:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b9b:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100b9e:	83 c4 08             	add    $0x8,%esp
f0100ba1:	56                   	push   %esi
f0100ba2:	6a 44                	push   $0x44
f0100ba4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100ba7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100baa:	b8 9c 20 10 f0       	mov    $0xf010209c,%eax
f0100baf:	e8 b4 fd ff ff       	call   f0100968 <stab_binsearch>

	if(lline <= rline) {
f0100bb4:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100bb7:	83 c4 10             	add    $0x10,%esp
f0100bba:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100bbd:	0f 8f a7 00 00 00    	jg     f0100c6a <debuginfo_eip+0x20c>
		info->eip_line = stabs[lline].n_desc;
f0100bc3:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100bc6:	8d 04 85 9c 20 10 f0 	lea    -0xfefdf64(,%eax,4),%eax
f0100bcd:	0f b7 48 06          	movzwl 0x6(%eax),%ecx
f0100bd1:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bd4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bd7:	eb 06                	jmp    f0100bdf <debuginfo_eip+0x181>
f0100bd9:	83 ea 01             	sub    $0x1,%edx
f0100bdc:	83 e8 0c             	sub    $0xc,%eax
f0100bdf:	39 d6                	cmp    %edx,%esi
f0100be1:	7f 34                	jg     f0100c17 <debuginfo_eip+0x1b9>
	       && stabs[lline].n_type != N_SOL
f0100be3:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100be7:	80 f9 84             	cmp    $0x84,%cl
f0100bea:	74 0b                	je     f0100bf7 <debuginfo_eip+0x199>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100bec:	80 f9 64             	cmp    $0x64,%cl
f0100bef:	75 e8                	jne    f0100bd9 <debuginfo_eip+0x17b>
f0100bf1:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100bf5:	74 e2                	je     f0100bd9 <debuginfo_eip+0x17b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100bf7:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100bfa:	8b 14 85 9c 20 10 f0 	mov    -0xfefdf64(,%eax,4),%edx
f0100c01:	b8 62 73 10 f0       	mov    $0xf0107362,%eax
f0100c06:	2d 69 5a 10 f0       	sub    $0xf0105a69,%eax
f0100c0b:	39 c2                	cmp    %eax,%edx
f0100c0d:	73 08                	jae    f0100c17 <debuginfo_eip+0x1b9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c0f:	81 c2 69 5a 10 f0    	add    $0xf0105a69,%edx
f0100c15:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c1a:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c1d:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c22:	39 f2                	cmp    %esi,%edx
f0100c24:	7d 50                	jge    f0100c76 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
f0100c26:	83 c2 01             	add    $0x1,%edx
f0100c29:	89 d0                	mov    %edx,%eax
f0100c2b:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100c2e:	8d 14 95 9c 20 10 f0 	lea    -0xfefdf64(,%edx,4),%edx
f0100c35:	eb 04                	jmp    f0100c3b <debuginfo_eip+0x1dd>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100c37:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c3b:	39 c6                	cmp    %eax,%esi
f0100c3d:	7e 32                	jle    f0100c71 <debuginfo_eip+0x213>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c3f:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c43:	83 c0 01             	add    $0x1,%eax
f0100c46:	83 c2 0c             	add    $0xc,%edx
f0100c49:	80 f9 a0             	cmp    $0xa0,%cl
f0100c4c:	74 e9                	je     f0100c37 <debuginfo_eip+0x1d9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c53:	eb 21                	jmp    f0100c76 <debuginfo_eip+0x218>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c5a:	eb 1a                	jmp    f0100c76 <debuginfo_eip+0x218>
f0100c5c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c61:	eb 13                	jmp    f0100c76 <debuginfo_eip+0x218>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100c63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c68:	eb 0c                	jmp    f0100c76 <debuginfo_eip+0x218>
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

	if(lline <= rline) {
		info->eip_line = stabs[lline].n_desc;
	} else return -1;
f0100c6a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c6f:	eb 05                	jmp    f0100c76 <debuginfo_eip+0x218>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c71:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100c76:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100c79:	5b                   	pop    %ebx
f0100c7a:	5e                   	pop    %esi
f0100c7b:	5f                   	pop    %edi
f0100c7c:	5d                   	pop    %ebp
f0100c7d:	c3                   	ret    

f0100c7e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c7e:	55                   	push   %ebp
f0100c7f:	89 e5                	mov    %esp,%ebp
f0100c81:	57                   	push   %edi
f0100c82:	56                   	push   %esi
f0100c83:	53                   	push   %ebx
f0100c84:	83 ec 1c             	sub    $0x1c,%esp
f0100c87:	89 c7                	mov    %eax,%edi
f0100c89:	89 d6                	mov    %edx,%esi
f0100c8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c8e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100c91:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100c94:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c97:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100c9a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c9f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ca2:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100ca5:	39 d3                	cmp    %edx,%ebx
f0100ca7:	72 05                	jb     f0100cae <printnum+0x30>
f0100ca9:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cac:	77 45                	ja     f0100cf3 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cae:	83 ec 0c             	sub    $0xc,%esp
f0100cb1:	ff 75 18             	pushl  0x18(%ebp)
f0100cb4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cb7:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100cba:	53                   	push   %ebx
f0100cbb:	ff 75 10             	pushl  0x10(%ebp)
f0100cbe:	83 ec 08             	sub    $0x8,%esp
f0100cc1:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100cc4:	ff 75 e0             	pushl  -0x20(%ebp)
f0100cc7:	ff 75 dc             	pushl  -0x24(%ebp)
f0100cca:	ff 75 d8             	pushl  -0x28(%ebp)
f0100ccd:	e8 be 09 00 00       	call   f0101690 <__udivdi3>
f0100cd2:	83 c4 18             	add    $0x18,%esp
f0100cd5:	52                   	push   %edx
f0100cd6:	50                   	push   %eax
f0100cd7:	89 f2                	mov    %esi,%edx
f0100cd9:	89 f8                	mov    %edi,%eax
f0100cdb:	e8 9e ff ff ff       	call   f0100c7e <printnum>
f0100ce0:	83 c4 20             	add    $0x20,%esp
f0100ce3:	eb 18                	jmp    f0100cfd <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100ce5:	83 ec 08             	sub    $0x8,%esp
f0100ce8:	56                   	push   %esi
f0100ce9:	ff 75 18             	pushl  0x18(%ebp)
f0100cec:	ff d7                	call   *%edi
f0100cee:	83 c4 10             	add    $0x10,%esp
f0100cf1:	eb 03                	jmp    f0100cf6 <printnum+0x78>
f0100cf3:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf6:	83 eb 01             	sub    $0x1,%ebx
f0100cf9:	85 db                	test   %ebx,%ebx
f0100cfb:	7f e8                	jg     f0100ce5 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100cfd:	83 ec 08             	sub    $0x8,%esp
f0100d00:	56                   	push   %esi
f0100d01:	83 ec 04             	sub    $0x4,%esp
f0100d04:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100d07:	ff 75 e0             	pushl  -0x20(%ebp)
f0100d0a:	ff 75 dc             	pushl  -0x24(%ebp)
f0100d0d:	ff 75 d8             	pushl  -0x28(%ebp)
f0100d10:	e8 ab 0a 00 00       	call   f01017c0 <__umoddi3>
f0100d15:	83 c4 14             	add    $0x14,%esp
f0100d18:	0f be 80 89 1e 10 f0 	movsbl -0xfefe177(%eax),%eax
f0100d1f:	50                   	push   %eax
f0100d20:	ff d7                	call   *%edi
}
f0100d22:	83 c4 10             	add    $0x10,%esp
f0100d25:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d28:	5b                   	pop    %ebx
f0100d29:	5e                   	pop    %esi
f0100d2a:	5f                   	pop    %edi
f0100d2b:	5d                   	pop    %ebp
f0100d2c:	c3                   	ret    

f0100d2d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d2d:	55                   	push   %ebp
f0100d2e:	89 e5                	mov    %esp,%ebp
f0100d30:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d33:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d37:	8b 10                	mov    (%eax),%edx
f0100d39:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d3c:	73 0a                	jae    f0100d48 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d3e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100d41:	89 08                	mov    %ecx,(%eax)
f0100d43:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d46:	88 02                	mov    %al,(%edx)
}
f0100d48:	5d                   	pop    %ebp
f0100d49:	c3                   	ret    

f0100d4a <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d4a:	55                   	push   %ebp
f0100d4b:	89 e5                	mov    %esp,%ebp
f0100d4d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d50:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d53:	50                   	push   %eax
f0100d54:	ff 75 10             	pushl  0x10(%ebp)
f0100d57:	ff 75 0c             	pushl  0xc(%ebp)
f0100d5a:	ff 75 08             	pushl  0x8(%ebp)
f0100d5d:	e8 05 00 00 00       	call   f0100d67 <vprintfmt>
	va_end(ap);
}
f0100d62:	83 c4 10             	add    $0x10,%esp
f0100d65:	c9                   	leave  
f0100d66:	c3                   	ret    

f0100d67 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d67:	55                   	push   %ebp
f0100d68:	89 e5                	mov    %esp,%ebp
f0100d6a:	57                   	push   %edi
f0100d6b:	56                   	push   %esi
f0100d6c:	53                   	push   %ebx
f0100d6d:	83 ec 2c             	sub    $0x2c,%esp
f0100d70:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d73:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d76:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d79:	eb 12                	jmp    f0100d8d <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d7b:	85 c0                	test   %eax,%eax
f0100d7d:	0f 84 42 04 00 00    	je     f01011c5 <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100d83:	83 ec 08             	sub    $0x8,%esp
f0100d86:	53                   	push   %ebx
f0100d87:	50                   	push   %eax
f0100d88:	ff d6                	call   *%esi
f0100d8a:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d8d:	83 c7 01             	add    $0x1,%edi
f0100d90:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100d94:	83 f8 25             	cmp    $0x25,%eax
f0100d97:	75 e2                	jne    f0100d7b <vprintfmt+0x14>
f0100d99:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100d9d:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100da4:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100dab:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100db2:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100db7:	eb 07                	jmp    f0100dc0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db9:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100dbc:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc0:	8d 47 01             	lea    0x1(%edi),%eax
f0100dc3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100dc6:	0f b6 07             	movzbl (%edi),%eax
f0100dc9:	0f b6 d0             	movzbl %al,%edx
f0100dcc:	83 e8 23             	sub    $0x23,%eax
f0100dcf:	3c 55                	cmp    $0x55,%al
f0100dd1:	0f 87 d3 03 00 00    	ja     f01011aa <vprintfmt+0x443>
f0100dd7:	0f b6 c0             	movzbl %al,%eax
f0100dda:	ff 24 85 18 1f 10 f0 	jmp    *-0xfefe0e8(,%eax,4)
f0100de1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100de4:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100de8:	eb d6                	jmp    f0100dc0 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ded:	b8 00 00 00 00       	mov    $0x0,%eax
f0100df2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100df5:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100df8:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100dfc:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100dff:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100e02:	83 f9 09             	cmp    $0x9,%ecx
f0100e05:	77 3f                	ja     f0100e46 <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e07:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e0a:	eb e9                	jmp    f0100df5 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e0c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e0f:	8b 00                	mov    (%eax),%eax
f0100e11:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e14:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e17:	8d 40 04             	lea    0x4(%eax),%eax
f0100e1a:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e1d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e20:	eb 2a                	jmp    f0100e4c <vprintfmt+0xe5>
f0100e22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e25:	85 c0                	test   %eax,%eax
f0100e27:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e2c:	0f 49 d0             	cmovns %eax,%edx
f0100e2f:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e32:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e35:	eb 89                	jmp    f0100dc0 <vprintfmt+0x59>
f0100e37:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e3a:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100e41:	e9 7a ff ff ff       	jmp    f0100dc0 <vprintfmt+0x59>
f0100e46:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e49:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100e4c:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100e50:	0f 89 6a ff ff ff    	jns    f0100dc0 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100e56:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e59:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e5c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e63:	e9 58 ff ff ff       	jmp    f0100dc0 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e68:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e6e:	e9 4d ff ff ff       	jmp    f0100dc0 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e73:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e76:	8d 78 04             	lea    0x4(%eax),%edi
f0100e79:	83 ec 08             	sub    $0x8,%esp
f0100e7c:	53                   	push   %ebx
f0100e7d:	ff 30                	pushl  (%eax)
f0100e7f:	ff d6                	call   *%esi
			break;
f0100e81:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e84:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e87:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e8a:	e9 fe fe ff ff       	jmp    f0100d8d <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e8f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e92:	8d 78 04             	lea    0x4(%eax),%edi
f0100e95:	8b 00                	mov    (%eax),%eax
f0100e97:	99                   	cltd   
f0100e98:	31 d0                	xor    %edx,%eax
f0100e9a:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100e9c:	83 f8 06             	cmp    $0x6,%eax
f0100e9f:	7f 0b                	jg     f0100eac <vprintfmt+0x145>
f0100ea1:	8b 14 85 70 20 10 f0 	mov    -0xfefdf90(,%eax,4),%edx
f0100ea8:	85 d2                	test   %edx,%edx
f0100eaa:	75 1b                	jne    f0100ec7 <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100eac:	50                   	push   %eax
f0100ead:	68 a1 1e 10 f0       	push   $0xf0101ea1
f0100eb2:	53                   	push   %ebx
f0100eb3:	56                   	push   %esi
f0100eb4:	e8 91 fe ff ff       	call   f0100d4a <printfmt>
f0100eb9:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ebc:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ebf:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ec2:	e9 c6 fe ff ff       	jmp    f0100d8d <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100ec7:	52                   	push   %edx
f0100ec8:	68 aa 1e 10 f0       	push   $0xf0101eaa
f0100ecd:	53                   	push   %ebx
f0100ece:	56                   	push   %esi
f0100ecf:	e8 76 fe ff ff       	call   f0100d4a <printfmt>
f0100ed4:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100ed7:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100edd:	e9 ab fe ff ff       	jmp    f0100d8d <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100ee2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee5:	83 c0 04             	add    $0x4,%eax
f0100ee8:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100eeb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eee:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100ef0:	85 ff                	test   %edi,%edi
f0100ef2:	b8 9a 1e 10 f0       	mov    $0xf0101e9a,%eax
f0100ef7:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100efa:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100efe:	0f 8e 94 00 00 00    	jle    f0100f98 <vprintfmt+0x231>
f0100f04:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100f08:	0f 84 98 00 00 00    	je     f0100fa6 <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f0e:	83 ec 08             	sub    $0x8,%esp
f0100f11:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f14:	57                   	push   %edi
f0100f15:	e8 0c 04 00 00       	call   f0101326 <strnlen>
f0100f1a:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100f1d:	29 c1                	sub    %eax,%ecx
f0100f1f:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0100f22:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0100f25:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100f29:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f2c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100f2f:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f31:	eb 0f                	jmp    f0100f42 <vprintfmt+0x1db>
					putch(padc, putdat);
f0100f33:	83 ec 08             	sub    $0x8,%esp
f0100f36:	53                   	push   %ebx
f0100f37:	ff 75 e0             	pushl  -0x20(%ebp)
f0100f3a:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f3c:	83 ef 01             	sub    $0x1,%edi
f0100f3f:	83 c4 10             	add    $0x10,%esp
f0100f42:	85 ff                	test   %edi,%edi
f0100f44:	7f ed                	jg     f0100f33 <vprintfmt+0x1cc>
f0100f46:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100f49:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0100f4c:	85 c9                	test   %ecx,%ecx
f0100f4e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f53:	0f 49 c1             	cmovns %ecx,%eax
f0100f56:	29 c1                	sub    %eax,%ecx
f0100f58:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f5b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f5e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100f61:	89 cb                	mov    %ecx,%ebx
f0100f63:	eb 4d                	jmp    f0100fb2 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f65:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f69:	74 1b                	je     f0100f86 <vprintfmt+0x21f>
f0100f6b:	0f be c0             	movsbl %al,%eax
f0100f6e:	83 e8 20             	sub    $0x20,%eax
f0100f71:	83 f8 5e             	cmp    $0x5e,%eax
f0100f74:	76 10                	jbe    f0100f86 <vprintfmt+0x21f>
					putch('?', putdat);
f0100f76:	83 ec 08             	sub    $0x8,%esp
f0100f79:	ff 75 0c             	pushl  0xc(%ebp)
f0100f7c:	6a 3f                	push   $0x3f
f0100f7e:	ff 55 08             	call   *0x8(%ebp)
f0100f81:	83 c4 10             	add    $0x10,%esp
f0100f84:	eb 0d                	jmp    f0100f93 <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f0100f86:	83 ec 08             	sub    $0x8,%esp
f0100f89:	ff 75 0c             	pushl  0xc(%ebp)
f0100f8c:	52                   	push   %edx
f0100f8d:	ff 55 08             	call   *0x8(%ebp)
f0100f90:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100f93:	83 eb 01             	sub    $0x1,%ebx
f0100f96:	eb 1a                	jmp    f0100fb2 <vprintfmt+0x24b>
f0100f98:	89 75 08             	mov    %esi,0x8(%ebp)
f0100f9b:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100f9e:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100fa1:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fa4:	eb 0c                	jmp    f0100fb2 <vprintfmt+0x24b>
f0100fa6:	89 75 08             	mov    %esi,0x8(%ebp)
f0100fa9:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100fac:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0100faf:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100fb2:	83 c7 01             	add    $0x1,%edi
f0100fb5:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100fb9:	0f be d0             	movsbl %al,%edx
f0100fbc:	85 d2                	test   %edx,%edx
f0100fbe:	74 23                	je     f0100fe3 <vprintfmt+0x27c>
f0100fc0:	85 f6                	test   %esi,%esi
f0100fc2:	78 a1                	js     f0100f65 <vprintfmt+0x1fe>
f0100fc4:	83 ee 01             	sub    $0x1,%esi
f0100fc7:	79 9c                	jns    f0100f65 <vprintfmt+0x1fe>
f0100fc9:	89 df                	mov    %ebx,%edi
f0100fcb:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fce:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fd1:	eb 18                	jmp    f0100feb <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100fd3:	83 ec 08             	sub    $0x8,%esp
f0100fd6:	53                   	push   %ebx
f0100fd7:	6a 20                	push   $0x20
f0100fd9:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100fdb:	83 ef 01             	sub    $0x1,%edi
f0100fde:	83 c4 10             	add    $0x10,%esp
f0100fe1:	eb 08                	jmp    f0100feb <vprintfmt+0x284>
f0100fe3:	89 df                	mov    %ebx,%edi
f0100fe5:	8b 75 08             	mov    0x8(%ebp),%esi
f0100fe8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100feb:	85 ff                	test   %edi,%edi
f0100fed:	7f e4                	jg     f0100fd3 <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fef:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100ff2:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ff8:	e9 90 fd ff ff       	jmp    f0100d8d <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100ffd:	83 f9 01             	cmp    $0x1,%ecx
f0101000:	7e 19                	jle    f010101b <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f0101002:	8b 45 14             	mov    0x14(%ebp),%eax
f0101005:	8b 50 04             	mov    0x4(%eax),%edx
f0101008:	8b 00                	mov    (%eax),%eax
f010100a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010100d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101010:	8b 45 14             	mov    0x14(%ebp),%eax
f0101013:	8d 40 08             	lea    0x8(%eax),%eax
f0101016:	89 45 14             	mov    %eax,0x14(%ebp)
f0101019:	eb 38                	jmp    f0101053 <vprintfmt+0x2ec>
	else if (lflag)
f010101b:	85 c9                	test   %ecx,%ecx
f010101d:	74 1b                	je     f010103a <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f010101f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101022:	8b 00                	mov    (%eax),%eax
f0101024:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101027:	89 c1                	mov    %eax,%ecx
f0101029:	c1 f9 1f             	sar    $0x1f,%ecx
f010102c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010102f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101032:	8d 40 04             	lea    0x4(%eax),%eax
f0101035:	89 45 14             	mov    %eax,0x14(%ebp)
f0101038:	eb 19                	jmp    f0101053 <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f010103a:	8b 45 14             	mov    0x14(%ebp),%eax
f010103d:	8b 00                	mov    (%eax),%eax
f010103f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101042:	89 c1                	mov    %eax,%ecx
f0101044:	c1 f9 1f             	sar    $0x1f,%ecx
f0101047:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010104a:	8b 45 14             	mov    0x14(%ebp),%eax
f010104d:	8d 40 04             	lea    0x4(%eax),%eax
f0101050:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101053:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101056:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101059:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f010105e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101062:	0f 89 0e 01 00 00    	jns    f0101176 <vprintfmt+0x40f>
				putch('-', putdat);
f0101068:	83 ec 08             	sub    $0x8,%esp
f010106b:	53                   	push   %ebx
f010106c:	6a 2d                	push   $0x2d
f010106e:	ff d6                	call   *%esi
				num = -(long long) num;
f0101070:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101073:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101076:	f7 da                	neg    %edx
f0101078:	83 d1 00             	adc    $0x0,%ecx
f010107b:	f7 d9                	neg    %ecx
f010107d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101080:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101085:	e9 ec 00 00 00       	jmp    f0101176 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010108a:	83 f9 01             	cmp    $0x1,%ecx
f010108d:	7e 18                	jle    f01010a7 <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f010108f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101092:	8b 10                	mov    (%eax),%edx
f0101094:	8b 48 04             	mov    0x4(%eax),%ecx
f0101097:	8d 40 08             	lea    0x8(%eax),%eax
f010109a:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010109d:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010a2:	e9 cf 00 00 00       	jmp    f0101176 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f01010a7:	85 c9                	test   %ecx,%ecx
f01010a9:	74 1a                	je     f01010c5 <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f01010ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ae:	8b 10                	mov    (%eax),%edx
f01010b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010b5:	8d 40 04             	lea    0x4(%eax),%eax
f01010b8:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010bb:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010c0:	e9 b1 00 00 00       	jmp    f0101176 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01010c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c8:	8b 10                	mov    (%eax),%edx
f01010ca:	b9 00 00 00 00       	mov    $0x0,%ecx
f01010cf:	8d 40 04             	lea    0x4(%eax),%eax
f01010d2:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01010d5:	b8 0a 00 00 00       	mov    $0xa,%eax
f01010da:	e9 97 00 00 00       	jmp    f0101176 <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010df:	83 ec 08             	sub    $0x8,%esp
f01010e2:	53                   	push   %ebx
f01010e3:	6a 58                	push   $0x58
f01010e5:	ff d6                	call   *%esi
			putch('X', putdat);
f01010e7:	83 c4 08             	add    $0x8,%esp
f01010ea:	53                   	push   %ebx
f01010eb:	6a 58                	push   $0x58
f01010ed:	ff d6                	call   *%esi
			putch('X', putdat);
f01010ef:	83 c4 08             	add    $0x8,%esp
f01010f2:	53                   	push   %ebx
f01010f3:	6a 58                	push   $0x58
f01010f5:	ff d6                	call   *%esi
			break;
f01010f7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010fa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010fd:	e9 8b fc ff ff       	jmp    f0100d8d <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f0101102:	83 ec 08             	sub    $0x8,%esp
f0101105:	53                   	push   %ebx
f0101106:	6a 30                	push   $0x30
f0101108:	ff d6                	call   *%esi
			putch('x', putdat);
f010110a:	83 c4 08             	add    $0x8,%esp
f010110d:	53                   	push   %ebx
f010110e:	6a 78                	push   $0x78
f0101110:	ff d6                	call   *%esi
			num = (unsigned long long)
f0101112:	8b 45 14             	mov    0x14(%ebp),%eax
f0101115:	8b 10                	mov    (%eax),%edx
f0101117:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f010111c:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010111f:	8d 40 04             	lea    0x4(%eax),%eax
f0101122:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101125:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010112a:	eb 4a                	jmp    f0101176 <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f010112c:	83 f9 01             	cmp    $0x1,%ecx
f010112f:	7e 15                	jle    f0101146 <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0101131:	8b 45 14             	mov    0x14(%ebp),%eax
f0101134:	8b 10                	mov    (%eax),%edx
f0101136:	8b 48 04             	mov    0x4(%eax),%ecx
f0101139:	8d 40 08             	lea    0x8(%eax),%eax
f010113c:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010113f:	b8 10 00 00 00       	mov    $0x10,%eax
f0101144:	eb 30                	jmp    f0101176 <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f0101146:	85 c9                	test   %ecx,%ecx
f0101148:	74 17                	je     f0101161 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f010114a:	8b 45 14             	mov    0x14(%ebp),%eax
f010114d:	8b 10                	mov    (%eax),%edx
f010114f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101154:	8d 40 04             	lea    0x4(%eax),%eax
f0101157:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010115a:	b8 10 00 00 00       	mov    $0x10,%eax
f010115f:	eb 15                	jmp    f0101176 <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101161:	8b 45 14             	mov    0x14(%ebp),%eax
f0101164:	8b 10                	mov    (%eax),%edx
f0101166:	b9 00 00 00 00       	mov    $0x0,%ecx
f010116b:	8d 40 04             	lea    0x4(%eax),%eax
f010116e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101171:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101176:	83 ec 0c             	sub    $0xc,%esp
f0101179:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f010117d:	57                   	push   %edi
f010117e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101181:	50                   	push   %eax
f0101182:	51                   	push   %ecx
f0101183:	52                   	push   %edx
f0101184:	89 da                	mov    %ebx,%edx
f0101186:	89 f0                	mov    %esi,%eax
f0101188:	e8 f1 fa ff ff       	call   f0100c7e <printnum>
			break;
f010118d:	83 c4 20             	add    $0x20,%esp
f0101190:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101193:	e9 f5 fb ff ff       	jmp    f0100d8d <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101198:	83 ec 08             	sub    $0x8,%esp
f010119b:	53                   	push   %ebx
f010119c:	52                   	push   %edx
f010119d:	ff d6                	call   *%esi
			break;
f010119f:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011a2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011a5:	e9 e3 fb ff ff       	jmp    f0100d8d <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011aa:	83 ec 08             	sub    $0x8,%esp
f01011ad:	53                   	push   %ebx
f01011ae:	6a 25                	push   $0x25
f01011b0:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011b2:	83 c4 10             	add    $0x10,%esp
f01011b5:	eb 03                	jmp    f01011ba <vprintfmt+0x453>
f01011b7:	83 ef 01             	sub    $0x1,%edi
f01011ba:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01011be:	75 f7                	jne    f01011b7 <vprintfmt+0x450>
f01011c0:	e9 c8 fb ff ff       	jmp    f0100d8d <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01011c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01011c8:	5b                   	pop    %ebx
f01011c9:	5e                   	pop    %esi
f01011ca:	5f                   	pop    %edi
f01011cb:	5d                   	pop    %ebp
f01011cc:	c3                   	ret    

f01011cd <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011cd:	55                   	push   %ebp
f01011ce:	89 e5                	mov    %esp,%ebp
f01011d0:	83 ec 18             	sub    $0x18,%esp
f01011d3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d6:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011dc:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011e0:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011e3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	74 26                	je     f0101214 <vsnprintf+0x47>
f01011ee:	85 d2                	test   %edx,%edx
f01011f0:	7e 22                	jle    f0101214 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011f2:	ff 75 14             	pushl  0x14(%ebp)
f01011f5:	ff 75 10             	pushl  0x10(%ebp)
f01011f8:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011fb:	50                   	push   %eax
f01011fc:	68 2d 0d 10 f0       	push   $0xf0100d2d
f0101201:	e8 61 fb ff ff       	call   f0100d67 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101206:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101209:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010120c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010120f:	83 c4 10             	add    $0x10,%esp
f0101212:	eb 05                	jmp    f0101219 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101214:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101219:	c9                   	leave  
f010121a:	c3                   	ret    

f010121b <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010121b:	55                   	push   %ebp
f010121c:	89 e5                	mov    %esp,%ebp
f010121e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101221:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101224:	50                   	push   %eax
f0101225:	ff 75 10             	pushl  0x10(%ebp)
f0101228:	ff 75 0c             	pushl  0xc(%ebp)
f010122b:	ff 75 08             	pushl  0x8(%ebp)
f010122e:	e8 9a ff ff ff       	call   f01011cd <vsnprintf>
	va_end(ap);

	return rc;
}
f0101233:	c9                   	leave  
f0101234:	c3                   	ret    

f0101235 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101235:	55                   	push   %ebp
f0101236:	89 e5                	mov    %esp,%ebp
f0101238:	57                   	push   %edi
f0101239:	56                   	push   %esi
f010123a:	53                   	push   %ebx
f010123b:	83 ec 0c             	sub    $0xc,%esp
f010123e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101241:	85 c0                	test   %eax,%eax
f0101243:	74 11                	je     f0101256 <readline+0x21>
		cprintf("%s", prompt);
f0101245:	83 ec 08             	sub    $0x8,%esp
f0101248:	50                   	push   %eax
f0101249:	68 aa 1e 10 f0       	push   $0xf0101eaa
f010124e:	e8 01 f7 ff ff       	call   f0100954 <cprintf>
f0101253:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101256:	83 ec 0c             	sub    $0xc,%esp
f0101259:	6a 00                	push   $0x0
f010125b:	e8 1c f4 ff ff       	call   f010067c <iscons>
f0101260:	89 c7                	mov    %eax,%edi
f0101262:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101265:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f010126a:	e8 fc f3 ff ff       	call   f010066b <getchar>
f010126f:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101271:	85 c0                	test   %eax,%eax
f0101273:	79 18                	jns    f010128d <readline+0x58>
			cprintf("read error: %e\n", c);
f0101275:	83 ec 08             	sub    $0x8,%esp
f0101278:	50                   	push   %eax
f0101279:	68 8c 20 10 f0       	push   $0xf010208c
f010127e:	e8 d1 f6 ff ff       	call   f0100954 <cprintf>
			return NULL;
f0101283:	83 c4 10             	add    $0x10,%esp
f0101286:	b8 00 00 00 00       	mov    $0x0,%eax
f010128b:	eb 79                	jmp    f0101306 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010128d:	83 f8 08             	cmp    $0x8,%eax
f0101290:	0f 94 c2             	sete   %dl
f0101293:	83 f8 7f             	cmp    $0x7f,%eax
f0101296:	0f 94 c0             	sete   %al
f0101299:	08 c2                	or     %al,%dl
f010129b:	74 1a                	je     f01012b7 <readline+0x82>
f010129d:	85 f6                	test   %esi,%esi
f010129f:	7e 16                	jle    f01012b7 <readline+0x82>
			if (echoing)
f01012a1:	85 ff                	test   %edi,%edi
f01012a3:	74 0d                	je     f01012b2 <readline+0x7d>
				cputchar('\b');
f01012a5:	83 ec 0c             	sub    $0xc,%esp
f01012a8:	6a 08                	push   $0x8
f01012aa:	e8 ac f3 ff ff       	call   f010065b <cputchar>
f01012af:	83 c4 10             	add    $0x10,%esp
			i--;
f01012b2:	83 ee 01             	sub    $0x1,%esi
f01012b5:	eb b3                	jmp    f010126a <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012b7:	83 fb 1f             	cmp    $0x1f,%ebx
f01012ba:	7e 23                	jle    f01012df <readline+0xaa>
f01012bc:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012c2:	7f 1b                	jg     f01012df <readline+0xaa>
			if (echoing)
f01012c4:	85 ff                	test   %edi,%edi
f01012c6:	74 0c                	je     f01012d4 <readline+0x9f>
				cputchar(c);
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	53                   	push   %ebx
f01012cc:	e8 8a f3 ff ff       	call   f010065b <cputchar>
f01012d1:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01012d4:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01012da:	8d 76 01             	lea    0x1(%esi),%esi
f01012dd:	eb 8b                	jmp    f010126a <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01012df:	83 fb 0a             	cmp    $0xa,%ebx
f01012e2:	74 05                	je     f01012e9 <readline+0xb4>
f01012e4:	83 fb 0d             	cmp    $0xd,%ebx
f01012e7:	75 81                	jne    f010126a <readline+0x35>
			if (echoing)
f01012e9:	85 ff                	test   %edi,%edi
f01012eb:	74 0d                	je     f01012fa <readline+0xc5>
				cputchar('\n');
f01012ed:	83 ec 0c             	sub    $0xc,%esp
f01012f0:	6a 0a                	push   $0xa
f01012f2:	e8 64 f3 ff ff       	call   f010065b <cputchar>
f01012f7:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01012fa:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f0101301:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101306:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101309:	5b                   	pop    %ebx
f010130a:	5e                   	pop    %esi
f010130b:	5f                   	pop    %edi
f010130c:	5d                   	pop    %ebp
f010130d:	c3                   	ret    

f010130e <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010130e:	55                   	push   %ebp
f010130f:	89 e5                	mov    %esp,%ebp
f0101311:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101314:	b8 00 00 00 00       	mov    $0x0,%eax
f0101319:	eb 03                	jmp    f010131e <strlen+0x10>
		n++;
f010131b:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f010131e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101322:	75 f7                	jne    f010131b <strlen+0xd>
		n++;
	return n;
}
f0101324:	5d                   	pop    %ebp
f0101325:	c3                   	ret    

f0101326 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101326:	55                   	push   %ebp
f0101327:	89 e5                	mov    %esp,%ebp
f0101329:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010132c:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010132f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101334:	eb 03                	jmp    f0101339 <strnlen+0x13>
		n++;
f0101336:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101339:	39 c2                	cmp    %eax,%edx
f010133b:	74 08                	je     f0101345 <strnlen+0x1f>
f010133d:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101341:	75 f3                	jne    f0101336 <strnlen+0x10>
f0101343:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101345:	5d                   	pop    %ebp
f0101346:	c3                   	ret    

f0101347 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101347:	55                   	push   %ebp
f0101348:	89 e5                	mov    %esp,%ebp
f010134a:	53                   	push   %ebx
f010134b:	8b 45 08             	mov    0x8(%ebp),%eax
f010134e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101351:	89 c2                	mov    %eax,%edx
f0101353:	83 c2 01             	add    $0x1,%edx
f0101356:	83 c1 01             	add    $0x1,%ecx
f0101359:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010135d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101360:	84 db                	test   %bl,%bl
f0101362:	75 ef                	jne    f0101353 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101364:	5b                   	pop    %ebx
f0101365:	5d                   	pop    %ebp
f0101366:	c3                   	ret    

f0101367 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101367:	55                   	push   %ebp
f0101368:	89 e5                	mov    %esp,%ebp
f010136a:	53                   	push   %ebx
f010136b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010136e:	53                   	push   %ebx
f010136f:	e8 9a ff ff ff       	call   f010130e <strlen>
f0101374:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101377:	ff 75 0c             	pushl  0xc(%ebp)
f010137a:	01 d8                	add    %ebx,%eax
f010137c:	50                   	push   %eax
f010137d:	e8 c5 ff ff ff       	call   f0101347 <strcpy>
	return dst;
}
f0101382:	89 d8                	mov    %ebx,%eax
f0101384:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101387:	c9                   	leave  
f0101388:	c3                   	ret    

f0101389 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101389:	55                   	push   %ebp
f010138a:	89 e5                	mov    %esp,%ebp
f010138c:	56                   	push   %esi
f010138d:	53                   	push   %ebx
f010138e:	8b 75 08             	mov    0x8(%ebp),%esi
f0101391:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101394:	89 f3                	mov    %esi,%ebx
f0101396:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101399:	89 f2                	mov    %esi,%edx
f010139b:	eb 0f                	jmp    f01013ac <strncpy+0x23>
		*dst++ = *src;
f010139d:	83 c2 01             	add    $0x1,%edx
f01013a0:	0f b6 01             	movzbl (%ecx),%eax
f01013a3:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013a6:	80 39 01             	cmpb   $0x1,(%ecx)
f01013a9:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013ac:	39 da                	cmp    %ebx,%edx
f01013ae:	75 ed                	jne    f010139d <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013b0:	89 f0                	mov    %esi,%eax
f01013b2:	5b                   	pop    %ebx
f01013b3:	5e                   	pop    %esi
f01013b4:	5d                   	pop    %ebp
f01013b5:	c3                   	ret    

f01013b6 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013b6:	55                   	push   %ebp
f01013b7:	89 e5                	mov    %esp,%ebp
f01013b9:	56                   	push   %esi
f01013ba:	53                   	push   %ebx
f01013bb:	8b 75 08             	mov    0x8(%ebp),%esi
f01013be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01013c1:	8b 55 10             	mov    0x10(%ebp),%edx
f01013c4:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013c6:	85 d2                	test   %edx,%edx
f01013c8:	74 21                	je     f01013eb <strlcpy+0x35>
f01013ca:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01013ce:	89 f2                	mov    %esi,%edx
f01013d0:	eb 09                	jmp    f01013db <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01013d2:	83 c2 01             	add    $0x1,%edx
f01013d5:	83 c1 01             	add    $0x1,%ecx
f01013d8:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01013db:	39 c2                	cmp    %eax,%edx
f01013dd:	74 09                	je     f01013e8 <strlcpy+0x32>
f01013df:	0f b6 19             	movzbl (%ecx),%ebx
f01013e2:	84 db                	test   %bl,%bl
f01013e4:	75 ec                	jne    f01013d2 <strlcpy+0x1c>
f01013e6:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01013e8:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01013eb:	29 f0                	sub    %esi,%eax
}
f01013ed:	5b                   	pop    %ebx
f01013ee:	5e                   	pop    %esi
f01013ef:	5d                   	pop    %ebp
f01013f0:	c3                   	ret    

f01013f1 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013f1:	55                   	push   %ebp
f01013f2:	89 e5                	mov    %esp,%ebp
f01013f4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013f7:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013fa:	eb 06                	jmp    f0101402 <strcmp+0x11>
		p++, q++;
f01013fc:	83 c1 01             	add    $0x1,%ecx
f01013ff:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101402:	0f b6 01             	movzbl (%ecx),%eax
f0101405:	84 c0                	test   %al,%al
f0101407:	74 04                	je     f010140d <strcmp+0x1c>
f0101409:	3a 02                	cmp    (%edx),%al
f010140b:	74 ef                	je     f01013fc <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010140d:	0f b6 c0             	movzbl %al,%eax
f0101410:	0f b6 12             	movzbl (%edx),%edx
f0101413:	29 d0                	sub    %edx,%eax
}
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	53                   	push   %ebx
f010141b:	8b 45 08             	mov    0x8(%ebp),%eax
f010141e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101421:	89 c3                	mov    %eax,%ebx
f0101423:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101426:	eb 06                	jmp    f010142e <strncmp+0x17>
		n--, p++, q++;
f0101428:	83 c0 01             	add    $0x1,%eax
f010142b:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010142e:	39 d8                	cmp    %ebx,%eax
f0101430:	74 15                	je     f0101447 <strncmp+0x30>
f0101432:	0f b6 08             	movzbl (%eax),%ecx
f0101435:	84 c9                	test   %cl,%cl
f0101437:	74 04                	je     f010143d <strncmp+0x26>
f0101439:	3a 0a                	cmp    (%edx),%cl
f010143b:	74 eb                	je     f0101428 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010143d:	0f b6 00             	movzbl (%eax),%eax
f0101440:	0f b6 12             	movzbl (%edx),%edx
f0101443:	29 d0                	sub    %edx,%eax
f0101445:	eb 05                	jmp    f010144c <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101447:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010144c:	5b                   	pop    %ebx
f010144d:	5d                   	pop    %ebp
f010144e:	c3                   	ret    

f010144f <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010144f:	55                   	push   %ebp
f0101450:	89 e5                	mov    %esp,%ebp
f0101452:	8b 45 08             	mov    0x8(%ebp),%eax
f0101455:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101459:	eb 07                	jmp    f0101462 <strchr+0x13>
		if (*s == c)
f010145b:	38 ca                	cmp    %cl,%dl
f010145d:	74 0f                	je     f010146e <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010145f:	83 c0 01             	add    $0x1,%eax
f0101462:	0f b6 10             	movzbl (%eax),%edx
f0101465:	84 d2                	test   %dl,%dl
f0101467:	75 f2                	jne    f010145b <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101469:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010146e:	5d                   	pop    %ebp
f010146f:	c3                   	ret    

f0101470 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	8b 45 08             	mov    0x8(%ebp),%eax
f0101476:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010147a:	eb 03                	jmp    f010147f <strfind+0xf>
f010147c:	83 c0 01             	add    $0x1,%eax
f010147f:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101482:	38 ca                	cmp    %cl,%dl
f0101484:	74 04                	je     f010148a <strfind+0x1a>
f0101486:	84 d2                	test   %dl,%dl
f0101488:	75 f2                	jne    f010147c <strfind+0xc>
			break;
	return (char *) s;
}
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	57                   	push   %edi
f0101490:	56                   	push   %esi
f0101491:	53                   	push   %ebx
f0101492:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101495:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101498:	85 c9                	test   %ecx,%ecx
f010149a:	74 36                	je     f01014d2 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010149c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014a2:	75 28                	jne    f01014cc <memset+0x40>
f01014a4:	f6 c1 03             	test   $0x3,%cl
f01014a7:	75 23                	jne    f01014cc <memset+0x40>
		c &= 0xFF;
f01014a9:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01014ad:	89 d3                	mov    %edx,%ebx
f01014af:	c1 e3 08             	shl    $0x8,%ebx
f01014b2:	89 d6                	mov    %edx,%esi
f01014b4:	c1 e6 18             	shl    $0x18,%esi
f01014b7:	89 d0                	mov    %edx,%eax
f01014b9:	c1 e0 10             	shl    $0x10,%eax
f01014bc:	09 f0                	or     %esi,%eax
f01014be:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01014c0:	89 d8                	mov    %ebx,%eax
f01014c2:	09 d0                	or     %edx,%eax
f01014c4:	c1 e9 02             	shr    $0x2,%ecx
f01014c7:	fc                   	cld    
f01014c8:	f3 ab                	rep stos %eax,%es:(%edi)
f01014ca:	eb 06                	jmp    f01014d2 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01014cc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014cf:	fc                   	cld    
f01014d0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014d2:	89 f8                	mov    %edi,%eax
f01014d4:	5b                   	pop    %ebx
f01014d5:	5e                   	pop    %esi
f01014d6:	5f                   	pop    %edi
f01014d7:	5d                   	pop    %ebp
f01014d8:	c3                   	ret    

f01014d9 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014d9:	55                   	push   %ebp
f01014da:	89 e5                	mov    %esp,%ebp
f01014dc:	57                   	push   %edi
f01014dd:	56                   	push   %esi
f01014de:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014e4:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014e7:	39 c6                	cmp    %eax,%esi
f01014e9:	73 35                	jae    f0101520 <memmove+0x47>
f01014eb:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014ee:	39 d0                	cmp    %edx,%eax
f01014f0:	73 2e                	jae    f0101520 <memmove+0x47>
		s += n;
		d += n;
f01014f2:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014f5:	89 d6                	mov    %edx,%esi
f01014f7:	09 fe                	or     %edi,%esi
f01014f9:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01014ff:	75 13                	jne    f0101514 <memmove+0x3b>
f0101501:	f6 c1 03             	test   $0x3,%cl
f0101504:	75 0e                	jne    f0101514 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0101506:	83 ef 04             	sub    $0x4,%edi
f0101509:	8d 72 fc             	lea    -0x4(%edx),%esi
f010150c:	c1 e9 02             	shr    $0x2,%ecx
f010150f:	fd                   	std    
f0101510:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101512:	eb 09                	jmp    f010151d <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101514:	83 ef 01             	sub    $0x1,%edi
f0101517:	8d 72 ff             	lea    -0x1(%edx),%esi
f010151a:	fd                   	std    
f010151b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010151d:	fc                   	cld    
f010151e:	eb 1d                	jmp    f010153d <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101520:	89 f2                	mov    %esi,%edx
f0101522:	09 c2                	or     %eax,%edx
f0101524:	f6 c2 03             	test   $0x3,%dl
f0101527:	75 0f                	jne    f0101538 <memmove+0x5f>
f0101529:	f6 c1 03             	test   $0x3,%cl
f010152c:	75 0a                	jne    f0101538 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f010152e:	c1 e9 02             	shr    $0x2,%ecx
f0101531:	89 c7                	mov    %eax,%edi
f0101533:	fc                   	cld    
f0101534:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101536:	eb 05                	jmp    f010153d <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101538:	89 c7                	mov    %eax,%edi
f010153a:	fc                   	cld    
f010153b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010153d:	5e                   	pop    %esi
f010153e:	5f                   	pop    %edi
f010153f:	5d                   	pop    %ebp
f0101540:	c3                   	ret    

f0101541 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101541:	55                   	push   %ebp
f0101542:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101544:	ff 75 10             	pushl  0x10(%ebp)
f0101547:	ff 75 0c             	pushl  0xc(%ebp)
f010154a:	ff 75 08             	pushl  0x8(%ebp)
f010154d:	e8 87 ff ff ff       	call   f01014d9 <memmove>
}
f0101552:	c9                   	leave  
f0101553:	c3                   	ret    

f0101554 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101554:	55                   	push   %ebp
f0101555:	89 e5                	mov    %esp,%ebp
f0101557:	56                   	push   %esi
f0101558:	53                   	push   %ebx
f0101559:	8b 45 08             	mov    0x8(%ebp),%eax
f010155c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010155f:	89 c6                	mov    %eax,%esi
f0101561:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101564:	eb 1a                	jmp    f0101580 <memcmp+0x2c>
		if (*s1 != *s2)
f0101566:	0f b6 08             	movzbl (%eax),%ecx
f0101569:	0f b6 1a             	movzbl (%edx),%ebx
f010156c:	38 d9                	cmp    %bl,%cl
f010156e:	74 0a                	je     f010157a <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101570:	0f b6 c1             	movzbl %cl,%eax
f0101573:	0f b6 db             	movzbl %bl,%ebx
f0101576:	29 d8                	sub    %ebx,%eax
f0101578:	eb 0f                	jmp    f0101589 <memcmp+0x35>
		s1++, s2++;
f010157a:	83 c0 01             	add    $0x1,%eax
f010157d:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101580:	39 f0                	cmp    %esi,%eax
f0101582:	75 e2                	jne    f0101566 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101584:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101589:	5b                   	pop    %ebx
f010158a:	5e                   	pop    %esi
f010158b:	5d                   	pop    %ebp
f010158c:	c3                   	ret    

f010158d <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010158d:	55                   	push   %ebp
f010158e:	89 e5                	mov    %esp,%ebp
f0101590:	53                   	push   %ebx
f0101591:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101594:	89 c1                	mov    %eax,%ecx
f0101596:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101599:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010159d:	eb 0a                	jmp    f01015a9 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f010159f:	0f b6 10             	movzbl (%eax),%edx
f01015a2:	39 da                	cmp    %ebx,%edx
f01015a4:	74 07                	je     f01015ad <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01015a6:	83 c0 01             	add    $0x1,%eax
f01015a9:	39 c8                	cmp    %ecx,%eax
f01015ab:	72 f2                	jb     f010159f <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01015ad:	5b                   	pop    %ebx
f01015ae:	5d                   	pop    %ebp
f01015af:	c3                   	ret    

f01015b0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015b0:	55                   	push   %ebp
f01015b1:	89 e5                	mov    %esp,%ebp
f01015b3:	57                   	push   %edi
f01015b4:	56                   	push   %esi
f01015b5:	53                   	push   %ebx
f01015b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015b9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015bc:	eb 03                	jmp    f01015c1 <strtol+0x11>
		s++;
f01015be:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015c1:	0f b6 01             	movzbl (%ecx),%eax
f01015c4:	3c 20                	cmp    $0x20,%al
f01015c6:	74 f6                	je     f01015be <strtol+0xe>
f01015c8:	3c 09                	cmp    $0x9,%al
f01015ca:	74 f2                	je     f01015be <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015cc:	3c 2b                	cmp    $0x2b,%al
f01015ce:	75 0a                	jne    f01015da <strtol+0x2a>
		s++;
f01015d0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015d3:	bf 00 00 00 00       	mov    $0x0,%edi
f01015d8:	eb 11                	jmp    f01015eb <strtol+0x3b>
f01015da:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015df:	3c 2d                	cmp    $0x2d,%al
f01015e1:	75 08                	jne    f01015eb <strtol+0x3b>
		s++, neg = 1;
f01015e3:	83 c1 01             	add    $0x1,%ecx
f01015e6:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015eb:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015f1:	75 15                	jne    f0101608 <strtol+0x58>
f01015f3:	80 39 30             	cmpb   $0x30,(%ecx)
f01015f6:	75 10                	jne    f0101608 <strtol+0x58>
f01015f8:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01015fc:	75 7c                	jne    f010167a <strtol+0xca>
		s += 2, base = 16;
f01015fe:	83 c1 02             	add    $0x2,%ecx
f0101601:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101606:	eb 16                	jmp    f010161e <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f0101608:	85 db                	test   %ebx,%ebx
f010160a:	75 12                	jne    f010161e <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010160c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101611:	80 39 30             	cmpb   $0x30,(%ecx)
f0101614:	75 08                	jne    f010161e <strtol+0x6e>
		s++, base = 8;
f0101616:	83 c1 01             	add    $0x1,%ecx
f0101619:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f010161e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101623:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101626:	0f b6 11             	movzbl (%ecx),%edx
f0101629:	8d 72 d0             	lea    -0x30(%edx),%esi
f010162c:	89 f3                	mov    %esi,%ebx
f010162e:	80 fb 09             	cmp    $0x9,%bl
f0101631:	77 08                	ja     f010163b <strtol+0x8b>
			dig = *s - '0';
f0101633:	0f be d2             	movsbl %dl,%edx
f0101636:	83 ea 30             	sub    $0x30,%edx
f0101639:	eb 22                	jmp    f010165d <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f010163b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010163e:	89 f3                	mov    %esi,%ebx
f0101640:	80 fb 19             	cmp    $0x19,%bl
f0101643:	77 08                	ja     f010164d <strtol+0x9d>
			dig = *s - 'a' + 10;
f0101645:	0f be d2             	movsbl %dl,%edx
f0101648:	83 ea 57             	sub    $0x57,%edx
f010164b:	eb 10                	jmp    f010165d <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f010164d:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101650:	89 f3                	mov    %esi,%ebx
f0101652:	80 fb 19             	cmp    $0x19,%bl
f0101655:	77 16                	ja     f010166d <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101657:	0f be d2             	movsbl %dl,%edx
f010165a:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f010165d:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101660:	7d 0b                	jge    f010166d <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101662:	83 c1 01             	add    $0x1,%ecx
f0101665:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101669:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f010166b:	eb b9                	jmp    f0101626 <strtol+0x76>

	if (endptr)
f010166d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101671:	74 0d                	je     f0101680 <strtol+0xd0>
		*endptr = (char *) s;
f0101673:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101676:	89 0e                	mov    %ecx,(%esi)
f0101678:	eb 06                	jmp    f0101680 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010167a:	85 db                	test   %ebx,%ebx
f010167c:	74 98                	je     f0101616 <strtol+0x66>
f010167e:	eb 9e                	jmp    f010161e <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101680:	89 c2                	mov    %eax,%edx
f0101682:	f7 da                	neg    %edx
f0101684:	85 ff                	test   %edi,%edi
f0101686:	0f 45 c2             	cmovne %edx,%eax
}
f0101689:	5b                   	pop    %ebx
f010168a:	5e                   	pop    %esi
f010168b:	5f                   	pop    %edi
f010168c:	5d                   	pop    %ebp
f010168d:	c3                   	ret    
f010168e:	66 90                	xchg   %ax,%ax

f0101690 <__udivdi3>:
f0101690:	55                   	push   %ebp
f0101691:	57                   	push   %edi
f0101692:	56                   	push   %esi
f0101693:	53                   	push   %ebx
f0101694:	83 ec 1c             	sub    $0x1c,%esp
f0101697:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010169b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010169f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f01016a3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01016a7:	85 f6                	test   %esi,%esi
f01016a9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01016ad:	89 ca                	mov    %ecx,%edx
f01016af:	89 f8                	mov    %edi,%eax
f01016b1:	75 3d                	jne    f01016f0 <__udivdi3+0x60>
f01016b3:	39 cf                	cmp    %ecx,%edi
f01016b5:	0f 87 c5 00 00 00    	ja     f0101780 <__udivdi3+0xf0>
f01016bb:	85 ff                	test   %edi,%edi
f01016bd:	89 fd                	mov    %edi,%ebp
f01016bf:	75 0b                	jne    f01016cc <__udivdi3+0x3c>
f01016c1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016c6:	31 d2                	xor    %edx,%edx
f01016c8:	f7 f7                	div    %edi
f01016ca:	89 c5                	mov    %eax,%ebp
f01016cc:	89 c8                	mov    %ecx,%eax
f01016ce:	31 d2                	xor    %edx,%edx
f01016d0:	f7 f5                	div    %ebp
f01016d2:	89 c1                	mov    %eax,%ecx
f01016d4:	89 d8                	mov    %ebx,%eax
f01016d6:	89 cf                	mov    %ecx,%edi
f01016d8:	f7 f5                	div    %ebp
f01016da:	89 c3                	mov    %eax,%ebx
f01016dc:	89 d8                	mov    %ebx,%eax
f01016de:	89 fa                	mov    %edi,%edx
f01016e0:	83 c4 1c             	add    $0x1c,%esp
f01016e3:	5b                   	pop    %ebx
f01016e4:	5e                   	pop    %esi
f01016e5:	5f                   	pop    %edi
f01016e6:	5d                   	pop    %ebp
f01016e7:	c3                   	ret    
f01016e8:	90                   	nop
f01016e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01016f0:	39 ce                	cmp    %ecx,%esi
f01016f2:	77 74                	ja     f0101768 <__udivdi3+0xd8>
f01016f4:	0f bd fe             	bsr    %esi,%edi
f01016f7:	83 f7 1f             	xor    $0x1f,%edi
f01016fa:	0f 84 98 00 00 00    	je     f0101798 <__udivdi3+0x108>
f0101700:	bb 20 00 00 00       	mov    $0x20,%ebx
f0101705:	89 f9                	mov    %edi,%ecx
f0101707:	89 c5                	mov    %eax,%ebp
f0101709:	29 fb                	sub    %edi,%ebx
f010170b:	d3 e6                	shl    %cl,%esi
f010170d:	89 d9                	mov    %ebx,%ecx
f010170f:	d3 ed                	shr    %cl,%ebp
f0101711:	89 f9                	mov    %edi,%ecx
f0101713:	d3 e0                	shl    %cl,%eax
f0101715:	09 ee                	or     %ebp,%esi
f0101717:	89 d9                	mov    %ebx,%ecx
f0101719:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010171d:	89 d5                	mov    %edx,%ebp
f010171f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101723:	d3 ed                	shr    %cl,%ebp
f0101725:	89 f9                	mov    %edi,%ecx
f0101727:	d3 e2                	shl    %cl,%edx
f0101729:	89 d9                	mov    %ebx,%ecx
f010172b:	d3 e8                	shr    %cl,%eax
f010172d:	09 c2                	or     %eax,%edx
f010172f:	89 d0                	mov    %edx,%eax
f0101731:	89 ea                	mov    %ebp,%edx
f0101733:	f7 f6                	div    %esi
f0101735:	89 d5                	mov    %edx,%ebp
f0101737:	89 c3                	mov    %eax,%ebx
f0101739:	f7 64 24 0c          	mull   0xc(%esp)
f010173d:	39 d5                	cmp    %edx,%ebp
f010173f:	72 10                	jb     f0101751 <__udivdi3+0xc1>
f0101741:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101745:	89 f9                	mov    %edi,%ecx
f0101747:	d3 e6                	shl    %cl,%esi
f0101749:	39 c6                	cmp    %eax,%esi
f010174b:	73 07                	jae    f0101754 <__udivdi3+0xc4>
f010174d:	39 d5                	cmp    %edx,%ebp
f010174f:	75 03                	jne    f0101754 <__udivdi3+0xc4>
f0101751:	83 eb 01             	sub    $0x1,%ebx
f0101754:	31 ff                	xor    %edi,%edi
f0101756:	89 d8                	mov    %ebx,%eax
f0101758:	89 fa                	mov    %edi,%edx
f010175a:	83 c4 1c             	add    $0x1c,%esp
f010175d:	5b                   	pop    %ebx
f010175e:	5e                   	pop    %esi
f010175f:	5f                   	pop    %edi
f0101760:	5d                   	pop    %ebp
f0101761:	c3                   	ret    
f0101762:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101768:	31 ff                	xor    %edi,%edi
f010176a:	31 db                	xor    %ebx,%ebx
f010176c:	89 d8                	mov    %ebx,%eax
f010176e:	89 fa                	mov    %edi,%edx
f0101770:	83 c4 1c             	add    $0x1c,%esp
f0101773:	5b                   	pop    %ebx
f0101774:	5e                   	pop    %esi
f0101775:	5f                   	pop    %edi
f0101776:	5d                   	pop    %ebp
f0101777:	c3                   	ret    
f0101778:	90                   	nop
f0101779:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101780:	89 d8                	mov    %ebx,%eax
f0101782:	f7 f7                	div    %edi
f0101784:	31 ff                	xor    %edi,%edi
f0101786:	89 c3                	mov    %eax,%ebx
f0101788:	89 d8                	mov    %ebx,%eax
f010178a:	89 fa                	mov    %edi,%edx
f010178c:	83 c4 1c             	add    $0x1c,%esp
f010178f:	5b                   	pop    %ebx
f0101790:	5e                   	pop    %esi
f0101791:	5f                   	pop    %edi
f0101792:	5d                   	pop    %ebp
f0101793:	c3                   	ret    
f0101794:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101798:	39 ce                	cmp    %ecx,%esi
f010179a:	72 0c                	jb     f01017a8 <__udivdi3+0x118>
f010179c:	31 db                	xor    %ebx,%ebx
f010179e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f01017a2:	0f 87 34 ff ff ff    	ja     f01016dc <__udivdi3+0x4c>
f01017a8:	bb 01 00 00 00       	mov    $0x1,%ebx
f01017ad:	e9 2a ff ff ff       	jmp    f01016dc <__udivdi3+0x4c>
f01017b2:	66 90                	xchg   %ax,%ax
f01017b4:	66 90                	xchg   %ax,%ax
f01017b6:	66 90                	xchg   %ax,%ax
f01017b8:	66 90                	xchg   %ax,%ax
f01017ba:	66 90                	xchg   %ax,%ax
f01017bc:	66 90                	xchg   %ax,%ax
f01017be:	66 90                	xchg   %ax,%ax

f01017c0 <__umoddi3>:
f01017c0:	55                   	push   %ebp
f01017c1:	57                   	push   %edi
f01017c2:	56                   	push   %esi
f01017c3:	53                   	push   %ebx
f01017c4:	83 ec 1c             	sub    $0x1c,%esp
f01017c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017cb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01017cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01017d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01017d7:	85 d2                	test   %edx,%edx
f01017d9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01017dd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01017e1:	89 f3                	mov    %esi,%ebx
f01017e3:	89 3c 24             	mov    %edi,(%esp)
f01017e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01017ea:	75 1c                	jne    f0101808 <__umoddi3+0x48>
f01017ec:	39 f7                	cmp    %esi,%edi
f01017ee:	76 50                	jbe    f0101840 <__umoddi3+0x80>
f01017f0:	89 c8                	mov    %ecx,%eax
f01017f2:	89 f2                	mov    %esi,%edx
f01017f4:	f7 f7                	div    %edi
f01017f6:	89 d0                	mov    %edx,%eax
f01017f8:	31 d2                	xor    %edx,%edx
f01017fa:	83 c4 1c             	add    $0x1c,%esp
f01017fd:	5b                   	pop    %ebx
f01017fe:	5e                   	pop    %esi
f01017ff:	5f                   	pop    %edi
f0101800:	5d                   	pop    %ebp
f0101801:	c3                   	ret    
f0101802:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101808:	39 f2                	cmp    %esi,%edx
f010180a:	89 d0                	mov    %edx,%eax
f010180c:	77 52                	ja     f0101860 <__umoddi3+0xa0>
f010180e:	0f bd ea             	bsr    %edx,%ebp
f0101811:	83 f5 1f             	xor    $0x1f,%ebp
f0101814:	75 5a                	jne    f0101870 <__umoddi3+0xb0>
f0101816:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010181a:	0f 82 e0 00 00 00    	jb     f0101900 <__umoddi3+0x140>
f0101820:	39 0c 24             	cmp    %ecx,(%esp)
f0101823:	0f 86 d7 00 00 00    	jbe    f0101900 <__umoddi3+0x140>
f0101829:	8b 44 24 08          	mov    0x8(%esp),%eax
f010182d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101831:	83 c4 1c             	add    $0x1c,%esp
f0101834:	5b                   	pop    %ebx
f0101835:	5e                   	pop    %esi
f0101836:	5f                   	pop    %edi
f0101837:	5d                   	pop    %ebp
f0101838:	c3                   	ret    
f0101839:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101840:	85 ff                	test   %edi,%edi
f0101842:	89 fd                	mov    %edi,%ebp
f0101844:	75 0b                	jne    f0101851 <__umoddi3+0x91>
f0101846:	b8 01 00 00 00       	mov    $0x1,%eax
f010184b:	31 d2                	xor    %edx,%edx
f010184d:	f7 f7                	div    %edi
f010184f:	89 c5                	mov    %eax,%ebp
f0101851:	89 f0                	mov    %esi,%eax
f0101853:	31 d2                	xor    %edx,%edx
f0101855:	f7 f5                	div    %ebp
f0101857:	89 c8                	mov    %ecx,%eax
f0101859:	f7 f5                	div    %ebp
f010185b:	89 d0                	mov    %edx,%eax
f010185d:	eb 99                	jmp    f01017f8 <__umoddi3+0x38>
f010185f:	90                   	nop
f0101860:	89 c8                	mov    %ecx,%eax
f0101862:	89 f2                	mov    %esi,%edx
f0101864:	83 c4 1c             	add    $0x1c,%esp
f0101867:	5b                   	pop    %ebx
f0101868:	5e                   	pop    %esi
f0101869:	5f                   	pop    %edi
f010186a:	5d                   	pop    %ebp
f010186b:	c3                   	ret    
f010186c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101870:	8b 34 24             	mov    (%esp),%esi
f0101873:	bf 20 00 00 00       	mov    $0x20,%edi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	29 ef                	sub    %ebp,%edi
f010187c:	d3 e0                	shl    %cl,%eax
f010187e:	89 f9                	mov    %edi,%ecx
f0101880:	89 f2                	mov    %esi,%edx
f0101882:	d3 ea                	shr    %cl,%edx
f0101884:	89 e9                	mov    %ebp,%ecx
f0101886:	09 c2                	or     %eax,%edx
f0101888:	89 d8                	mov    %ebx,%eax
f010188a:	89 14 24             	mov    %edx,(%esp)
f010188d:	89 f2                	mov    %esi,%edx
f010188f:	d3 e2                	shl    %cl,%edx
f0101891:	89 f9                	mov    %edi,%ecx
f0101893:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101897:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010189b:	d3 e8                	shr    %cl,%eax
f010189d:	89 e9                	mov    %ebp,%ecx
f010189f:	89 c6                	mov    %eax,%esi
f01018a1:	d3 e3                	shl    %cl,%ebx
f01018a3:	89 f9                	mov    %edi,%ecx
f01018a5:	89 d0                	mov    %edx,%eax
f01018a7:	d3 e8                	shr    %cl,%eax
f01018a9:	89 e9                	mov    %ebp,%ecx
f01018ab:	09 d8                	or     %ebx,%eax
f01018ad:	89 d3                	mov    %edx,%ebx
f01018af:	89 f2                	mov    %esi,%edx
f01018b1:	f7 34 24             	divl   (%esp)
f01018b4:	89 d6                	mov    %edx,%esi
f01018b6:	d3 e3                	shl    %cl,%ebx
f01018b8:	f7 64 24 04          	mull   0x4(%esp)
f01018bc:	39 d6                	cmp    %edx,%esi
f01018be:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01018c2:	89 d1                	mov    %edx,%ecx
f01018c4:	89 c3                	mov    %eax,%ebx
f01018c6:	72 08                	jb     f01018d0 <__umoddi3+0x110>
f01018c8:	75 11                	jne    f01018db <__umoddi3+0x11b>
f01018ca:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ce:	73 0b                	jae    f01018db <__umoddi3+0x11b>
f01018d0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01018d4:	1b 14 24             	sbb    (%esp),%edx
f01018d7:	89 d1                	mov    %edx,%ecx
f01018d9:	89 c3                	mov    %eax,%ebx
f01018db:	8b 54 24 08          	mov    0x8(%esp),%edx
f01018df:	29 da                	sub    %ebx,%edx
f01018e1:	19 ce                	sbb    %ecx,%esi
f01018e3:	89 f9                	mov    %edi,%ecx
f01018e5:	89 f0                	mov    %esi,%eax
f01018e7:	d3 e0                	shl    %cl,%eax
f01018e9:	89 e9                	mov    %ebp,%ecx
f01018eb:	d3 ea                	shr    %cl,%edx
f01018ed:	89 e9                	mov    %ebp,%ecx
f01018ef:	d3 ee                	shr    %cl,%esi
f01018f1:	09 d0                	or     %edx,%eax
f01018f3:	89 f2                	mov    %esi,%edx
f01018f5:	83 c4 1c             	add    $0x1c,%esp
f01018f8:	5b                   	pop    %ebx
f01018f9:	5e                   	pop    %esi
f01018fa:	5f                   	pop    %edi
f01018fb:	5d                   	pop    %ebp
f01018fc:	c3                   	ret    
f01018fd:	8d 76 00             	lea    0x0(%esi),%esi
f0101900:	29 f9                	sub    %edi,%ecx
f0101902:	19 d6                	sbb    %edx,%esi
f0101904:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101908:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010190c:	e9 18 ff ff ff       	jmp    f0101829 <__umoddi3+0x69>
