#include "PCInt.h"

volatile long ticktocks = 0;
long i = 0;

void tick(void) {
  ticktocks++;
}

void tock(void) {
  ticktocks--;
}

void setup()
{
  Serial.begin(9600);
  pinMode(4, INPUT);
  pinMode(5, INPUT);
  delay(3000);
  PCattachInterrupt(4, tick, CHANGE);
  PCattachInterrupt(5, tock, CHANGE);
}

void loop() {
  i++;
  delay(1000);
  Serial.print(i, DEC);
  Serial.print(" ");
  Serial.println(ticktocks);
  if (i > 256) {
    PCdetachInterrupt(4);
    PCdetachInterrupt(5);
  }
}
