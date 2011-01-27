#include <AikoEvents.h>
#include <AikoSExpression.h>

using namespace Aiko;

#include "mobsendat_config.h"

void setup() {
  Serial.begin(38400);
 
  #ifdef FEATURE_MICROSD
  setup_microsd();
  #endif
}

void loop() {
  Events.loop();
}

//////////////////////////////////////////////////////////////////////////////
