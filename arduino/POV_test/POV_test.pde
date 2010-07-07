/*
 Fading
 
 This example shows how to fade an LED using the analogWrite() function.
 
 The circuit:
 * LED attached from digital pin 9 to ground.
 
 Created 1 Nov 2008
 By David A. Mellis
 Modified 17 June 2009
 By Tom Igoe
 
 http://arduino.cc/en/Tutorial/Fading
 
 */
 

const int NUMPINS = 10;
const int SVITI = LOW;
const int NESVITI = HIGH;
                          // nahore   ... dole 
const int pins[NUMPINS] = {9,8,7,6,5,4,3,2,1,0};

void send(int co) {
  for (int i = 0; i < NUMPINS; i++) {
    digitalWrite(pins[i], (co & 0x01) ? SVITI : NESVITI);
    co >>= 1;
  };  
  delayMicroseconds(3000);
};

void setup()  { 
  // nothing happens in setup 
  for (int i = 0; i < NUMPINS; i++) {
    pinMode(pins[i], OUTPUT);
    digitalWrite(pins[i], NESVITI);
  };
  
//  for(;;) {
  for (int i = 0; i < NUMPINS; i++) {
    digitalWrite(pins[i], SVITI);
    delay(50);
  };
  for (int i = 0; i < NUMPINS; i++) {
    digitalWrite(pins[i], NESVITI);
    delay(50);
  };
  delay(500);
  for (int i = NUMPINS; i>=0; i--) {
    digitalWrite(pins[i], SVITI);
    delay(50);
  };
  for (int i = NUMPINS; i>=0; i--) {
    digitalWrite(pins[i], NESVITI);
    delay(50);
  };
  delay(500);
//  };

} 

void loop()  { 
  // fade in from min to max in increments of 5 points:
  for (;;) {
   // SIPKA:
    send(0b0000000000);
    send(0b0000110000);
    send(0b0000110000);
    send(0b0000110000);
    send(0b0000110000);
    send(0b1000110001);
    send(0b0100110010);
    send(0b0010110100);
    send(0b0001111000);
    send(0b0000110000);
    send(0b0000000000);
    send(0b0000000000);
    
    
//    // FIFA:
    send(0b000000);
    send(0b111111);
    send(0b000101);
    send(0b000101);
    send(0b000000);
    send(0b111111);
    send(0b000000);
    send(0b111111);
    send(0b000101);
    send(0b000101);
    send(0b000000);
    send(0b111100);
    send(0b001011);
    send(0b111100);
    send(0b000000);
  };
}


