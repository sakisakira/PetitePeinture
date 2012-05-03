/*
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 July 4
 */

#include <stdio.h>
//#include <qimage.h>
#include <cmath>
//#include <qfile.h>
//#include <qpe/resource.h>
//#import <Cocoa/Cocoa.h>

#include "constants.h"
#include "sketchpainter.h"
#include "colorpalette.h"
#include "ptpen.h"
#include "toolpanel.h"
#include "singletonjunction.h"
#import "ptpanelview.h"

NSString* ToolPanel::ToolPanelFileName = @"petitpeintu_toolpanel.tiff";
NSString* ToolPanel::ToolPanelBFileName = @"petitpeintu_toolpanel_b.tiff";

ToolPanel::ToolPanel(NSString *fname, int w) {
  initialize(fname, w);
}

ToolPanel::ToolPanel(int w) {
  initialize(ToolPanelFileName, w);
}

ToolPanel::~ToolPanel() {
  delete buf;
  delete buf_b;
  delete sp;
  delete color_palette;
}

void ToolPanel::initialize(NSString *fname, int w) {
  CFDataRef img = 0;
  CFDataRef img_b = 0;

  panelview = SingletonJunction::panelview;

  if (!fname)
    fname = ToolPanelFileName;
  
  UIImage* uiimg = [UIImage imageNamed:fname];
  UIImage* uiimg_b = [UIImage imageNamed:ToolPanelBFileName];
  img = CGDataProviderCopyData(CGImageGetDataProvider(uiimg.CGImage));
  img_b = CGDataProviderCopyData(CGImageGetDataProvider(uiimg_b.CGImage));

  if (img && img_b) {
    PtColor col;
    int x, y, fx;
    int imgw, imgh;
	  
    imgw = uiimg.size.width;
    imgh = uiimg.size.height;
    ALog(@"ToolPanel::initialize: %d %d", imgw, imgh);

    width = w > imgw ? imgw : w;
    width &= ~1;
    height = imgh;
    buf = new unsigned short int[width * height];
    buf_b = new unsigned short int[width * height];
    sp = new SketchPainter(width, height);
    
    panelview.buf = sp->frameBuffer();

    if (width >= imgw)
      ratio = 1.0;
    else
      ratio = ((double)imgw) / width;

    ALog(@"ToolPanel::initialize() ratio %f", ratio);
    UInt8* imgbuf = (UInt8*)CFDataGetBytePtr(img);
    UInt8* imgbuf_b = (UInt8*)CFDataGetBytePtr(img_b);

    uint index;
    for (y = 0; y < imgh; y ++)
      for (x = 0; x < width; x ++) {
        fx = (int)(x * ratio);
        index = (imgw * y + fx) * 3;
        col.setRgb(imgbuf[index + 0],
                   imgbuf[index + 1],
                   imgbuf[index + 2]);
        buf[(y) * width + x] =
          SketchPainter::pack_color(col);
        col.setRgb(imgbuf_b[index + 0],
                   imgbuf_b[index + 1],
                   imgbuf_b[index + 2]);
        buf_b[(y) * width + x] =
          SketchPainter::pack_color(col);
        }

    setup_toolrects();
  } else {
    ALog(@"cannot open image %@", fname);
  }
  
  if (img) CFRelease(img);
  if (img_b) CFRelease(img_b);

  setColorPalette(@"");
}

void ToolPanel::setup_toolrects(void) {
  float btn_w = (float)(width - PenInfoWidth) /
    (NumOfButtons + 1);

  toolrects.resize(NumOfToolIndex);

  toolrects[PaletteI].setRect(0, 0,
                              floor(width - btn_w),
                              ColorPaletteHeight);
  color_palette =
    new ColorPalette(toolrects[PaletteI].w,
		     toolrects[PaletteI].h);

  int x, y, h;
  y = ColorPaletteHeight;
  h = ToolButtonHeight;
  toolrects[PanelSwitchI].setRect(0, y, btn_w, h);
  for (int i = CloudI; i <= PencilI; i ++) {
    x = ceil(btn_w * i);
    toolrects[i].setRect(x, y, btn_w, h);
    toolrects[SelectI - CloudI + i]
      .setRect(x, y, btn_w, h);
  }

  toolrects[PenInfoI].setRect(btn_w * NumOfButtons, 
                              ColorPaletteHeight,
			      PenInfoWidth,
			      ToolButtonHeight);

  toolrects[LayerI].setRect(ceil(width - btn_w),
			   0,
			   btn_w,
			   ColorPaletteHeight
			   + ToolButtonHeight);

  x = ceil(width - btn_w);
  h = (ColorPaletteHeight + ToolButtonHeight) 
    / NumOfLayers0 - 1;

  for (uint i = 0; i < NumOfLayers0; i ++) {
    y = (NumOfLayers0 - 1 - i) * 
      (ColorPaletteHeight + ToolButtonHeight) /
      NumOfLayers0;
    toolrects[Layer0I + i]
      .setRect(x, y,
               btn_w / 2 - 1, h);
    toolrects[Layer0I + NumOfLayers0 + i]
      .setRect(x + btn_w / 2, y,
               btn_w / 2 - 1, h);
  }

  active.assign(NumOfToolIndex, false);
  layers.assign(NumOfLayers, false);
}

