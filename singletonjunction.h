#ifndef SINGLETONJUNCTION_H
#define SINGLETONJUNCTION_H

#import "constants.h"
#import "ptcolor.h"

class CanvasController;
class LayeredPainter;
class CanvasController;
class ColorPanel;
class LayerPanel;
@class PtTouchView;
@class PtPanelView;
@class PtView;

class SingletonJunction {
 public:

  static int penWidthMax;
  static LayeredPainter *layeredpainter;
  static CanvasController *canvas;
  static ColorPanel *colorpanel;
  static LayerPanel *layerpanel;
  static PtView *view;
  static PtTouchView *touchview;
  static PtPanelView *panelview;
  static PtPanelView *optpanelview;

  // from CanvasController
  static void pencilWidthChanged(int);
  static void brushWidthChanged(int);
  static void eraserWidthChanged(int);
  static void cloudWidthChanged(int);


  // from LayeredPainter
  static void toolPanelChanged(void);
  static void showingChanged(int, bool);
  static void compositionChanged(int, int);
  static void alphaChanged(int, int);
  static void currentChanged(int);
  static void numOfLayersChanged(int);

  // from ColorPanel
  static void colorpanel_selected(uint16);
  static void colorpanel_finished(void);
  static void colorpanel_showDialog(PtColor);
  static void paletteChanged(void);

  // from HueLine
  static void hueChanged(uint);

  // from SatLum
  static void satlum_selected(int, int, int);

  // from SkethcPainter
  static void showMessage(NSString*);

};

#endif // SINGLETONJUNCTION_H
