#ifndef UNDOPAINTER_H
#define UNDOPAINTER_H

//#include <qarray.h>
#include <vector>

#include "constants.h"
#include "sketchpainter.h"
#include "ptpen.h"

class LayeredPainter;

class pen_stroke {
 public:
  static const int PenUp = -1;
  static const int Shift = -2;

  PtPen pen;
  int x0, x1, y0, y1;
};

class UndoPainter : public SketchPainter {
  pen_stroke *stroke_que;
  pen_stroke *temp_que;
  uint stroke_index, temp_index, inter_index;
  LayeredPainter *parent;
  bool overflowed;

 public:
  UndoPainter(LayeredPainter*, int, int);
  ~UndoPainter(void);

  void changePainter(SketchPainter *);

  void enque(const pen_stroke&);
  void enque(const PtPen&, int, int, int, int);
  void enquePenUp(void);
  void enquePenUpWithOverflow(void);
  void enquePenUpWithoutOverflow(void);
  void enqueShift(int, int);

  void getBuffer(SketchPainter*, uint);
  void getBufferForInterIndex(SketchPainter*);
  void setPreviousPenup(bool = false);
  void setNextPenup(void);
  bool isLastPenup(void) {return (inter_index == stroke_index);}
  PtPair undoStep(void);

  void fixStroke(void);

 private:
  void apply_stroke(pen_stroke &, bool onlyundo = false);
  void revert_shift(void);
  void forward_shift(void);
};

#endif // UNDOPAINTER_H
