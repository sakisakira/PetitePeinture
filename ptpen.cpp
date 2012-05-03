#include "ptpen.h"

PtPen::PtPen(void) {
  initialize();
  setWidth(this->width());
}

PtPen::PtPen(const PtColor &cl, uint w) {
  initialize();
  setColor(cl);
  setWidth(w);
}

void PtPen::setDWidth(uint dw) {
  d_width = dw;
}

uint PtPen::dwidth(void) {
  return d_width;
}

void PtPen::initialize(void) {
  d_width = 0x300;
  red = green = blue = 0;
  p_red = p_green = p_blue = 255;
}

void PtPen::setColor(const PtColor &col) {
  red = col.red;
  green = col.green;
  blue = col.blue;
}

PtColor PtPen::color(void) {
  PtColor col(red, green, blue);
  return col;
}

void PtPen::setWidth(uint w) {
  d_width = w << 8;
}

uint PtPen::width(void) {
  return d_width >> 8;
}

void PtPen::setPaperColor(const PtColor &col) {
  p_red = col.red;
  p_green = col.green;
  p_blue = col.blue;
}

PtColor PtPen::paperColor(void) {
  PtColor col(p_red, p_green, p_blue);
  return col;
}
