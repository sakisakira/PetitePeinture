#ifndef RGB_HSV_H
#define RGB_HSV_H

//#include <qcolor.h>
#include "ptcolor.h"

#include "constants.h"

class RGB_HSV {
  uint red, green, blue;
  uint val, val_min;
  /* note that 0 <= hue < 0x600 */

public:
  void setRGB(uint, uint, uint);
  void setColor(const PtColor &);
  PtColor getColor(void);
  void setPacked(uint16);
  uint16 packed(void);
  static uint luminance(uint, uint, uint);
  uint luminance(void);
  uint hue(void);
  uint chroma(void);
  uint saturation(void);
  uint value(void);
  void setHCL(uint, uint, uint);

  static const uint r_lum = 76;
  static const uint g_lum = 150;
  static const uint b_lum = 30;

private:
  inline uint adjust_r(uint l) {
    return ((l - g_lum - b_lum) << 8) / r_lum;
  }
  inline uint adjust_g(uint l) {
    return ((l - r_lum - b_lum) << 8) / g_lum;
  }
  inline uint adjust_b(uint l) {
    return ((l - r_lum - g_lum) << 8) / b_lum;
  }
};

#endif		// RGB_HSV_H
