#define ON LOW
#define OFF HIGH

#define SEGMENTS 7
const byte seg1[SEGMENTS] = {
//   2,3,4,5,6,7,8,9
//   6,5,2,8,9,3,4,7
     8,9,4,3,2,6,7  /* boarduino */
};
const byte seg2[SEGMENTS] = {
//     5,10,11,12,13,14,15
     11,12,5,15,13,10,14
};

#define segA 10
#define segB 11
#define segC 12
#define segD 13
#define segE 14
#define segF 15
#define segG 16
#define NOTHING 17
const byte font[18] = {
    0b00111111,    // 0
    0b00000110,    // 1
    0b01011011,    // 2
    0b01001111,    // 3
    0b01100110,    // 4
    0b01101101,    // 5
    0b01111101,    // 6
    0b00000111,    // 7
    0b01111111,    // 8
    0b01101111,    // 9
    
    0b0000001,    // segA
    0b0000010,    // segB
    0b0000100,
    0b0001000,
    0b0010000,
    0b0100000,    // segF
    0b1000000,    // segG
    0b0000000,    // NITHING
};

int cur1[SEGMENTS];
int cur2[SEGMENTS];
long int lastmillis;   

void setup()   {                
  // initialize the digital pin as an output:
  for (int i=0; i<SEGMENTS; i++) {
    cur1[i] = OFF;
    cur2[i] = OFF;
    pinMode(seg1[i], OUTPUT);
    pinMode(seg2[i], OUTPUT);
    digitalWrite(seg1[i], OFF);
    digitalWrite(seg2[i], OFF);
  };    
  
//  // vizualni prirazeni pinu:
//  for(;;) {
//    for (int i=0; i<SEGMENTS; i++) {
//      digitalWrite(seg1[i], ON);
//      digitalWrite(seg2[i], ON);
//      delay(1000);
//      digitalWrite(seg1[i], OFF);
//      digitalWrite(seg2[i], OFF);
//    };
//    delay(2000);
//  };
}

// na chvilku zobrazi konkretni cislici. Musi se volat v cyklu:
void display(byte digit1, byte digit2) {  
  byte bitmap1 = font[digit1];  // ktere piny maji byt rozsvicene
  byte bitmap2 = font[digit2];  // ktere piny maji byt rozsvicene

  // zkonvertuji si to primo na mapu pinu:
  byte map1[SEGMENTS];
  byte map2[SEGMENTS];
  for (int i=0; i<SEGMENTS; i++) {
    map1[i] = (bitmap1 & 0x01) ? ON : OFF;
    map2[i] = (bitmap2 & 0x01) ? ON : OFF;
    bitmap1 >>= 1;
    bitmap2 >>= 1;
  };

// rozsviti co je potreba
  for (int i=0; i<SEGMENTS; i++) {
    digitalWrite(seg1[i], map1[i]);
    digitalWrite(seg2[i], map2[i]);
// chvili pocka
  delayMicroseconds(200);
// a vsechno zhasne
    digitalWrite(seg1[i], OFF);
    digitalWrite(seg2[i], OFF);
  };
};

void display_and_wait(byte digit1, byte digit2, int milis) {  
    int lastmillis = millis();
    // refreshuje obraz dokud je to potreba:
    while (millis() - lastmillis < milis) {
      display(digit1, digit2);
    };
};

void loop() {
  for (int i=0; i<=10; i++) {
    // kazde cislo budu zobrazovat 1 vterinu:
    display_and_wait(i/10, i%10, 1000);
  };
  for (int i=99; i>=0; i--) {
    // kazde cislo budu zobrazovat 1/20 vteriny
    display_and_wait(i/10, i%10, 50);
  };
  // zablikame
  for (int i=1; i<=3; i++) {
    display_and_wait(0, 0, 500);
    display_and_wait(NOTHING, NOTHING, 500);
  };

//  // rotace:  
//  for (int i=0; i<SEGMENTS; i++) {
//    digitalWrite(seg1[i], OFF);
//    digitalWrite(seg2[i], OFF);
//  };
//  for (int j=1; j<5; j++) {
//    for (int i=0; i<=5; i++) {  // rozsvecim vse krome prostredni carky
//      lastmillis = millis();
//      while (millis() - lastmillis < 50) {    
//        digitalWrite(seg1[i], ON);      
//        delayMicroseconds(10);
//        digitalWrite(seg1[i], OFF);
//
//        digitalWrite(seg2[i], ON);      
//        delayMicroseconds(10);
//        digitalWrite(seg2[i], OFF);
//      };
//    };
//  };
  
  // jina rotace
  for(int i=0;i<5;i++) {
    display_and_wait(segA, NOTHING, 100);
    display_and_wait(NOTHING, segA, 100);
    display_and_wait(NOTHING, segB, 100);
    display_and_wait(NOTHING, segC, 100);
    display_and_wait(NOTHING, segD, 100);
    display_and_wait(segD, NOTHING, 100);
    display_and_wait(segE, NOTHING, 100);
    display_and_wait(segF, NOTHING, 100);
  };
  
  for(int i=0;i<5;i++) {
    display_and_wait(segA, NOTHING, 100);
    display_and_wait(NOTHING, segA, 100);
    display_and_wait(NOTHING, segB, 100);
    display_and_wait(NOTHING, segG, 100);
    display_and_wait(segG, NOTHING, 100);
    display_and_wait(segE, NOTHING, 100);
    display_and_wait(segD, NOTHING, 100);
    display_and_wait(NOTHING, segD, 100);
    display_and_wait(NOTHING, segC, 100);
    display_and_wait(NOTHING, segG, 100);
    display_and_wait(segG, NOTHING, 100);
    display_and_wait(segF, NOTHING, 100);
  };  
}
