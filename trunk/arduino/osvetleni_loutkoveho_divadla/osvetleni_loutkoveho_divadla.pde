/* vim: set expandtab tabstop=2 shiftwidth=2 filetype=c: */

#include <avr/sleep.h>
#include <stdio.h>

// #define DEBUG 1

const int sensorPinHue = 0;
const int sensorPinLightness = 2;
const int sensorPinSaturation = 1;

const int ledPinR = 3;
const int ledPinG = 6;
const int ledPinB = 5;

// gama korekce, aby (pri spravne serizene bile) nemely jednotlive tmavsi odstiny barevny nadech:
const float gammaR = 0.8;
const float gammaG = 1.1;
const float gammaB = 0.8;

#define filterSamples 13            // filterSamples should  be an odd number, no smaller than 3
int SmoothArrayHue [filterSamples];   // array for holding raw sensor values for sensor1 
int SmoothArrayLightness [filterSamples];
int SmoothArraySaturation [filterSamples];

unsigned long zhasnuto_kdy = 0; // jak dlouho uz je stazeny potik s jasem na 0?

void dbg(char *fmt, ... ) {
#ifdef DEBUG
        char tmp[200]; // resulting string limited to 200 chars
        va_list args;
        va_start (args, fmt );
        vsnprintf(tmp, 200, fmt, args);
        va_end (args);
        Serial.print(tmp);
#endif
}

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

// int nebo byte?
int gamma_correct(int vstup, double gamma) {
     return (int)(0.5 + 255.0 * pow(vstup/255.0, gamma));
};

void DisplayRGB255(int r, int g, int b) {
  int r2 = gamma_correct(r, gammaR);
  int g2 = gamma_correct(g, gammaG);
  int b2 = gamma_correct(b, gammaB);

  dbg("RGB(%d, %d, %d) corrected to (%d, %d, %d)\n", r, g, b, r2, g2, b2);

  analogWrite(ledPinR, r2);
  analogWrite(ledPinG, g2);         
  analogWrite(ledPinB, b2);  
};

// DisplayHSV(0-360, 0.0-1.0, 0.0-1.0);
void DisplayHSV(int Hue360, float Saturation, float Value) {
    // prevzato z Wikipedie: 
    //  http://en.wikipedia.org/wiki/HSL_and_HSV
    // a taky odtud:
    //  http://www.unrealwiki.com/HSV-RGB_Conversion

    // Given a color with hue H . [0°, 360°), saturation SHSV . [0, 1], and
    // value V . [0, 1], we first find chroma:
    float Chroma = Value * Saturation;

    // Then we can find a point (R1, G1, B1) along the bottom three faces of
    // the RGB cube, with the same hue and chroma as our color (using the
    // intermediate value X for the second largest component of this color):
    float Hseg = (float)Hue360 / 60; // 0.0 - 6.0
      // 0-1 = R ... R+G  (G^)
      // 1-2 = R+G ... G  (Rv)
      // 2-3 = G ... G+B  (B^)
      // 3-4 = G+B ... B  (Gv)
      // 4-5 = B ... B+R  (R^)
      // 5-6 = 
    float X = Chroma * (1.0 - abs(2*(Hseg/2 - trunc(Hseg/2)) - 1.0));  // [a/2 - int(a/2)] je nahrada fce modulo() pro float.

    float R, G, B = 0;
    if (Hseg < 1) {
        R = Chroma;
        G = X;
    } else if (Hseg < 2) {
        R = X;
        G = Chroma;
    } else if (Hseg < 3) {
        G = Chroma;
        B = X;
    } else if (Hseg < 4) {
        G = X;
        B = Chroma;
    } else if (Hseg < 5) {
        R = X;
        B = Chroma;
    } else if (Hseg <= 6) {
        R = Chroma;
        B = X;
    } else {
        // vyjimka, tohle nesmi nastat (a nebo je to 6, co je taky OK, proto "<=" u predchozi podminky
    };

    // Finally, we can find R, G, and B by adding the same amount to each component, to match value:
    float m = Value - Chroma;
    R += m;
    G += m;
    B += m;


    dbg("HSV(%d, %f, %f): Hseg=%f, Chroma=%f, X=%f, m=%f, RGB=%d/%d/%d\n", 
      Hue360, Saturation, Value,
      Hseg, Chroma, X, m,
      R, G, B
     );

    // zkonvertujeme do rozsahu 0 - 255.
    // O gama korekci se postara primo funkce DisplayRGB255:
    DisplayRGB255(
        trunc(R * 255 + 0.5), 
        trunc(G * 255 + 0.5), 
        trunc(B * 255 + 0.5)
    );
};


