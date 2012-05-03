#ifndef PTCOLOR_H
#define PTCOLOR_H

#include "constants.h"

class PtColor {
  public:
    uchar red, green, blue;
    
    PtColor(void);
    PtColor(int, int, int);
    ~PtColor(void);
    
    void setRgb(int, int, int);
};

#endif // PTCOLOR_H
