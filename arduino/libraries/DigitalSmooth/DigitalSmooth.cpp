#include "WProgram.h"
#include "DigitalSmooth.h"


DigitalSmooth::DigitalSmooth(int nsamples) {
	if ((nsamples % 2) == 0) { // sude cislo nesmi byt
		nsamples++;
	};
	if (nsamples > DigitalSmooth_MAX_SAMPLES) {
		nsamples = DigitalSmooth_MAX_SAMPLES;	// zariznuti
	};
	if (nsamples < 3) {
		nsamples = 3;	// minimum
	};

	_samples = nsamples;
	_counter = 0;
	_num_values_used = 0;
};

int DigitalSmooth::add(int rawIn) {
	// Serial.print("raw = ");
	_counter = (_counter + 1) % _samples;    // increment counter and roll over if necc. -  % (modulo operator) rolls over variable
	_raw_array[_counter] = rawIn;                 // input new data into the oldest slot

	if (_num_values_used < _samples) {	// pole jeste neni naplnene
		_num_values_used++;
	};

	return get();
};

int DigitalSmooth::get() {
  int j, k, temp, top, bottom;
  long total;
  
  int sorted[DigitalSmooth_MAX_SAMPLES];
  boolean done;

  for (j=0; j<_samples; j++){     // transfer data array into anther array for sorting and averaging
    sorted[j] = _raw_array[j];
  }

  done = 0;                // flag to know when we're done sorting              
  while(done != 1){        // simple swap sort, sorts numbers from lowest to highest
    done = 1;
    for (j = 0; j < (_samples - 1); j++){
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
  bottom = max(((_samples * 15)  / 100), 1); 
  top = min((((_samples * 85) / 100) + 1  ), (_samples - 1));   // the + 1 is to make up for asymmetry caused by integer rounding
  k = 0;
  total = 0;
  for ( j = bottom; j< top; j++){
    total += sorted[j];  // total remaining indices
    k++; 
    // Serial.print(sorted[j]); 
    // Serial.print("   "); 
  }

 int ret = total/k; 
 
// dbg("average(");
// dbg(rawIn);
// dbg(")=");
// dbg(ret);
// dbg("\n");
 
 return ret;
};

