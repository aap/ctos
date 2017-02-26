#include <stdarg.h>
#include "k.h"

void
putchar(int c)
{
	uartout(c);
}

int
getch(void)
{
	return uartin();
}

int
getchar(void)
{
	int c = getch();
	putchar(c);
	return c;
}

void
puts(char *s)
{
	char c;
	while((c = *s++) != '\0')
		putchar(c);
}

void
uprintn(uint n, int b)
{
	if(n/b)
		printn(n/b, b);
	putchar("0123456789ABCDEF"[n%b]);
}

void
printn(int n, int b)
{
	if(n < 0){
		putchar('-');
		uprintn(-n, b);
	}else
		uprintn(n, b);
}

void
printf(char *fmt, ...)
{
	int i;
	int c;

	va_list args;
	va_start(args, fmt);
loop:
	while((c = *fmt++) != '%'){
		if(c == '\0')
			goto end;
		putchar(c);
	}
	c = *fmt++;
	if(c == 'd' || c == 'o' || c == 'x')
		uprintn(va_arg(args, int), c == 'd' ? 10 :
		                           c == 'o' ? 8 : 16);
	if(c == 'p'){
		c = va_arg(args, int);
		for(i = 0; i < 8; i++){
			putchar("0123456789ABCDEF"[c>>28 & 0xF]);
			c <<= 4;
		}
	}
	if(c == 'c')
		putchar(va_arg(args, int));
	if(c == 's')
		puts(va_arg(args, char*));
	goto loop;
end:
	va_end(args);
}
