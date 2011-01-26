/*

*/

#include <SdFat.h>
#include <Wire.h>
#include <OneWire.h>
#include <Spi.h> // NOT upper-case SPI !!
#include <DallasTemperature.h>
#include "RTClib.h"

#include "BMP085.h"

int ac1;
int ac2;
int ac3;
int b1;
int b2;
int mb;
int mc;
int md;
unsigned int ac4;
unsigned int ac5;
unsigned int ac6;

// const int delay_time = 200;
const unsigned char oversampling_setting = 3;
const unsigned char pressure_waittime[4] = {5, 8, 14, 26};

void bmp085_read_temperature_and_pressure(int* temperature, long* pressure)
{
  int ut = bmp085_read_ut();
  long up = bmp085_read_up();
  long x1, x2, x3, b3, b5, b6, p;
  unsigned long b4, b7;

  //calculate the temperature
  x1 = ((long)ut - ac6) * ac5 >> 15;
  x2 = ((long) mc << 11) / (x1 + md);
  b5 = x1 + x2;
  *temperature = (b5 + 8) >> 4;

  //calculate the pressure
  b6 = b5 - 4000;
  x1 = (b2 * (b6 * b6 >> 12)) >> 11;
  x2 = ac2 * b6 >> 11;
  x3 = x1 + x2;

  if (oversampling_setting == 3) b3 = ((int32_t) ac1 * 4 + x3 + 2) << 1;
  if (oversampling_setting == 2) b3 = ((int32_t) ac1 * 4 + x3 + 2);
  if (oversampling_setting == 1) b3 = ((int32_t) ac1 * 4 + x3 + 2) >> 1;
  if (oversampling_setting == 0) b3 = ((int32_t) ac1 * 4 + x3 + 2) >> 2;

  x1 = ac3 * b6 >> 13;
  x2 = (b1 * (b6 * b6 >> 12)) >> 16;
  x3 = ((x1 + x2) + 2) >> 2;
  b4 = (ac4 * (uint32_t) (x3 + 32768)) >> 15;
  b7 = ((uint32_t) up - b3) * (50000 >> oversampling_setting);
  p = b7 < 0x80000000 ? (b7 * 2) / b4 : (b7 / b4) * 2;

  x1 = (p >> 8) * (p >> 8);
  x1 = (x1 * 3038) >> 16;
  x2 = (-7357 * p) >> 16;
  *pressure = p + ((x1 + x2 + 3791) >> 4);
}

unsigned int bmp085_read_ut()
{
  wire_write_register(0xf4,0x2e);
  delay(5);
  return wire_read_int_register(0xf6);
}

void bmp085_get_cal_data()
{
  ac1 = wire_read_int_register(0xAA);
  ac2 = wire_read_int_register(0xAC);
  ac3 = wire_read_int_register(0xAE);
  ac4 = wire_read_int_register(0xB0);
  ac5 = wire_read_int_register(0xB2);
  ac6 = wire_read_int_register(0xB4);
  b1  = wire_read_int_register(0xB6);
  b2  = wire_read_int_register(0xB8);
  mb  = wire_read_int_register(0xBA);
  mc  = wire_read_int_register(0xBC);
  md  = wire_read_int_register(0xBE);
}

long bmp085_read_up()
{
  wire_write_register(0xf4,0x34+(oversampling_setting<<6));
  delay(pressure_waittime[oversampling_setting]);
  unsigned char msb, lsb, xlsb;
  
  Wire.beginTransmission(BMP085_I2C_ADDRESS);
  Wire.send(0xf6);
  Wire.endTransmission();

  Wire.requestFrom(BMP085_I2C_ADDRESS, 3);
  while(!Wire.available());
  msb = Wire.receive();
  while(!Wire.available());
  lsb |= Wire.receive();
  while(!Wire.available());
  xlsb |= Wire.receive();

  return (((long)msb << 16) | ((long)lsb << 8) | ((long)xlsb)) >> (8 - oversampling_setting);
}

void wire_write_register(unsigned char r, unsigned char v)
{
  Wire.beginTransmission(BMP085_I2C_ADDRESS);
  Wire.send(r);
  Wire.send(v);
  Wire.endTransmission();
}

char wire_read_register(unsigned char r)
{
  unsigned char v;
  Wire.beginTransmission(BMP085_I2C_ADDRESS);
  Wire.send(r); // register to read
  Wire.endTransmission();

  Wire.requestFrom(BMP085_I2C_ADDRESS, 1); // read a byte
  while(!Wire.available());
  v = Wire.receive();
  return v;
}

int wire_read_int_register(unsigned char r)
{
  unsigned char msb, lsb;
  Wire.beginTransmission(BMP085_I2C_ADDRESS);
  Wire.send(r); // register to read
  Wire.endTransmission();

  Wire.requestFrom(BMP085_I2C_ADDRESS, 2); // read a byte
  while(!Wire.available());
  msb = Wire.receive();
  while(!Wire.available());
  lsb = Wire.receive();
  return (((int)msb<<8) | ((int)lsb));
}
