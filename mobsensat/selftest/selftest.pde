/*
 -*- c -*-
  Mobile Sensor Datalogger Selftest

  Test Program for MobSenDat board
  Luke Weston, January 2011

  Written by Paul Schulz
  to report hardware selftests.
  
  Based on software written by Luke Weston, January 2011

  This board uses the following 'board' setting.
    Arduino Pro or ProMini (3.3v 8MHz) w/ ATmega328

  Runs the BMP085 pressure and temperature sensor the DS18B20 and the
  accelerometer and the real-time clock, and reads the battery
  voltage, logging the data to the SD card.

  BMP085 sensor on the I2C bus. Requires the Wire (I2C) library.
  Battery voltage measured through a voltage divider connected to
  analog pin 1.

  Modified from code provided by ladyada
  https://github.com/adafruit/Light-and-Temp-logger

  Required Libraries
  ------------------
  You'll need the SD card and RTC libraries provided by ladyada
  http://www.ladyada.net/make/logshield/download.html

  This requires the Spi arduino library:
  http://www.arduino.cc/playground/Code/Spi

  Note that there is an Arduino SPI library and an Arduino Spi
  library - they are not the same!!
*/

#include "mobsendat_config.h"

#ifdef FEATURE_MICROSD
#include <SdFat.h>
#endif

#ifdef FEATURE_RTC
#include <RTClib.h>
#endif

#ifdef FEATURE_DS18820
#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#endif

#ifdef FEATURE_BPS
#include "BMP085.h"
#endif

#ifdef FEATURE_ACCEL
#include <Spi.h> // NOT upper-case SPI !!
#endif

#ifdef FEATURE_GPS
#include <TinyGPS.h>
#endif

#ifdef FEATURE_RADIO
#endif

#ifdef FEATURE_XBEE
#endif

// serial
#define SERIAL_OUTPUT 1     // send data to serial port
#define SERIAL_SPEED  57600

// pin allocation in hardware
const int SD_CHIP_SELECT     =  9;
const int ONE_WIRE_BUS       =  6;
const int CARD_DETECT        =  7;
const int VOLTAGE_MONITOR    =  1;
const int accelChipSelectPin = 10;
// The other hardware pins used for MISO, MOSI, SCK are fixed.

// -- Global parameters --
// microsd - see microsd.pde

// rtc
#ifdef FEATURE_RTC
RTC_DS1307 RTC;
DateTime now;
#endif

// one-wire temperature
#ifdef FEATURE_DS18820
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature oneWireSensors(&oneWire);
#endif

// bmp085
#ifdef FEATURE_BPS
int raw_temperature = 0;
float pressure      = 0;
long raw_pressure   = 0;
float voltage       = 0.0;
float temperature   = 0.0;
#endif

// accel (adxl345)
#ifdef FEATURE_ACCEL
byte tmp;
byte readData; // The byte that data read from Spi interface will be
               // stored in.
byte fifo[6];  // data read for x,y,z axis from the accelerometer's
               // FIFO buffer.
float x,y,z;   // The ranged x,y,z data.
float range;   // The range of the x,y,z data returned.
#endif

// gps - see gps.pde

// --- Utility Functions ---

void error(char *str)
{
  Serial.print("error: ");
  Serial.println(str);
}


// --- Setup Functions ---

// serial
void setup_serial (void) {
  Serial.begin(SERIAL_SPEED);
}

// microsd - see microsd.pde

// rtc
#ifdef FEATURE_RTC
void setup_rtc (void) {
}
#endif

#ifdef FEATURE_DS18820
void setup_wire (void) {
  Wire.begin();
  oneWireSensors.begin();
}
#endif

#ifdef FEATURE_BPS
void setup_bmp085 (void) {
  bmp085_get_cal_data();
}
#endif

