#define PUT8(a,v)   (*(byte*)(a) = v)
#define PUT16(a,v)  (*(ushort*)(a) = v)
#define PUT32(a,v)  (*(uint*)(a) = v)
#define GET8(a)     (*(byte*)(a))
#define GET16(a)    (*(ushort*)(a))
#define GET32(a)    (*(uint*)(a))

void getc0regs(C0 *c0);
void dosyscall(void);

void putchar(int c);
int getch(void);
int getchar(void);
void puts(char *s);
void printn(int n, int b);
void printf(char *fmt, ...);

void inituart(void);
int uartin(void);
void uartout(int c);

void timer(void);
void timerint(void);
