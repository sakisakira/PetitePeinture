#ifndef COLORPALETTE_H
#define COLORPALETTE_H

//#include <qstring.h>
//#include <qpe/resource.h>
#include <vector>
//#import <Cocoa/Cocoa.h>

#include "constants.h"

class PtPair;
class PtColor;
//class QImage;
class Settings;

class ColorPalette {

  uint width, height;

public:
  static const uint length = 20;
  static const uint16 init_colors[length];

private:
  static std::vector<uint16> colors;
  static std::vector<bool> changeds;
  static UIImage* img;
  static Settings *settings;

public:
  ColorPalette(int = 0, int = 0);
  ~ColorPalette(void);

  static NSString *Filename;

  static void setSettings(Settings *);
  void setImage(NSString *str);
  void setColors(const uint16* = init_colors);
  void setChangeds(const bool* = 0);
  PtPair size(void);
  PtColor getColor(uint, uint = 0);
  std::vector<uint16> getColors(void);
  static uint getLength(void) {return length;};
  uint getIndex(uint x, uint y = 0);
  void setChanged(uint i, bool f);

  void infoImage(uint16*);
  void setColor(uint, uint16);
  void setColor(uint, uint, uint16);
  
};

#endif		//  COLORPALETTE_H
