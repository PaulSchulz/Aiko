
void setup_microsd (void) {
  Events.addHandler(handler_microsd,1000);
}
  
void handler_microsd (void) {
  Serial.print(".");
}
