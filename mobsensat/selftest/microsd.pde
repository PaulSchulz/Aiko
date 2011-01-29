// microsd
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;

uint32_t syncTime = 0;     // time of last sync()

void setup_sd_card (void) {
  // initialize the SD card
  if (digitalRead(CARD_DETECT)) {
    error("MicroSD card not inserted.");
  }

  if (!card.init(SPI_HALF_SPEED, SD_CHIP_SELECT)) error("card.init");
  // initialize a FAT volume
  if (!volume.init(card)) error("volume.init");
  // open root directory
  if (!root.openRoot(volume)) error("openRoot");
  
  // create a new file
  char name[] = "LOGGER00.CSV";
  
  // Makes a new incremented filename every time you boot
  for (uint8_t i = 0; i < 100; i++)
  {
    name[6] = i/10 + '0';
    name[7] = i%10 + '0';
    if (file.open(root, name, O_CREAT | O_EXCL | O_WRITE)) break;
  }
  
  if (!file.isOpen()) error("file.create");
  Serial.println("Logging to: ");
  Serial.println(name);

  file.println("utime,dallas,pressure,tempurature,voltage,lat,long");

  file.writeError = 0;
}

void loop_sd_card (void) {
  // Write data to file.
  file.print(now.unixtime());
  file.print(",");
  file.print(oneWireSensors.getTempCByIndex(0));
  file.print(",");
  file.print(pressure);
  file.print(",");
  file.print(temperature);
  file.print(",");
  file.print(voltage);
  file.println("");
					      
  // For testing data writes.
  if (file.writeError) error("write data");
  
  // don't sync too often - requires 2048 bytes of I/O to SD card
  if ((millis() - syncTime) <  SYNC_INTERVAL) return;
  syncTime = millis();
  if (!file.sync()) error("sync");
}



