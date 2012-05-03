// SingletonJunction
// from 2008 Aug 10 by SAkira <sakira.09@g4.mnx.ne.jp>

#include <stdio.h>

#include "singletonjunction.h"
#include "constants.h"
#include "canvascontroller.h"
#include "layeredpainter.h"
#include "colorpanel.h"
#include "layerpanel.h"
#import "pttouchview.h"
#import "ptview.h"

LayeredPainter* SingletonJunction::layeredpainter = 0;
CanvasController* SingletonJunction::canvas = 0;
ColorPanel* SingletonJunction::colorpanel = 0;
LayerPanel* SingletonJunction::layerpanel = 0;
PtTouchView* SingletonJunction::touchview = 0;
PtView* SingletonJunction::view = 0;
PtPanelView* SingletonJunction::panelview = 0;
PtPanelView* SingletonJunction::optpanelview = 0;
int SingletonJunction::penWidthMax = 0;

void SingletonJunction::hueChanged(uint i) {
  if (colorpanel)
    colorpanel->setHue(i);
  else
    printf("colorpanel = 0\n");
}

void SingletonJunction::satlum_selected(int a, int b, int c) {
  if (colorpanel)
    colorpanel->setHueSatLum(a, b, c);
  else
    printf("colorpanel = 0\n");
}

void SingletonJunction::toolPanelChanged(void) {
  if (canvas)
    canvas->update_info_rect();
  else
    printf("canvas = 0\n");
}

void SingletonJunction::showingChanged(int a, bool b) {
  if (layerpanel) 
    layerpanel->setShowing(a, b);
  else
    printf("layerpanel = 0\n");
}

void SingletonJunction::compositionChanged(int a, int b) {
  if (layerpanel)
    layerpanel->setComposition(a, b);
  else
    printf("layerpanel = 0\n");
}

void SingletonJunction::alphaChanged(int a, int b) {
  if (layerpanel)
    layerpanel->setAlpha(a, b);
  else
    printf("layerpanel = 0\n");
}

void SingletonJunction::currentChanged(int a) {
  if (layerpanel)
    layerpanel->setCurrent(a);
  else
    printf("layerpanel = 0\n");

  if (canvas)
    canvas->layerChanged(a);
  else
    printf("canvas = 0\n");
}

void SingletonJunction::numOfLayersChanged(int a) {
  if (layerpanel)
    layerpanel->setNumOfLayers(a);
  else
    printf("layerpanel = 0\n");
}

void SingletonJunction::colorpanel_selected(uint16 a) {
  if (canvas)
    canvas->getColor(a);
  else
    printf("canvas = 0\n");
}

void SingletonJunction::colorpanel_finished(void) {
  if (canvas)
    canvas->finishColorPanel();
  else
    printf("canvas = 0\n");
}

void SingletonJunction::colorpanel_showDialog(PtColor a) {
  if (canvas)
    canvas->set_pen_color_dlg(a);
  else
    printf("canvas = 0\n");
}

void SingletonJunction::paletteChanged(void) {
  if (canvas)
    canvas->setUserPalette();
  else
    printf("canvas = 0\n");
}

void SingletonJunction::showMessage(NSString *str) {
  if (touchview)
    [touchview showMessage:str];
  else
    printf("touchview = 0\n");
}
