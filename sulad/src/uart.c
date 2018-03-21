#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <syslog.h>

#include <termio.h>
#include <err.h>
#include <linux/serial.h>

/* baudrate settings are defined in <asm/termbits.h>, which is
included by <termios.h> */
#define BAUDRATE B1500000            
/* change this definition for the correct port */
#define MODEMDEVICE "/dev/ttyO2"
#define _POSIX_SOURCE 1 /* POSIX compliant source */

#define FALSE 0
#define TRUE 1

volatile int STOP=FALSE; 

int set_speed(int fd, long int rate, struct termios *options, int *baud_base);

static int rate_to_constant(int baudrate) {
#define B(x) case x: return B##x
	switch(baudrate) {
		B(50);     B(75);     B(110);    B(134);    B(150);
		B(200);    B(300);    B(600);    B(1200);   B(1800);
		B(2400);   B(4800);   B(9600);   B(19200);  B(38400);
		B(57600);  B(115200); B(230400); B(460800); B(500000); 
		B(576000); B(921600); B(1000000);B(1152000);B(1500000); 
	default: return 0;
	}
#undef B
} 

int uart_init(const char* device, long int baud_rate, unsigned char ncharb, char parity, unsigned char nstopb, int *baud_base, int *custom_divisor){
  int fd,c, res;
  //long int custom_baudrate=0;
  //long int closestSpeed=0;
  struct termios oldtio,newtio;
  struct serial_struct ss;
  *custom_divisor=*baud_base=0;
/* 
  Open modem device for reading and writing and not as controlling tty
  because we don't want to get killed if linenoise sends CTRL-C.
*/
 fd = open(device, O_RDWR | O_NOCTTY ); 
 if (fd <0) {
     return -1; 
     perror(MODEMDEVICE); 
     exit(-1);
 }

 tcgetattr(fd,&oldtio); /* save current serial port settings */
 bzero(&newtio, sizeof(newtio)); /* clear struct for new port settings */

/* 
  BAUDRATE: Set bps rate. You could also use cfsetispeed and cfsetospeed.
  CRTSCTS : output hardware flow control (only used if the cable has
            all necessary lines. See sect. 7 of Serial-HOWTO)
  CS8     : 8n1 (8bit,no parity,1 stopbit)
  CLOCAL  : local connection, no modem contol
  CREAD   : enable receiving characters
*/

 newtio.c_cflag = CLOCAL | CREAD;
  
 //if (cfsetspeed (&newtio, (speed_t) baud_rate)<0) return -1;
 
 /* Change bit per char*/
 if (ncharb==8) newtio.c_cflag |= CS8;
 else if (ncharb==7) newtio.c_cflag |= CS7;
 else if (ncharb==6) newtio.c_cflag |= CS6;
 else if (ncharb==5) newtio.c_cflag |= CS5;
 else return -1;
 
 /* Parity bit */
 if (parity=='n') {}
 else if (parity=='o') newtio.c_cflag |= PARENB | PARODD;
 else if (parity=='e') newtio.c_cflag |= PARENB;
 else return -1;
 
 /* Stop bits */
 if (nstopb==1) {}
 else if (nstopb==2) newtio.c_cflag |= CSTOPB;
 else return -1;
 
/*
  IGNPAR  : ignore bytes with parity errors
  ICRNL   : map CR to NL (otherwise a CR input on the other computer
            will not terminate input)
  otherwise make device raw (no other input processing)
*/
 //newtio.c_iflag = IGNPAR;
 newtio.c_iflag = IGNPAR;
 
/*
 Raw output.
*/
 newtio.c_oflag = 0;
 
/*
  ICANON  : enable canonical input
  disable all echo functionality, and don't send signals to calling program
*/
 //newtio.c_lflag = ICANON;
 
/* 
  initialize all control characters 
  default values can be found in /usr/include/termios.h, and are given
  in the comments, but we don't need them here
*/
 newtio.c_cc[VINTR]    = 0;     /* Ctrl-c */ 
 newtio.c_cc[VQUIT]    = 0;     /* Ctrl-\ */
 newtio.c_cc[VERASE]   = 0;     /* del */
 newtio.c_cc[VKILL]    = 0;     /* @ */
 newtio.c_cc[VEOF]     = 4;     /* Ctrl-d */
 newtio.c_cc[VTIME]    = 0;     /* inter-character timer unused */
 newtio.c_cc[VMIN]     = 1;     /* blocking read until 1 character arrives */
 newtio.c_cc[VSWTC]    = 0;     /* '\0' */
 newtio.c_cc[VSTART]   = 0;     /* Ctrl-q */ 
 newtio.c_cc[VSTOP]    = 0;     /* Ctrl-s */
 newtio.c_cc[VSUSP]    = 0;     /* Ctrl-z */
 newtio.c_cc[VEOL]     = 0;     /* '\0' */
 newtio.c_cc[VREPRINT] = 0;     /* Ctrl-r */
 newtio.c_cc[VDISCARD] = 0;     /* Ctrl-u */
 newtio.c_cc[VWERASE]  = 0;     /* Ctrl-w */
 newtio.c_cc[VLNEXT]   = 0;     /* Ctrl-v */
 newtio.c_cc[VEOL2]    = 0;     /* '\0' */

 *custom_divisor =set_speed(fd, baud_rate, &newtio, baud_base);
     /* 
      now clean the modem line and activate the settings for the port
    */
 tcflush(fd, TCIFLUSH);
 tcsetattr(fd,TCSANOW,&newtio);
/*
  terminal settings done, now handle input
  In this example, inputting a 'z' at the beginning of a line will 
  exit the program.
*/
return fd;
}

/* Open serial port in raw mode, with custom baudrate if necessary */
int set_speed(int fd, long int rate, struct termios *options, int *baud_base)
{
	struct serial_struct serinfo;
	long int speed = 0;
    *baud_base=0;
	speed = rate_to_constant(rate);

	if (speed == 0) {
		/* Custom divisor */
		serinfo.reserved_char[0] = 0;
		if (ioctl(fd, TIOCGSERIAL, &serinfo) < 0)
			return -1;
		serinfo.flags &= ~ASYNC_SPD_MASK;
		serinfo.flags |= ASYNC_SPD_CUST;
		serinfo.custom_divisor = (serinfo.baud_base + (rate / 2)) / rate;
		if (serinfo.custom_divisor < 1) 
			serinfo.custom_divisor = 1;
		if (ioctl(fd, TIOCSSERIAL, &serinfo) < 0)
			return -1;
		if (ioctl(fd, TIOCGSERIAL, &serinfo) < 0)
			return -1;
		if (serinfo.custom_divisor * rate != serinfo.baud_base) {
			/*warnx("actual baudrate is %d / %d = %f",
			      serinfo.baud_base, serinfo.custom_divisor,
			      (float)serinfo.baud_base / serinfo.custom_divisor);*/
		}
	}

	//fcntl(fd, F_SETFL, 0);
	//tcgetattr(fd, &options);
	cfsetispeed(options, speed ?: B38400);
	cfsetospeed(options, speed ?: B38400);
	//cfmakeraw(options);
	//options.c_cflag |= (CLOCAL | CREAD);
	//options.c_cflag &= ~CRTSCTS;
	//if (tcsetattr(fd, TCSANOW, &options) != 0)
	//	return -1;

    *baud_base = serinfo.baud_base;
	return speed ? 0 : serinfo.custom_divisor;
}