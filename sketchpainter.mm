/**
 **	sketchpainter.cpp
 **	SketchPainter (originally) written for SL-C700
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 June 14
 **
 **	off-screen paint device (originally) for SL-C700
 **	5bit depth for each red, green, blue
 */

#include <stdio.h>
//#include <iostream>
//#include <qcstring.h>
#include <cmath>
//#include <qimage.h>
//#include <qdirectpainter_qws.h>
//#include <qcstring.h>
//#include <qcolor.h>
#include "ptcolor.h"
//#include <qpointarray.h>
//#include <qtopia/qpeapplication.h>
//#include <qpe/qpeapplication.h>
//#include <qbitarray.h>
//#include <qclipboard.h>

#include "sketchpainter.h"
#include "clipboard.h"
#include "ptimageutil.h"
#import "singletonjunction.h"

uint32a *SketchPainter::cloud_work =
  new uint32a[CloudWorkWidth * CloudWorkWidth];
PtBitArray *SketchPainter::cloud_on =
  new PtBitArray(CloudWorkWidth * CloudWorkWidth);
//PtBitArray *SketchPainter::mask = new PtBitArray();
PPClipboard SketchPainter::clipboard;

SketchPainter::SketchPainter(int w, int h) {
  bufdata = NULL;

  initialize(w, h);
}

SketchPainter::~SketchPainter(void) {
  [bufdata release];
}

void SketchPainter::initialize(int w, int h) {
  int size = w * h;

  width = w;
  height = h;

#if 0
  if (buf) delete[] buf;
  buf = new uint16[size];
#endif
  if (bufdata) [bufdata release];
  bufdata = [[NSMutableData alloc]
	      initWithLength:sizeof(uint16) * size];
  //  buf = (uint16*)[bufdata mutableBytes];

  //  if (buf == NULL) {
  //    printf("SketchPainter::buf : memory alloc. error\n");
//    qApp->quit();
//  }

  mask = new PtBitArray((uint)size);
//  if (!mask->fill(false, size)) {
//    printf("SketchPainter::mask : memory alloc. error\n");
//    qApp->quit();
//  }

  paper_color = unpack_color(tighten(disperse(0xffdf)));
    // RGB 555
  pen.setColor(PtColor(0, 0, 0));
  pen.setWidth(3);
  pen.brush_method = SolidBrush;
  pen.density = 128;
  pen.cloud_density = 128;
  composition_method = MinComposition;
  composition_alpha = 128;
  paper_color = PtColor(255, 255, 255);
  pen.setPaperColor(paper_color);
  pen.antialias = true;
  fill();
  showing = true;

  shift.x = 0; shift.y = 0;
}

void SketchPainter::setPaperColor(PtColor p) {
  paper_color = unpack_color(pack_color(p));
  pen.setPaperColor(paper_color);
}

void SketchPainter::setSize(int w, int h) {
  if (width == w && height == h) return;
  uint16 *buf = this->buf();

  int new_size = w * h;
  NSMutableData *newbufdata = [[NSMutableData alloc]
			       initWithLength:sizeof(uint16) * new_size];
  uint16 *new_buf = (uint16*)[newbufdata mutableBytes];

  uint16 col = pack_color(pen.paperColor());
  for (int i = 0; i < new_size; i ++)
    new_buf[i] = col;

  int min_w = min(w, width);
  int min_h = min(h, height);
  int sindex, dindex;
  for (int y = 0; y < min_h; y ++) {
    sindex = y * width;
    dindex = y * w;
    for (int x = 0; x < min_w; x ++)
      new_buf[dindex ++] = buf[sindex ++];
  }
  
  [bufdata release];
  bufdata = newbufdata;
  width = w;
  height = h;

  mask->fill(false, new_size);

  shift.x = 0;
  shift.y = 0;
}

void SketchPainter::fill(void) {
  fill(pen.paperColor());
}

void SketchPainter::fill(const PtColor &c) {
//  if (!showing) return;
  
  int size;
  unsigned long int pc;
  unsigned long int *lbuf;

  pen.setPaperColor(c);
  
  pc = pack_color(c);
  pc = pc | pc << 16;
  size = (width * height) >> 1;
  lbuf = (unsigned long int*)buf();

  for (int i = 0; i < size; i ++)
    lbuf[i] = pc;

  mask->fill(false);
}

unsigned short int* SketchPainter::frameBuffer(void) {
  return buf();
}

NSString* SketchPainter::infoString(void) {
  NSString* show = nil;
  NSString* alpha;
  NSString* comp;

  if (showing)
    show = @" S";
  else
    show = @" H";

  alpha = [NSString stringWithFormat:@" %3d",composition_alpha];

  switch (composition_method) {
  case MinComposition:
  	comp = @" min.";
    break;
  case MaxComposition:
  	comp = @" max.";
    break;
  case MulComposition:
  	comp = @" mul.";
    break;
  case ScreenComposition:
  	comp = @" screen";
    break;
  case SatComposition:
  	comp = @" sat.";
    break;
  case ColComposition:
  	comp = @" color";
    break;
  case DodgeComposition:
  	comp = @" dodge";
    break;
  case NormalComposition:
  	comp = @" normal";
    break;
  case MaskComposition:
  	comp = @"mask";
    break;
  case AlphaChannelComposition:
  	comp = @" alpha";
    break;
  default:
    comp = @"";
  }

  return [[show stringByAppendingString:comp] 
	  stringByAppendingString:alpha];
}

void SketchPainter::setPenColor(const PtColor &c) {
  pen.setColor(c);
}

void SketchPainter::setPen(const PtPen &p) {
  pen = p;

  pen_shape.setWidth(pen);
}

void SketchPainter::setPenMethod(int bm) {
  pen.brush_method = bm;
}

int SketchPainter::penMethod(void) {
  return pen.brush_method;
}

void SketchPainter::setPenDensity(uint d) {
  pen.density = d;
}

void SketchPainter::setCloudDensity(uint d) {
  pen.cloud_density = d;
}

void SketchPainter::setAntialias(bool a) {
  pen.antialias = a;
}

void SketchPainter::setShowing(bool f) {
  showing = f;
}

void SketchPainter::clearMask(void) {
  mask->fill(false);
}

int SketchPainter::get_index(int x, int y) {
    return (y * width) + x;
}

PtPair SketchPainter::get_point(int i) {
  int x, y;

  y = i / width;
  x = i % width;

  PtPair p(x, y);

  return p;
}

inline unsigned long int SketchPainter::blend(
  unsigned long int &pack, unsigned long int &rgb,
  unsigned long int &p_rgb, uint &alpha,
  uint16 pred, uint16 pgreen, uint16 pblue) {
  rgb = ((pack & 0xf800) << 9) |
    ((pack & 0x07c0) << 4) |
      ((pack & 0x003e) >> 1);
  rgb *= 32 - alpha;
  rgb += p_rgb;

  rgb = ((rgb & 0x3e000000) >> 14) |
    ((rgb & 0x000f8000) >> 9) |
      ((rgb & 0x000003e0) >> 4);

  if (pack == rgb) {
    if ((pack & 0xf800) < pred)
      rgb += 0x0800;
    else if ((pack & 0xf800) > pred)
      rgb -= 0x0800;

    if ((pack & 0x07c0) < pgreen)
      rgb += 0x0040;
    else if ((pack & 0x07c0) > pgreen)
      rgb -= 0x0040;

    if ((pack & 0x003e) < pblue)
      rgb += 0x0002;
    if ((pack & 0x003e) > pblue)
      rgb -= 0x0002;
  }

  return rgb;
}

void SketchPainter::drawPoint(int x, int y) {
  if (!showing) return;
  
  switch (pen.brush_method) {
  case SolidBrush:
  case EraserBrush:
//    draw_diamond(x, y, pen.antialias);
    draw_circle(x, y, pen.antialias);
    break;
  case WaterBrush:
//    draw_water_diamond(x, y, pen.density);
    draw_water_circle(x, y, pen.density);
    break;
  case CloudWeakBrush:
  case CloudMidBrush:
  case CloudWideBrush:
    draw_cloud_short_line(x, y, x, y, pen.antialias);
    break;
  }
}

void SketchPainter::drawPoint(const PtPair &p) {
  drawPoint(p.x, p.y);
}

void SketchPainter::clip_to_this(int *x, int *y, int m) {
  if (*x < m)
    *x = m;
  else if (*x >= width - m)
    *x = width - 1 - m;
  
  if (*y < m)
    *y = m;
  else if (*y >= height - m)
    *y = height - 1 - m;
}

void SketchPainter::clip_to_this(int &x, int &y, int m) {
  clip_to_this(&x, &y, m);
}

void SketchPainter::swap_points(int *x0, int *y0,
                               int *x1, int *y1) {
  int z;

  z = *x0; *x0 = *x1; *x1 = z;
  z = *y0; *y0 = *y1; *y1 = z;
}

void SketchPainter::swap_points(int &x0, int &y0,
                                int &x1, int &y1) {
  swap_points(&x0, &y0, &x1, &y1);
}

