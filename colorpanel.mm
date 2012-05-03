/*
 **	colorpanel.cpp
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 September 9
 */

//#include <qimage.h>
//#import <Cocoa/Cocoa.h>
//#include <qfile.h>
//#include <qstring.h>

#include "sketchpainter.h"
#include "rgb_hsv.h"
#include "colorpalette.h"
#include "colorpanel.h"
#import "ptpanelview.h"

////////////////////////////////////////////////////////////
//	ColorPanel

ColorPanel::ColorPanel(int w, int h, const PtColor &init_col) {
  width = w;
  height = h;

  int l = width * height;
  
  buf = new uint16[l];
  uint32a *buf32 = (uint32a*)buf;
  for (int i = 0; i < (l >> 1); i ++)
    buf32[i] = 0x0000ffff;

  optpanelview = SingletonJunction::optpanelview;
  optpanelview.buf = buf;
  
  hue = new HueLine(w, 20);
  sat_lum = new SatLum();

  hue_rect = PtRect(0, 10, hue->width, hue->height);
  satlum_rect = PtRect(10, 40, sat_lum->width, sat_lum->height);

  int x, y;
  for (y = 0; y < hue->height; y ++) 
    for (x = 0; x < hue->width; x ++)
      buf[(hue_rect.top() + y)*width + hue_rect.left() + x] =
        hue->buf[y * hue->width + x];

  dlg_btn = PtRect(210, 50, 20, 20);
  cancel_btn = PtRect(190, 100, 40, 40);
  ok_btn = PtRect(190, 170, 40, 40);

  palette_rect = PtRect(0, 220, w, 20);
  palette = new ColorPalette(palette_rect.w,
                             palette_rect.h);

  fillRect(dlg_btn, 0xffff);
  setInitColor(init_col);
  user_palette = false;
  mode = ModeNone;

  SingletonJunction::colorpanel = this;
}

ColorPanel::~ColorPanel(void) {
#if 0
  delete hue;
  delete sat_lum;
  delete buf;
  delete palette;
#endif
}

void ColorPanel::fillRect(const PtRect &rect, uint16 col) {
	int x0, x1, y0, y1, index;
	
	x0 = rect.left();
	x1 = rect.right();
	y0 = rect.top();
	y1 = rect.bottom();
	
	for (int y = y0; y < y1; y ++) {
		index = y * width + x0;
		for (int x = x0; x < x1; x ++)
			buf[index ++] = col;
	}
}

void ColorPanel::setInitColor(const PtColor &col) {
  fillRect(cancel_btn, SketchPainter::pack_color(col));

  setColor(col);
}

void ColorPanel::setColor(const PtColor &col, bool modify_hsl) {
	rgb_hsv.setColor(col);
	sat_num = rgb_hsv.chroma();
	lum_num = rgb_hsv.luminance();

	if (modify_hsl)
		sat_lum->setColor(rgb_hsv.hue());

	fillRect(ok_btn, SketchPainter::pack_color(col));
}

void ColorPanel::setHue(uint hue) {
//  setHueSatLum(hue, sat_num, lum_num);
  rgb_hsv.setHCL(hue, sat_num, lum_num);
  sat_lum->setColor(hue);
}

PtPair ColorPanel::huePoint(int o) {
  int x, y;

  x = hue_rect.left() + rgb_hsv.hue() * width / 0x600;
  y = hue_rect.top() + hue_rect.h / 2;

  if (o)
    return PtPair(y, width - 1 - x);
  else
    return PtPair(x, y);
}

PtPair ColorPanel::satlumPoint(int o) {
  int x, y;

  x = satlum_rect.left() + 
    lum_num * sat_lum->width / 256;
  y = satlum_rect.top() +
    sat_num * sat_lum->height / 256;

  if (o)
    return PtPair(y, width - 1 - x);
  else
    return PtPair(x, y);
}

