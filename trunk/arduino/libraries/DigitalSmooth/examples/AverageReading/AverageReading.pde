/* vim: set expandtab tabstop=2 shiftwidth=2 filetype=c: */

#include <DigitalSmooth.h>

const int sensorPinHue = 0;
const int sensorPinLightness = 2;
const int sensorPinSaturation = 1;

#define filterSamples 13            // filterSamples should  be an odd number, no smaller than 3
DigitalSmooth hue_avg = DigitalSmooth(filterSamples);
DigitalSmooth lightness_avg = DigitalSmooth(filterSamples);
DigitalSmooth saturation_avg = DigitalSmooth(filterSamples);

void setup() {
  pinMode(sensorPinHue, INPUT);  
  pinMode(sensorPinLightness, INPUT);  
  pinMode(sensorPinSaturation, INPUT);  
}

void loop()  { 
  int Lightness  =  lightness_avg.add(analogRead(sensorPinLightness));
  int Saturation = saturation_avg.add(analogRead(sensorPinSaturation));
  int Hue        =        hue_avg.add(analogRead(sensorPinHue));
  
  // ...
}

