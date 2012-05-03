/*
 **	colorpalette.cpp
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 September 23
 */

//#include <qsize.h>
#include "ptpair.h"
//#include <qcolor.h>
#include "ptcolor.h"
//#include <qarray.h>
#include <vector>
//#include <qfile.h>
//#include <qimage.h>
//#include <qpe/resource.h>
//#import <Cocoa/Cocoa.h>

#include "settings.h"
#include "sketchpainter.h"
#include "colorpalette.h"

NSString* ColorPalette::Filename = @"petitpeintu_colorpallete.tiff";
std::vector<uint16> ColorPalette::colors(ColorPalette::length);
const uint16 ColorPalette::init_colors[] =
{0x0000, 0x1000, 0x0100, 0x0010, 0x0001,
  0x8000, 0x0800, 0x0080, 0x0008, 0xffff};
std::vector<bool> ColorPalette::changeds(0);
UIImage* ColorPalette::img;
Settings* ColorPalette::settings = 0;

ColorPalette::ColorPalette(int w, int h) {
  width = w;
  height = h;

  if (changeds.size() == 0) {
    changeds.assign(length, false);
    colors.resize(length);
  }

  if (settings)
    settings->getPaletteColors(colors, changeds);

}

ColorPalette::~ColorPalette(void) {
  //  settings->save();
}

void ColorPalette::setSettings(Settings *s) {
  settings = s;
}

void ColorPalette::setImage(NSString *fn2) {
  NSString* fn = [NSString stringWithString:fn2];
  UIImage* _img = 0;

  if (![fn length])
    fn = settings->getPaletteFileName();
  ALog(@"colorpalette::filename %@", fn);
  _img = [UIImage imageNamed:fn];

  if (!_img) {
    _img = [UIImage imageNamed:ColorPalette::Filename];
    if (!_img)
      ALog(@"palette image %@ does not exist\n", fn);
  }

  
  img = _img;
}

void ColorPalette::setColors(const uint16* cs) {
  for (uint i = 0; i < length; i ++)
    colors[i] = cs[i];
}

void ColorPalette::setChangeds(const bool *cs) {
  if (cs)
    for (uint i = 0; i < length; i ++)
      changeds[i] = cs[i];
  else
    changeds.assign(length, false);
}

void ColorPalette::setChanged(uint i, bool f) {
  changeds[i] = f;

  if (settings)
    settings->setPaletteColors(colors, changeds);

}

uint ColorPalette::getIndex(uint x, uint) {
  return x * length / width;
}

PtPair ColorPalette::size(void) {
  return PtPair(width, height);
}

PtColor ColorPalette::getColor(uint x, uint) {
  return SketchPainter::unpack_color(colors[getIndex(x)]);
}

std::vector<uint16> ColorPalette::getColors(void) {
  std::vector<uint16> rcolors(length);

  for (uint i = 0; i < length; i ++)
    rcolors[i] = colors[i];

  return rcolors;
}

void ColorPalette::infoImage(uint16 *buf) {
  CFDataRef ibuf;
  float imgw, imgh;

  ibuf = CGDataProviderCopyData(CGImageGetDataProvider(img.CGImage));
  
  if (img.size.width > 0) {
    PtColor col;
    uint x, y;
	  
    imgw = img.size.width;
    imgh = img.size.height;

    UInt8* imgbuf = (UInt8*)CFDataGetBytePtr(ibuf);

    uint index;
    for (y = 0; y < height; y ++)
      for (x = 0; x < width; x ++) {
        index = (floor((double)imgh * y / height) * imgw + 
                 floor((double)imgw * x / width)) * 3;
        col.setRgb(imgbuf[index],
                   imgbuf[index + 1],
                   imgbuf[index + 2]);
        buf[y * width +  x] =
          SketchPainter::pack_color(col);
      }
  } else {
    for (uint i = 0; i < length; i ++)
      if (!changeds[i]) {
        colors[i] = init_colors[i];
        changeds[i] = true;
      }
  }
  CFRelease(ibuf);
  
  uint x, y, index;
  uint16 c;
  int i;

  for (x = 0; x < width; x ++) {
    i = x * length / width;
    if (changeds[i]) {
      c = colors[i];
      index = x;
      for (y = 0; y < height; y ++) {
        buf[index] = c;
        index += width;
      }
    }
  }
}

void ColorPalette::setColor(uint i, uint16 c) {
  colors[i] = c;
  changeds[i] = true;

  if (settings)
    settings->setPaletteColors(colors, changeds);
}

void ColorPalette::setColor(uint x, uint, uint16 c) {
  setColor(x * length / width, c);
}
