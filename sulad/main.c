#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <uart.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <syslog.h>


/**
 * TCP Uses 2 types of sockets, the connection socket and the listen socket.
 * The Goal is to separate the connection phase from the data exchange phase.
 * */
volatile sig_atomic_t flag = 0;
int __listen_sock=0;
#define UART_RX_BUFER_SIZE 512
#define TCP_RX_BUFER_SIZE 512
char __TCPbuffer[TCP_RX_BUFER_SIZE];
char __UARTbuffer[UART_RX_BUFER_SIZE];
int sock=0;

struct settings_t{
	const char *uart_device;	/* параметр -D */
	long int uart_speed;		/* параметр -s */
	int uart_data_bits;			/* параметр -b */
    char uart_parity_bit;       /* параметр -p */
    int uart_stop_bit;			/* параметр -s */
    int tcp_port; 				/* параметр -P */
    char **inputFiles;          /* входные файлы */
    int numInputFiles;          /* число входных файлов */
} settings;
 


static void skeleton_daemon();

void display_usage();
int set_option(struct settings_t *settings, int argc, char *argv[]);

void scallback(int sig){
    syslog (LOG_NOTICE, "Send SIGINT\n");
    close(sock);
    close(__listen_sock);
    exit(0);
}

int main(int argc, char *argv[]) {
	pid_t pid;
	int uart_fd;
	
	skeleton_daemon();
	
	set_option(&settings, argc, argv);
	syslog (LOG_NOTICE, "SuLa UART <=> TCP daemon started.");
	
    signal(SIGINT, scallback);
    
    if ((uart_fd=uart_init(settings.uart_device, 
    						settings.uart_speed,
    						settings.uart_data_bits,
    						settings.uart_parity_bit,
    						settings.uart_stop_bit))<0) {
    	syslog (LOG_ERR, "could not set uart:uart_init()\n");
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
		syslog (LOG_ERR, "could not create listen socket\n");
		return 1;
	}

	// bind it to listen to the incoming connections on the created server
	// address, will return -1 on error
	if ((bind(__listen_sock, (struct sockaddr *)&server_address,
	          sizeof(server_address))) < 0) {
		syslog (LOG_ERR, "could not bind socket\n");
		return 1;
	}

	int wait_size = 16;  // maximum number of waiting clients, after which
	                     // dropping begins
	if (listen(__listen_sock, wait_size) < 0) {
		syslog (LOG_ERR, "could not open socket for listening\n");
		return 1;
	}

	// socket address used to store client address
	struct sockaddr_in client_address;
	int client_address_len = 0;

	// run indefinitely
	while (true) {
		// open a new socket to transmit data per connection
		//int sock;
		if ((sock = accept(__listen_sock, (struct sockaddr *)&client_address,
		                &client_address_len)) < 0) {
			syslog (LOG_ERR, "could not open a socket to accept data\n");
			return 1;
		}

		int n = 0;

		/*printf("client connected with ip address: %s\n",
		       inet_ntoa(client_address.sin_addr));*/
		//printf("fffooorking....\n");
		switch(pid=fork()){
			case -1: syslog (LOG_ERR, "fork"); /* произошла ошибка */
        			 exit(1); /*выход из родительского процесса*/
        	case 0: //printf("fork i am here!!!\n");
        			while ((n = read(uart_fd, __UARTbuffer, UART_RX_BUFER_SIZE)) > 0) {
        				//__UARTbuffer[n]=0;
						//printf("UART received: %s", __UARTbuffer);
						// echo received content back
						send(sock, __UARTbuffer, n, 0);
					}
					break;
			default: //printf("Parent here!!!\n");
					// keep running as long as the client keeps the connection open
					while ((n = recv(sock, __TCPbuffer, TCP_RX_BUFER_SIZE, 0)) > 0) {
						//__TCPbuffer[n]=0;
						//printf("TCP received: %s", __TCPbuffer);
						// echo received content back
						//send(sock, __TCPbuffer, n, 0);
						if (write(uart_fd,__TCPbuffer,n)<0){
							syslog (LOG_ERR, "uart write error: '%s'\n", strerror(errno));
						}
					} 
		}

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
    openlog ("sulad", LOG_PID, LOG_DAEMON);
}

int set_option(struct settings_t *settings, int argc, char *argv[]){
	int opt;
	static const char *optString = "D:S:b:p:s:P:h?";
	settings->uart_device="/dev/ttyO2";	/* параметр -D */
	settings->uart_speed=9600;					/* параметр -s */
	settings->uart_data_bits=8;						/* параметр -b */
    settings->uart_parity_bit='n';       			/* параметр -p */
    settings->uart_stop_bit=1;						/* параметр -s */
    settings->tcp_port=9988; 							/* параметр -P */
    settings->inputFiles=NULL;         			/* входные файлы */
    settings->numInputFiles=0;        				/* число входных файлов */
    
    while( (opt = getopt( argc, argv, optString )) != -1 ) {
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