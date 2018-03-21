#include <stdio.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <uart.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <syslog.h>
#include <getopt.h>
#include <fcntl.h>

/**
 * TCP Uses 2 types of sockets, the connection socket and the listen socket.
 * The Goal is to separate the connection phase from the data exchange phase.
 * */
volatile sig_atomic_t flag = 0;
int __listen_sock=0;
#define UART_RX_BUFER_SIZE 1024
#define TCP_RX_BUFER_SIZE 1024
char __TCPbuffer[TCP_RX_BUFER_SIZE];
char __UARTbuffer[UART_RX_BUFER_SIZE];
int sock=0;
int __fd_pid=-1;
int __child=0;

static int gpio_permit_out[] = {70,71,72,73,74,75,110,113};

struct settings_t{
	const char *uart_device;	/* параметр -D */
	long int uart_speed;		/* параметр -S */
	int uart_data_bits;			/* параметр -b */
    char uart_parity_bit;       /* параметр -p */
    int uart_stop_bit;			/* параметр -s */
    int tcp_port; 				/* параметр -P */
    int led_rx;                 /* параметр --event-rx-led*/
    int fd_led_rx;                 /* параметр --event-rx-led*/
    int led_tx;                 /* параметр --event-tx-led*/
    int fd_led_tx;                 /* параметр --event-tx-led*/
    const char *pid_file;                 /* параметр --pid-file*/
    char **inputFiles;          /* входные файлы */
    int numInputFiles;          /* число входных файлов */
} settings;
 

void event_rx_led();
void event_tx_led();
int gpio_permit_out_check(int gpio);
int gpio_out_init(int gpio);
void gpio_out_deinit(int fd);
int gpio_out_write(int fd, int value);
static void skeleton_daemon();
int create_pid_file(const char *pid_file, int pid);
int delete_pid_file(int pid);

void display_usage();
int set_option(struct settings_t *settings, int argc, char *argv[]);

void scallback(int sig){
    syslog (LOG_NOTICE, "Close thread");
    delete_pid_file(__fd_pid);
    
    if (__child>0) {
        close(sock);
        close(__listen_sock);
    }
    
    exit(0);
}

