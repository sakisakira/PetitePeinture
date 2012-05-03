#ifndef LAYERPANEL_H
#define LAYERPANEL_H

//#include <qpixmap.h>
//#import <Cocoa/Cocoa.h>
//#include <qpoint.h>
#include "ptpair.h"
//#include <qarray.h>
#include "vector"
//#include <qobject.h>

class SketchPainter;

class LayerPanel {
  
//  NSBitmapImageRep* pix;
	PtPair _size;
  uint num_of_layers;
  int current;
  bool show;
  PtPair top_left_point;

  std::vector<PtRect> showing_rects;
  std::vector<PtRect> composition_rects;
  std::vector<PtRect> alpha_rects;
  //  std::vector<PtRect> tab_rects;

  std::vector<bool> showings;
  std::vector<int> compositions;
  std::vector<int> alphas;

  NSString* compositionString(int);

  static const uint fontSize = 16;
  
public:
  LayerPanel(int n = 1);

  //  enum {Show = 0, Composition, Alpha, Tab};
  enum {Show = 0, Composition, Alpha};
  
  bool showing(int);
  int composition(int);
  int alpha(int);

  void setTopLeft(PtPair &);
  PtRect rect(void);
  PtPair size(void);
  int width(void) {return size().x;}
  int height(void) {return size().y;}
  int x(void) {return top_left_point.x;}
  int y(void) {return top_left_point.y;}
  UIImage* getImage(void);
  //  void setImage(NSImage*);

  uint layerNum(int y);
  uint typeNum(int x);
  uint editing;

  //public slots:
 public:
  void setShowing(int, bool);
  void setShow(bool);
  void setComposition(int, int);
  void setAlpha(int, int);
  void setCurrent(int i) {current = i;}
  void setNumOfLayers(int n);

};

#endif 	// LAYERPANEL_H
