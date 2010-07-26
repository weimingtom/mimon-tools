int sensorPin = 0;    // select the input pin for the potentiometer
//int brightnessPin = 1;    // select the input pin for the potentiometer

int sensorValue = 0;  // variable to store the value coming from the sensor
int lastSensor = 0;

int auxValue = 0;

int ledPinR = 3;    // LED connected to digital pin 9
int ledPinG = 5;    // LED connected to digital pin 9
int ledPinB = 6;    // LED connected to digital pin 9

const int BLANK = 255;
const int FULL = 0;

#define filterSamples   13              // filterSamples should  be an odd number, no smaller than 3
int sensSmoothArray1 [filterSamples];   // array for holding raw sensor values for sensor1 
//int sensSmoothArray2 [filterSamples];   // array for holding raw sensor values for sensor2 
int digitalSmooth(int rawIn, int *sensSmoothArray){     // "int *sensSmoothArray" passes an array to the function - the asterisk indicates the array name is a pointer
  int j, k, temp, top, bottom;
  long total;
  static int i;
 // static int raw[filterSamples];
  static int sorted[filterSamples];
  boolean done;

  i = (i + 1) % filterSamples;    // increment counter and roll over if necc. -  % (modulo operator) rolls over variable
  sensSmoothArray[i] = rawIn;                 // input new data into the oldest slot

  // Serial.print("raw = ");

  for (j=0; j<filterSamples; j++){     // transfer data array into anther array for sorting and averaging
    sorted[j] = sensSmoothArray[j];
  }

  done = 0;                // flag to know when we're done sorting              
  while(done != 1){        // simple swap sort, sorts numbers from lowest to highest
    done = 1;
    for (j = 0; j < (filterSamples - 1); j++){
      if (sorted[j] > sorted[j + 1]){     // numbers are out of order - swap
        temp = sorted[j + 1];
        sorted [j+1] =  sorted[j] ;
        sorted [j] = temp;
        done = 0;
      }
    }
  }

/*
  for (j = 0; j < (filterSamples); j++){    // print the array to debug
    Serial.print(sorted[j]); 
    Serial.print("   "); 
  }
  Serial.println();
*/

  // throw out top and bottom 15% of samples - limit to throw out at least one from top and bottom
  bottom = max(((filterSamples * 15)  / 100), 1); 
  top = min((((filterSamples * 85) / 100) + 1  ), (filterSamples - 1));   // the + 1 is to make up for asymmetry caused by integer rounding
  k = 0;
  total = 0;
  for ( j = bottom; j< top; j++){
    total += sorted[j];  // total remaining indices
    k++; 
    // Serial.print(sorted[j]); 
    // Serial.print("   "); 
  }

//  Serial.println();
//  Serial.print("average = ");
//  Serial.println(total/k);
  return total / k;    // divide by number of samples
};

void zobraz(int faze, float value, float jas, float bila) {
  float r; float g; float b;

  if (faze==0) {  // B => R
      r = value;
      g = 0;
      b = 255-value;
  } else if (faze==1) {  // R => G
      r = 255-value;
      g = value;
      b = 0;
  } else if (faze==2) {  // G => B
      r = 0;
      g = 255-value;
      b = value;
  } else {
      r = g = b = value;
  };
  
  // nejdriv zbeleni
  r = r + (255-r) * bila;
  g = g + (255-g) * bila;
  b = b + (255-b) * bila;

  // normalizace (napr. zlusta=RGB=0.5/0.5/0 zmeni na 1/1/0
  float m;
  m = r;  // max
  if (g > m) {m = g;};
  if (b > m) {m = b;};
  // a pak skutecna normalizace:
  r = r / m * 255;  
  g = g / m * 255;  
  b = b / m * 255;  
  
  // pak jas
  r = r * jas;
  g = g * jas;
  b = b * jas;
  
  analogWrite(ledPinR, r);         
  analogWrite(ledPinG, g);         
  analogWrite(ledPinB, b);  
  
//  Serial.print("r=");
//  Serial.print(r);
//  Serial.print(", g=");
//  Serial.print(g);
//  Serial.print(", b=");
//  Serial.print(b);  
//  Serial.print(", faze=");
//  Serial.print(faze);
//  Serial.print(", value=");
//  Serial.print(value);
//  Serial.print(", jas=");
//  Serial.print(jas);
//  Serial.print(", bila=");
//  Serial.print(bila);
//  Serial.println();  
};


void setup() {
  // declare the ledPin as an OUTPUT:
  pinMode(ledPinR, OUTPUT);  
  pinMode(ledPinG, OUTPUT);  
  pinMode(ledPinB, OUTPUT);  
  pinMode(sensorPin, INPUT);  
//  pinMode(brightnessPin, INPUT);
//  Serial.begin(9600);

//  for (int faze=0; faze<=2; faze++) {
//    for (int value=0; value<=255; value++) {
//     zobraz(faze, value, 1.0, 0.0);
//     delayMicroseconds(1000);
//    };
//  };
//  for (int i=1; i<=3; i++) {
//    zobraz(3, 255, 0.5, 0.0);
//    delay(200);
//    zobraz(3, 0, 1.0, 0.0);
//    delay(200);
//  };
}

void loop()  { 
  //sensorValue = analogRead(sensorPin);      // 0 - 1023
  // vyhlazeni teto hodnoty:
  
  int rawValue = analogRead(sensorPin);  // 0 - 1023
  sensorValue = digitalSmooth(rawValue, sensSmoothArray1);

  
  float jas = 1.0;
  float bila = 0.0;
//  if (auxValue <= 512) {
//    jas = auxValue;
//    jas = jas / 512;  // 0-1
//    bila = 0;
//  } else {
//    jas = 1;
//    bila = auxValue;
//    bila -= 512;
//    bila /= 512;  // 0-1
//  };
  
  float value = 0;
  int faze = 0;

  // 0 - 1023
  if (sensorValue < 24) {
    value = 0;
    faze = 3;
  } else {
    sensorValue -= 24;  // 0 - 999;
    if (sensorValue <= 250) {
      faze = 0;
      value = sensorValue;
      value = value / 250 * 255;
    } else if (sensorValue <= 500) {
      faze = 1;
      value = sensorValue - 250;    
      value = value / 250 * 255;      
    } else if (sensorValue <= 750) {
      faze = 2;
      value = sensorValue - 500;    
      value = value / 250 * 255;      
    } else {
      faze = 3;
//        value = sensorValue - 750;
//        value = value / 250 * 255;      
      value = 255;
      jas = (sensorValue - 750);  // 0 - 250
      
      if (jas < 50) {
        jas = 0;
      } else {
        jas = (jas-50) / 200;  // aby se to spocitalo jako float
      }
    };
  };
  
  // value = opet 0-255 
// lepsi "pridrzeni" zakladnich hodnot:
//      if (value < 50) {
//        value = 0;
//      } else {
//        value = (value - 50) / (255-50) * 255;
//      };
  
  zobraz(faze, value, jas, bila);

//  delay(200);
    
  delay(10);  
}