void SketchPainter::draw_point(int x, int y, unsigned int alpha) {
  /* we assume 0 <= alpha <= 256 */
  if (alpha <= 0)
    return;
  if (alpha > 256)
    alpha = 256;

  uint16* buf = this->buf();
  int r, g, b;
  int i = get_index(x, y);
  PtColor c = unpack_color(buf[i]);
  PtColor pc = pen.color();

  r = ((256 - alpha) * c.red + alpha * pc.red) >> 8;
  g = ((256 - alpha) * c.green + alpha * pc.green) >> 8;
  b = ((256 - alpha) * c.blue + alpha * pc.blue) >> 8;

  c.setRgb(r, g, b);
  buf[i] = pack_color(c);
}

#ifndef USE_OLD_DRAW_LINE

void SketchPainter::draw_line(int x0, int y0, int x1, int y1,
                              bool edge) {
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  unsigned short int pc = pack_color(pen.color());
  int p_w;
  uint16 *buf = this->buf();

  int E, x, y, dx, dy, sx, sy, i, j, index;
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
  } else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
  } else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  double l = sqrt((double)dx*dx + dy*dy);
  p_w = (int)(l / (double)umax((uint)dx, (uint)dy)
                     * (double)(pen.width() + 0.5));
  int d = (int)ceil(pen.width() * umin((uint)dx, (uint)dy) / l);
  int f = 0;
  const int f_head = 1;
  const int f_tail = 2;

  x = x0;
  y = y0;
  if (dx >= dy) {
    int yy0, yyw, dx2, yywd;
    E = -dx;
    for (i = 0; i < ( d >> 1); i ++) {
      x -= sx;
      E -= 2 * dy;
      if (E < 0) {
        y -= sy;
        E += 2 * dx;
      }
    }
    dx2 = dx + d;
    for (i = 0; i <= dx2; i ++) {
      yy0 = y - (p_w >> 1);
      yyw = p_w;
      f = 0;
      if (i < d) {
        yywd = p_w * (d - i) / d;
        yyw -= yywd;
        if (sy > 0) {
          yy0 += yywd;
          f |= f_head;
        } else
          f |= f_tail;
      }
      if ((i > dx) && d) {
        yywd = p_w * (i - dx) / d;
        yyw -= yywd;
        if (sy < 0) {
          yy0 += yywd;
          f |= f_head;
        } else
          f |= f_tail;
      }
      if (yyw > 0 && (uint)x < (uint)width) {
        if (yy0 < 0) {
          yyw += yy0;
          yy0 = 0;
        } else {
          if (edge && !(f & f_head)) {
            index = get_index(x, yy0);
            if (!mask->at(index)) {
              draw_point(x, yy0,
                         (((sy < 0 ? E + 2*dx : -E) << 7) / dx));
              mask->set(index, true);
            }
            yy0 ++;
            yyw --;
          }
        }
        if (yy0 + yyw >= height) {
          yyw = height - 1 - yy0;
        } else {
          if (edge && !(f & f_tail)) {
            index = get_index(x, yy0 + yyw - 1);
            if (!mask->at(index)) {
              draw_point(x, yy0 + yyw - 1,
                         (((sy < 0 ? -E : E + 2*dx) << 7) / dx));
              mask->set(index, true);
            }
            yyw --;
          }
        }
        index = get_index(x, yy0);
        for (j = 0; j < yyw; j ++) {
          buf[index] = pc;
          mask->set(index, true);
          index += width;
        }
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    int xx0, xxw, dy2, xxwd;
    E = -dy;
    for (i = 0; i < (d >> 1); i ++) {
      y -= sy;
      E -= 2 * dx;
      if (E < 0) {
        x -= sx;
        E += 2 * dy;
      }
    }
    dy2 = dy + d;
    for (i = 0; i <= dy2; i ++) {
      xx0 = x - (p_w >> 1);
      xxw = p_w;
      f = 0;
      if (i < d) {
        xxwd = p_w * (d - i) / d;
        xxw -= xxwd;
        if (sx > 0) {
          xx0 += xxwd;
          f |= f_head;
        } else
          f |= f_tail;
      }
      if ((i > dy) && d) {
        xxwd = p_w * (i - dy) / d;
        xxw -= xxwd;
        if (sx < 0) {
          xx0 += xxwd;
          f |= f_head;
        } else
          f |= f_tail;
      }
      
      if (xxw > 0 && (uint)y < (uint)height) {
        if (xx0 < 0) {
          xxw += xx0;
          xx0 = 0;
        } else {
          if (edge && !(f & f_head)) {
            index = get_index(xx0, y);
            if (!mask->at(index)) {
              draw_point(xx0, y,
                         (((sx < 0 ? E + 2*dy : -E) << 7) / dy));
              mask->set(index, true);
            }
            xx0 ++;
            xxw --;
          }
        }
        if (xx0 + xxw >= width) {
          xxw = width - 1 - xx0;
        } else {
          if (edge && !(f & f_tail)) {
            index = get_index(xx0 + xxw - 1, y);
            if (!mask->at(index)) {
              draw_point(xx0 + xxw - 1, y,
                         (((sx < 0 ? -E : E + 2*dy) << 7) / dy));
              mask->set(index, true);
            }
            xxw --;
          }
        }
        index = get_index(xx0, y);
        for (j = 0; j < xxw; j ++) {
          mask->set(index, true);
          buf[index ++] = pc;
        }
      }
      
      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

#else
void SketchPainter::draw_line(int x0, int y0, int x1, int y1,
                              bool) {
  int x, y;
  float pw;
  float ratio, l, r, red;
  float w, h, wh, c;
  uint pc;

  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  pc = pack_color(pen.color());
  pw = pen.width() + 0.5;

  w = (float)(x1 - x0);
  h = (float)(y1 - y0);
  wh = sqrt(w*w + h*h);
  c = - h * x0 + w * y0;
  	// this line is ' h x - w y + c = 0 '

//  pw = wh / umin(abs(w), abs(h)) * (pen.width() + 0.5);

  if (w != 0 &&
      (ratio = h/w) < 1.0 && ratio > -1.0) {
    if (x1 < x0)
      swap_points(&x0, &y0, &x1, &y1);
    
    float yy;
    int yy0, yy1;

    ratio = ((float)(y1 - y0))/(x1 - x0);
    l = pw * wh / ((x1 - x0) * 2);

    for (x = x0; x < x1; x ++) {
      yy = (x - x0) * ratio + y0;
      yy0 = (int)ceil(yy - l);
      if (yy0 < 0)
        yy0 = 0;
      yy1 = (int)floor(yy + l);
      if (yy1 >= height)
        yy1 = height - 1;
      for (y = yy0 + 1; y < yy1; y ++)
        buf[get_index(x, y)] = pc;

      red = h*x + c;
      r = (red - w*yy0)/wh;
      r = r >= 0 ? r : -r;
      draw_point(x, yy0, (int)((pw * 0.5 - r) * 256));
      r = (red - w*yy1)/wh;
      r = r >= 0 ? r : -r;
      draw_point(x, yy1, (int)((pw * 0.5 - r) * 256));
    }
  } else {
    if (y1 < y0)
      swap_points(&x0, &y0, &x1, &y1);

    float xx;
    int xx0, xx1;

    ratio = ((float)(x1 - x0))/(y1 - y0);
    l = pw * wh / ((y1 - y0) * 2);

    for (y = y0; y < y1; y ++) {
      xx = (y - y0) * ratio + x0;
      xx0 = (int)ceil(xx - l);
      if (xx0 < 0)
        xx0 = 0;
      xx1 = (int)floor(xx + l);
      if (xx1 >= width)
        xx1 = width - 1;
      for (x = xx0 + 1; x < xx1; x ++)
        buf[get_index(x, y)] = pc;
      
      red = -w*y + c;
      r = (h*xx0 + red)/wh;
      r = r >= 0 ? r : -r;
      draw_point(xx0, y, (int)((pw * 0.5 - r) * 256));
      r = (h*xx1 + red)/wh;
      r = r >= 0 ? r : -r;
      draw_point(xx1, y, (int)((pw * 0.5 - r)* 256));
    }
  }
}
#endif

void SketchPainter::draw_diamond_line(int x0, int y0,
                                      int x1, int y1, bool edge) {
  uint16 pc = pack_color(pen.color());
  int p_w = pen.width();
  uint edgea = 128;
  uint16 *buf = this->buf();
  
  if (edge && (pen.dwidth() & 1)) {
    if (p_w < 1) {
      draw_diamond_line_w1(x0, y0, x1, y1);
      return;
    } else if (p_w < 2) {
      draw_diamond_line_w2(x0, y0, x1, y1);
      return;
    } else if (p_w == 2) {
      edgea = ((pen.dwidth() & 0xff) + 0xff) >> 2;
    } else if (p_w <= (int)pensize_small) {
      edgea = (pen.dwidth() & 0xff) >> 1;
    } else {
      edgea = 128;
    }
  }

  clip_to_this(x0, y0);
  clip_to_this(x1, y1);

  int E, x, y, dx, dy, sx, sy, i, j, index;
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
  } else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
  } else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  x = x0;
  y = y0;
  if (dx >= dy) {
    int yy0, yyw;
    E = -dx;
    for (i = 0; i <= dx; i ++) {
      yy0 = y - (p_w >> 1);
      yyw = p_w;

      if (yy0 < 0) {
        yyw += yy0;
        yy0 = 0;
      } else {
        if (edge) {
          index = get_index(x, yy0);
          if (!mask->at(index)) {
            draw_point(x, yy0,
                       ((sy < 0 ? E + 2*dx : -E) * edgea) / dx);
            mask->set(index, true);
          }
          yy0 ++;
          yyw --;
        }
      }
      if (yy0 + yyw >= height) {
        yyw = height - 1 - yy0;
      } else {
        if (edge) {
          index = get_index(x, yy0 + yyw - 1);
          if (!mask->at(index)) {
            draw_point(x, yy0 + yyw - 1,
                       ((sy < 0 ? -E : E + 2*dx) * edgea) / dx);
            mask->set(index, true);
          }
          yyw --;
        }
      }

      index = get_index(x, yy0);
      for (j = 0; j < yyw; j ++) {
        buf[index] = pc;
        index += width;
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    int xx0, xxw;
    E = -dy;
    for (i = 0; i <= dy; i ++) {
      xx0 = x - (p_w >> 1);
      xxw = p_w;
      
      if (xx0 < 0) {
        xxw += xx0;
        xx0 = 0;
      } else {
        if (edge) {
          index = get_index(xx0, y);
          if (!mask->at(index)) {
            draw_point(xx0, y,
                       ((sx < 0 ? E + 2*dy : -E) * edgea) / dy);
            mask->set(index, true);
          }
          xx0 ++;
          xxw --;
        }
      }
      if (xx0 + xxw >= width) {
        xxw = width - 1 - xx0;
      } else {
        if (edge) {
          index = get_index(xx0 + xxw - 1, y);
          if (!mask->at(index)) {
            draw_point(xx0 + xxw - 1, y,
                       ((sx < 0 ? -E : E + 2*dy) * edgea) / dy);
            mask->set(index, true);
          }
          xxw --;
        }
      }

      index = get_index(xx0, y);
      for (j = 0; j < xxw; j ++)
        buf[index ++] = pc;
      
      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

void SketchPainter::draw_diamond_line_w1(int x0, int y0, int x1, int y1) {
  clip_to_this(x0, y0);
  clip_to_this(x1, y1);

  uint edgea = pen.dwidth() & 0xff;

  int E, x, y, dx, dy, sx, sy, i, index;
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
  } else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
  } else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  x = x0;
  y = y0;
  if (dx >= dy) {
    E = -dx;
    for (i = 0; i <= dx; i ++) {
      index = get_index(x, y);
      if (!mask->at(index)) {
        draw_point(x, y, edgea);
        mask->set(index, true);
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    E = -dy;
    for (i = 0; i <= dy; i ++) {
      index = get_index(x, y);
      if (!mask->at(index)) {
        draw_point(x, y, edgea);
        mask->set(index, true);
      }

      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

void SketchPainter::draw_diamond_line_w2(int x0, int y0, int x1, int y1) {
  clip_to_this(x0, y0);
  clip_to_this(x1, y1);

  uint edgea = (pen.dwidth() & 0x1ff) >> 2;

  int E, Em, Es, x, y, dx, dy, sx, sy, i, index;
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
  } else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
  } else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  x = x0;
  y = y0;
  if (dx >= dy) {
    E = -dx;
    for (i = 0; i <= dx; i ++) {
      if (E + dx < 0) {
        Em = -E; Es = E + 2*dx;
      } else {
        Em = E + 2*dx; Es = -E;
      }
      draw_point(x, y, Em * edgea / dx);
      if (sy * (E + dx) >= 0) {
        if (y > 0) {
          index = get_index(x, y - 1);
          if (!mask->at(index)) {
            draw_point(x, y - 1, Es * edgea / dx);
            mask->set(index, true);
          }
        }
      } else {
        if (y + 1 < height) {
          index = get_index(x, y + 1);
          if (!mask->at(index)) {
            draw_point(x, y + 1, Es * edgea / dx);
            mask->set(index, true);
          }
        }
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    E = -dy;
    for (i = 0; i <= dy; i ++) {
      if (E + dy < 0) {
        Em = -E; Es = E + 2*dy;
      } else {
        Em = E + 2*dy; Es = -E;
      }
      draw_point(x, y, Em * edgea / dy);
      if (sx * (E + dy) >= 0) {
        if (x > 0) {
          index = get_index(x - 1, y);
          if (!mask->at(index)) {
            draw_point(x - 1, y, Es * edgea / dy);
            mask->set(index, true);
          }
        }
      } else {
        if (x + 1 < width) {
          index = get_index(x + 1, y);
          if (!mask->at(index)) {
            draw_point(x + 1, y, Es * edgea / dy);
            mask->set(index, true);
          }
        }
      }
      
      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

void SketchPainter::draw_water_line(int x0, int y0,
                                    int x1, int y1,
                                    uint alpha) {
  int x, y, p_w;
  unsigned long int p_rgb, rgb, pack;
  uint16 pred, pgreen, pblue;
//  QColor pc;

  if (alpha > 256)
    alpha = 256;
  alpha = alpha >> 3;
  if (alpha == 0)
    return;
  
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  p_rgb = disperse(pen.color());
  p_rgb *= alpha;
  p_w = pen.width();

  pred = ((uint16)(pen.color().red & 0xf8)) << 8;
  pgreen = ((uint16)(pen.color().green & 0xf8)) << 3;
  pblue = ((uint16)(pen.color().blue & 0xf8)) >> 2;

  signed short int E, dx, dy, sx, sy;
  int i, j, index;
  uint16 *buf = this->buf();
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
  } else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
  } else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  double l = sqrt((double)dx*dx + dy*dy);
  p_w = (int)(l / (double)umax((uint)dx, (uint)dy)
              * (double)(pen.width() + 0.5));
  int d = (int)ceil(pen.width() * umin((uint)dx, (uint)dy) / l);
  
  x = x0;
  y = y0;
  if (dx >= dy) {
    int yy0, yyw, dx2, yywd;
    E = -dx;
    for (i = 0; i < ( d >> 1); i ++) {
      x -= sx;
      E -= 2 * dy;
      if (E < 0) {
        y -= sy;
        E += 2* dx;
      }
    }
    dx2 = dx + d;
    for (i = 0; i <= dx2; i ++) {
      yy0 = y - (p_w >> 1);
      yyw = p_w;
      if (i < d) {
        yywd = p_w * (d - i) / d;
        yyw -= yywd;
        if (sy > 0)
          yy0 += yywd;
      }
      if ((i > dx) && d) {
        yywd = p_w * (i - dx) / d;
        yyw -= yywd;
        if (sy < 0)
          yy0 += yywd;
      }

      if (yyw > 0 && (uint)x < (uint)width) {
        if (yy0 < 0) {
          yyw += yy0;
          yy0 = 0;
        } if (yy0 + yyw >= height) {
          yyw = height - 1 - yy0;
        }
        index = get_index(x, yy0);
        for (j = 0 ; j < yyw; j ++) {

          if (!mask->at(index)) {
            pack = buf[index];
            buf[index] = blend(pack, rgb, p_rgb, alpha,
                               pred, pgreen, pblue);
            mask->set(index, true);
          }

          index += width;
        }
      }
        
      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    int xx0, xxw, dy2, xxwd;
    E = -dy;
    for (i = 0; i < (d >> 1); i ++) {
      y -= sy;
      E -= 2 * dx;
      if (E < 0) {
        x -= sx;
        E += 2 * dy;
      }
    }
    dy2 = dy + d;
    for (i = 0; i <= dy2; i ++) {
      xx0 = x - (p_w >> 1);
      xxw = p_w;
      if (i < d) {
        xxwd = p_w * (d - i) / d;
        xxw -= xxwd;
        if (sx > 0)
          xx0 += xxwd;
      }
      if ((i > dy) && d) {
        xxwd = p_w * (i - dy) / d;
        xxw -= xxwd;
        if (sx < 0)
          xx0 += xxwd;
      }

      if (xxw > 0 && (uint)y < (uint)height) {
        if (xx0 < 0) {
          xxw += xx0;
          xx0 = 0;
        } else if (xx0 + xxw >= width) {
          xxw = width - 1 - xx0;
        }
        index = get_index(xx0, y);
        for (j = 0; j < xxw; j ++) {

          if (!mask->at(index)) {
            pack = buf[index];
            buf[index] = blend(pack, rgb, p_rgb, alpha,
                             pred, pgreen, pblue);
            mask->set(index, true);
          }

          index ++;
        }
      }

      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

void SketchPainter::draw_water_line_w1(int x0, int y0,
                                       int x1, int y1, uint alpha) {

  alpha = (alpha * (pen.dwidth() & 0xff)) >> 8;

  unsigned long int p_rgb, rgb, pack;
  uint16 pred, pgreen, pblue;
  uint16 *buf = this->buf();

  if (alpha > 256)
    alpha = 256;
  alpha = alpha >> 3;
  if (alpha == 0)
    return;
  
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  p_rgb = disperse(pen.color());
  p_rgb *= alpha;

  pred = ((uint16)(pen.color().red & 0xf8)) << 8;
  pgreen = ((uint16)(pen.color().green & 0xf8)) << 3;
  pblue = ((uint16)(pen.color().blue & 0xf8)) >> 2;

  int x, y, E, dx, dy, sx, sy, i, index;
  dx = x1 - x0;
  if (dx > 0)
    sx = 1;
  else {
    sx = -1;
    dx = -dx;
  }
  dy = y1 - y0;
  if (dy > 0)
    sy = 1;
  else {
    sy = -1;
    dy = -dy;
  }
  if (!dx && !dy) return;

  x = x0;
  y = y0;
  if (dx >= dy) {
    E = -dx;
    for (i = 0; i <= dx; i ++) {
      index = get_index(x, y);
      if (!mask->at(index)) {
        pack = buf[index];
        buf[index] = blend(pack, rgb, p_rgb, alpha,
                           pred, pgreen, pblue);
        mask->set(index, true);
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    E = -dy;
    for (i = 0; i <= dy; i ++) {
      index = get_index(x, y);
      if (!mask->at(index)) {
        pack = buf[index];
        buf[index] = blend(pack, rgb, p_rgb, alpha,
                           pred, pgreen, pblue);
        mask->set(index, true);
      }

      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }
}

void SketchPainter::clear_cloud_work(int dx, int dy) {
//  cloud_blend->fill(false);
  cloud_on->fill(false);

  int x, y, index;
  for (y = 0; y < dy; y ++) {
    index = y * CloudWorkWidth;
    for (x = 0; x < dx; x ++)
      cloud_work[index ++] = 0;
  }
}

void SketchPainter::set_cloud_flag(int x0, int y0,
                                   int dx, int dy,
                                   int sx, int sy) {
  int x, y, p_w;
  int E, i, j, index;

  p_w = pen.width();
  cloud_on->fill(false);

  // line
  x = x0;
  y = y0;
  if (dx >= dy) {
    int yy0, yyw;
    E = -dx;
    for (i = 0; i <= dx; i ++) {
      yy0 = y - (p_w >> 1);
      yyw = p_w;

      index = (yy0 * CloudWorkWidth) + x;
      for (j = 0; j < yyw; j ++) {
        cloud_on->set(index, true);
        index += CloudWorkWidth;
      }

      x += sx;
      E += 2 * dy;
      if (E >= 0) {
        y += sy;
        E -= 2 * dx;
      }
    }
  } else {
    int xx0, xxw;
    E = -dy;
    for (i = 0; i <= dy; i ++) {
      xx0 = x - (p_w >> 1);
      xxw = p_w;
      
      index = (y * CloudWorkWidth) + xx0;
      for (j = 0; j < xxw; j ++) {
        cloud_on->set(index ++, true);
      }

      y += sy;
      E += 2 * dx;
      if (E >= 0) {
        x += sx;
        E -= 2 * dy;
      }
    }
  }

  //diamond
  int x1, y1, pw, l, index0, index1;
  x1 = x0 + dx * sx;
  y1 = y0 + dy * sy;
  pw = p_w >> 1;

  for (y = -pw; y <= pw; y ++) {
    l = (pw - (y >= 0 ? y : -y)) << 1;
    index0 = (y0 + y) * CloudWorkWidth + x0 - (l >> 1);
    index1 = (y1 + y) * CloudWorkWidth + x1 - (l >> 1);

    for (i = 0; i < l; i ++) {
      cloud_on->set(index0 + i, true);
      cloud_on->set(index1 + i, true);
    }
  }
}

void SketchPainter::disperse_rect(int x0, int y0,
                                  int dx, int dy) {
  int x, y, index, cindex, cx0, cy0;
  unsigned long int paper_col = disperse(pen.paperColor());
  uint16* buf = this->buf();

  cx0 = cy0 = 0;
  
  if (x0 < 0) {
    for (y = 0; y < dy; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < -x0; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dx += x0;
    cx0 = -x0;
    x0 = 0;
  }
  if (y0 < 0) {
    for (y = 0; y < -y0; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < dx; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dy += y0;
    cy0 = -y0;
    y0 = 0;
  }
  if (x0 + dx > width) {
    int dx2 = x0 + dx - width;
    for (y = 0; y < dy; y ++) {
      cindex = y * CloudWorkWidth + width - x0;
      for (x = 0; x < dx2; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dx = width - x0;
  }
  if (y0 + dy > height) {
    for (y = height - y0; y < dy; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < dx; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dy = height - y0;
  }
  
  for (y = 0; y < dy; y ++) {
    index = get_index(x0, y0 + y);
    cindex = (cy0 + y) * CloudWorkWidth + cx0;
    for (x = 0; x < dx; x ++)
      cloud_work[cindex ++] = disperse(buf[index ++]);
  }
}

void SketchPainter::disperse_h_rect(int x0, int y0,
                                  int dx, int dy) {
  int x, y, index, cindex, cx0, cy0;
  unsigned long int paper_col = disperse_h(pen.paperColor());
  uint16 *buf = this->buf();

  cx0 = cy0 = 0;
  
  if (x0 < 0) {
    for (y = 0; y < dy; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < -x0; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dx += x0;
    cx0 = -x0;
    x0 = 0;
  }
  if (y0 < 0) {
    for (y = 0; y < -y0; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < dx; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dy += y0;
    cy0 = -y0;
    y0 = 0;
  }
  if (x0 + dx > width) {
    int dx2 = x0 + dx - width;
    for (y = 0; y < dy; y ++) {
      cindex = y * CloudWorkWidth + width - x0;
      for (x = 0; x < dx2; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dx = width - x0;
  }
  if (y0 + dy > height) {
    for (y = height - y0; y < dy; y ++) {
      cindex = y * CloudWorkWidth;
      for (x = 0; x < dx; x ++)
        cloud_work[cindex ++] = paper_col;
    }
    dy = height - y0;
  }
  
  for (y = 0; y < dy; y ++) {
    index = get_index(x0, y0 + y);
    cindex = (cy0 + y) * CloudWorkWidth + cx0;
    for (x = 0; x < dx; x ++)
      cloud_work[cindex ++] = disperse_h(buf[index ++]);
  }
}

void SketchPainter::draw_cloud_line(int x0, int y0,
                                    int x2, int y2,
                                    bool edge) {
  int dx, dy, p_w;

  dx = x2 - x0;
  dx = dx >= 0 ? dx : -dx;
  dy = y2 - y0;
  dy = dy >= 0 ? dy : -dy;
  p_w = pen.width();
  
  if (dx + p_w + 6 >= CloudWorkWidth ||
      dy + p_w + 6 >= CloudWorkWidth) {
    int x1, y1;
    x1 = (x0 + x2) >> 1;
    y1 = (y0 + y2) >> 1;
    draw_cloud_line(x0, y0, x1, y1, edge);
    draw_cloud_line(x1, y1, x2, y2, edge);
  } else
    draw_cloud_short_line(x0, y0, x2, y2, edge);
}

inline uint32a SketchPainter::pick_dispersed_pixel(
  uint cindex, uint32a opixel, bool edge) {
  if (edge || cloud_on->at(cindex))
    return cloud_work[cindex];
  else
    return opixel;
}

void SketchPainter::draw_cloud_short_line(int x0, int y0,
                                          int x1, int y1,
                                          bool edge) {
  int min_x, min_y, p_w, cloud_w;
  uint32a alpha;
  uint16* buf = this->buf();

  alpha = (pen.cloud_density >> 3);
  if (alpha > 31)
    alpha = 31;
  //  alpha *= 0x00100402;
  alpha *= 0x00100401;
  
  switch (pen.brush_method) {
  case CloudWeakBrush:
    cloud_w = 1;
    alpha = (alpha >> 2) & 0x01f07c3e;
    break;
  case CloudMidBrush:
    cloud_w = 2;
    alpha = alpha & 0x01f07c3e;
    break;
  case CloudWideBrush:
    cloud_w = 3;
    //    alpha = (alpha & 0x01f07c3e) << 1;
    alpha = (alpha & 0x01f07c1f) << 1;
    break;
  default:
    return;
  }

//  clip_to_this(&x0, &y0, cloud_w);
//  clip_to_this(&x1, &y1, cloud_w);
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);
  p_w = pen.width();

  int dx, dy, sx, sy;
  dx = x1 - x0;
  if (dx > 0) {
    sx = 1;
    min_x = x0;
  } else {
    sx = -1;
    dx = -dx;
    min_x = x1;
  }
  dy = y1 - y0;
  if (dy > 0) {
    sy = 1;
    min_y = y0;
  } else {
    sy = -1;
    dy = -dy;
    min_y = y1;
  }

#if 0
  if (dx + p_w + cloud_w * 2 >= CloudWorkWidth)
    dx = CloudWorkWidth - p_w - cloud_w * 2 - 1;
  if (dy + p_w + cloud_w * 2 >= CloudWorkWidth)
    dy = CloudWorkWidth - p_w - cloud_w * 2 - 1;
#endif

//  clear_cloud_work(dx + p_w + cloud_w * 2, dy + p_w + cloud_w * 2);
  set_cloud_flag(x0 - min_x + cloud_w + (p_w >> 1),
                 y0 - min_y + cloud_w + (p_w >> 1),
                 dx, dy, sx, sy);
  switch (pen.brush_method) {
  case CloudWeakBrush:
  case CloudMidBrush:
    disperse_rect(min_x - cloud_w - (p_w >> 1),
                min_y - cloud_w - (p_w >> 1),
                dx + p_w + cloud_w * 2,
                dy + p_w + cloud_w * 2);
    break;
  case CloudWideBrush:
    disperse_h_rect(min_x - cloud_w - (p_w >> 1),
                min_y - cloud_w - (p_w >> 1),
                dx + p_w + cloud_w * 2,
                dy + p_w + cloud_w * 2);
    break;
  }
    

  int pw = p_w >> 1;
  int x, mx, y, index, cindex, xx, yy, cindex2;
  uint32a ocol;
  unsigned long int col;
  for (y = 0; y < dy + p_w; y ++) {
    if (min_y + y - pw < 0)
      y = pw - min_y;
    if (min_y + y - pw >= height)
      break;
    
    index = (min_y + y - pw) * width + min_x - pw;
    cindex = (y + cloud_w) * CloudWorkWidth + cloud_w;
    for (x = 0; x < dx + p_w; x ++, index ++, cindex ++) {
      mx = min_x + x - pw;
      if (mx < 0) {
        x = pw - min_x;
        index += x;
        cindex += x;
      }
      if (min_x + x - pw >= width)
        break;
      
      if (cloud_on->at(cindex)) {
        ocol = cloud_work[cindex];
        
        col = 0;
        for (yy = -cloud_w; yy <= cloud_w; yy ++) {
          cindex2 = cindex + yy * CloudWorkWidth;
          for (xx = -cloud_w; xx <= cloud_w; xx ++)
            col += pick_dispersed_pixel(cindex2 + xx, ocol, edge);
        }
        switch (pen.brush_method) {
        case CloudWeakBrush:
          col -= cloud_work[cindex];
          break;
        case CloudMidBrush:
          col -= cloud_work[cindex];
          col += pick_dispersed_pixel(cindex - CloudWorkWidth,
                                      ocol, edge);
          col += pick_dispersed_pixel(cindex + CloudWorkWidth,
                                      ocol, edge);
          col += pick_dispersed_pixel(cindex - 1, ocol, edge);
          col += pick_dispersed_pixel(cindex + 1, ocol, edge);
          col += pick_dispersed_pixel(cindex - CloudWorkWidth + 1,
                                      ocol, edge);
          col += pick_dispersed_pixel(cindex - CloudWorkWidth - 1,
                                      ocol, edge);
          col += pick_dispersed_pixel(cindex + CloudWorkWidth + 1,
                                      ocol, edge);
          col += pick_dispersed_pixel(cindex + CloudWorkWidth - 1,
                                      ocol, edge);
          break;
        case CloudWideBrush:
          for (yy = -1; yy <= 1; yy ++) {
            cindex2 = cindex + yy * CloudWorkWidth;
            for (xx = -2; xx <= 2; xx ++)
              col += pick_dispersed_pixel(cindex2 + xx, ocol, edge);
          }
          break;
        }
        switch (pen.brush_method) {
        case CloudWeakBrush:
          buf[index] = tighten((col + alpha) >> 3);
          break;
        case CloudMidBrush:
          buf[index] = tighten((col + alpha) >> 5);
          break;
        case CloudWideBrush:
          buf[index] = tighten((col + alpha) >> 5);
          break;
        }
      }
    }
  }
}

void SketchPainter::draw_line(const PtPair &p0,
                              const PtPair &p1,
                              bool edge) {
  draw_line(p0.x, p0.y, p1.x, p1.y, edge);
}

void SketchPainter::draw_diamond_line(const PtPair &p0,
                                      const PtPair &p1,
                                      bool edge) {
  draw_diamond_line(p0.x, p0.y, p1.x, p1.y, edge);
}

void SketchPainter::draw_water_line(const PtPair &p0,
                                    const PtPair &p1,
                                    uint alpha) {
  draw_water_line(p0.x, p0.y, p1.x, p1.y, alpha);
}

void SketchPainter::draw_diamond(int cx, int cy, bool edge) {
  int y, x0, y0, x1, y1, l, index, i, d;
  int pw;
  unsigned short int pc = pack_color(pen.color());
  uint16* buf = this->buf();

  pw = (pen.width() - 1)  >> 1;

  y0 = cy - pw;
  if (y0 < 0) y0 = 0;
  y1 = cy + pw;
  if (y1 >= height) y1 = height - 1;
  
  for (y = y0; y <= y1; y ++) {
    d = cy - y;
    d = d >= 0 ? d : -d;
    x0 = (cx - (pw - d));
    x1 = (cx + (pw - d));

    if (x0 < 0) x0 = 0;
    if (x1 >= width) x1 = width - 1;
    l = x1 - x0;
    index = get_index(x0, y);
    if (edge) {
      if (!mask->at(index)) {
        draw_point(x0, y, 128);
        mask->set(index, true);
      }
      if (!mask->at(index + l)) {
        draw_point(x1, y, 128);
        mask->set(index + l, true);
      }
//      l -= 2;
      l --;
      index ++;
    }
    l += index;
    for (i = index; i < l; i ++)
      buf[i] = pc;

  }
}

void SketchPainter::draw_water_diamond(int cx, int cy,
                                       uint alpha) {
  int y, x0, y0, x1, y1, l, i, index, d, pw;
  uint16 pred, pgreen, pblue;
  unsigned long int p_rgb, rgb, pack;
  uint16* buf = this->buf();
//  QColor pc;

  if (alpha > 256)
    alpha = 256;
  alpha = alpha >> 3;
  if (alpha == 0)
    return;

  clip_to_this(&cx, &cy);

  p_rgb = disperse(pen.color());
  p_rgb *= alpha;
  pw = pen.width() >> 1;
  
  pred = ((uint16)(pen.color().red & 0xf8)) << 8;
  pgreen = ((uint16)(pen.color().green & 0xf8)) << 3;
  pblue = ((uint16)(pen.color().blue & 0xf8)) >> 2;

  y0 = cy - pw;
  if (y0 < 0) y0 = 0;
  y1 = cy + pw;
  if (y1 >= height) y1 = height - 1;
  
  for (y = y0; y <= y1; y ++) {
    d = cy - y;
    d = d >= 0 ? d : -d;
    x0 = (cx - (pw - d));
    x1 = (cx + (pw - d));

    if (x0 < 0) x0 = 0;
    if (x1 >= width) x1 = width - 1;
    l = x1 - x0;
    index = get_index(x0, y);
    for (i = 0; i < l; i ++)
      if (!mask->at(index + i)) {
        pack = buf[index + i];
        buf[index + i] = blend(pack, rgb, p_rgb, alpha,
                               pred, pgreen, pblue);
        mask->set(index + i, true);
      }

  }
}
  
void SketchPainter::draw_diamond(const PtPair &p, bool edge) {
  draw_diamond(p.x, p.y, edge);
}

void SketchPainter::draw_circle(int cx, int cy, bool edge) {
  int y, x0, y0, x1, y1, l, index, i, d;
  uint hw;
  uint16 *buf = this->buf();

  uint16 pc = pack_color(pen.color());

  pen_shape.setWidth(pen);
  hw = (uint)pen_shape.halfWidth();

  y0 = cy - hw;
  if (y0 < 0) y0 = 0;
  y1 = cy + hw;
  if (y1 >= height) y1 = height -1;

  for (y = y0; y <= y1; y ++) {
    d = cy -y;
    d = d >= 0 ? d : -d;
    x0 = cx - pen_shape.width(d);
    x1 = cx + pen_shape.width(d);

    if (x0 < 0) x0 = 0;
    if (x1 >= width) x1 = width - 1;
    l = x1 - x0;
    index = get_index(x0, y);

    if (edge) {
      if (!mask->at(index)) {
        draw_point(x0, y, pen_shape.alpha(d));
        mask->set(index, true);
      }
      if (!mask->at(index + l)) {
        draw_point(x0, y, pen_shape.alpha(d));
        mask->set(index + l, true);
      }

      l -= 2;
      index ++;
    }

    l += index;
    for (i = index; i < l; i ++) {
      buf[i] = pc;
      mask->set(i, true);
    }
  }
}

void SketchPainter::draw_circle(const PtPair &p, bool edge) {
  draw_circle(p.x, p.y, edge);
}

void SketchPainter::draw_water_diamond(const PtPair &p,
                                       uint alpha) {
  draw_water_diamond(p.x, p.y, alpha);
}

void SketchPainter::draw_water_circle(const PtPair &p,
                                      uint alpha) {
  draw_water_circle(p.x, p.y, alpha);
}

void SketchPainter::draw_water_circle(int cx, int cy, uint alpha) {
  int y, x0, y0, x1, y1, l, i, index, d, pw;
  uint16 pred, pgreen, pblue;
  unsigned long int p_rgb, rgb, pack;
  uint16* buf = this->buf();
//  QColor pc;

  if (alpha > 256)
    alpha = 256;
  alpha = alpha >> 3;
  if (alpha == 0)
    return;

  clip_to_this(&cx, &cy);

  p_rgb = disperse(pen.color());
  p_rgb *= alpha;

  pen_shape.setWidth(pen);
  pw = (uint)pen_shape.halfWidth();
  
  pred = ((uint16)(pen.color().red & 0xf8)) << 8;
  pgreen = ((uint16)(pen.color().green & 0xf8)) << 3;
  pblue = ((uint16)(pen.color().blue & 0xf8)) >> 2;

  y0 = cy - pw;
  if (y0 < 0) y0 = 0;
  y1 = cy + pw;
  if (y1 >= height) y1 = height - 1;
  
  for (y = y0; y <= y1; y ++) {
    d = cy - y;
    d = d >= 0 ? d : -d;
    x0 = cx - pen_shape.width(d);
    x1 = cx + pen_shape.width(d);

    if (x0 < 0) x0 = 0;
    if (x1 >= width) x1 = width - 1;
    l = x1 - x0;
    index = get_index(x0, y);
    for (i = 0; i < l; i ++)
      if (!mask->at(index + i)) {
        pack = buf[index + i];
        buf[index + i] = blend(pack, rgb, p_rgb, alpha,
                               pred, pgreen, pblue);
        mask->set(index + i, true);
      }

  }
}

void SketchPainter::drawLine(int x0, int y0, int x1, int y1) {
  if (!showing) return;
  
  switch (pen.brush_method) {
  case SolidBrush:
  case EraserBrush:
#if 0
    if (pen.width() <= pensize_small) {
      draw_diamond_line(x0, y0, x1, y1, pen.antialias);
      if (pen.width() <= pensize_tiny) {
	if (!pen.antialias || !(pen.dwidth() & 1)) {
	  draw_point(x0, y0, 256);
	  draw_point(x1, y1, 256);
	}
      } else {
        draw_diamond(x0, y0, pen.antialias);
        draw_diamond(x1, y1, pen.antialias);
      }
#endif
      if (pen.width() < pensize_tiny) {
	draw_diamond_line(x0, y0, x1, y1, false);
      } else if (pen.width() <= pensize_small) {
	draw_diamond_line(x0, y0, x1, y1, pen.antialias);
        draw_diamond(x0, y0, pen.antialias);
        draw_diamond(x1, y1, pen.antialias);
      } else {
	draw_line(x0, y0, x1, y1, pen.antialias);
	draw_circle(x0, y0, pen.antialias);
	draw_circle(x1, y1, pen.antialias);
      }
      break;
  case WaterBrush:
    if (pen.antialias && pen.width() < 1) {
      draw_water_line_w1(x0, y0, x1, y1, pen.density);
    } else {
      draw_water_line(x0, y0, x1, y1, pen.density);
      if (pen.width() > pensize_tiny) {
        draw_water_circle(x0, y0, pen.density);
        draw_water_circle(x1, y1, pen.density);
      }
    }
    break;
  case CloudWeakBrush:
  case CloudMidBrush:
  case CloudWideBrush:
    draw_cloud_line(x0, y0, x1, y1, pen.antialias);
    break;
  }
}

void SketchPainter::drawWaterLine(int x0, int y0, int x1, int y1,
                                  uint alpha) {
  if (!showing) return;

  draw_water_line(x0, y0, x1, y1, alpha);
}

void SketchPainter::drawLine(const PtPair &p0,
                             const PtPair &p1) {
  drawLine(p0.x, p0.y, p1.x, p1.y);
}

void SketchPainter::drawWaterLine(const PtPair &p0,
                                  const PtPair &p1,
                                  uint alpha) {
  drawWaterLine(p0.x, p0.y, p1.x, p1.y, alpha);
}

#if 0
void SketchPainter::drawPolyline(const QPointArray &pta) {
  if (!showing) return;

  int i, size;
  QPoint p0, p1;

  if (!(size = pta.size()))
    return;

  p1 = pta.point(0);

  if (size == 1) {
    drawPoint(p1);
    return;
  }

  for (i = 1; i < size; i ++) {
    p0 = p1;
    p1 = pta.point(i);
    draw_line(p0, p1);
    if (pen.width() > 4)
//      draw_diamond(p1);
      draw_circle(p1);
  }
}
#endif

void SketchPainter::fillRect16(int x0, int y0, int w, int h,
                unsigned short int pat) {
  unsigned long int lpat;

  lpat = (pat << 16) | pat;

  fillRect32(x0, y0, w, h, lpat);
}

void SketchPainter::fillRect16(const PtRect &r,
                               unsigned short int pat) {
  fillRect16(r.x, r.y, r.w, r.h, pat);
}

void SketchPainter::fillRect32(int x0, int y0, int w, int h,
                               unsigned long int pat) {
  if (!showing) return;
  
  int x1, y1, y, i, j, w2;
  uint16* buf = this->buf();
  unsigned long int *buf32 = (unsigned long int*)buf;

  x1 = x0 + w - 1;
  y1 = y0 + h - 1;
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) {
    unsigned short int pat1 = pat & 0xffff;

    for (y = y0; y <= y1; y ++)
      buf[get_index(x0, y)] = pat1;
  }

  x0 &= ~1;
  w = x1 - x0 + 1;
  h = y1 - y0 + 1;
  w2 = w >> 1;
  
  for (y = y0; y <= y1; y ++) {
    i = get_index(x0, y) >> 1;
    for (j = 0; j < w2; j ++)
      buf32[i + j] = pat;
  }

  if (w & 1) {
    unsigned short int pat0 = pat >> 16;

    for (y = y0; y <= y1; y ++)
      buf[get_index(x1, y)] = pat0;
  }
}

void SketchPainter::fillRect32(const PtRect &r,
                               unsigned long int pat) {
  fillRect32(r.x, r.y, r.w, r.h, pat);
}

void SketchPainter::invertRect(int x0, int y0, int w, int h) {
  if (!showing) return;
  
  int x1, y1, y, i, j, w2;
  uint16* buf = this->buf();
  unsigned long int *buf32 = (unsigned long int*)buf;

  x1 = x0 + w - 1;
  y1 = y0 + h - 1;
  clip_to_this(&x0, &y0);
  clip_to_this(&x1, &y1);

  if (x0 & 1) {
    for (y = y0; y <= y1; y ++) {
      i = get_index(x0, y);
      buf[i] = ~buf[i];
    }
    x0 ++;
  }

  x0 &= ~1;
  w = x1 - x0 + 1;
  h = y1 - y0 + 1;
  w2 = w >> 1;

  for (y = y0; y <= y1; y ++) {
    i = get_index(x0, y) >> 1;
    for (j = 0; j < w2; j ++)
      buf32[i + j] = ~buf32[i + j];
  }

  if (w & 1)
    for (y = y0; y <= y1; y ++) {
      i = get_index(x1, y);
      buf[i] = ~buf[i];
    }
}

void SketchPainter::invertRect(const PtRect &r) {
  invertRect(r.x, r.y, r.w, r.h);
}

void SketchPainter::mirrorHorizontal(void) {
  int halfw = width >> 1;
  int hw = height * width;
  int x0, x1;
  unsigned short int d;
  uint16* buf = this->buf();

  for (x0 = 0; x0 < halfw; x0 ++) {
    x1 = width - 1 - x0;
    for (int y = 0; y < hw; y += width) {
      d = buf[y + x0];
      buf[y + x0] = buf[y + x1];
      buf[y + x1] = d;
    }
  }
}

void SketchPainter::mirrorVertical(void) {
  uint16* buf = this->buf();
  uint32a *buf32 = (uint32a*)buf;
  int halfh = height >> 1;
  int halfw = width >> 1;
  int y0, y1;
  uint32a d;

  for (int y = 0; y < halfh; y ++) {
    y0 = y * width / 2;
    y1 = (height - 1 - y) * width / 2;
    for (int x = 0; x < halfw; x ++) {
      d = buf32[y0 + x];
      buf32[y0 + x] = buf32[y1 + x];
      buf32[y1 + x] = d;
    }
  }
}

void SketchPainter::rotateCW(void) {
  uint16 *new_buf;
  int x, y;
  uint16 *buf = this->buf();

  NSMutableData *newbufdata = [[NSMutableData alloc]
			       initWithLength:sizeof(uint16) * width * height];
  new_buf = (uint16*)[newbufdata mutableBytes];

  for (y = 0; y < height; y ++)
    for (x = 0; x < width; x ++)
      new_buf[x * height + height - y -1] =
        buf[y * width + x];

  setSize(height, width);
  [bufdata release];
  bufdata = newbufdata;
}

void SketchPainter::rotateCCW(void) {
  uint16 *new_buf;
  int x, y;
  uint16* buf = this->buf();

  NSMutableData* newbufdata = [[NSMutableData alloc]
			       initWithLength:sizeof(uint16) * width * height];
  new_buf = (uint16*)[newbufdata mutableBytes];

  for (y = 0; y < height; y ++)
    for (x = 0; x < width; x ++)
      new_buf[(width - x - 1) * height + y] =
        buf[y * width + x];

  setSize(height, width);
  [bufdata release];
  bufdata = newbufdata;
}

PtPair& SketchPainter::copyWithShift(uint16 *sbuf, PtPair &diff) {
  int dx = (diff.x + width) % width;
  int dy = (diff.y + height) % height;
  uint16 *buf = this->buf();

  if (dx & 1) {
    int x, y, height_dy, width_dx;
    uint sindex, dindex;
    unsigned short int a;

    height_dy = height - dy;
    width_dx = width - dx;

    for (y = 0; y < height_dy; y ++) {
      sindex = (dy + y) * width + dx;
      dindex = y * width;
      for (x = 0; x < width_dx; x ++) {
	a = sbuf[sindex ++];
	buf[dindex ++] = a;
      }

      sindex = (dy + y) * width;
      for (x = 0; x < dx; x ++) {
	a = sbuf[sindex ++];
	buf[dindex ++] = a;
      }
    }

    for (y = height_dy; y < height; y ++) {
      sindex = (y - height_dy) * width + dx;
      dindex = y * width;
      for (x = 0; x < width_dx; x ++) {
	a = sbuf[sindex ++];
	buf[dindex ++] = a;
      }

      sindex = (y - height_dy) * width;
      for (x = 0; x < dx; x ++) {
	a = sbuf[sindex ++];
	buf[dindex ++] = a;
      }
    }
  } else {
    int x, y, height_dy, width_dx, width_, dx_;
    uint sindex, dindex;
    uint32a* buf32 = (uint32a*)buf;
    uint32a* sbuf32 = (uint32a*)sbuf;

    height_dy = height - dy;
    width_dx = (width - dx) >> 1;
    width_ = width >> 1;
    dx_ = dx >> 1;

    for (y = 0; y < height_dy; y ++) {
      sindex = (dy + y) * width_ + dx_;
      dindex = y * width_;
      for (x = 0; x < width_dx; x ++)
	buf32[dindex ++] = sbuf32[sindex ++];
      
      sindex = (dy + y) * width_;
      for (x = 0; x < dx_; x ++)
	buf32[dindex ++] = sbuf32[sindex ++];
    }

    for (y = height_dy; y < height; y ++) {
      sindex = (y - height_dy) * width_ + dx_;
      dindex = y * width_;
      for (x = 0; x < width_dx; x ++)
	buf32[dindex ++] = sbuf32[sindex ++];

      sindex = (y - height_dy) * width_;
      for (x = 0; x < dx_; x ++)
	buf32[dindex ++] = sbuf32[sindex ++];
    }
  }

  shift.x = ((dx + shift.x) % width);
  shift.y = ((dy + shift.y) % height);
  
  return shift;
}

#if 0
// It seems that Zaurus's behavior (or ARM's uint[]?)
// have difference with emulator's one.
// This routine works fine in Qtopia on emulator on PC,
// though it works curiously on SL-C760.
PtPair& SketchPainter::copyWithShift(uint16 *sbuf, PtPari &diff) {
  int x, y, height_dy, width_dx, width_, dx_;
  uint sindex, dindex;
  int dx = (diff.x() + width) % width;
  int dy = (diff.y() + height) % height;
  uint16* buf = this->buf;
  uint32a* buf32 = (uint32a*)buf;
  uint32a* sbuf32 = (uint32a*)(sbuf + (dx & 1));

  height_dy = height - dy;
  width_dx = (width - dx) >> 1;
  width_ = width >> 1;
  dx_ = dx >> 1;

  for (y = 0; y < height_dy; y ++) {
    sindex = (dy + y) * width_ + dx_;
    dindex = y * width_;
    for (x = 0; x < width_dx; x ++)
      buf32[dindex ++] = sbuf32[sindex ++];

    if (dx & 1) dindex ++;
    
    sindex = (dy + y) * width_;
    for (x = 0; x < dx_; x ++)
      buf32[dindex ++] = sbuf32[sindex ++];
  }

  for (y = height_dy; y < height; y ++) {
    sindex = (y - height_dy) * width_ + dx_;
    dindex = y * width_;
    for (x = 0; x < width_dx; x ++)
      buf32[dindex ++] = sbuf32[sindex ++];

    if (dx & 1) dindex ++;

    sindex = (y - height_dy) * width_;
    for (x = 0; x < dx_; x ++)
      buf32[dindex ++] = sbuf32[sindex ++];
  }

  if (dx && 1) {
    sindex = dy * width + width - 1;
    dindex = width - dx - 1;
    for (y = 0; y < height_dy; y ++) {
      buf[dindex] = sbuf[sindex];
      dindex += width;
      sindex += width;
    }

    sindex = dy * width;
    dindex = width - dx;
    for (y = 0; y < height_dy; y ++) {
      buf[dindex] = sbuf[sindex];
      dindex += width;
      sindex += width;
    }

    sindex = width - 1;
    dindex = height_dy * width + width - dx - 1;
    for (y = 0; y < dy; y ++) {
      buf[dindex] = sbuf[sindex];
      dindex += width;
      sindex += width;
    }

    sindex = 0;
    dindex = height_dy * width + width - dx;;
    for (y = 0; y < dy; y ++) {
      buf[dindex] = sbuf[sindex];
      dindex += width;
      sindex += width;
    }
  }
  
  shift.x = ((dx + shift.x) % width);
  shift.y = ((dy + shift.y) % height);
  
  return shift;
}
#endif

void SketchPainter::copyClipboard(PtRect &rect) {
  int x0, y0, w, h, x, y;
  uint16 *cbuf, a;
  uint16 *buf = this->buf();

  x0 = rect.x;
  y0 = rect.y;
  w = rect.w;
  h = rect.h;

  cbuf = clipboard.resize(w, h);
  clipboard.setParent(this);
  clipboard.setPasteMode(false);
  clipboard.setX(x0);
  clipboard.setY(y0);

  int index, cindex;
  for (y = 0; y < h; y ++) {
    index = (y0 + y) * width + x0;
    cindex = y * w;
    for (x = 0; x < w; x ++) {
      a = buf[index ++];
      cbuf[cindex ++] = a;
    }
  }
}

void SketchPainter::pasteClipboard(PtPair &pt) {
  int x0, y0, w, h, x, y, w2, h2;
  uint16 *cbuf, a;
  uint16 *buf = this->buf();

  x0 = pt.x;
  y0 = pt.y;

  w = w2 = clipboard.width();
  h = h2 = clipboard.height();
  cbuf = clipboard.frameBuffer();

  if (!cbuf) return;
  
  clipboard.setPasteMode(false);

  if (x0 + w2 >= width)
    w2 = width - 1 - x0;
  if (y0 + h2 >= height)
    h2 = height - 1 - y0;

  int index, cindex;
  for (y = 0; y < h2; y ++) {
    if (y0 + y >= 0) {
      index = (y0 + y) * width + x0;
      cindex = y * w;
      for (x = 0; x < w2; x ++)
	if (x0 + x >= 0) {
	  a = cbuf[cindex + x];
	  buf[index + x] = a;
	}
    }
  }
}

PtColor SketchPainter::pickColor(int x, int y) {
  return unpack_color(buf()[get_index(x, y)]);
}

#if 0
void SketchPainter::setUIImage(UIImage *img) {
  NSData* ibuf;
  CGDataProviderRef imgprov;
  double ratio, ratio_w, ratio_h;
  uint16 *buf = this->buf();
  uint x, y, index, offset_x, offset_y, offset;
  CFIndex datasize;

  CGImageRef cgimg = img.CGImage;
  uint bpp = CGImageGetBitsPerPixel(cgimg);
  uint bpr = CGImageGetBytesPerRow(cgimg);
  uint imgw = CGImageGetWidth(cgimg);
  uint imgh = CGImageGetHeight(cgimg);

  if (imgw == width)
    ratio_w = 1.0;
  else
    ratio_w = (double)(imgw - 1) / width;
  if (imgh == height)
    ratio_h = 1.0;
  else
    ratio_h = (double)(imgh - 1) / height;
  ratio = (ratio_w < ratio_h) ? ratio_w : ratio_h;
  offset_x = max(0, (int)floor((imgw - width * ratio) / 2));
  offset_y = max(0, (int)floor((imgh - height * ratio) / 2));

  imgprov = CGImageGetDataProvider(cgimg);
  ibuf = (NSData*)CGDataProviderCopyData(imgprov);
  [ibuf autorelease];

  ALog(@"bits per pixel %d", bpp);

  if (ibuf) {
    if (bpp == 16) {
      uint16 a;
      const uint16 *imgbuf = (uint16*)[ibuf bytes];
      datasize = [ibuf length] / 2;
	  
      offset = offset_y * (bpr / 2) + offset_x;
      for (y = 0; y < height; y ++)
	for (x = 0; x < width; x ++) {
	  index = offset + 
	    (uint)floor(y * ratio) * (bpr / 2) +
	    (uint)floor(x * ratio);
	  if (index < datasize) {
	    a = imgbuf[index];
	    buf[y * width +  x] = (a << 1);
	  }
	}
    } else if (bpp == 32) {
      PtColor col;
      const UInt8* imgbuf = (UInt8*)[ibuf bytes];
      datasize = [ibuf length];
      
      offset = offset_y * (bpr / 4) + offset_x;
      for (y = 0; y < height; y ++)
	for (x = 0; x < width; x ++) {
	  index = offset +
	    (uint)floor(y * ratio) * bpr +
	    (uint)floor(x * ratio) * 4;
	  if (index < datasize) {
	    col.setRgb(imgbuf[index + 2],
		       imgbuf[index + 1],
		       imgbuf[index + 0]);
	    buf[y * width +  x] =
	      SketchPainter::pack_color(col);
	  }
	}
    } else {
      SingletonJunction::showMessage(@"unknown file format");
    }
  }
}
#endif

void SketchPainter::setUIImage(UIImage *img) {
  double ratio, ratio_w, ratio_h;
  uint16 *buf = this->buf();
  uint x, y, index, offset_x, offset_y, offset;
  int imgw, imgh;
  uint16 *imgbuf;
  imgbuf = PtImageUtil::UIImagetoUint16(img, &imgw, &imgh);

  ratio_w = (double)imgw / width;
  ratio_h = (double)imgh / height;
  ratio = (ratio_w < ratio_h) ? ratio_w : ratio_h;
  offset_x = max(0, (int)floor((imgw - width * ratio) / 2));
  offset_y = max(0, (int)floor((imgh - height * ratio) / 2));

  offset = offset_y * imgw + offset_x;
  for (y = 0; y < height; y ++)
    for (x = 0; x < width; x ++) {
      index = (offset + 
	       (uint)floor(y * ratio) * imgw +
	       (uint)floor(x * ratio));
      buf[y * width + x] = imgbuf[index];
    }
  delete[] imgbuf;
}

#if 0
void SketchPainter::getNSImageR270(NSImage *img,
                                  const NSRect &r) {
//  QColor col;
  PtRect rect(r);
  int i, x, y, x0, y0, x1, y1, index;
  unsigned long int *p;
  uint16 *buf = this->buf();

  if (!(rect.w * rect.h))
    rect.setRect(0, 0, height, width);
  
  img->create(rect.width(), rect.height(), 32);
  p = (unsigned long int*)img->bits();

  i = 0;
  x0 = rect.left();
  y0 = width - 1 - rect.bottom();
  x1 = rect.right();
  y1 = width - 1 - rect.top();
  for (x = y1; x >= y0; x --) {
    index = get_index(x, x0);
    for (y = x0; y <= x1; y ++) {
//      col = unpack_color(buf[index]);
//      p[i ++] = col.rgb();
      p[i ++] = rgb32(buf[index]);
      index += width;
    }
  }
}

void SketchPainter::getQImageR0(QImage *img,
                                const QRect &r) {
//  QColor col;
  QRect rect(r);
  int i, x, y, x0, y0, x1, y1, index;
  unsigned long int *p;
  uint16 *buf = this->buf();

  if (!rect.isValid())
    rect.setRect(0, 0, width, height);

  img->create(rect.width(), rect.height(), 32);
  p = (unsigned long int*)img->bits();

  i = 0;
  x0 = rect.left();
  y0 = rect.top();
  x1 = rect.right();
  y1 = rect.bottom();
  for (y = y0; y <= y1; y ++) {
    index = get_index(x0, y);
    for (x = x0; x <= x1; x ++) {
//      col = unpack_color(buf[index ++]);
//      p[i ++] = col.rgb();
      p[i ++] = rgb32(buf[index ++]);
    }
  }
}

void SketchPainter::getQImage(QImage *img, int o) {
  getQImage(img, QRect(), o);
}

void SketchPainter::getQImage(QImage *img,
                              const QRect &rect, int o) {
  getQImageR0(img, rect);
}

void SketchPainter::setQImage(const QImage &img) {
  int x, y, fx, fy;
  QColor col;
  int o = (width != img.width());

  img.convertDepth(32);
  
  for (y = 0; y < height; y ++)
    for (x = 0; x < width; x ++) {
      if (o) {
        fx = y;
        fy = width - 1 - x;
      } else {
        fx = x;
        fy = y;
      }
      if (img.valid(fx, fy)) {
        col.setRgb(img.pixel(fx, fy));
        buf[get_index(x, y)] = pack_color(col);
      }
    }
}

bool SketchPainter::load(const QString &fn,
                         const char *format) {
  QImage img;

  if (img.load(fn, format)) {
    setQImage(img);
    return true;
  } else
    return FALSE;
}

bool SketchPainter::save(const QString &fn,
                         const char* format) {
  QImage img;
  getQImage(&img);

  return img.save(fn, format);
}
#endif
 
UIImage* SketchPainter::getUIImage(const PtRect &rect) {
  PtRect r = rect;
  if (!(r.w * r.h))
    r = PtRect(0, 0, width, height);

  return PtImageUtil::uint16toUIImage(this->buf(), width, r.x, r.y, r.w, r.h);
}

unsigned short int SketchPainter::pack_color(const PtColor &c) {
  uint r, g, b;

  r = (c.red >> 3);
  g = (c.green >> 3);
  b = (c.blue >> 3);

  return r << 11 | g << 6 | b << 1;
}

PtColor SketchPainter::unpack_color(unsigned short int p) {
  int r, g, b;

  r = ((p >> 8) & 0xf8) | 7;
  g = ((p >> 3) & 0xf8) | 7;
  b = ((p << 2) & 0xf8) | 7;
  PtColor c(r, g, b);

  return c;
}

inline uint32a SketchPainter::unpack_color_uint32(uint16 p) {
  return ((p & 0xf100) << 8) |
    ((p & 0x07c0) << 5) |
      ((p & 0x003e) << 2);
}

////////////////////////////////////////////////////////////
// PenShape

PenShape::PenShape(void) {
  half_width = 0.0;
  table = new uchar[SingletonJunction::penWidthMax >> 1];
  alphas = new uchar[SingletonJunction::penWidthMax >> 1];
}

PenShape::~PenShape(void) {
	delete [] table;
	delete [] alphas;
}

void PenShape::setHalfWidth(double hw) {
  if (half_width == hw) return;
  
  half_width = hw;

  double hw2 = hw*hw;
  double l;
  uint li;

  for (uint y = 0; y < hw; y ++) {
    l = sqrt(hw2 - y*y);
    li = (uint)ceil(l);
    table[y] = (uchar)li;
    alphas[y] = (uchar)(floor((l - li + 1) * 0x100));
  }
}

void PenShape::setWidth(PtPen &pen) {
  setHalfWidth((double)pen.width() / 2.0 - 0.5);
}

uchar PenShape::width(uint y) {
  if (y < half_width)
    return table[y];
  else
    return 0;
}

uchar PenShape::alpha(uint y) {
  if (y < half_width)
    return (uchar)alphas[y];
  else
    return 0;
}

////////////////////////////////////////////////////////////
// PtBitArray

PtBitArray::PtBitArray(void) {
	_bytes = new uchar[1];
	_size = 0;
}

PtBitArray::PtBitArray(uint size) {
   	uint al = (size >> 5) + 1;
	uint32a* ui32s = new uint32a[al];
	_size = size;
	
	for (int i = 0; i < al; i ++)
		ui32s[i] = 0;
	_bytes = (uchar *)ui32s;
}

PtBitArray::~PtBitArray(void) {
	delete [] _bytes;
}

bool PtBitArray::at(uint index) {
	return _bytes[index >> 3]  & (1 << (index & 7));
}

void PtBitArray::set(uint index, bool value) {
	if (value)
		_bytes[index >> 3] |= (1 << (index & 7));
	else
		_bytes[index >> 3] &= ~(1 << (index & 7));
}

bool PtBitArray::fill(bool val) {
	uint32a fval = val ? 0xffffffff : 0;
	uint al = (_size >> 5) + 1;
	uint32a * ui32s = (uint32a *)_bytes;
	for (int i = 0; i < al; i ++)
		ui32s[i] = fval;
	return true;
}

bool PtBitArray::fill(bool val, uint size) {
	delete [] _bytes;
	
	uint al = (size >> 5) + 1;
        _size = size;
	_bytes = (uchar*)(new uint32a[al]);
	if (!_bytes) return false;
	fill(val);
	return true;
}
