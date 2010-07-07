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


int ledPinR = 9;    // LED connected to digital pin 9
int ledPinG = 10;    // LED connected to digital pin 9
int ledPinB = 11;    // LED connected to digital pin 9

const int BLANK = 255;
const int FULL = 0;

void setup()  { 
  // nothing happens in setup 
} 

void loop()  { 
  // fade in from min to max in increments of 5 points:
  for (int bila=0; bila<=1; bila++) {
  for (int faze=0; faze<=2; faze++) {
  for(int r=0; r<=255; r+=1) { 
//    for(int g=0; g<=255; g+=5) { 
//      for(int b=0; b<=255; b+=5) { 
        int x = 255-r;
        if (faze==0) {  // B => R
            analogWrite(ledPinR, x);         
            analogWrite(ledPinG, bila ? FULL : BLANK);
            analogWrite(ledPinB, 255-x);         
        } else if (faze==1) {  // R => G
            analogWrite(ledPinR, 255-x);         
            analogWrite(ledPinG, x);   
            analogWrite(ledPinB, bila ? FULL : BLANK);               
        } else if (faze==2) {  // G => B
            analogWrite(ledPinR, bila ? FULL : BLANK);         
            analogWrite(ledPinG, 255-x);   
            analogWrite(ledPinB, x);               

        };
//        analogWrite(ledPinC, b);         
        
        delay(3);                            
//      };
//    };
  } ;
  };
  };

            analogWrite(ledPinR, FULL);         
            analogWrite(ledPinG, FULL);         
            analogWrite(ledPinB, FULL);         
  
//  delay(10000);

/*  
  delay(100);

  // fade out from max to min in increments of 5 points:
  for(int fadeValue = 255 ; fadeValue >= 0; fadeValue -=1) { 
    // sets the value (range from 0 to 255):
    analogWrite(ledPin, fadeValue);         
    // wait for 30 milliseconds to see the dimming effect    
    delay(5);                            
  } ;
  
  delay(100);
  */
}


