#include <avr/sleep.h>

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

unsigned long zhasnuto_kdy = 0;	// jak dlouho uz je stazeny potik s jasem na 0?

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

// int nebo byte?
int gamma_correct(int vstup, double gamma) {
	 return (int)(0.5 + 255.0 * pow(vstup/255.0, gamma));
};

void DisplayRGB255(int r, int g, int b) {
	r = gamma_correct(r, gammaR);
	g = gamma_correct(g, gammaG);
	b = gamma_correct(b, gammaB);

  analogWrite(ledPinR, r);
  analogWrite(ledPinG, g);         
  analogWrite(ledPinB, b);  
};

// DisplayHSV(0-360, 0.0-1.0, 0.0-1.0);
void DisplayHSV(int Hue360, float Saturation, float Value) {
	// prevzato z Wikipedie: 
	// 	http://en.wikipedia.org/wiki/HSL_and_HSV
	// a taky odtud:
	// 	http://www.unrealwiki.com/HSV-RGB_Conversion

	// Given a color with hue H . [0°, 360°), saturation SHSV . [0, 1], and
	// value V . [0, 1], we first find chroma:
	float Chroma = Value * Saturation;

	// Then we can find a point (R1, G1, B1) along the bottom three faces of
	// the RGB cube, with the same hue and chroma as our color (using the
	// intermediate value X for the second largest component of this color):
	float Hseg = (float)Hue360 / 60;
	float X = Chroma * (1.0 - abs((Hseg/2 - trunc(Hseg/2)) - 1.0));  // [a/2 - int(a/2)] je nahrada fce modulo() pro float.

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
	} else if (Hseg < 6) {
		R = Chroma;
		B = X;
	} else {
		// vyjimka, tohle nesmi nastat
	};

	// Finally, we can find R, G, and B by adding the same amount to each component, to match value:
	float m = Value - Chroma;
	R += m;
	G += m;
	B += m;

	// zkonvertujeme do rozsahu 0 - 255:
	DisplayRGB255(
		trunc(R * 255 + 0.5), 
		trunc(G * 255 + 0.5), 
		trunc(B * 255 + 0.5)
	);

	// FIXME a co gama korekce?
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
  DisplayRGB255(255, 0, 255); delay(500);
  DisplayRGB255(0, 0, 0);
  
  // testy:
  delay(1000);
  DisplayHSV(0, 1.0, 1.0);	// cervena
  delay(500);
  DisplayHSV(0, 1.0, 0.5);	// cervena
  delay(500);
  DisplayHSV(120, 1.0, 1.0);	// zelena
  delay(500);
  DisplayHSV(120, 1.0, 0.5);	// zelena
  delay(500);
  DisplayHSV(240, 1.0, 1.0);	// modra
  delay(500);
  DisplayHSV(240, 1.0, 0.5);	// modra
  delay(500);
  DisplayHSV(0, 0.0, 0.0);	// cerna


//  Serial.begin(9600);
}

void loop()  { 
  int tmpval;
  
  tmpval = 1023 - analogRead(sensorPinHue);  // 0-1023
  int Hue = digitalSmooth(tmpval, SmoothArrayHue);
  tmpval = 1023 - analogRead(sensorPinLightness);  // 0 - 1023
  int Lightness = digitalSmooth(tmpval, SmoothArrayLightness);  
  tmpval = 1023 - analogRead(sensorPinSaturation);   // 0 - 1023
  int Saturation = digitalSmooth(tmpval, SmoothArraySaturation);

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

  // zobraz(faze, (float)value, ((float)Lightness)/1023, ((float)Saturation)/1023);
  DisplayHSV(
    (float)Hue/1023*360, 
    ((float)Lightness)/1023, 
    ((float)Saturation)/1023
  );
  delay(5);
  
  if (Lightness > 0) {	// rozsviceno
	zhasnuto_kdy = millis();
  };
  if ((millis() - zhasnuto_kdy) > (1000L * 60 * 5)) { 	// je zhasnuto dele nez 5 minut, uspim se, at setrim baterky
    // uspime se, definitivne a trvale, tzn. je potreba odpojit baterku aby se obvod znovu probudil:
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);	// kompletni powersave
    sleep_enable();    	// pojistka, defaultne je totiz sleep zakazany a bez tohoto volani se neprovede
    sleep_mode(); 		// timto se konecne uspi. 
    	
    // Po probuzeni by pak pokracoval odtud:
    // FIXME (ale bylo by potreba ho nejdriv NEJAK probudit :-))
    sleep_disable();  	// zakazeme spanek, at se omylem zase hned neuspi
    // a pokracujeme dal ...
    		
    // FIXME co takhle probouzeni casovacem?
    	    
    // A jeste zajistit, abych pri dalsim pruchodu smyckou hned zase hned neusnul, pokud by byl potik porad stazeny na 0: :-)
    zhasnuto_kdy = millis();
  };
}


