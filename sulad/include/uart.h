#ifndef UART
#define UART

int uart_init(const char* device, long int baud_rate, unsigned char ncharb, char parity, unsigned char nstopb, int *baud_base, int *custom_divisor);

#endif