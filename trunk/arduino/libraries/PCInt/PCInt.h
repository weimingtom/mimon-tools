// ensure this library description is only included once
#ifndef PCInt_h
#define PCInt_h

// include types & constants of Wiring core API
#include "WProgram.h"

void PCattachInterrupt(uint8_t pin, void (*userFunc)(void), int mode);
void PCdetachInterrupt(uint8_t pin);

#endif


