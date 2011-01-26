/*

 */

#ifndef BMP085_h
#define BMP085_h

#define BMP085_I2C_ADDRESS 0x77

void bmp085_read_temperature_and_pressure(int* temperature, long* pressure);
unsigned int bmp085_read_ut();
void bmp085_get_cal_data();
long bmp085_read_up();
void wire_write_register(unsigned char r, unsigned char v);
char wire_read_register(unsigned char r);
int wire_read_int_register(unsigned char r);

#endif
