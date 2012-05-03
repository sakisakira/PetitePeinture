/**
 **	undopainter.cpp
 **	UndoPainter
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2006 June 7
 */

#include <stdio.h>

#include "undopainter.h"
#include "layeredpainter.h"

UndoPainter::UndoPainter(LayeredPainter *p, int w, int h)
: SketchPainter(w, h) {
  
  parent = p;
  
  stroke_que = new pen_stroke[UndoStrokesMax];
  if (!stroke_que)
    printf("UndoPainter::stroke_que : mem. alloc. fails\n");

  temp_que = new pen_stroke[UndoStrokesMax];
  if (!temp_que)
    printf("UndoPainter::temp_que : mem. alloc. fails\n");

  inter_index = stroke_index = temp_index = 0;
  overflowed = false;
}

UndoPainter::~UndoPainter(void) {
  delete[] stroke_que;
  delete[] temp_que;
}

void UndoPainter::changePainter(SketchPainter *sp) {
  int l = (width * height) >> 1;
  uint32a* buf32 = (uint32a*)frameBuffer();
  uint32a* sbuf32 = (uint32a*)(sp->frameBuffer());

  for (int i = 0; i < l; i ++)
    buf32[i] = sbuf32[i];

  inter_index = stroke_index = temp_index = 0;
  overflowed = false;
}

void UndoPainter::enque(const pen_stroke &stroke) {
  fixStroke();

  if (temp_index == UndoStrokesMax) {
    stroke_index = inter_index = temp_index = 0;
    if (!overflowed) {
      overflowed = true;
      parent->copyTempLayerToUndoLayer();
    }
  }

  if (overflowed)
    apply_stroke(temp_que[temp_index], true);
  temp_que[temp_index ++] = stroke;
}

void UndoPainter::enque(const PtPen &pen, 
                        int x0, int y0, int x1, int y1) {
  pen_stroke ps;
  ps.pen = pen;
  ps.x0 = x0;
  ps.x1 = x1;
  ps.y0 = y0;
  ps.y1 = y1;
  enque(ps);
}

void UndoPainter::enquePenUp(void) {
  if (overflowed)
    enquePenUpWithOverflow();
  else
    enquePenUpWithoutOverflow();

  overflowed = false;
}

void UndoPainter::enquePenUpWithOverflow(void) {
  int index, index2;
  
  for (index = 0; index < UndoStrokesMax / 2; index ++)
    apply_stroke(temp_que[(temp_index + index) % UndoStrokesMax], true);
  
  for (index2 = index ; index < UndoStrokesMax; index ++)
    stroke_que[index - index2] = 
      temp_que[(temp_index + index) % UndoStrokesMax];

  stroke_index = index - index2;
  stroke_que[stroke_index ++].x0 = pen_stroke::PenUp;

  inter_index = stroke_index;
  temp_index = 0;
  overflowed = false;
}

void UndoPainter::enquePenUpWithoutOverflow(void) {
  int l, diff, index;
  uint32a * stroke_array = (uint32a *)stroke_que;
  uint32a * temp_array = (uint32a *)temp_que;
  uint justoverflowed = false;

  if (temp_index == 0 && stroke_index > 0 &&
      stroke_que[stroke_index - 1].x0 == pen_stroke::PenUp)
    return;

  if (temp_index < UndoStrokesMax) {
    temp_que[temp_index ++].x0 = pen_stroke::PenUp;
  } else {
    justoverflowed = true;
  }

//  ALog(@"temp_index %d", temp_index);

  l = stroke_index + temp_index - UndoStrokesMax;
  for (index = 0; index < l; index ++)
    apply_stroke(stroke_que[index], true);
//  ALog(@"local index %d", index);
    
  if (index) {
    while (stroke_que[index].x0 != pen_stroke::PenUp
	   && index < (int)stroke_index)
      apply_stroke(stroke_que[index ++], true);
    clearMask();
  }

  diff = (index * sizeof(pen_stroke)) >> 2;
  l = ((stroke_index - index) * sizeof(pen_stroke)) >> 2;
  if (diff)
    for (int i = 0; i < l; i ++)
      stroke_array[i] = stroke_array[i + diff];
#if 0
  diff = (index);
  l = ((stroke_index - index));
  if (diff)
    for (int i = 0; i < l; i ++)
      stroke_que[i] = stroke_que[i + diff];
#endif

  diff = l;
  l = (temp_index * sizeof(pen_stroke)) >> 2;
  for (int i = 0; i < l; i ++)
    stroke_array[i + diff] = temp_array[i];
#if 0
  diff = l;
  l = (temp_index);
  for (int i = 0; i < l; i ++)
    stroke_que[i + diff] = temp_que[i];
#endif

  stroke_index = stroke_index - index + temp_index;
  temp_index = 0;
  inter_index = stroke_index;
  overflowed = false;
  if (justoverflowed)
    enquePenUp();

//  ALog(@"stroke index %d", stroke_index);
}

