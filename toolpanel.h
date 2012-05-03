#ifndef TOOLPANEL_H
#define TOOLPANEL_H

//#include <qstring.h>
//#include <qarray.h>
#include <vector>
//#include <qrect.h>
#include "ptpair.h"
#include "ptpen.h"

//class QSize;
class SketchPainter;
class ColorPalette;
@class PtPanelView;

class ToolPanel {
  unsigned short int *buf, *buf_b;
  SketchPainter *sp;
  int width, height;
  double ratio;
  PtPen pen;
  int density;
  ColorPalette *color_palette;
  
  PtPanelView *panelview;

  std::vector<PtRect> toolrects;
  std::vector<bool> active;
  std::vector<bool> layers;

public:

  enum {PanelSwitchI = 0,
	CloudI, EraserI, BrushI, PencilI,
	SelectI, FileI, ToolI, SettingI,
	PenInfoI, PaletteI, LayerI, Layer0I};
  static const uint NumOfLayers0 = 5;
  static const uint NumOfLayers = NumOfLayers0 + NumOfLayers0;
  static const uint NumOfButtons = SelectI;
  static const uint NumOfToolIndex = 
    Layer0I + NumOfLayers;
  static const uint ColorPaletteHeight = 30;
  static const uint ToolButtonHeight = 40;
  static const uint PenInfoWidth = 60;

  bool is_panel_b;

  ToolPanel(NSString *, int = 320);
  ToolPanel(int = 320);
  ~ToolPanel();

  static NSString* ToolPanelFileName;
  static NSString* ToolPanelBFileName;

  PtPair size(void);
  int getIndex(int, int);
  PtColor getColor(int, int);
  void setActive(int, bool = true);
  void clearSelection(void);
  void setPen(const PtPen &);
  void setPenDensity(int);
  void setPenMethod(int);
  void setShowLayer(int, bool);
  void setColorPalette(NSString * = nil);
  void initPalette(void);
  PtRect rect(int i) {return toolrects[i];};

  unsigned short int* infoImage();

private:
  void initialize(NSString *, int);
  void setup_toolrects(void);

  void copy_buf();
  
};

#endif		//  TOOLPANEL_H
