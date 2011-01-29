#ifndef   SELFTEST_CONFIG_H
#define   SELFTEST_CONFIG_H

#define LOG_INTERVAL     1 // mills between entries
#define FILE_OUTPUT      1 // echo data to serial port
#define SERIAL_OUTPUT    0 // echo data to serial port
#define SYNC_INTERVAL 1000 // mills between calls to sync()
#define RESET_RTC_TIME   1

// --- Implmented features --- 
// Comment out to remove feature.

// #define FEATURE_NUM_TIMERS   6

// Serial output
//   This feature is always used. This switch does nothing, but is here
//   for completeness.
#define FEATURE_SERIAL

// micro-sd card
#define FEATURE_MICROSD

// DS1338 -top right-hand corner + button cell
#define FEATURE_RTC

// DS18820 one-wire
//   Running in SLOW (750ms) parasitic mode.
#define FEATURE_DS18820

// barometric pressure sensor (bmp085)
#define FEATURE_BPS

// 3-axis accelerometer
// #define FEATURE_ACCEL

// GPS module
#define FEATURE_GPS

// radiometrix NTX2
#define FEATURE_RADIO
//#define ENABLE_RADIO

// XBee module
// #define FEATURE_XBEE

#endif // SELFTEST_CONFIG_H

