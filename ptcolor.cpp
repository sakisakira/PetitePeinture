#include "ptcolor.h"

PtColor::PtColor(void) {
	red = green = blue = 0xff;
}

PtColor::PtColor(int r, int g, int b) {
	red = r;
	green = g;
	blue = b;
}

PtColor::~PtColor(void) {}

void PtColor::setRgb(int r, int g, int b) {
    red = r;
    green = g;
    blue = b;
}