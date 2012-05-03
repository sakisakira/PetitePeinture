/*
**	clipboard.cpp
**	by Saki Sakira <sakira@sun.dhis.portside.net>
**	from January 28, 2004
*/

#include <stdio.h>
//#include <qpe/qpeapplication.h>
#include "ptpair.h"

#include "clipboard.h"

PPClipboard::PPClipboard(void) {
  buf = 0;
  width_ = height_ = 0;
}

PPClipboard::~PPClipboard(void) {
  if (buf)
    delete[] buf;
}

uint16* PPClipboard::resize(int w, int h) {
  if (buf) delete buf;

  width_ = w;
  height_ = h;
  buf = new uint16[w * h];

  if (!buf) {
    printf("PPClipboard::buf : memory alloc. error¥n");
//    qApp->quit();
  }

  return buf;
}

PtRect PPClipboard::rect(void) {
  return PtRect(x_, y_, width_, height_);
}