#ifdef FEATURE_ACCEL
void setup_accel (void) {

   Spi.mode((1 << SPE) 
	    | (1 << MSTR)
	    | (1 << CPOL)
	    | (1 << CPHA)
	    | (1 << SPR1)
	    | (1 << SPR0));
  // Set select high, slave disabled waiting to pull low for first exchange
  digitalWrite(accelChipSelectPin, HIGH);

  Serial.print("mode set ");
  delay(4000);

  // Wait for POWER_CTL register to go to correct state
  readData = 0x00;

  while (readData != 0x28) {    
    // POWER_CTL register: measure
    digitalWrite(accelChipSelectPin, LOW);
    Spi.transfer(0x2D);
    Spi.transfer(0x28); // Measure
    digitalWrite(accelChipSelectPin, HIGH);
    delay(5);
    digitalWrite(accelChipSelectPin, LOW);
    Spi.transfer(1<<7 | 0x2D); // Set "read" MSb
    readData = Spi.transfer(0x00); // Send dummy byte to keep clock pulse going!
    digitalWrite(accelChipSelectPin, HIGH);
    delay(1000);
  }

 // Set format
  digitalWrite(accelChipSelectPin, LOW);
  Spi.transfer(0x31);
  Spi.transfer(0x08); 
  digitalWrite(accelChipSelectPin, HIGH);
  delay(5);
  // Readback format
  digitalWrite(accelChipSelectPin, LOW);
  Spi.transfer(1<<7 | 0x31);
  readData = Spi.transfer(0x00); 
  digitalWrite(accelChipSelectPin, HIGH);
  readData = readData & 0x03;
  
  switch (readData)
  {
    case 0:
      range = 2.0;
      break;
    case 1:
      range = 4.0;
      break;
    case 2:
      range = 8.0;
      break;
    case 3:
      range = 16.0;
      break;
  }
  // Set FIFO
  digitalWrite(accelChipSelectPin, LOW);
  Spi.transfer(0x38); // ???
  Spi.transfer(0x00); // ???
  digitalWrite(accelChipSelectPin, HIGH);
  delay(5);
  // Readback FIFO
  digitalWrite(accelChipSelectPin, LOW);
  Spi.transfer(1<<7 | 0x38);
  readData = Spi.transfer(0x00); 
  digitalWrite(accelChipSelectPin, HIGH);
}
#endif

// radio - see radio.pde
// gps - see gps.pde

#ifdef FEATURE_RADIO
// TBD
#endif

#ifdef FEATURE_XBEE
// TBD
#endif

// --- Loop Functions ---

// microsd - see microsd.pde

// rtc
#ifdef FEATURE_RTC
void loop_rtc (void) {
  now = RTC.now();
}
#endif

#ifdef FEATURE_DS18820
void loop_onewire (void) {
  oneWireSensors.requestTemperatures();
}
#endif

#ifdef FEATURE_BPS
void loop_bmp085 (void) {
  bmp085_read_temperature_and_pressure(&raw_temperature, &raw_pressure);
  temperature = (((raw_temperature
		   - (raw_temperature % 10)) / 10) 
		 + (float)((raw_temperature % 10) / (float)10));
  pressure = (raw_pressure / (float)100);
  voltage = ((float)(analogRead(VOLTAGE_MONITOR) / (float)97) + 0.6);
}
#endif

#ifdef FEATURE_ACCEL
void loop_accel (void) {
  // All x,y,z data must be read from FIFO in a multiread burst
  digitalWrite(accelChipSelectPin, LOW);
  // Start reading at 0x32 and set "Read" and "Multi" bits
  Spi.transfer(1<<7 | 1<<6 | 0x32);
  for (int i=0; i<6; i++)
    fifo[i] = Spi.transfer(0x00);
  digitalWrite(accelChipSelectPin, HIGH);
  delay(5);
  // The measurements in the FIFO 10 bit  
  x = (float)((fifo[1]<<8) | fifo[0]) * range / 512.0;
  y = (float)((fifo[3]<<8) | fifo[2]) * range / 512.0;
  z = (float)((fifo[5]<<8) | fifo[4]) * range / 512.0;
}
#endif

// gps - see gps.pde

#ifdef FEATURE_XBEE
// TBD
#endif

// --- Main Functions ---

void setup (void) {
  setup_serial();

#ifdef FEATURE_MICROSD
  setup_sd_card();
#endif

#ifdef FEATURE_RTC
  // TBD
#endif

#ifdef FEATURE_DS18829
  setup_wire();
#endif

#ifdef FEATURE_BPS
  setup_bmp085();
#endif

#ifdef FEATURE_ACCEL
  setup_accel();
#endif

#ifdef FEATURE_GPS
  setup_gps();
#endif

#ifdef FEATURE_RADIO
  setup_radio();
#endif

#ifdef FEATURE_XBEE
  // TBD
#endif

}

void loop (void) {
#ifdef FEATURE_MICROSD
  loop_sd_card();
#endif

#ifdef FEATURE_RTC
  loop_rtc();
#endif

#ifdef FEATURE_DS18820
  loop_onewire();
#endif

#ifdef FEATURE_BPS
  loop_bmp085();
#endif

#ifdef FEATURE_ACCEL
  loop_accel();
#endif

#ifdef FEATURE_GPS
  loop_gps();
#endif

#ifdef FEATURE_RADIO
#ifdef DISABLE_RADIO
  loop_radio();
#endif
#endif

#ifdef FEATURE_XBEE
  // TBD;
#endif
}
