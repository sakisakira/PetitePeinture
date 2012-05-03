/**
 **	layeredpainter.cpp
 **	LayeredPainter
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 June 15
 */

#include <stdio.h>
#include <cmath>
//#include <qfileinfo.h>
//#import <Cocoa/Cocoa.h>
//#include <qcstring.h>
//#include <qcolor.h>
#import "ptcolor.h"
//#include <qpointarray.h>
//#include <qpen.h>
//#include <qsize.h>
//#include <qrect.h>

#include "constants.h"
#include "toolpanel.h"
#include "rgb_hsv.h"
//#include "ptptformat.h"
#include "sketchpainter.h"
#include "layeredpainter.h"
#include "undopainter.h"
#include "singletonjunction.h"

PtBitArray *LayeredPainter::alpha_mask = new PtBitArray();

LayeredPainter::LayeredPainter(int w, int h)
     : SketchPainter(w, h)
{
  layers.resize(1);
  cur = 0;

  for (uint i = 0; i < layers.size(); i ++) {
    layers[i] = new SketchPainter(w, h);
    layers[i]->composition_method = MinComposition;
    layers[i]->setCompositionAlpha(255);
  }
  
  temp_layer = new SketchPainter(w, h);
  temp_layer->fill(PtColor(255, 255, 255));
  backup_layer = new SketchPainter(w, h);
  backup_layer->fill(PtColor(255, 255, 255));
  undo_layer = new UndoPainter(this, w, h);

  tools = 0;
  showing_info = FALSE;

  alpha_mask->fill(false, mask->_size);
  setup_sqrt_tbl();
  
  this->_lineQueue = [[NSMutableArray alloc] init];
  
  SingletonJunction::layeredpainter = this;
}

LayeredPainter::~LayeredPainter() {
  for (uint i = 0; i < layers.size(); i ++)
    delete layers[i];
  
  delete temp_layer;
  delete backup_layer;
  delete undo_layer;

  if (tools)
    delete tools;

  [this->_lineQueue release];
  
  // delete buf;  // done by ~SketchPainter()
}

void LayeredPainter::setSize(int w, int h) {
  if (width == w && height == h) return;

  SketchPainter::setSize(w, h);

  for (uint i = 0; i < layers.size(); i ++)
    layers[i]->setSize(w, h);

  temp_layer->setSize(w, h);
  backup_layer->setSize(w, h);
  undo_layer->setSize(w, h);
  undo_layer->changePainter(layers[cur]);
  copy_entire_buf(*layers[cur], *temp_layer);

  updateRect(PtRect(0, 0, w, h));
}

void LayeredPainter::setup_sqrt_tbl(void) {
  sqrt_tbl.assign(257, 0);

  for (int i = 0; i <= 256; i ++)
    //    sqrt_tbl[i] = (int)floor(sqrt((double)i / 256.0) * 256);
    sqrt_tbl[i] = i;
    //sqrt_tbl[i] = (int)floor((double)i * 0.5);
}

void LayeredPainter::setPen(const PtPen &p, bool tool, bool each) {
  SketchPainter::setPen(p);

  if (tool)
    tools->setPen(p);

  if (each && cur < layers.size())
    layers[cur]->setPen(p);
}

void LayeredPainter::setPenDensity(int d, bool tool, bool each) {
  SketchPainter::setPenDensity(d);

  if (tool)
    tools->setPenDensity(d);

  if (each && cur < layers.size())
    layers[cur]->setPenDensity(d);
}

void LayeredPainter::setPenMethod(int m) {
  SketchPainter::setPenMethod(m);

  tools->setPenMethod(m);
}

void LayeredPainter::clearMask(void) {
  layers[cur]->clearMask();
  alpha_mask->fill(false);
  undo_layer->enquePenUp();
}

void LayeredPainter::setToolPanelActive(int i, bool f) {
  tools->setActive(i, f);
}

void LayeredPainter::setToolPanel(ToolPanel *t) {
  tools = t;

  for (uint i = 0; i < layers.size(); i ++)
    //    tools->setShowLayer(ToolPanel::LayerI + i,
    //                        layers[i]->getShowing());
    tools->setShowLayer(i,
                        layers[i]->getShowing());
}

void LayeredPainter::updateRect(const PtRect &r) {
  uint16 *bbuf;

  if (layers[0]->getShowing()) {
    update_rect_copy((uint32a *)layers[0]->frameBuffer(), r);
    if (layers[0] == clipboard.parent())
      update_rect_clipboard();
  } else {
    SketchPainter::fillRect16(
      r, pack_color(layers[0]->paperColor()));
  }
  bbuf = buf();

  for (uint i = 1; i < layers.size(); i ++) {
    if (layers[i]->getShowing()) {
      uint16 *cbuf = layers[i]->frameBuffer();
      switch (layers[i]->composition_method) {
      case MinComposition:
        update_rect_min((uint32a*)bbuf, (uint32a*)cbuf, r);
        break;
      case MaxComposition:
        update_rect_max((uint32a*)bbuf, (uint32a*)cbuf, r);
        break;
      case MulComposition:
        update_rect_mul((uint32a*)bbuf, (uint32a*)cbuf, r);
        break;
      case ScreenComposition:
	update_rect_screen((uint32a*)bbuf, (uint32a*)cbuf, r);
	break;
      case SatComposition:
        update_rect_sat(bbuf, cbuf, r);
        break;
      case ColComposition:
        update_rect_col(bbuf, cbuf, r);
        break;
      case DodgeComposition:
        update_rect_dodge(bbuf, cbuf, r);
        break;
      case NormalComposition:
        update_rect_normal(this, layers[i], r);
        break;
      case MaskComposition:
      case AlphaChannelComposition:
	if (i + 1 < layers.size())
	  update_rect_mask(bbuf, cbuf, layers[++ i]->frameBuffer(), r);
	else
	  update_rect_normal(this, layers[i], r);
	break;
      }
      if (layers[i] == clipboard.parent())
	update_rect_clipboard();
    } else if (i == 1 && layers[0]->getShowing()) {
      update_rect_copy((uint32a *)bbuf, r);
    }

    bbuf = buf();
  }
}