uint16* ColorPanel::infoImage(void) {
  int x, y, x0, y0, index, index2;

  y0 = satlum_rect.top();
  x0 = satlum_rect.left();
  for (y = 0; y < sat_lum->height; y ++) {
    index = (y0 + y) * width + x0;
    index2 = y * sat_lum->width;
    for (x = 0; x < sat_lum->width; x ++)
      buf[index ++] = sat_lum->buf[index2 ++];
  }
  
  return buf;
}

PtPair ColorPanel::size(void) {
  return PtPair(width, height);
}

void ColorPanel::setUserPalette(NSString *fn) {
  uint w, h, x, y;

  palette->setImage(fn);

  w = palette_rect.w;
  h = palette_rect.h;
  uint16 pbuf[w * h];

  palette->infoImage(pbuf);

  for (y = 0; y < h; y ++)
    for (x = 0; x < w; x ++)
      buf[(palette_rect.top() + y) * width +
          palette_rect.left() + x]
        = pbuf[y * w + x];

  user_palette = true;
}

PtColor ColorPanel::getColor(uint x, uint y) {
  if (x >= width || y >= height)
    return PtColor(255, 255, 255);

  uint16 *buf = infoImage();

  return SketchPainter::unpack_color(buf[y * width + x]);
}

void ColorPanel::clicked(int x, int y, bool move) {
  if (ok_btn.contains(x, y) && !move && !mode) {
    mode = ModePaletteSetting;
  } else if (palette_rect.contains(x, y) && !move) {
    mode = ModePaletteClearing;
    palette_index = palette->getIndex(x, y);
  } else if (!mode && hue_rect.contains(x, y))
    hue->clicked(x);
  else if (!move && satlum_rect.contains(x, y)) {
    mode = ModeSatLum;
    sat_lum->clicked(x - satlum_rect.left(),
                     y - satlum_rect.top());
  } else if (mode == ModeSatLum && move &&
           satlum_rect.contains(x, y))
    sat_lum->clicked(x - satlum_rect.left(),
                     y - satlum_rect.top());
}

void ColorPanel::released(int x, int y) {
  if ((mode == ModePaletteSetting) &&
      palette_rect.contains(x, y)) {
    uint16 col = buf[ok_btn.y * width + ok_btn.x];

    palette->setColor(x, y, col);
    SingletonJunction::paletteChanged();
    setUserPalette();
  } else if ((mode == ModePaletteClearing) &&
             (cancel_btn.contains(x, y) ||
              ok_btn.contains(x, y))) {
    palette->setChanged(palette_index, false);
    SingletonJunction::paletteChanged();
    setUserPalette();
  } else if ((mode == ModePaletteClearing) &&
             palette_rect.contains(x, y)) {
    setColor(SketchPainter::unpack_color(buf[y * width + x]));
    SingletonJunction::colorpanel_selected(buf[y * width + x]);
  } else if (cancel_btn.contains(x, y)) {
    SingletonJunction::colorpanel_selected(buf[cancel_btn.y * width + cancel_btn.x]);
    SingletonJunction::colorpanel_finished();
  } else if (ok_btn.contains(x, y)) {
    SingletonJunction::colorpanel_selected(buf[ok_btn.y * width + ok_btn.x]);
    SingletonJunction::colorpanel_finished();
  } else if (dlg_btn.contains(x, y)) {
    SingletonJunction::colorpanel_finished();
    SingletonJunction::colorpanel_showDialog(SketchPainter::unpack_color(
       buf[ok_btn.y * width + ok_btn.x]));
  }

  if (mode) mode = ModeNone;
}

void ColorPanel::setHueSatLum(int hue, int sat, int lum) {
  rgb_hsv.setHCL(hue, sat, lum);
  PtColor col = rgb_hsv.getColor();

  setColor(col, false);
  sat_num = sat;
  lum_num = lum;

  SingletonJunction::colorpanel_selected(SketchPainter::pack_color(col));
}

////////////////////////////////////////////////////////////
//	HueLIne