int main(int argc, char *argv[]) {
	pid_t pid;
	int uart_fd;
	
	skeleton_daemon();
	
	//signal(SIGINT, scallback);
    signal(SIGTERM, scallback);
	    
	set_option(&settings, argc, argv);
	syslog (LOG_NOTICE, "SuLa UART <=> TCP daemon started. Param %d", argc);
	int i= argc;
	while (i--) syslog (LOG_NOTICE, "%s", argv[i]);

    if ((uart_fd=uart_init(settings.uart_device, 
    						settings.uart_speed,
    						settings.uart_data_bits,
    						settings.uart_parity_bit,
    						settings.uart_stop_bit))<0) {
    	syslog (LOG_ERR, "could not set uart:uart_init()");
    	exit(-1);
    }
    

	// socket address used for the server
	struct sockaddr_in server_address;
	memset(&server_address, 0, sizeof(server_address));
	server_address.sin_family = AF_INET;

	// htons: host to network short: transforms a value in host byte
	// ordering format to a short value in network byte ordering format
	server_address.sin_port = htons(settings.tcp_port);

	// htonl: host to network long: same as htons but to long
	server_address.sin_addr.s_addr = htonl(INADDR_ANY);
    
	// create a TCP socket, creation returns -1 on failure
	//int listen_sock;
	if ((__listen_sock = socket(PF_INET, SOCK_STREAM, 0)) < 0) {
		syslog (LOG_ERR, "could not create listen socket");
		return 1;
	}
    
    int enable = 1;
    if (setsockopt(__listen_sock, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
                            syslog (LOG_ERR, "setsockopt(SO_REUSEADDR) failed");

	// bind it to listen to the incoming connections on the created server
	// address, will return -1 on error
	if ((bind(__listen_sock, (struct sockaddr *)&server_address,
	          sizeof(server_address))) < 0) {
		syslog (LOG_ERR, "could not bind socket %d", settings.tcp_port);
		return 1;
	}

	int wait_size = 16;  // maximum number of waiting clients, after which
	                     // dropping begins
	if (listen(__listen_sock, wait_size) < 0) {
		syslog (LOG_ERR, "could not open socket for listening");
		return 1;
	}

	// socket address used to store client address
	struct sockaddr_in client_address;
	int client_address_len = 0;
	// run indefinitely
	if ((__fd_pid = create_pid_file(settings.pid_file, getpid()))<0){
					    syslog (LOG_ERR, "not create pid file %d:",pid);
					    syslog (LOG_ERR, "%s",settings.pid_file);
	};
	while (true) {
		// open a new socket to transmit data per connection
		//int sock;
		if ((sock = accept(__listen_sock, (struct sockaddr *)&client_address,
		                &client_address_len)) < 0) {
			syslog (LOG_ERR, "could not open a socket to accept data");
			return 1;
		}

		int n = 0;

		/*printf("client connected with ip address: %s\n",
		       inet_ntoa(client_address.sin_addr));*/
		syslog (LOG_NOTICE, ("client connected with ip address: %s",
		                                    inet_ntoa(client_address.sin_addr)));
		//printf("fffooorking....\n");
		switch(pid=fork()){
			case -1: syslog (LOG_ERR, "fork"); /* произошла ошибка */
        			 exit(1); /*выход из родительского процесса*/
        	case 0: //printf("fork i am here!!!\n");
        	        __child=1;
        	        if ((__fd_pid = create_pid_file(settings.pid_file, getpid()))<0){
					    syslog (LOG_ERR, "child not create pid file %d",pid);
					};
        			while ((n = read(uart_fd, __UARTbuffer, UART_RX_BUFER_SIZE)) > 0) {
        				//__UARTbuffer[n]=0;
						//printf("UART received: %s", __UARTbuffer);
						// echo received content back
						if (send(sock, __UARTbuffer, n, 0)<0){
							syslog (LOG_ERR, "tcp send error: %s", strerror(errno));
						} else event_rx_led(&settings);
					}
					break;
			default: //printf("Parent here!!!\n");
					// keep running as long as the client keeps the connection open
                     __child=0;
					while ((n = recv(sock, __TCPbuffer, TCP_RX_BUFER_SIZE, 0)) > 0) {
						//__TCPbuffer[n]=0;
						//printf("TCP received: %s", __TCPbuffer);
						// echo received content back
						//send(sock, __TCPbuffer, n, 0);
						if (write(uart_fd,__TCPbuffer,n)<0){
							syslog (LOG_ERR, "uart write error: %s", strerror(errno));
						} else event_tx_led(&settings);
					} 
		}
        kill(pid, SIGTERM);
		close(sock);
	}

	close(__listen_sock);
	return 0;
}

static void skeleton_daemon()
{
    pid_t pid;

    /* Fork off the parent process */
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* On success: The child process becomes session leader */
    if (setsid() < 0)
        exit(EXIT_FAILURE);

    /* Catch, ignore and handle signals */
    //TODO: Implement a working signal handler */
    signal(SIGCHLD, SIG_IGN);
    signal(SIGHUP, SIG_IGN);

    /* Fork off for the second time*/
    pid = fork();

    /* An error occurred */
    if (pid < 0)
        exit(EXIT_FAILURE);

    /* Success: Let the parent terminate */
    if (pid > 0)
        exit(EXIT_SUCCESS);

    /* Set new file permissions */
    umask(0);

    /* Change the working directory to the root directory */
    /* or another appropriated directory */
    chdir("/");

    /* Close all open file descriptors */
    int x;
    for (x = sysconf(_SC_OPEN_MAX); x>=0; x--)
    {
        close (x);
    }

    /* Open the log file */
    openlog ("sulad", LOG_CONS | LOG_PID | LOG_NDELAY, LOG_DAEMON);
}

int set_option(struct settings_t *settings, int argc, char *argv[]){
	int opt;
	int longIndex;
	static const struct option longOpts[] = {
        { "event-rx-led", required_argument, NULL, 0},
        { "event-tx-led", required_argument, NULL, 0},
        { "gpio-high", required_argument, NULL, 0},
        { "gpio-low", required_argument, NULL, 0},
        { "pid-file", required_argument, NULL, 0},
        { "device", required_argument, NULL, 'D' },
        { "baudrate", required_argument, NULL, 'S' },
        { "tcp-port", required_argument, NULL, 'P'},
        { "help", no_argument, NULL, 'h' },
        { NULL, 0, NULL, 0 }
    };
	static const char *optString = "D:S:b:p:s:P:h?";
	settings->uart_device="/dev/ttyO2";	/* параметр -D */
	settings->uart_speed=9600;					/* параметр -S */
	settings->uart_data_bits=8;						/* параметр -b */
    settings->uart_parity_bit='n';       			/* параметр -p */
    settings->uart_stop_bit=1;						/* параметр -s */
    settings->tcp_port=9988; 							/* параметр -P */
    settings->led_rx=settings->led_tx = -1;     /* led not change */
    settings->fd_led_rx=settings->fd_led_tx = -1;     /* led not change */
    settings->inputFiles=NULL;         			/* входные файлы */
    settings->numInputFiles=0;        				/* число входных файлов */
    
    while( (opt = getopt_long( argc, argv, optString, longOpts, &longIndex  )) != -1 ) {
        switch( opt ) {
            case 'D':
                settings->uart_device = optarg;
                break;
                 
            case 'S':
                settings->uart_speed = strtol(optarg,(char **)NULL,10);
                break;
                 
            case 'b':
                settings->uart_data_bits = strtol(optarg,(char **)NULL,10);
                break;
                 
            case 'p':
                settings->uart_parity_bit = optarg[0];
                break;
            case 's':
                settings->uart_stop_bit = strtol(optarg,(char **)NULL,10);
                break;
            case 'P':
                settings->tcp_port = strtol(optarg,(char **)NULL,10);
                break;
                 
            case 'h':   /* намеренный проход в следующий case-блок */
            case '?':
                display_usage();
                break;
            case 0:     /* длинная опция без короткого эквивалента */
                if( strcmp( "pid-file", longOpts[longIndex].name ) == 0 ) {
                    settings->pid_file = optarg;
                }
                else if( strcmp( "event-rx-led", longOpts[longIndex].name ) == 0 ) {
                    if (gpio_permit_out_check(settings->led_rx 
                                        = strtol(optarg,(char **)NULL,10))){
                        settings->fd_led_rx = gpio_out_init(settings->led_rx);
                    } else {
                        syslog (LOG_ERR, "could not gpio permit out gpio(%d)",settings->led_rx);
                        settings->led_rx=-1;
                    }
                }
                else if(strcmp( "event-tx-led", longOpts[longIndex].name ) == 0){
                    if (gpio_permit_out_check(settings->led_tx 
                                        = strtol(optarg,(char **)NULL,10))){
                        settings->fd_led_tx = gpio_out_init(settings->led_tx);
                    } else {
                        syslog (LOG_ERR, "could not gpio permit out gpio(%d)",settings->led_tx);
                        settings->led_tx=-1;
                    }
                }
                else if(strcmp( "gpio-high", longOpts[longIndex].name ) == 0){
                    int gpio, fd_gpio;
                    if (gpio_permit_out_check(gpio
                                        = strtol(optarg,(char **)NULL,10))){
                        fd_gpio=gpio_out_init(gpio);
                        gpio_out_write(fd_gpio, 1);
                        syslog (LOG_ERR, "high gpio %d", gpio);
                    } else syslog (LOG_ERR, "could not gpio permit out gpio(%d)",settings->led_tx);
                }
                else if(strcmp( "gpio-low", longOpts[longIndex].name ) == 0){
                    int gpio, fd_gpio;
                    if (gpio_permit_out_check(gpio
                                        = strtol(optarg,(char **)NULL,10))){
                        fd_gpio=gpio_out_init(gpio);
                        gpio_out_write(fd_gpio, 0);
                        syslog (LOG_ERR, "low gpio %d", gpio);
                    } else syslog (LOG_ERR, "could not gpio permit out gpio(%d)",settings->led_tx);
                }
                break;
                 
            default:
                /* сюда на самом деле попасть невозможно. */
                break;
        }
    }
     
    settings->inputFiles = argv + optind;
    settings->numInputFiles = argc - optind;
    return 0;
}

void display_usage(){
	
}

void event_rx_led(struct settings_t *settings){
    static int value=0;
    gpio_out_write(settings->fd_led_rx, value);
    value^=1;
}

void event_tx_led(struct settings_t *settings){
    static int value=0;
    gpio_out_write(settings->fd_led_tx, value);
    value^=1;
}

int gpio_permit_out_check(int gpio){
    int i=sizeof(gpio_permit_out)/sizeof(gpio_permit_out[0]);
    while (i--){
        if (gpio_permit_out[i]==gpio) return 1;
    }
    return 0;
}

int gpio_out_init(int gpio){
    int io,iodir;
    int ioval;
    char buf_path[128];

    if ((io = open("/sys/class/gpio/export", O_WRONLY))<0) {
        syslog (LOG_ERR, "export path not exist");
        return -1;
    }
    lseek(io,0,SEEK_SET);
    dprintf(io,"%d",gpio);
    //fflush(io);

    snprintf( buf_path, sizeof(buf_path), "/sys/class/gpio/gpio%d/direction", gpio);
    if ((iodir = open(buf_path, O_WRONLY))<0) {
        syslog (LOG_ERR, "path not exist: %s", buf_path);
        return -1;
    }
    lseek(iodir,0,SEEK_SET);
    dprintf(iodir,"out");
    //fflush(iodir);

    snprintf( buf_path, sizeof(buf_path), "/sys/class/gpio/gpio%d/value", gpio);
    if ((ioval = open(buf_path, O_WRONLY))<0) {
        syslog (LOG_ERR, "path not exist: %s", buf_path);
        return -1;
    }
    lseek(ioval,0,SEEK_SET);

    /*while(1)
    {
        fprintf(ioval,"%d",1);
        fflush(ioval);
        sleep(1);
        fprintf(ioval,"%d",0);
        fflush(ioval);
        sleep(1);
    }
    */
    close(io);
    close(iodir);
    //fclose(ioval);
    return ioval;
}

void gpio_out_deinit(int fd){
    close(fd);
}

int gpio_out_write(int fd, int value){
    dprintf(fd,"%d",value);
    //fflush(fd);
}

int create_pid_file(const char *pid_file, int pid){
    int fd_pid_file;
    char str[128];
    char *target = str;
    target += snprintf(target, sizeof(str)-(target-str),"%s", pid_file);
    target += snprintf(target, sizeof(str)-(target-str),".%d.pid", pid);
    
    if ((fd_pid_file = open(str, O_WRONLY | O_APPEND | O_CREAT))<0) {
        return -1;
    }
    dprintf(fd_pid_file,"%d\n", pid);
    return fd_pid_file;
    //strncpy(buf,settings->pid_file,sizeof(buf)-1);
}

int delete_pid_file(int pid){
    char str[128];
    char path[256];
    snprintf(str, sizeof(str)-1, "/proc/self/fd/%d",pid);
    int n = readlink(str, path, sizeof(path)-1);
    path[n]='\0';
    syslog (LOG_NOTICE, "Unlink");
    syslog (LOG_NOTICE, "Unlink: %s", path);
    return unlink(path);
}
//