void setup() {
  // declare the ledPin as an OUTPUT:
  pinMode(ledPinR, OUTPUT);  
  pinMode(ledPinG, OUTPUT);  
  pinMode(ledPinB, OUTPUT);  
  pinMode(sensorPinHue, INPUT);  
  pinMode(sensorPinLightness, INPUT);  
  pinMode(sensorPinSaturation, INPUT);  

#ifdef DEBUG
  Serial.begin(9600);
#endif

  // KALIBRACE:
  // potiky jsou zapojene obracene, takze 1023=vlevo a 0=vpravo)
  if ((analogRead(sensorPinHue) < 5)
      &&
      (analogRead(sensorPinLightness) < 5)
      &&
      (analogRead(sensorPinSaturation) < 5)) {
    // vsechny jsou otocene plne doprava, prepnu se na kalibracni rezim
      while ((analogRead(sensorPinLightness) < 5) && (analogRead(sensorPinSaturation) < 5)) {  
        // DOKUD jsou prvni dva otocene plne doprava, kalibruji.
        if (analogRead(sensorPinHue) < 256) {
          DisplayRGB255(255, 0, 0);     // cervena
        } else if (analogRead(sensorPinHue) < 512) {
          DisplayRGB255(0, 255, 0);     // modra
        } else if (analogRead(sensorPinHue) < 768) {
          DisplayRGB255(0, 0, 255);     // zelena
        } else {
          DisplayRGB255(255, 255, 255); // bila, vsechny naplno
        };
      };
      // nekdo pohnul s prvnim dvema potiky, takze kalibraci koncim
  };

//  DisplayRGB255(255, 0, 0); delay(500);
//  DisplayRGB255(0, 255, 0); delay(500);
//  DisplayRGB255(0, 0, 255); delay(500);
//  DisplayRGB255(255, 255, 0); delay(500);
//  DisplayRGB255(0, 255, 255); delay(500);
//  DisplayRGB255(255, 0, 255); delay(500);
//  DisplayRGB255(0, 0, 0);
//  
//  // testy:
//  delay(1000);
  for (int i=0; i<360; i+=60) {
    DisplayHSV(i, 1.0, 1.0);  // cervena
    delay(200);
  };
  DisplayHSV(0, 0.0, 0.0);  // cerna
}

void loop()  { 
  int tmpval;
  
  tmpval = 1023 - analogRead(sensorPinHue);  // 0-1023
  int Hue = digitalSmooth(tmpval, SmoothArrayHue);
  tmpval = 1023 - analogRead(sensorPinLightness);  // 0 - 1023
  int Lightness = digitalSmooth(tmpval, SmoothArrayLightness);  
  tmpval = 1023 - analogRead(sensorPinSaturation);   // 0 - 1023
  int Saturation = digitalSmooth(tmpval, SmoothArraySaturation);

  dbg("Hue=%d, Light=%d, Sat=%d\n", Hue, Lightness, Saturation);

  DisplayHSV(
    (float)Hue/1023*360,  
    ((float)Saturation)/1023,
    ((float)Lightness)/1023   
  );
  delay(5);
  
  if (Lightness > 5) {  // rozsviceno, aspon trochu
    zhasnuto_kdy = millis();
  };
  if ((millis() - zhasnuto_kdy) > (1000L * 60 * 5)) {   // je zhasnuto dele nez 5 minut, uspim se, at setrim baterky
    dbg("sleep");
    // uspime se, definitivne a trvale, tzn. je potreba odpojit baterku aby se obvod znovu probudil:
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);    // kompletni powersave
    sleep_enable();     // pojistka, defaultne je totiz sleep zakazany a bez tohoto volani se neprovede
    sleep_mode();       // timto se konecne uspi. 
        
    // Po probuzeni by pak pokracoval odtud:
    // FIXME (ale bylo by potreba ho nejdriv NEJAK probudit :-))
    sleep_disable();    // zakazeme spanek, at se omylem zase hned neuspi
    dbg("wakeup");
    // a pokracujeme dal ...
            
    // FIXME co takhle probouzeni casovacem?
            
    // A jeste zajistit, abych pri dalsim pruchodu smyckou hned zase hned neusnul, pokud by byl potik porad stazeny na 0: :-)
    zhasnuto_kdy = millis();
  };
}


