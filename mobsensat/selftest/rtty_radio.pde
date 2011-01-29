int lineno=0;

#define MAXLINES 10
char * message[MAXLINES];
int    txline=0;

#define MSG1 1

void setup_message (void) {
#ifdef MSG1
  //            0000000001111111111222222222233333
  // 	        1234567890123456789012345678901234
  message[0] = "    .--.                         \n";
  message[1] = "   |o_o |   Powered by Linux     \n";
  message[2] = "   |:_/ |   Arduino, freetonics  \n";
  message[3] = "  //   ` \\  Free and Open Source \n";
  message[4] = " (|     | ) Software and a G24   \n";
  message[5] = "/'\\_   _/`\\ rocket motor.        \n";
  message[6] = "`___)=(___/                      \n";
  message[7] = "";
#endif
  
#ifdef MSG2
  message[0] = "Powered by Linux,    \n";
  message[1] = "Arduino, freetronics,\n";
  message[2] = "Free and Open Source \n";
  message[3] = "Software and a G24   \n";
  message[4] = "rocket motor.        \n";
  message[5] = "";
#endif
}

void setup_radio (void) {
  pinMode(A2, OUTPUT);
  pinMode(A3, OUTPUT);
  pinMode(5, OUTPUT);

#ifdef ENABLE_RADIO
  digitalWrite(5, HIGH);
  MobSenDat_setupRTTY();
#else
  digitalWrite(5, LOW);
#endif

  setup_message();

}

void loop_radio (void) {
  if(!txLock) return;
     
  MobSenDat_txLine(message[txline]);
  txline++;
  if(message[txline] == 0) {
    txline = 0;
  }

}    