#if 0
inline uint16 LayeredPainter::update_over16(
  uint16 c0, uint16 c1, uint16 paper_col) {
  if (c1 == paper_col)
    return c0;
  else
    return c1;
}
#endif

#if 0
inline uint16 LayeredPainter::update_over16(
  uint16 c0, uint16 c1, uint16 paper_col, uint alpha) {
  if (c1 == paper_col)
    return c0;
  else
    return tighten((disperse(c0) * (32 - alpha)
                   + disperse(c1) * alpha) >> 5);
}
#endif

inline uint32a LayeredPainter::update_over32(
  uint32a c0, uint32a c1, uint16 paper_col, uint alpha) {
  return
    ((uint32a)update_over16(c0 >> 16, c1 >> 16,
                           paper_col, alpha) << 16) |
      (update_over16(c0 & 0xffff, c1 & 0xffff, paper_col, alpha));
}

#if 0
inline uint32a LayeredPainter::update_over32(
  uint32a &c0, uint32a c1, uint32a paper_col, uint32a paper_col_h,
  uint32a &mask_c) {
  if ((mask_c = c1 & 0xffff0000) != paper_col_h)
    c0 = (c0 & 0x0000ffff) | mask_c;
  if ((mask_c = c1 & 0x0000ffff) != paper_col)
    c0 = (c0 & 0xffff0000) | mask_c;

  return c0;
}
#endif

void LayeredPainter::update_rect_copy(
  uint32a *buf, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  uint32a *this_buf;

  this_buf = (uint32a *)frameBuffer();
  
  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;

  int y, index, i;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y) >> 1;
    for (i = 0; i < w; i ++, index ++)
      this_buf[index] = buf[index];
  }
}

void LayeredPainter::update_rect_min(
  uint32a *buf0, uint32a *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  static const unsigned long int masks[] = {
    0xf8000000, 0x07c00000, 0x003f0000,
    0x0000f800, 0x000007c0, 0x0000003f};
  unsigned long int *this_buf;

  this_buf = (unsigned long int *)frameBuffer();
  
  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;

  int y, index, i, j;
  unsigned long int b, c, n, mask;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y) >> 1;
    for (i = 0; i < w; i ++, index ++) {
      b = buf0[index];
      c = buf1[index];
      n = 0;
      for (j = 0; j < 6; j ++) {
        mask = masks[j];
        n |= (b < c) ? (b & mask) : (c & mask);
        b &= ~mask;
        c &= ~mask;
      }
      this_buf[index] = n;
    }
  }
}

void LayeredPainter::update_rect_max(
  uint32a *buf0, uint32a *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  static const unsigned long int masks[] = {
    0xf8000000, 0x07c00000, 0x003e0000,
    0x0000f800, 0x000007c0, 0x0000003e};
  unsigned long int *this_buf;

  this_buf = (uint32a *)frameBuffer();
  
  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;

  int y, index, i, j;
  unsigned long int b, c, n, mask;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y) >> 1;
    for (i = 0; i < w; i ++, index ++) {
      b = buf0[index];
      c = buf1[index];
      n = 0;
      for (j = 0; j < 6; j ++) {
        mask = masks[j];
        n |= (b > c) ? (b & mask) : (c & mask);
        b &= ~mask;
        c &= ~mask;
      }
      this_buf[index] = n;
    }
  }
}

void LayeredPainter::update_rect_mul(
  uint32a *buf0, uint32a *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  unsigned long int *this_buf;

  this_buf = (uint32a *)frameBuffer();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  
  int y, index, i;
  unsigned long int b, c, t, n;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y) >> 1;
    for (i = 0; i < w; i ++, index ++) {
      b = buf0[index];
      c = buf1[index];
      t = ((((b >> 17) & 0x7c00) | ((b >> 11) & 0x001f)) + 0x0401)
        * (((c >> 16) & 0xf800) | ((c >> 11) & 0x001f));  // red
      n = ((t << 1) & 0xf8000000) | ((t << 6) & 0x0000f800);
      t = ((((b >> 12) & 0x7c00) | ((b >> 6) & 0x001f)) + 0x0401)
        * (((c >> 11) & 0xf800) | ((c >> 6) & 0x001f));  // green
      n |= ((t >> 4) & 0x07c00000) | ((t << 1) & 0x000007c0);
      t = ((((b >> 7) & 0x7c00) | ((b >> 1) & 0x001f)) + 0x0401)
        * (((c >> 6) & 0xf800) | ((c >> 1) & 0x001f));  // blue
      n |= ((t >> 9) & 0x003e0000) | ((t >> 4) & 0x0000003e);
      this_buf[index] = n;
    }
  }
}

