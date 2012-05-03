#ifndef COLORPANEL_H
#define COLORPANEL_H

//#include <qobject.h>
#include "singletonjunction.h"
#include "ptpair.h"

#include "constants.h"
#include "rgb_hsv.h"

//class QSize;
class PtColor;

class ColorPalette;
class HueLine;
class SatLum;
@class PtPanelView;

class ColorPanel {
public:
  uint16 *buf;
  uint width, height;
  RGB_HSV rgb_hsv;
  int sat_num, lum_num;
  HueLine *hue;
  SatLum *sat_lum;
  PtRect dlg_btn, cancel_btn, ok_btn;
  PtRect palette_rect, hue_rect, satlum_rect;
  bool user_palette;
  ColorPalette *palette;
  int mode;
  enum {ModeNone = 0,
    ModePaletteSetting, ModePaletteClearing,
    ModeSatLum,
    NumOfModes};
  uint palette_index;

  PtPanelView *optpanelview;

  void fillRect(const PtRect&, uint16);

public:
  ColorPanel(int = 240, int = 240,
             const PtColor &init_col = PtColor(255, 0, 0));
  ~ColorPanel(void);

  PtPair size(void);
  PtColor getColor(uint, uint);

  uint16* infoImage(void);
  void setUserPalette(NSString * = @"");
  PtPair huePoint(int);
  PtPair satlumPoint(int);

  //public slots:
  void setColor(const PtColor &, bool modify_hsl = true);
  void setInitColor(const PtColor &);
  void setHue(uint);
  void clicked(int x, int y, bool = true);
  void released(int, int);
  void setHueSatLum(int, int, int);

#if 0
signals:
  void selected(uint16);
  void finished(void);
  void showDialog(QColor);
  void paletteChanged(void);
#endif
};

class HueLine {

  int width, height;
  uint16 *buf;

public:
  HueLine(int, int);
  ~HueLine(void) {
    delete buf;
  }

  //public slots:
  void clicked(uint);
  
#if 0
signals:
  void hueChanged(uint);
#endif
  
protected:
  friend class ColorPanel;
};

class SatLum {

  uint16 *buf;
  uint hue;

  static const int width = 171;
  static const int height = 171;

public:
  SatLum(uint hue = 0);
  ~SatLum(void) {
    delete buf;
  }

  //public slots:
  void setColor(uint hue);
  void clicked(int x, int y);

#if 0
signals:
  void selected(int, int, int);
#endif
  
protected:
  friend class ColorPanel;
};
      
#endif		// COLORPANEL_H
