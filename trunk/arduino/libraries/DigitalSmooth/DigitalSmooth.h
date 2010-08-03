// ensure this library description is only included once
#ifndef DigitalSmooth_h
#define DigitalSmooth_h

// include types & constants of Wiring core API
#include "WProgram.h"

#define DigitalSmooth_MAX_SAMPLES 31            // filterSamples should  be an odd number, no smaller than 3

class DigitalSmooth
{
  public:
	DigitalSmooth(int nsamples);

	int add(int value);
	int get();

  private:
	int _raw_array[DigitalSmooth_MAX_SAMPLES];
  	int _samples;
	int _counter;
	int	_num_values_used;
};

#endif

