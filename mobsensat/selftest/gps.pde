// TinyGPS library required
// http://arduiniana.org/libraries/tinygps/
// #include <TinyGPS.h>

TinyGPS gps;
void gpsdump(TinyGPS &gps);
void printFloat(double f, int digits = 2);
bool feedgps();

static int gpsEnable    = 4;
static int updatePeriod = 1000;

void setup_gps()
{
  digitalWrite(gpsEnable, HIGH);
}

void loop_gps()
{
  bool newdata = false;
  unsigned long start = millis();

  // Every 5 seconds we print an update
  while (millis() - start < updatePeriod)
  {
    if (feedgps())
      newdata = true;
  }
  
  if (newdata)
  {
    gpsdump(gps);
    Serial.println();
  }
}

// global variables
float flat, flon;

void gpsdump(TinyGPS &gps)
{
  long lat, lon;
  unsigned long age, date, time, chars;
  int year;
  byte month, day, hour, minute, second, hundredths;
  unsigned short sentences, failed;
  
  feedgps(); // If we don't feed the gps during this long routine, we
             // may drop characters and get checksum errors.

/*
  gps.get_position(&lat, &lon, &age);
  Serial.print("Position: ");
  Serial.print(lat);
  Serial.print(", ");
  Serial.println(lon); 
*/  
  gps.f_get_position(&flat, &flon, &age);
  Serial.print("Position: ");
  printFloat(flat, 5);
  Serial.print(", ");
  printFloat(flon, 5);
  Serial.println();
  feedgps();

  Serial.print("Altitude: ");
  Serial.print(gps.altitude());
  Serial.println(" cm");  
  Serial.print("Course: ");
  Serial.print(gps.course());
  Serial.println(" (centi-degrees)");
  Serial.print("Speed: ");
  printFloat(gps.f_speed_mps());
  Serial.print(" m/s (");
  printFloat(gps.f_speed_kmph());
  Serial.println(" km/h)");

/*
  gps.get_datetime(&date, &time, &age);
  Serial.print("Date(ddmmyy): ");
  Serial.print(date);
  Serial.print(" Time(hhmmsscc): ");
  Serial.print(time);

  feedgps();
*/
  gps.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);
  
  Serial.print("Date: ");
  Serial.print(static_cast<int>(day));
  Serial.print("/");
  Serial.print(static_cast<int>(month));
  Serial.print("/");
  Serial.print(year);
  
  Serial.print("; Time: ");
  Serial.print(static_cast<int>(hour));
  Serial.print(":");
  Serial.print(static_cast<int>(minute));
  Serial.print(":");
  Serial.print(static_cast<int>(second));
  Serial.print(".");
  Serial.println(static_cast<int>(hundredths));
  
  feedgps();
}
  
bool feedgps()
{
  while (Serial.available())
  {
    if (gps.encode(Serial.read()))
      return true;
  }
  return false;
}

void printFloat(double number, int digits)
{
  if (number < 0.0)
  {
     Serial.print('-');
     number = -number;
  }

  double rounding = 0.5;
  for (uint8_t i=0; i<digits; ++i)
    rounding /= 10.0;
  
  number += rounding;

  // Extract the integer part of the number and print it
  unsigned long int_part = (unsigned long)number;
  double remainder = number - (double)int_part;
  Serial.print(int_part);

  // Print the decimal point, but only if there are digits beyond
  if (digits > 0)
    Serial.print("."); 

  // Extract digits from the remainder one at a time
  while (digits-- > 0)
  {
    remainder *= 10.0;
    int toPrint = int(remainder);
    Serial.print(toPrint);
    remainder -= toPrint; 
  } 
}