void LayeredPainter::update_rect_screen(
  uint32a *buf0, uint32a *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  unsigned long int *this_buf;

  this_buf = (uint32a *)frameBuffer();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;

  int y, index, i;
  unsigned long int b, c, t, n;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y) >> 1;
    for (i = 0; i < w; i ++, index ++) {
      b = ~buf0[index];
      c = ~buf1[index];
      t = ((((b >> 17) & 0x7c00) | ((b >> 11) & 0x001f)) + 0x0401)
        * (((c >> 16) & 0xf800) | ((c >> 11) & 0x001f)); // red
      n = ((t << 1) & 0xf8000000) | ((t << 6) & 0x0000f800);
      t = ((((b >> 12) & 0x7c00) | ((b >> 6) & 0x001f)) + 0x0401)
        * (((c >> 11) & 0xf800) | ((c >> 6) & 0x001f));  // green
      n |= ((t >> 4) & 0x07c00000) | ((t << 1) & 0x000007c0);
      t = ((((b >> 7) & 0x7c00) | ((b >> 1) & 0x001f)) + 0x0401)
        * (((c >> 6) & 0xf800) | ((c >> 1) & 0x001f));  // blue
      n |= ((t >> 9) & 0x003e0000) | ((t >> 4) & 0x0000003e);
      this_buf[index] = ~n;
    }
  }
}

void LayeredPainter::update_rect_sat(
  uint16 *buf0, uint16 *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  uint16* buf = this->buf();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  w2 = w << 1;

  int y, index, i;
  RGB_HSV rgb_hsv;
  uint hue, lum, chroma;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (i = 0; i < w2; i ++, index ++) {
      rgb_hsv.setPacked(buf0[index]);
      hue = rgb_hsv.hue();
      lum = rgb_hsv.luminance();
      rgb_hsv.setPacked(buf1[index]);
      chroma = rgb_hsv.chroma();
      rgb_hsv.setHCL(hue, chroma, lum);
      buf[index] = rgb_hsv.packed();
    }
  }
}

void LayeredPainter::update_rect_col(
  uint16 *buf0, uint16 *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  uint16 *buf = this->buf();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  w2 = w << 1;

  int y, index, i;
  RGB_HSV rgb_hsv;
  uint hue, lum, chroma;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (i = 0; i < w2; i ++, index ++) {
      rgb_hsv.setPacked(buf0[index]);
      lum = rgb_hsv.luminance();
      rgb_hsv.setPacked(buf1[index]);
      chroma = rgb_hsv.chroma();
      hue = rgb_hsv.hue();
      rgb_hsv.setHCL(hue, chroma, lum);
      buf[index] = rgb_hsv.packed();
    }
  }
}

void LayeredPainter::update_rect_normal(
  SketchPainter *sp0, SketchPainter *sp1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  uint16 *buf0, *buf1;
  uint16* buf = this->buf();

  buf0 = sp0->frameBuffer();
  buf1 = sp1->frameBuffer();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  w2 = w << 1;

  uint16 cp_col = pack_color(sp1->pen.paperColor());
  uint ca = (sp1->composition_alpha + 1) >> 3;

  int y, index, i;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (i = 0; i < w2; i ++, index ++) {
      buf[index] = update_over16(
          buf0[index], buf1[index], cp_col, ca);
    }
  }
}

void LayeredPainter::update_rect_dodge(
  uint16 *buf0, uint16 *buf1, const PtRect &r) {
  int x0, y0, x1, y1, w, w2;
  uint16* buf = this->buf();

  x0 = r.x;
  y0 = r.y;
  x1 = r.x + r.w - 1;
  y1 = r.y + r.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) x0 --;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 -x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  w2 = w << 1;

  int y, index, i, b, c, n;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (i = 0; i < w2; i ++, index ++) {
      b = buf0[index];
      c = buf1[index];
      n = umin(((((b >> 11) & 0x1f) << 6) / (0x3f - ((c >> 10) & 0x3e))),
              0x1f) << 11;
      n |= umin(((((b >> 6) & 0x1f) << 6) / (0x3f - ((c >> 5) & 0x3e))),
               0x1f) << 6;
      n |= umin(((((b >> 1) & 0x1f) << 6) / (0x3f - ((c << 0) & 0x3e))), 
               0x1f) << 1;
      buf[index] = n;
    }
  }
}

void LayeredPainter::update_rect_clipboard(void) {
  if (!clipboard.pasteMode()) return;

  int x0 = clipboard.x();
  int y0 = clipboard.y();
  PtPair pt(x0, y0);

  SketchPainter::pasteClipboard(pt);
  clipboard.setPasteMode(true);
}

void LayeredPainter::update_rect_mask(uint16 *buf0, uint16 *buf1,
				      uint16 *buf2, const PtRect &rect) {
  int x0, y0, x1, y1, w, w2;
  uint16 *buf = this->buf();

  x0 = rect.x;
  y0 = rect.y;
  x1 = rect.x + rect.w - 1;
  y1 = rect.y + rect.h - 1;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  x0 &= -2;
  if ((x1 & 1) != 1) x1 ++;
  w2 = x1 - x0 + 1;
  w = w2 >> 1;
  if (w2 & 1) w ++;
  w2 = w << 1;

  int y, index, i;
  uint32a r, g, b, a0, a1, a2, ra, ga, ba;
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (i = 0; i < w2; i ++, index ++) {
      a0 = buf0[index];
      a1 = buf1[index];
      a2 = buf2[index];
      ra = a1 >> 11;
      ga = (a1 >> 6) & 31;
      ba = (a1 >> 1) & 31;
      if (ra >= 16) ra ++;
      if (ga >= 16) ga ++;
      if (ba >= 16) ba ++;
      r = (a0 >> 11) * ra;
      g = ((a0 >> 6) & 31) * ga;
      b = ((a0 >> 1) & 31) * ba;
      r += (a2 >> 11) * (32 - ra);
      g += ((a2 >> 6) & 31) * (32 - ga);
      b += ((a2 >> 1) & 31) * (32 - ba);
      buf[index] = ((r << 6) & 0xf800) |
	((g << 1) & 0x7c0) | ((b >> 4) & 0x003e);
    }
  }
}
				      

