#ifndef UART
#define UART

int uart_init(char* device, long int baud_rate, unsigned char ncharb, char parity, unsigned char nstopb);

#endif