PtPair ToolPanel::size(void) {
  return PtPair(width, height);
}

int ToolPanel::getIndex(int x, int y) {
  if (toolrects[PanelSwitchI].contains(x, y)) {
    is_panel_b = true;
    return PanelSwitchI;
  }

  if (!is_panel_b) {
    for (uint i = CloudI; i <= PencilI; i ++)
      if (toolrects[i].contains(x, y))
	return i;
  } else {
    for (uint i = SelectI; i <= SettingI; i ++)
      if (toolrects[i].contains(x, y))
	return i;
  }

  for (uint i = PenInfoI; i <= LayerI; i ++)
    if (toolrects[i].contains(x, y))
      return i;

  return -1;
}

PtColor ToolPanel::getColor(int x, int y) {
  return SketchPainter::unpack_color(buf[y * width + x]);
}

void ToolPanel::setActive(int i, bool f) {
  for (int j = 0; j <= SettingI; j ++)
    active[j] = false;

  if (i >= 0 && i < (int)NumOfToolIndex) {
    if (i >= SelectI && i <= SettingI) {
      is_panel_b = f;
      active[PanelSwitchI] = f;
    }
    active[i] = f;
  }
}

void ToolPanel::clearSelection(void) {
  is_panel_b = false;
  for (int i = 0; i <= PenInfoI; i ++)
    active[i] = false;
}

void ToolPanel::setPen(const PtPen &p) {
  pen = p;
  sp->setPen(p);
}

void ToolPanel::setPenDensity(int d) {
  density = d;
  sp->setPenDensity(d);
}

void ToolPanel::setColorPalette(NSString *fn) {
  uint w, h, x0, y0, x, y;
  uint16 *pbuf;

  if (!fn) return;

  color_palette->setImage(fn);

  w = toolrects[PaletteI].w;
  h = toolrects[PaletteI].h;
  x0 = toolrects[PaletteI].x;
  y0 = toolrects[PaletteI].y;
  pbuf = new uint16[w * h];

  color_palette->infoImage(pbuf);

  for (y = 0; y < h; y ++)
    for (x = 0; x < w; x ++) {
      buf[(y0 + y) * width + x0 + x]
	= buf_b[(y0 + y) * width + x0 + x]
        = pbuf[y * w + x];
    }

  delete pbuf;
}

void ToolPanel::initPalette(void) {
  NSString *fn = ToolPanelFileName;
  initialize(fn, width);
}

void ToolPanel::copy_buf(void) {
  unsigned long int *buf32;
  if (!is_panel_b)
    buf32 = (unsigned long int*)buf;
  else
    buf32 = (unsigned long int*)buf_b;
  unsigned long int *spbuf32 =
    (unsigned long int*)sp->frameBuffer();
  int l = width * height >> 1;

  for (int i = 0; i < l; i ++)
    spbuf32[i] = buf32[i];
}

void ToolPanel::setPenMethod(int p) {
  sp->setPenMethod(p);
}

void ToolPanel::setShowLayer(int i, bool f) {
  if (i < (int)NumOfLayers)
    layers[i] = f;
}

unsigned short int* ToolPanel::infoImage(void) {
  copy_buf();
  
  const uint16 white = 0xffff;
  const uint16 yellow = 0xffe0;
  const uint16 gray = 0x4210;

  sp->fillRect16(toolrects[LayerI], gray);
  for (uint i = 0; i < NumOfLayers; i ++)
    if (layers[i])
      sp->fillRect16(toolrects[Layer0I + i], yellow);
    else
      sp->fillRect16(toolrects[Layer0I + i], white);
  
  for (uint i = 0; i < NumOfToolIndex; i ++)
    if (i != LayerI && active[i])
      sp->invertRect(toolrects[i]);

  int cx, cy, cl;
  PtRect *pi = &toolrects[PenInfoI];
  //  sp->fillRect32(*pi, 0xffff0000);
  cl = pi->w >> 2;
  cx = pi->x + cl;
  cy = pi->y + (pi->h >> 1);

  sp->clearMask();
  sp->drawLine(cx, cy, cx + cl * 2, cy);
  sp->clearMask();

  if (active[PenInfoI]) {
    PtRect rect = toolrects[PenInfoI];

    rect.h = rect.h / 2;
    sp->invertRect(rect);
  }

  return sp->frameBuffer();
}
