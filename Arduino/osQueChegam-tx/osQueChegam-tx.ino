//transmitter

#include <VirtualWire.h>  

#undef int
#undef abs
#undef double
#undef float
#undef round

//////////
#define COMMAND_RECEIVE      0x25  // b 0010_0101
#define COMMAND_SYNC         0x5A  // b 0101_1010
#define COMMAND_ENABLE_SYNC  0xD6  // b 1101_0110
#define COMMAND_DISABLE_SYNC 0xB9  // b 1011_1001
#define COMMAND_RANDOM       0xAB  // b 1010_1011

// in millis
#define UPDATE_PERIOD 1000
#define NUM_LIGHTS 60

unsigned char onOff;
unsigned char theMsg[3];
unsigned long transCnt;
unsigned long lastUpdate;


#define NUM_TRANSITIONS (400*8)+1
// leave 0 empty. there's no lamp with id 0
unsigned char theTrans[NUM_LIGHTS+1][NUM_TRANSITIONS/8] = {
  {
    0x00      }
  , {
    0xB6, 0x6D, 0xB6, 0x6D        }
  , {
    0x55, 0x55, 0x55, 0x55        }
  , {
    0xA5, 0xA5, 0xA5, 0xA5        }
  , {
    0x5A, 0x5A, 0x5A, 0x5A        }
};

void setup() {
  Serial.begin(9600);
  vw_set_ptt_inverted(true);    // Required for RF Link module
  vw_setup(1200);               // Bits per sec
  vw_set_tx_pin(7);             // pin 7 is used as the transmit data out into the TX Link module

  lastUpdate = millis();
  transCnt = 0;
}

// to send commands that don't need an id
void sendCommand(unsigned char cmd){
  theMsg[0] = cmd;
  theMsg[1] = 0xFF;
  theMsg[2] = '\0';

  const char * foo = (const char *)theMsg;
  vw_send((uint8_t *)foo, strlen(foo));
  vw_wait_tx();
}

void loop() {
  /// sync !!
  sendCommand(COMMAND_ENABLE_SYNC);

  if((millis() - lastUpdate) > UPDATE_PERIOD){
    for(unsigned char i = 1; i < NUM_LIGHTS+1; i++){
      // leet shit
      onOff = theTrans[i][transCnt/8];
      onOff = (onOff>>(transCnt%8))&0x1;

      theMsg[0] = (COMMAND_RECEIVE<<0x1)|onOff;
      theMsg[1] = i&0xFF;
      theMsg[2] = '\0';

      Serial.print("message: ");
      Serial.print(theMsg[0]);
      Serial.print(" ID: ");
      Serial.print(theMsg[1]);
      Serial.print("\n");

      const char * foo = (const char *)theMsg;
      vw_send((uint8_t *)foo, strlen(foo));
      vw_wait_tx(); 
    }

    //
    lastUpdate = millis();
    transCnt = (transCnt+1)%(int)(NUM_TRANSITIONS);

    /// sync !!
    sendCommand(COMMAND_SYNC);
  }
}