HueLine::HueLine(int w, int h) {
  width = w;
  height = h;
  
  buf = new uint16[w * h];

  RGB_HSV rgb_hsv;
  int x, y;
  uint c;

  for (x = 0; x < width; x ++) {
    rgb_hsv.setHCL(x * 0x600 / width, 256, 128);
    c = rgb_hsv.packed();
    for (y = 0; y < height; y ++)
      buf[y * width + x] = c;
  }
}

void HueLine::clicked(uint x) {
  SingletonJunction::hueChanged(x * 0x600 / width);
}

////////////////////////////////////////////////////////////
//	SatLum

SatLum::SatLum(uint hue) {
  buf = new uint16[width * height];

  setColor(hue);
}

void SatLum::setColor(uint h) {
  int r, g, b, h2, *_max, *_mid, *_min;
  uint r2, g2, b2, *_max2, *_mid2, *_min2;
  int l_mid, l_min;
  RGB_HSV rh;

  hue = h;

  if (h < 0x100) {
    _max = &r; _max2 = &r2;
    _min = &g; l_min = rh.g_lum; _min2 = &g2;
    _mid = &b; l_mid = rh.b_lum; _mid2 = &b2;
    h2 = 0x100 - h;
  } else if (h < 0x200) {
    _max = &r; _max2 = &r2;
    _min = &b; l_min = rh.b_lum; _min2 = &b2;
    _mid = &g; l_mid = rh.g_lum; _mid2 = &g2;
    h2 = h - 0x100;
  } else if (h < 0x300) {
    _max = &g; _max2 = &g2;
    _min = &b; l_min = rh.b_lum; _min2 = &b2;
    _mid = &r; l_mid = rh.r_lum; _mid2 = &r2;
    h2 = 0x300 - h;
  } else if (h < 0x400) {
    _max = &g; _max2 = &g2;
    _min = &r; l_min = rh.r_lum; _min2 = &r2;
    _mid = &b; l_mid = rh.b_lum; _mid2 = &b2;
    h2 = h - 0x300;
  } else if (h < 0x500) {
    _max = &b; _max2 = &b2;
    _min = &r; l_min = rh.r_lum; _min2 = &r2;
    _mid = &g; l_mid = rh.g_lum; _mid2 = &g2;
    h2 = 0x500 - h;
  } else {
    _max = &b; _max2 = &b2;
    _min = &g; l_min = rh.g_lum; _min2 = &g2;
    _mid = &r; l_mid = rh.r_lum; _mid2 = &r2;
    h2 = h - 0x500;
  }

  int x, y;
  uint l, l2;
  uint32a c32;
  
  for (y = 0; y < height; y ++) {
//    c32 = y * 256 / height;
    c32 = (y * 3) >> 1;  /* c32 = y * 256 / 171 */
    *_max = 256;
    *_min = 256 - c32;
    *_mid = *_min + (h2 * c32 >> 8);
    for (x = 0; x < width; x ++) {
//      l = x * 256 / width;
      l = (x * 3) >> 1;  /* l = x * 256 / 171 */
      l2 = rh.luminance(r, g, b);
      if (l2) {
        r2 = l * r / l2;
        g2 = l * g / l2;
        b2 = l * b / l2;

        if (*_max2 > 255) {
          c32 = ((uint32a)(256 - l) << 16) /
            ((uint32a)(l_min << 8) + (uint32a)(256 - h2) * l_mid);
          *_max2 = 255;
          *_min2 = 256 - c32;
          *_mid2 = *_min2 + (h2 * c32 >> 8);
        }
      
        r2 = umin(r2, (uint)255);
        g2 = umin(g2, (uint)255);
        b2 = umin(b2, (uint)255);
      } else 
        r2 = g2 = b2 = l;

      buf[y * width + x] = ((r2 & 0xf8) << 8) |
        ((g2 & 0xf8) << 3) | ((b2 & 0xf8) >> 2);
    }
  }
}

void SatLum::clicked(int x, int y) {
//  RGB_HSV rh;
  int c, l;

  l = x * 256 / width;
  c = y * 256 / height;

//  rh.setHCL(hue, c, l);

  SingletonJunction::satlum_selected(hue, c, l);
}
