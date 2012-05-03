#ifndef PTPEN_H
#define PTPEN_H

//#include <qcolor.h>
#include "ptcolor.h"

#include "constants.h"

class PtPen {
 private:
  uint d_width;
  uchar red, green, blue;
  uchar p_red, p_green, p_blue;

 public:
  int brush_method;
  uint density, cloud_density;
  bool antialias;

 public:
  PtPen(void);
  PtPen(const PtColor&, uint w = 0);
  void setDWidth(uint dw);
  uint dwidth(void);

 private:
  void initialize(void);

 public:
  void setColor(const PtColor &);
  PtColor color(void);
  void setWidth(uint);
  uint width(void);
  void setPaperColor(const PtColor &);
  PtColor paperColor(void);

};

#endif // PTPEN_H
