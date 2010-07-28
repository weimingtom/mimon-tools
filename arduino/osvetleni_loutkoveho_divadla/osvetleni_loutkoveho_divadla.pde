const int sensorPinHue = 0;
const int sensorPinLightness = 2;
const int sensorPinSaturation = 1;

const int ledPinR = 3;
const int ledPinG = 6;
const int ledPinB = 5;

const int BLANK = 255;
const int FULL = 0;

#define filterSamples 13            // filterSamples should  be an odd number, no smaller than 3
int SmoothArrayHue [filterSamples];   // array for holding raw sensor values for sensor1 
int SmoothArrayLightness [filterSamples];
int SmoothArraySaturation [filterSamples];




//int sensorValue = 0;  // variable to store the value coming from the sensor
//int lastSensor = 0;
//int auxValue = 0;

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

void zobraz(int faze, float value, float jas, float saturace) {
  float r; float g; float b;

  if (faze==0) {  // R-G
      r = 255-value;
      g = value;
      b = 0;
  } else if (faze==1) {  // G-B
      r = 0;
      g = 255-value;
      b = value;
  } else if (faze==2) {  // B-R
      r = value;
      g = 0;
      b = 255-value;
  } else {
      r = g = b = value;
  };
  
//  // normalizace (napr. zlusta=RGB=0.5/0.5/0 zmeni na 1/1/0
//  float m;
//  m = r;  // max
//  if (g > m) {m = g;};
//  if (b > m) {m = b;};
//  // a pak skutecna normalizace:
//  r = r / m * 255;  
//  g = g / m * 255;  

//  b = b / m * 255;  

  // sytost
  float avg;
  avg = (r + g + b) / 3;
  // a ted:
  // sytost=0 ... barvy by se mely stahnout na prumer
  // sytost=1 ... barvy by mely zustat stejne
  r = avg + (r-avg)*saturace;
  g = avg + (g-avg)*saturace;
  b = avg + (b-avg)*saturace;  
    
  // pak jas
  r = r * jas;
  g = g * jas;
  b = b * jas;

  DisplayRGB255(r, g, b);
  
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

void DisplayRGB255(int r, int g, int b) {
  analogWrite(ledPinR, r);         
  analogWrite(ledPinG, g);         
  analogWrite(ledPinB, b);  
};


void setup() {
  // declare the ledPin as an OUTPUT:
  pinMode(ledPinR, OUTPUT);  
  pinMode(ledPinG, OUTPUT);  
  pinMode(ledPinB, OUTPUT);  
  pinMode(sensorPinHue, INPUT);  
  pinMode(sensorPinLightness, INPUT);  
  pinMode(sensorPinSaturation, INPUT);  
  
  DisplayRGB255(255, 0, 0); delay(500);
  DisplayRGB255(0, 255, 0); delay(500);
  DisplayRGB255(0, 0, 255); delay(500);
  DisplayRGB255(255, 255, 0); delay(500);
  DisplayRGB255(0, 255, 255); delay(500);
  DisplayRGB255(255, 0, 255); delay(5
  00);
  DisplayRGB255(0, 0, 0);

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
  int tmpval;
  
  tmpval = 1023 - analogRead(sensorPinHue);  // 0-1023
  int Hue = digitalSmooth(tmpval, SmoothArrayHue);
  tmpval = 1023 - analogRead(sensorPinLightness);  // 0 - 1023
  int Lightness = digitalSmooth(tmpval, SmoothArrayLightness);  
  tmpval = 1023 - analogRead(sensorPinSaturation);   // 0 - 1023
  int Saturation = digitalSmooth(tmpval, SmoothArraySaturation);

//  int faze = Hue >> 8;  // 0-3 (3ka se nepouziva)
//  int value = (Hue & 0xff);  // 0-255

  int faze = 0;
  int value = 0;
  if (Hue <= 340) { // 0 - 340
    faze = 0;
    value = ((float)Hue) / 340 * 255;
  } else if (Hue <= 682) { // 341- 682
    faze = 1;
    value = ((float)Hue - 341) / 341 * 255;
  } else {  // 683 - 1023
    faze = 2;
    value = ((float)Hue - 683) / 340 * 255;
  };

//
//  Serial.print("hue=");
//  Serial.print(Hue);
//  Serial.print(", Light=");
//  Serial.print(Lightness);
//  Serial.print(", Sat=");
//  Serial.print(Saturation);  
//  Serial.print(", faze=");
//  Serial.print(faze);  
//  Serial.print(", value=");
//  Serial.print(value);  
//  Serial.println();  

  zobraz(faze, (float)value, ((float)Lightness)/1023, ((float)Saturation)/1023);
  delay(5);
}