void UndoPainter::enqueShift(int sx, int sy) {
  pen_stroke ps;
  ps.x0 = pen_stroke::Shift;
  ps.x1 = sx;
  ps.y1 = sy;

  enque(ps);
  enquePenUp();
}

void UndoPainter::apply_stroke(pen_stroke & stroke, bool onlyundo) {
  if (stroke.x0 >= 0) {
    pen = stroke.pen;
    drawLine(stroke.x0, stroke.y0, stroke.x1, stroke.y1);
  } else if (stroke.x0 == pen_stroke::PenUp) {
    clearMask();
  } else if (stroke.x0 == pen_stroke::Shift) {
    PtPair p(stroke.x1, stroke.y1);
    if (!onlyundo)
      parent->shiftCurrentLayer(p);
    else
      parent->shiftUndoLayer(p);
  }
}

void UndoPainter::getBuffer(SketchPainter* dest, uint ratio) {
  /*  0 < ratio < 0x10000 */
  uint16 *buf = this->buf();

  uint16* last_buf;
  uint16* dbuf = dest->frameBuffer();
  uint32a* dbuf32 = (uint32a*)dbuf;
  uint32a* buf32 = (uint32a*)buf;

  uint index = (ratio * stroke_index) >> 16;

  int l = (width * height) >> 1;
  for (int i = 0; i < l; i ++)
    dbuf32[i] = buf32[i];

  last_buf = buf;
  buf = dbuf;
  for (uint i = 0; i < index; i ++)
    apply_stroke(stroke_que[i], false);

  buf = last_buf;
  
  inter_index = index;
}

void UndoPainter::getBufferForInterIndex(SketchPainter* dest) {
  id lastbufdata;
  uint32a* dbuf32 = (uint32a*)dest->buf();
  uint32a* buf32 = (uint32a*)this->buf();

//  ALog(@"getBuffer: inter_index %d stroke_index %d temp_index %d", inter_index, stroke_index, temp_index);

  int l = (width * height) >> 1;
  for (int i = 0; i < l; i ++)
    dbuf32[i] = buf32[i];

  lastbufdata = bufdata;
  for (uint i = 0; i < inter_index; i ++) {
    bufdata = dest->bufdata;
    apply_stroke(stroke_que[i], false);
  }
  bufdata = lastbufdata;
}

void UndoPainter::setPreviousPenup(bool just_adjust) {
  temp_index = 0;
  if (just_adjust && inter_index > 0 &&
      stroke_que[inter_index - 1].x0 == pen_stroke::PenUp) 
    return;
  if (inter_index == 0) return;
  for (int i = inter_index - 2; i >= 0; i --)
    if (stroke_que[i].x0 == pen_stroke::PenUp) {
      revert_shift();
      inter_index = i + 1;
      forward_shift();
      return;
    }
  revert_shift();
  inter_index = 0;
  forward_shift();
}

void UndoPainter::setNextPenup(void) {
  temp_index = 0;
  if (inter_index == stroke_index) return;
  for (int i = inter_index; i < stroke_index; i ++)
    if (stroke_que[i].x0 == pen_stroke::PenUp) {
      revert_shift();
      inter_index = i + 1;
      forward_shift();
      return;
    }
  revert_shift();
  enquePenUp();
  forward_shift();
}

PtPair UndoPainter::undoStep(void) {
  int allstep, step;
  allstep = step = 0;

  for (int i = 0; i < inter_index; i ++)
    if (stroke_que[i].x0 == pen_stroke::PenUp) {
      allstep ++;
    }
  for (int i = inter_index; i < stroke_index; i ++)
    if (stroke_que[i].x0 == pen_stroke::PenUp) {
      step ++;
      allstep ++;
    }

  return PtPair(step, allstep);
}

void UndoPainter::fixStroke(void) {
  if (inter_index < stroke_index) {
    stroke_index = inter_index;
    if (stroke_index > 0 &&
	stroke_que[stroke_index - 1].x0 != pen_stroke::PenUp)
      enquePenUp();
  }
}

void UndoPainter::revert_shift(void) {
  int sx, sy;

  sx = sy = 0;
  for (int i = 0; i < inter_index; i ++)
    if (stroke_que[i].x0 == pen_stroke::Shift) {
      sx += stroke_que[i].x1;
      sy += stroke_que[i].y1;
    }

  PtPair p(-sx, -sy);
  parent->shiftAllLayers(p, false);
}

void UndoPainter::forward_shift(void) {
  int sx, sy;

  sx = sy = 0;
  for (int i = 0; i < inter_index; i ++)
    if (stroke_que[i].x0 == pen_stroke::Shift) {
      sx += stroke_que[i].x1;
      sy += stroke_que[i].y1;
    }

  PtPair p(sx, sy);
  parent->shiftAllLayers(p, false);
}
