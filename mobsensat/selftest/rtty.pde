// RTTY Functions

#define PIN_RTTY_ENABLE     5
#define PIN_RTTY_SPACE      A2
#define PIN_RTTY_MARK       A3

// RTTY Functions & Settings
#define     ASCII_LENGTH    7
#define     RTTY_BAUD_RATE  300

/* Timer2 reload value, globally available */  
unsigned int tcnt2;

boolean txLock = false;
int current_tx_byte = 0;
short current_byte_position;

char rttyBuffer[70];
char txBuffer[70];

void rtty_txstring(char *string) {
  if(txLock == false){	 	
    strcpy(rttyBuffer, string);	 	
    current_tx_byte = 0;
    current_byte_position = 0;
    txLock = true;
  }
}

void MobSenDat_setupRTTY(void) {
  // Just so I can test without activating the GPS.
  pinMode(PIN_RTTY_MARK, OUTPUT);
  pinMode(PIN_RTTY_SPACE, OUTPUT);
  pinMode(PIN_RTTY_ENABLE, OUTPUT);
    
  TIMSK2 &= ~(1<<TOIE2);  
  
  /* Configure timer2 in normal mode (pure counting, no PWM etc.) */  
  TCCR2A &= ~((1<<WGM21) | (1<<WGM20));  
  TCCR2B &= ~(1<<WGM22);  
  
  /* Select clock source: internal I/O clock */  
  ASSR &= ~(1<<AS2);  
  
  /* Disable Compare Match A interrupt enable (only want overflow) */  
  TIMSK2 &= ~(1<<OCIE2A);  

  /* Now configure the prescaler to CPU clock divided by 128 */  
  TCCR2B |= (1<<CS22)  | (1<<CS20); // Set bits  
  TCCR2B &= ~(1<<CS21);             // Clear bit  

  /* We need to calculate a proper value to load the timer counter. 
   * The following loads the value 131 into the Timer 2 counter register 
   * The math behind this is: 
   * (CPU frequency) / (prescaler value) = 62500 Hz = 16us. 
   * (desired period) / 8us = 208. 
   * MAX(uint8) + 1 - 208 = 45; 
   */  

  /* Save value globally for later reload in ISR */  
  tcnt2 = 45; // Set for 300 baud on a 8MHz clock.  

  /* Finally load end enable the timer */  
  TCNT2 = tcnt2;  
  TIMSK2 |= (1<<TOIE2);  
}


ISR(TIMER2_OVF_vect) {  
  TCNT2 = tcnt2; // Reset timer2 counter.
  
  if(txLock){
    // Pull out current byte
    char current_byte = rttyBuffer[current_tx_byte];
  
    // Null character? Finish transmitting
    if(current_byte == 0){
      txLock = false;
      return;
    }
      
    int current_bit = 0;
      
    if(current_byte_position == 0){ // Start bit
      current_bit = 0;
    } else if(current_byte_position == (ASCII_LENGTH + 1)){ // Stop bit
      current_bit = 1;
    } else { // Data bit
      current_bit = 1&(current_byte>>(current_byte_position-1));
    }
  
    Serial.print(current_bit);

    // Transmit!
    rtty_txbit(current_bit);

    // Increment all our counters.
    current_byte_position++;
  
    if(current_byte_position==(ASCII_LENGTH + 2)){
      current_tx_byte++;
      current_byte_position = 0;
    }
  }
}

/*
// Transmit a string, one char at a time
void rtty_txstring (char *string) {
	//dummySerial.read();
	for (int i = 0; i < strlen(string); i++) {
		rtty_txbyte(string[i]);
	}
}
*/

// Transmit a byte, bit by bit, LSB first
// ASCII_BIT can be either 7bit or 8bit
void rtty_txbyte (char c) {
  int i;
  // Start bit
  rtty_txbit (0);
  // Send bits for for char LSB first	
  for (i=0;i<ASCII_LENGTH;i++) {
    if (c & 1) rtty_txbit(1); 
    else rtty_txbit(0);	
    c = c >> 1;
  }
  // Stop bit
  rtty_txbit (1);
}

// Transmit a bit as a mark or space
void rtty_txbit (int bit) {
  if (bit) {
    // High - mark
    digitalWrite(PIN_RTTY_SPACE, HIGH);
    digitalWrite(PIN_RTTY_MARK, LOW);	

  } else {
    // Low - space
    digitalWrite(PIN_RTTY_MARK, HIGH);
    digitalWrite(PIN_RTTY_SPACE, LOW);
  }
  
  switch (RTTY_BAUD_RATE) {
    
  case 200:
    delayMicroseconds(5050);
    break;
    
  case 300:
    delayMicroseconds(3400);
    break;
    
  case 150:
    delayMicroseconds(6830);
    break;
    
  case 100:
    delayMicroseconds(10300);
    break;
    
  default:
    delayMicroseconds(10000);
    delayMicroseconds(10600);
  }
}

// Send a line of text, with a CRC16 checksum on the end.
void MobSenDat_txLine(char *string) {

  // We need accurate timing, switch off interrupts
  noInterrupts();
	
  // CRC16 checksum
  //  char txSum[6];
  //  unsigned int checkSum = CRC16Sum(string);
  //  sprintf(txSum, "%04X", checkSum);
	
  // TX the string
  rtty_txstring(string);
  // rtty_txstring("*");
  // rtty_txstring(txSum);
  rtty_txstring("\r\n");
	
  // Interrupts back on
  interrupts();
}

void MobSenDat_RadioOn(){
  digitalWrite(PIN_RTTY_ENABLE,HIGH);
}

void MobSenDat_RadioOff(){
  digitalWrite(PIN_RTTY_ENABLE,LOW);
}

/*
unsigned int CRC16Sum(char *string) {
  unsigned int i;
  unsigned int crc;
  crc = 0xFFFF;
  // Calculate the sum, ignore $ sign's
  for (i = 0; i < strlen(string); i++) {
    if (string[i] != '$') crc = _crc_xmodem_update(crc,(uint8_t)string[i]);
  }
  return crc;
}
*/
