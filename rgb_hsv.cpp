/**
 **	rgb_hsv.cpp
 **	RGB_HSV, RGB <--> HSV(L) converter
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 July 27
 */

#include <stdio.h>

#include "rgb_hsv.h"

inline void RGB_HSV::setRGB(uint r, uint g, uint b) {
  red = r;
  green = g;
  blue = b;

  val = max(r, max(g, b));
  val_min = min(r, min(g, b));
}

void RGB_HSV::setColor(const PtColor &col) {
  setRGB(col.red, col.green, col.blue);
}

PtColor RGB_HSV::getColor(void) {
  return PtColor(red, green, blue);
}

void RGB_HSV::setPacked(uint16 p) {
  red = (p >> 8) & 0xf8;
  green = (p >> 3) & 0xf8;
  blue = (p << 2) & 0xf8;

  val = max(red, max(green, blue));
  val_min = min(red, min(green, blue));
}

uint16 RGB_HSV::packed(void) {
  return (red & 0xf8) << 8 | (green & 0xf8) << 3
    | (blue & 0xf8) >> 2;
}

uint RGB_HSV::luminance(uint r, uint g, uint b) {
  return (r_lum * r + g_lum * g + b_lum * b) >> 8;
}

uint RGB_HSV::luminance(void) {
  return luminance(red, green, blue);
}

uint RGB_HSV::hue(void) {
  int c = val - val_min;

  if (c == 0) return 0;
  
  if (val == red)
    return (((int)green - (int)blue) << 8) / c + 0x100;
  else if (val == green)
    return (((int)blue - (int)red) << 8) / c + 0x300;
  else
    return (((int)red - (int)green) << 8) / c + 0x500;
}

uint RGB_HSV::chroma(void) {
  return val - val_min;
}

uint RGB_HSV::saturation(void) {
  if (val)
    return ((val - val_min) << 8) / val;
  else
    return 0;
}

uint RGB_HSV::value(void) {
  return val;
}

void RGB_HSV::setHCL(uint h, uint c, uint l) {
  uint32a c32 = c;
  int r, g, b, h2, *_max, *_mid, *_min;
  int l_mid, l_min;

  if (h < 0x100) {
    _max = &r;
    _min = &g; l_min = g_lum;
    _mid = &b; l_mid = b_lum;
    h2 = 0x100 - h;
  } else if (h < 0x200) {
    _max = &r;
    _min = &b; l_min = b_lum;
    _mid = &g; l_mid = g_lum;
    h2 = h - 0x100;
  } else if (h < 0x300) {
    _max = &g;
    _min = &b; l_min = b_lum;
    _mid = &r; l_mid = r_lum;
    h2 = 0x300 - h;
  } else if (h < 0x400) {
    _max = &g;
    _min = &r; l_min = r_lum;
    _mid = &b; l_mid = b_lum;
    h2 = h - 0x300;
  } else if (h < 0x500) {
    _max = &b;
    _min = &r; l_min = r_lum;
    _mid = &g; l_mid = g_lum;
    h2 = 0x500 - h;
  } else {
    _max = &b;
    _min = &g; l_min = g_lum;
    _mid = &r; l_mid = r_lum;
    h2 = h - 0x500;
  }
  
  *_max = 256;
  *_min = 256 - c32;
  *_mid = *_min + (h2 * c32 >> 8);
  uint l2 = luminance(r, g, b);
  if (!l2) {
    red = green = blue = l;
    return;
  }
  r = l * r / l2;
  g = l * g / l2;
  b = l * b / l2;

  if (*_max > 255) {
    c32 = ((uint32a)(256 - l) << 16) /
      ((uint32a)(l_min << 8) + (uint32a)(256 - h2) * l_mid);
    *_max = 255;
    *_min = 256 - c32;
    *_mid = *_min + (h2 * c32 >> 8);
  }
      
  red = umin(r, (uint)255);
  green = umin(g, (uint)255);
  blue = umin(b, (uint)255);
}

