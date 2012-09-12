//receiver

#include <VirtualWire.h>  // you must download and install the VirtualWire.h to your hardware/libraries folder
#undef int
#undef abs
#undef double
#undef float
#undef round

/////
// can't have ID of 0 because we can't transmit a byte that's equal to \0
#define MY_ID 0x2

#define STATE_RECEIVE 0x0
#define STATE_SYNC 0x1
#define STATE_RANDOM 0x2

#define COMMAND_RECEIVE      0x25  // b 0010_0101
#define COMMAND_SYNC         0x5A  // b 0101_1010
#define COMMAND_ENABLE_SYNC  0xD6  // b 1101_0110
#define COMMAND_DISABLE_SYNC 0xB9  // b 1011_1001
#define COMMAND_RANDOM       0xAB  // b 1010_1011

unsigned int currentState;
unsigned long lastUpdated;

int go;
int current;
int relayPin = 9;

void setup() {
  Serial.begin(9600);    
  pinMode(relayPin, OUTPUT);

  // Initialise the IO and ISR
  vw_set_ptt_inverted(true);    // Required for RX Link Module
  vw_setup(1200);               // Bits per sec
  vw_set_rx_pin(11);            // We will be receiving on pin 11 (ie the RX pin from the module connects to this pin)
  vw_rx_start();                // Start the receiver 

  current = go = 0;
  currentState = STATE_RECEIVE;
  lastUpdated = millis();

  randomSeed(MY_ID*MY_ID);
}

void loop(){
  uint8_t buf[VW_MAX_MESSAGE_LEN];
  uint8_t buflen = VW_MAX_MESSAGE_LEN;


  // check to see if anything has been received
  if ((currentState != STATE_RANDOM) && (vw_get_message(buf, &buflen))) {
    Serial.print("Received something, buflen = ");
    Serial.println(buflen);
    if(buflen >= 2){
      unsigned char cmd = (buf[0]>>1)&0x7F;
      unsigned char onOff = (buf[0])&0x1;
      unsigned char id = (buf[1])&0xFF;

      // no checksum
      Serial.print("comamnd: ");
      Serial.print(cmd);
      Serial.print(" on/off: ");
      Serial.print(onOff);
      Serial.print(" ID: ");
      Serial.print(id);
      Serial.print("\n");

      // check for command to enable random mode
      if(buf[0] == COMMAND_RANDOM){
        Serial.println("command random");
        currentState = STATE_RANDOM;
      }
      // check for command to enable sync mode
      else if(buf[0] == COMMAND_ENABLE_SYNC){
        Serial.println("command enable sync");
        currentState = STATE_SYNC;
      }
      // check for command to disable sync mode
      else if(buf[0] == COMMAND_DISABLE_SYNC){
        Serial.println("command disable sync");
        currentState = STATE_RECEIVE;
      }
      // check for command to actually sync stuff
      else if(buf[0] == COMMAND_SYNC){
        Serial.println("command sync");
        // immediately update light
        digitalWrite(relayPin, go);
        current = go;
      }
      // receive command
      else if((cmd == COMMAND_RECEIVE) && (id == MY_ID)){
        Serial.println("command receive for my ID");
        // set signal for on/off
        go = onOff;
      }
    }
    //
    lastUpdated = millis();
  }
  // if in random mode, 
  //    pick a random value for on/off variable about every 5 seconds
  else if(currentState == STATE_RANDOM){
    if((millis() - lastUpdated) > random(4000,8000)){
      go = (int)(random(0,2));
      lastUpdated = millis();
    }
  }
  // if it's been a long time since we've seen an update (5 minutes)
  //    we're in RECEIVE mode, but not receiving
  else if((millis() - lastUpdated) > 300000){
    currentState = STATE_RANDOM;
    go = (int)(random(0,2));
    lastUpdated = millis();
  }

  // always do this. even if in random mode. but not in sync mode
  if((go != current) && (currentState != STATE_SYNC)){
    digitalWrite(relayPin, go);
    current = go;
  }

}




