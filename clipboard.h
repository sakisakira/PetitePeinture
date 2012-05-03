#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include "constants.h"

class PtRect;
class SketchPainter;

class PPClipboard {
  int width_, height_, x_, y_;
  uint16 *buf;
  SketchPainter *parent_;
  bool paste_mode;

 public:
  PPClipboard(void);
  ~PPClipboard(void);

  uint16* resize(int, int);
  uint16* frameBuffer(void) {return buf;}
  int width(void) {return width_;}
  int height(void) {return height_;}

  void setParent(SketchPainter *sp) {parent_ = sp;}
  SketchPainter* parent(void) {return parent_;}

  void setPasteMode(bool pm) {paste_mode = pm;}
  bool pasteMode(void) {return paste_mode;}

  void setX(int x) {x_ = x;}
  int x(void) {return x_;}
  void setY(int y) {y_ = y;}
  int y(void) {return y_;}
  PtRect rect(void);
};

#endif // CLIPBOARD_H
