/* vim: set expandtab tabstop=2 shiftwidth=2 filetype=c: */

#include <avr/sleep.h>
#include <stdio.h>
#include <DigitalSmooth.h>

// #define DEBUG 1
#define USE_GAMMMA 1

#ifdef DEBUG
  #define dbg(x) Serial.print(x);
#else
  #define dbg(x) ;
#endif

const int sensorPinHue = 0;
const int sensorPinLightness = 2;
const int sensorPinSaturation = 1;

const int ledPinR = 3;
const int ledPinG = 6;
const int ledPinB = 5;

// gama korekce, aby (pri spravne serizene bile) nemely jednotlive tmavsi odstiny barevny nadech:
// POZOR, funguje opacne:
//   1 ... neutral
//  <1 ... jasnejsi
//  >1 ... tmavsi
#ifdef USE_GAMMA
const float gammaR = 1.1;
const float gammaG = 0.9;
const float gammaB = 1.1;
#endif

#define filterSamples 13            // filterSamples should  be an odd number, no smaller than 3
DigitalSmooth hue_avg = DigitalSmooth(filterSamples);
DigitalSmooth lightness_avg = DigitalSmooth(filterSamples);
DigitalSmooth saturation_avg = DigitalSmooth(filterSamples);

unsigned long zhasnuto_kdy = 0; // jak dlouho uz je stazeny potik s jasem na 0?

// int nebo byte?
#ifdef USE_GAMMA
int gamma_correct(int vstup, double gamma) {
     return (int)(0.5 + 255.0 * pow(vstup/255.0, gamma));
};
#else
int gamma_correct(int vstup, double gamma) {return vstup;};
#endif

void DisplayRGB255(int r, int g, int b) {
#ifdef USE_GAMMA  
  int r2 = gamma_correct(r, gammaR);
  int g2 = gamma_correct(g, gammaG);
  int b2 = gamma_correct(b, gammaB);
   dbg("_R=");
   dbg(r2);
   dbg(", _G=");
   dbg(g2);
   dbg(", _B=");
   dbg(b2);
   dbg("\n");
  analogWrite(ledPinR, r2);
  analogWrite(ledPinG, g2);         
  analogWrite(ledPinB, b2);
#else
  analogWrite(ledPinR, r);
  analogWrite(ledPinG, g);         
  analogWrite(ledPinB, b);
#endif
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


// Jak to, ze:
// H=360, Sytost=1.00, Jas=0.36, Hseg=6.00, Chroma=0.36, X=0.00, m=0.00, R=93, G=51, B=0
// ???
// Uaaaaaaaaaa, neinicializovana promenna!
    float R = 0;
    float G = 0;
    float B = 0;
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

    int R255 = trunc(R * 255 + 0.5);
    int G255 = trunc(G * 255 + 0.5);
    int B255 = trunc(B * 255 + 0.5);    

#ifdef DEBUG
  Serial.print("H=");
  Serial.print(Hue360);  
  Serial.print(", Sytost=");
  Serial.print(Saturation);  
  Serial.print(", Jas=");
  Serial.print(Value);  
  Serial.print(", Hseg=");
  Serial.print(Hseg);  
  Serial.print(", Chroma=");
  Serial.print(Chroma);  
  Serial.print(", X=");
  Serial.print(X);  
  Serial.print(", m=");
  Serial.print(m);  
  Serial.print(", R=");
  Serial.print(R255);  
  Serial.print(", G=");
  Serial.print(G255);  
  Serial.print(", B=");
  Serial.print(B255);  
  Serial.println();
#endif

    // zkonvertujeme do rozsahu 0 - 255.
    // O gama korekci se postara primo funkce DisplayRGB255:
    DisplayRGB255(R255, G255, B255);
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
  Serial.begin(38400);
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
  int Lightness  =  lightness_avg.add(1023 - analogRead(sensorPinLightness));
  int Saturation = saturation_avg.add(analogRead(sensorPinSaturation));
  int Hue        =        hue_avg.add(1023 - analogRead(sensorPinHue));

//  dbg("Hue=%d, Light=%d, Sat=%d\n", Hue, Lightness, Saturation);

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
    // naposledy zablikame:
    DisplayHSV(0, 0, 1.0); delay(100);  DisplayHSV(0, 1.0, 0.0); delay(500);
    DisplayHSV(0, 0, 1.0); delay(100);  DisplayHSV(0, 1.0, 0.0); delay(500);
    DisplayHSV(0, 0, 1.0); delay(100);  DisplayHSV(0, 1.0, 0.0); delay(500);
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