void LayeredPainter::joinShowingLayers(void) {
  uint first;

  for (first = 0; first < layers.size(); first ++)
    if (layers[first]->getShowing())
      break;
  if (first >= layers.size()) return;

  updateRect(PtRect(0, 0, width, height));
  copy_entire_buf(*this, *layers[first]);

  for (uint i = first + 1; i < layers.size(); i ++)
    if (layers[i]->getShowing()) {
      cur = i --;
      deleteCurrentLayer();
    }

  setLayer(first);
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::copy_entire_buf(SketchPainter &ls,
                                     SketchPainter &ld) {
  int size = (ls.get_width() * ls.get_height()) >> 1;
  unsigned long int *bufs, *bufd;

  bufs = (unsigned long int*)ls.frameBuffer();
  bufd = (unsigned long int*)ld.frameBuffer();

  for (int i = 0; i < size; i ++)
    bufd[i] = bufs[i];
}

void LayeredPainter::copy_entire_buf_with_scaling(
  SketchPainter &ls, SketchPainter &ld,
  uint xscale, uint yscale) {
  if (xscale == 0 || xscale > 500*(uint)width ||
      yscale == 0 || yscale > 500*(uint)height)
    return;
  
  // scaling by (xscale/width, yscale/height)
  uint dx, dy, sx, sy, sx0, sx1, sy0, sy1;
  uint r, g, b, size, sindex, dindex;
  uint16 a, *sbuf, *dbuf;
  PtColor col;

  sbuf = ls.frameBuffer();
  dbuf = ld.frameBuffer();

  for (sy1 = dy = 0; dy < (uint)height; dy ++) {
    dindex = dy * width;
    if (sy1 >= (uint)height) break;
    sy0 = sy1;
    sy1 = umin((dy + 1) * height / yscale, height);
    for (sx1 = dx = 0; dx < (uint)width; dx ++) {
      r = g = b = size = 0;
      sindex = sy0 * width;
      if (sx1 >= (uint)width) break;
      sx0 = sx1;
      sx1 = umin((dx + 1) * width / xscale, width);
      a = sbuf[get_index(sx0, sy0)];
      for (sy = sy0; sy < sy1; sy ++, sindex += width)
        for (sx = sx0; sx < sx1; sx ++) {
          col = unpack_color(sbuf[sindex + sx]);
          r += col.red;
          g += col.green;
          b += col.blue;
          size ++;
        }
      if (size) {
        col.setRgb(r / size, g / size, b / size);
        a = pack_color(col);
      }
      dbuf[dindex + dx] = a;
    }
  }
}

void LayeredPainter::scaleCurrentLayer(uint sx, uint sy) {
  if (cur >= layers.size()) return;

  backupCurrentLayer();
  fill(layers[cur]->paperColor() , false);
  copy_entire_buf_with_scaling(*temp_layer, *layers[cur],
                               sx, sy);

  undo_layer->changePainter(layers[cur]);
  copy_entire_buf(*layers[cur], *temp_layer);
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::exchange_entire_buf(SketchPainter &l0,
                                         SketchPainter &l1) {
  int size = (width * height) >> 1;
  unsigned long int dat, *buf0, *buf1;

  buf0 = (unsigned long int*)l0.frameBuffer();
  buf1 = (unsigned long int*)l1.frameBuffer();

  for (int i = 0; i < size; i ++) {
    dat = buf0[i];
    buf0[i] = buf1[i];
    buf1[i] = dat;
  }
}

void LayeredPainter::backupCurrentLayer(void) {
  copy_entire_buf(*temp_layer, *backup_layer);
  copy_entire_buf(*layers[cur], *temp_layer);
}

void LayeredPainter::cancelCurrentLayer(void) {
  copy_entire_buf(*temp_layer, *layers[cur]);
  undo_layer->setPreviousPenup(true);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::restoreCurrentLayer(void) {
  copy_entire_buf(*backup_layer, *layers[cur]);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::copyTempLayerToUndoLayer(void) {
  copy_entire_buf(*temp_layer, *undo_layer);
}

void LayeredPainter::exchangeCurrentLayer(void) {
  exchange_entire_buf(*layers[cur], *backup_layer);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::exchangeLayers(int i0, int i1) {
  if (i0 < 0 || i0 >= (int)layers.size() ||
      i1 < 0 || i1 >= (int)layers.size())
    return;

  SketchPainter *temp_l;

  if (i0 == i1) return;

  if (i0 < i1) {
    temp_l = layers[i0];
    for (int i = i0; i < i1; i ++)
      layers[i] = layers[i + 1];
    layers[i1] = temp_l;
    if (i0 < (int)cur && (int)cur < i1) cur --;
  } else {
    temp_l = layers[i0];
    for (int i = i0 - 1; i >= i1; i --)
      layers[i + 1] = layers[i];
    layers[i1] = temp_l;
    if (i1 < (int)cur && (int)cur < i0) cur ++;
  }
  if ((int)cur == i0)
    cur = i1;
  else if ((int)cur == i1)
    cur = i0;
  
  copy_entire_buf(*layers[cur], *temp_layer);
  updateRect(PtRect(0, 0, width, height));
  setLayer(cur);
}

void LayeredPainter::setPaperColor(PtColor c) {
  SketchPainter::setPaperColor(c);

  layers[cur]->setPaperColor(c);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::setPaperColor(int l, PtColor c) {
  if (l == cur) {
    setPaperColor(c);
  } else {
    layers[l]->setPaperColor(c);
    updateRect(PtRect(0, 0, width, height));
  }
}

void LayeredPainter::clear(void) {
  for (uint i = 1; i < layers.size(); i ++)
    delete layers[i];
  layers.resize(1);
  SingletonJunction::numOfLayersChanged(1);
  setLayer(0);
  
  fill(PtColor(255, 255, 255), true);
}

void LayeredPainter::fill(const PtColor &c, bool all) {
  pen.setPaperColor(c);
  
  if (all) {
    for (uint i = 0; i < layers.size(); i ++) {
      layers[i]->composition_method = MinComposition;
      layers[i]->setCompositionAlpha(128);
      SingletonJunction::alphaChanged(i, 128);
      tools->setShowLayer(i, true);
      SingletonJunction::showingChanged(i, true);
      layers[i]->fill(c);
    }

    SketchPainter::fill(c);
  } else {
    layers[cur]->fill(c);
    updateRect(PtRect(0, 0, width, height));
  }

  undo_layer->changePainter(layers[cur]);

  SingletonJunction::toolPanelChanged();
}

void LayeredPainter::setLayer(int l) {
  if (l >= 0 && l <= (int)layers.size())
    cur = l;
  SingletonJunction::currentChanged(cur);

  for (uint i = 0; i < layers.size(); i ++) {
    SingletonJunction::showingChanged(i, layers[i]->getShowing());
    SingletonJunction::compositionChanged(i, layers[i]->composition_method);
    SingletonJunction::alphaChanged(i, layers[i]->compositionAlpha());
  }
  
  //  tools->setActive(ToolPanel::LayerI, false);
  for (uint j = 0; j < ToolPanel::NumOfLayers; j ++)
    tools->setActive(ToolPanel::Layer0I + j, false);
  if (cur < ToolPanel::NumOfLayers)
    tools->setActive(ToolPanel::Layer0I + cur, true);
  
  bool f2;
  for (uint i = 0; i < ToolPanel::NumOfLayers; i ++) {
    f2 = (i < layers.size() && layers[i]->getShowing());
    tools->setShowLayer(i, f2);
  }

  SingletonJunction::toolPanelChanged();

  undo_layer->changePainter(layers[cur]);
  copy_entire_buf(*layers[cur], *temp_layer);
  copy_entire_buf(*layers[cur], *backup_layer);
}

bool LayeredPainter::getShowing(void) {
  return getShowing(cur);
}

bool LayeredPainter::getShowing(int l) {
  if (l >= 0 && l < (int)layers.size())
    return layers[l]->getShowing();

  return false;
}

void LayeredPainter::setShowing(bool f) {
  setShowing(cur, f);
}

void LayeredPainter::setShowing(int l, bool f) {
  if (l < 0 || l >= (int)layers.size()) return;

  layers[l]->setShowing(f);
  tools->setShowLayer(l, f);
  SingletonJunction::toolPanelChanged();
  SingletonJunction::showingChanged(l, f);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::createLayer(void) {
  int n;

  n = layers.size();
  layers.resize(n + 1);
  layers[n] = new SketchPainter(width, height);

  SingletonJunction::numOfLayersChanged(n + 1);
  SingletonJunction::alphaChanged(n, layers[n]->compositionAlpha());
  SingletonJunction::showingChanged(n, layers[n]->getShowing());
  tools->setShowLayer(n, layers[n]->getShowing());
  SingletonJunction::toolPanelChanged();

  setLayer(cur);
}

void LayeredPainter::duplicateCurrentLayer(void) {
  createLayer();
  exchangeLayers(cur + 1, layers.size() - 1);
  copy_entire_buf(*layers[cur], *layers[cur + 1]);

  layers[cur + 1]->setPaperColor(layers[cur]->paperColor());
  layers[cur + 1]->setCompositionAlpha(layers[cur]->compositionAlpha());
  layers[cur + 1]->setCompositionMethod(layers[cur]->compositionMethod());

  setLayer(cur);
}

void LayeredPainter::deleteCurrentLayer(void) {
  deleteLayer(cur);
}

void LayeredPainter::deleteLayer(int l) {
  if (layers.size() <= 1) return;
  
  delete layers[l];

  for (uint i = l; i < layers.size() - 1; i ++)
    layers[i] = layers[i + 1];

  layers.resize(layers.size() - 1);

  if (cur >= layers.size())
    cur = layers.size() - 1;

  SingletonJunction::numOfLayersChanged(layers.size());
  for (uint i = l; i < layers.size(); i ++) {
    SingletonJunction::alphaChanged(i, layers[i]->compositionAlpha());
    SingletonJunction::showingChanged(i, layers[i]->getShowing());
    tools->setShowLayer(i, layers[i]->getShowing());
  }
  SingletonJunction::toolPanelChanged();

  setLayer(cur);
  
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::setLayerAlpha(int l, int alpha) {
  if (l < 0 || l >= (int)layers.size()) return;

  layers[l]->setCompositionAlpha(alpha);
  SingletonJunction::alphaChanged(cur, alpha);

  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::setLayerAlpha(int alpha) {
  setLayerAlpha(cur, alpha);
}

void LayeredPainter::switchLayer(int d) {
  int newcur = cur + d;
  
  if (newcur < 0) newcur = layers.size() - 1;
  if (newcur >= (int)layers.size()) newcur = 0;

  setLayer(newcur);
}

void LayeredPainter::setCompositionMethod(int m) {
  setCompositionMethod(cur, m);
}

void LayeredPainter::setCompositionMethod(int l, int m) {
  if (l < 0 || l >= (int)layers.size()) return;
  
  layers[l]->composition_method = m;
  updateRect(PtRect(0, 0, width, height));
  setLayer(cur);
}

void LayeredPainter::prepare_layer(SketchPainter *l) {
  l->setPen(pen);
}

void LayeredPainter::prepare_current(void) {
  prepare_layer(layers[cur]);
}  

void LayeredPainter::drawPoint(int x, int y) {
  //  hideInfo();
  
  prepare_current();
  layers[cur]->drawPoint(x, y);
}

void LayeredPainter::drawLine(int x0, int y0, int x1, int y1,
                              bool update) {
  //  hideInfo();

  prepare_current();
  if (cur > 0 && 
      layers[cur - 1]->compositionMethod() == AlphaChannelComposition)
    draw_line_with_alpha(x0, y0, x1, y1, layers[cur], layers[cur - 1]);
  else
    layers[cur]->drawLine(x0, y0, x1, y1);

  undo_layer->enque(pen, x0, y0, x1, y1);

  if (!update) return;
  
  if (x0 >= x1) {
    int x;
    x = x1; x1 = x0; x0 = x;
  }
  if (y0 >= y1) {
    int y;
    y = y1; y1 = y0; y0 = y;
  }
  int pw = (pen.width() >> 1) + 1;
  x0 -= pw;
  x1 += pw;
  y0 -= pw;
  y1 += pw;
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  PtRect rect(x0, y0, x1 - x0 + 1, y1 - y0 + 1);
  updateRect(rect);
}

void LayeredPainter::draw_line_with_alpha(int x0, int y0, int x1, int y1,
                                          SketchPainter *normal_l,
                                          SketchPainter *alpha_l) {
  PtBitArray *last_mask;
  int ad = alpha_l->compositionAlpha();
  int rad = 256 - ad;

  prepare_layer(normal_l);
  prepare_layer(alpha_l);

  if (pen.brush_method == EraserBrush) {
    alpha_l->setPenMethod(WaterBrush);
    alpha_l->setPenDensity(ad / 2);
    alpha_l->setPenColor(PtColor(255, 255, 255));

    last_mask = mask;
    alpha_l->drawLine(x0, y0, x1, y1);
    mask = last_mask;
  } else {
    int d;
    alpha_l->setPenColor(PtColor(rad, rad, rad));
    if (pen.brush_method == WaterBrush)
      d = sqrt_tbl[pen.density];
    else
      d = 256;
    normal_l->setPenDensity(d);
    alpha_l->setPenDensity(d);

    normal_l->drawLine(x0, y0, x1, y1);
    last_mask = mask;
    mask = alpha_mask;
    alpha_l->drawLine(x0, y0, x1, y1);
    mask = last_mask;
  }
}

#if 0
void LayeredPainter::drawPolyline(const QPointArray &pta) {
  int i, size, x0, y0, x1, y1, x, y;
  QPoint p;

  hideInfo();

  layers[cur]->setPen(pen);

  if (!(size = pta.size()))
    return;

  p = pta.point(0);

  if (size == 1) {
    drawPoint(p.x(), p.y());
    return;
  }

  x0 = x1 = p.x();
  y0 = y1 = p.y();
  
  for (i = 1; i < size; i ++) {
    p = pta.point(i);
    x = p.x();
    y = p.y();
    if (x < x0) x0 = x;
    if (y < y0) y0 = y;
    if (x > x1) x1 = x;
    if (y > y1) y1 = y;
  }
 
  layers[cur]->drawPolyline(pta);

//  QRect rect(x0, y0, x1 - x0, y1 - y0);
//  update_rect(rect);
}
#endif

#if 0
PtRect& LayeredPainter::showPenInfo(void) {
  if (showing_tools) {
    tools->setPen(pen);
    return info_rect;
  } else {
    int w, wh, x, y;

    w = (SingletonJunction::penWidthMax + 4) & ~1;
    x = (width - 31 - w) & ~1;
    y = 4;
    info_rect.setRect(x, y, w, w);
    fillRect32(info_rect, 0xffff0000);

    wh = w >> 1;
    draw_circle(x + wh, y + wh);

    showing_info = TRUE;

    return info_rect;
  }
}
#endif

void LayeredPainter::setShowingTools(bool s) {
  static PtRect rect;

  showing_tools = s;
}

#if 0
PtRect& LayeredPainter::hideInfo(void) {
  if (showing_info) {
    updateRect(info_rect);

    showing_info = FALSE;

    return info_rect;
  } else 
    return info_rect;
}
#endif

NSMutableArray* LayeredPainter::infoStrings(void) {
  NSMutableArray* info = [NSMutableArray arrayWithCapacity:layers.size() + 1];
  NSString *str;

  for (uint i = 0; i < layers.size(); i ++) {
    if (i == cur)
      str = @"*";
    else
      str = @" ";
    str = [str stringByAppendingString:layers[i]->infoString()];
    [info addObject:str];
  }

  return info;
}

void LayeredPainter::loadToCurrentLayer(UIImage *img) {
  //  layers[cur]->setUIImage(getUIImage(PtRect(0, 0, width, height)));
  layers[cur]->setUIImage(img);
  undo_layer->changePainter(layers[cur]);
  copy_entire_buf(*layers[cur], *temp_layer);
  updateRect(PtRect(0, 0, width, height));
}

#if 0
bool LayeredPainter::load(const QString &fn,
                          const char* ft) {
  if (QString("PTPT") == ft ||
      PtptFormat::isPtpt(fn))
    return loadPtpt(fn);
  
  bool r;
  QString fn0, fn1, fn2;
  QFileInfo info(fn);
  QString base = info.dirPath() + "/" + info.baseName();

  if (base.right(2) == "_0" ||
      base.right(2) == "_1" ||
      base.right(2) == "_2") {
    base = base.left(base.length() - 2);

    for (uint i = 3; i < layers.size(); i ++)
      delete layers[i];

    layers.resize(3);
    emit numOfLayersChanged(3);

    fn0 = base + "_0." + info.extension();
    fn1 = base + "_1." + info.extension();
    fn2 = base + "_2." + info.extension();

    r = (layers[0]->load(fn0, ft) &&
         layers[1]->load(fn1, ft) &&
         layers[2]->load(fn2, ft));
  } else {
    r = layers[0]->load(fn, ft);

    for (uint i = 1; i < layers.size(); i ++)
      delete layers[i];
    layers.resize(1);
    emit numOfLayersChanged(1);
  }
  
  if (cur >= layers.size())
    cur = layers.size() - 1;
  setLayer(cur);

  printf("%d¥n", layers.size());
  
  updateRect(PtRect(0, 0, width, height));

  return r;
}

bool LayeredPainter::loadLayer(const QString &fn) {
  bool r;
  
  r = layers[cur]->load(fn);
  undo_layer->changePainter(layers[cur]);
  updateRect(PtRect(0, 0, width, height));

  return r;
}

bool LayeredPainter::loadPtpt(const QString &fn) {
  PtptFormat ptpt;
  bool r;

  r = ptpt.load(fn);

  if (layers.size() > 0) {
    QImage img(ptpt.layer(0));
    int w = img.width();
    int h = img.height();

    if (!((w == width && h == height) ||
          (h == width && w == height)))
      setSize(max(width, img.width()), max(height, img.height()));
  }

  for (uint i = 1; i < layers.size(); i ++)
    delete layers[i];

  layers.resize(ptpt.numOfLayers());
  emit numOfLayersChanged(layers.size());

  delete layers[0];
  for (uint i = 0; i < layers.size(); i ++) {
    layers[i] = new SketchPainter(width, height);
    layers[i]->composition_method = 
      ptpt.compositionMethod(i);  
    layers[i]->setCompositionAlpha(ptpt.alpha(i));
    layers[i]->setPaperColor(ptpt.paperColor(i));
    layers[i]->setQImage(ptpt.layer(i));
    
    emit showingChanged(i, layers[i]->getShowing());
    emit alphaChanged(i, layers[i]->compositionAlpha());
    tools->setShowLayer(i, layers[i]->getShowing());
  }
  emit toolPanelChanged();

  if (cur >= layers.size())
    cur = layers.size() - 1;
  setLayer(cur);
  
  updateRect(PtRect(0, 0, width, height));

  return r;
}

bool LayeredPainter::save(const QString &fn,
                          const char* format) {
  if (QString("PTPT") == format)
    return savePtpt(fn);

  return SketchPainter::save(fn, format);
}

bool LayeredPainter::savePtpt(const QString &fn) {
  PtptFormat ptpt(layers.size());
  QImage *img;

  for (uint i = 0; i < layers.size(); i ++) {
    img = new QImage();
    layers[i]->getQImage(img, -1);
    ptpt.addLayer(*img);
    delete img;
    
    ptpt.setCompositionMethod(i, layers[i]->composition_method);
    ptpt.setAlpha(i, layers[i]->composition_alpha);
    ptpt.setPaperColor(i, layers[i]->paperColor());
  }

  img = new QImage();
  getQImage(img, -1);
  ptpt.setThumbnail(*img);
  delete img;

  return ptpt.save(fn);
}

bool LayeredPainter::saveLayer(const QString &fn) {
  return layers[cur]->save(fn, "PNG");
}
  

bool LayeredPainter::fileExists(const QString &fn) {
  if (PtptFormat::isPtpt(fn))
    return true;
  
  QFileInfo info0, info1, info2;
  QFileInfo info(fn);
  QString base = info.dirPath() + "/" + info.baseName();

  info0.setFile(base + "_0." + info.extension());
  info1.setFile(base + "_1." + info.extension());
  info2.setFile(base + "_2." + info.extension());

  return (info0.exists() || info1.exists() || info2.exists());
}
#endif

UIImage* LayeredPainter::getUIImageOfCurrentLayer(const PtRect &rect) {
  return layers[cur]->getUIImage(rect);
}

void LayeredPainter::mirrorHorizontal(void) {
  for (uint i = 0; i < layers.size(); i ++)
    layers[i]->mirrorHorizontal();

  undo_layer->changePainter(layers[cur]);
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::mirrorVertical(void) {
  for (uint i = 0; i < layers.size(); i ++)
    layers[i]->mirrorVertical();

  undo_layer->changePainter(layers[cur]);
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::rotateCW(void) {
  int l = max(width, height);
  setSize(l, l);

  for (uint i = 0; i < layers.size(); i ++)
    layers[i]->rotateCW();

  undo_layer->changePainter(layers[cur]);
  updateRect(PtRect(0, 0, width, height));
}

void LayeredPainter::rotateCCW(void) {
  int l = max(width, height);
  setSize(l, l);

  for (uint i = 0; i < layers.size(); i ++)
    layers[i]->rotateCCW();

  undo_layer->changePainter(layers[cur]);
  updateRect(PtRect(0, 0, width, height));
}

PtPair LayeredPainter::shiftCurrentLayer(PtPair &diff) {
  PtRect rect(0, 0, width, height);
  return shiftCurrentLayer(diff, rect);
}

PtPair LayeredPainter::shiftCurrentLayer(PtPair &diff, PtRect & rect) {
  if (!diff.x && !diff.y) return layers[cur]->shift;

  PtPair pt;
  id tbufdata;

  //  if (diff.x < -short_shift || diff.x > short_shift)
  //    diff.x &= -2;

  tbufdata = layers[cur]->bufdata;
  layers[cur]->bufdata = temp_layer->bufdata;
  temp_layer->bufdata = tbufdata;
  
  pt = layers[cur]->copyWithShift(temp_layer->buf(), diff);
  updateRect(rect);

  return pt;
}

void LayeredPainter::shiftAllLayers(PtPair &diff, bool enque) {

  for (uint i = 0; i < layers.size(); i ++)
    if (layers[i]->getShowing()) {
      id tbufdata = layers[i]->bufdata;
      layers[i]->bufdata = temp_layer->bufdata;
      temp_layer->bufdata = tbufdata;
      //      copy_entire_buf(*layers[i], *temp_layer);
      layers[i]->copyWithShift(temp_layer->buf(), diff);
      layers[i]->shift = PtPair(0, 0);
    }

  if (enque) {
    undo_layer->enqueShift(diff.x, diff.y);
    copy_entire_buf(*layers[cur], *temp_layer);
    updateRect(PtRect(0, 0, width, height));
  }
}

void LayeredPainter::shiftUndoLayer(PtPair &diff) {
  id tbufdata = undo_layer->bufdata;
  undo_layer->bufdata = temp_layer->bufdata;
  temp_layer->bufdata = tbufdata;
  //  copy_entire_buf(*undo_layer, *temp_layer);

  undo_layer->copyWithShift(temp_layer->buf(), diff);
  undo_layer->shift = PtPair(0, 0);
}

void LayeredPainter::copyClipboard(PtRect &rect, uint i) {
  if (i >= layers.size()) return;

  layers[i]->copyClipboard(rect);
}

void LayeredPainter::pasteClipboard(PtPair &pt, uint i) {
  if (i >= layers.size()) return;

  backupCurrentLayer();

  layers[i]->pasteClipboard(pt);

  undo_layer->changePainter(layers[cur]);
  PtRect rect(pt.x, pt.y, clipboard.width(), clipboard.height());
  updateRect(rect);
}

void LayeredPainter::unshiftCurrentLayer(void) {
  PtPair d0 = layers[cur]->shift;
  PtPair diff = PtPair(- d0.x, - d0.y);
  shiftCurrentLayer(diff);
  fixShiftCurrentLayer(false);
}

void LayeredPainter::fixShiftCurrentLayer(bool changed) {
  layers[cur]->shift = PtPair(0, 0);
  if (changed)
    undo_layer->changePainter(layers[cur]);
}

PtPen LayeredPainter::getPen(void) {
  return layers[cur]->get_pen();
}

uint LayeredPainter::getPenDensity(void) {
  return layers[cur]->penDensity();
}

int LayeredPainter::getPenMethod(void) {
  return layers[cur]->penMethod();
}

void LayeredPainter::undo(uint i) {
  undo_layer->getBuffer(layers[cur], i);
  updateRect(PtRect(0, 0, width, height));
}

PtPair LayeredPainter::undo(void) {
  if (0) {
  //  if (undo_layer->isLastPenup()) {
    copy_entire_buf(*backup_layer, *layers[cur]);
    copy_entire_buf(*backup_layer, *temp_layer);
    undo_layer->setPreviousPenup();
  } else {
    undo_layer->setPreviousPenup();
    undo_layer->getBufferForInterIndex(layers[cur]);
    copy_entire_buf(*layers[cur], *temp_layer);
  }
  updateRect(PtRect(0, 0, width, height));

  return undo_layer->undoStep();
}

PtPair LayeredPainter::redo(void) {
  undo_layer->setNextPenup();
  undo_layer->getBufferForInterIndex(layers[cur]);
  copy_entire_buf(*layers[cur], *temp_layer);
  updateRect(PtRect(0, 0, width, height));

  return undo_layer->undoStep();
}

