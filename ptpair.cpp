#include "ptpair.h"
#include "constants.h"

////////////////////////////////////////////////////////////

PtPair::PtPair(void) {
	x = y = 0;
}

PtPair::PtPair(int x0, int y0) {
	x = x0;
	y = y0;
}

PtPair::PtPair(const PtPair & p) {
	x = p.x;
	y = p.y;
}

PtPair PtPair::operator-(const PtPair &p) const {
  return PtPair(x - p.x, y - p.y);
}

PtPair PtPair::operator+(const PtPair &p) const {
  return PtPair(x + p.x, y + p.y);
}

////////////////////////////////////////////////////////////

PtRect::PtRect(void) {
	x = y = w = h = 0;
}

PtRect::PtRect(int x0, int y0, int w0, int h0) {
	setRect(x0, y0, w0, h0);
}

PtRect::PtRect(const PtRect& r) {
	x = r.x;
	y = r.y;
	w = r.w;
	h = r.h;
}

void PtRect::setRect(int x0, int y0, int w0, int h0) {
	x = x0;
	y = y0;
	w = w0;
	h = h0;
}

bool PtRect::contains(int x0, int y0) {
  return (x <= x0 && x0 < x + w && y <= y0 && y0 < y + h);
}

void PtRect::moveBy(int x0, int y0) {
  x += x0;
  y += y0;
}

PtRect PtRect::operator&(const PtRect& r) const {
  int x0, x1, y0, y1;
  x0 = max(x, r.x);
  y0 = max(y, r.y);
  x1 = min(x + w - 1, r.x + r.w - 1);
  y1 = min(y + h - 1, r.y + r.h - 1);
  return PtRect(x0, y0, x1 - x0 + 1, y1 - y0 + 1);
}

PtRect PtRect::operator*(const float scale) const {
	int x0, x1, y0, y1;
	x0 = x * scale;
	y0 = y * scale;
	x1 = (x + w) * scale - 1;
	y1 = (y + h) * scale - 1;
  return PtRect(x0, y0, x1 - x0 + 1, y1 - y0 + 1);
}

void PtRect::enlarge(int d) {
	x -= d;
	y -= d;
	w += 2 * d;
	h += 2 * d;
}

