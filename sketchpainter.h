#ifndef SKETCHPAINTER_H
#define SKETCHPAINTER_H

//#include <qrect.h>
#include "ptpair.h"
//#include <qcstring.h>
//#include <qobject.h>
//#include <qbitarray.h>

#include "constants.h"
#include "clipboard.h"
#include "ptpen.h"
//#import <Cocoa/Cocoa.h>

class PtColor;
//class QCString;
//class QPointArray;

////////////////////////////////////////////////////////////
// PenShape

class PenShape {
  double half_width;
  uchar* table;
  uchar* alphas;

public:
  PenShape(void);
  ~PenShape(void);

  void setHalfWidth(double);
  void setWidth(PtPen&);
  double halfWidth(void) {return half_width;};

  uchar width(uint);
  uchar alpha(uint);
};

////////////////////////////////////////////////////////////
// PtBitArray

class PtBitArray {
  public:
    uchar* _bytes;
    uint _size;
    
    PtBitArray(void);
    PtBitArray(uint);
    ~PtBitArray(void);
    
    bool at(uint);
    void set(uint, bool);
    bool fill(bool, uint);
    bool fill(bool);
};

////////////////////////////////////////////////////////////
// SketchPainter

class SketchPainter {
  friend class LayeredPainter;

 public:
  NSMutableData *bufdata;
  uint16* buf(void) {return (uint16*)[bufdata mutableBytes];}
 protected:
  static uint32a *cloud_work;
  static PtBitArray *cloud_on;
  PtBitArray *mask;
  int width, height;
  PtPen pen;
  PtColor paper_color;

  int composition_method;
  uint composition_alpha;
  bool showing;
  PenShape pen_shape;
  PtPair shift;
  static PPClipboard clipboard;

public:
  SketchPainter(int w = 0, int h = 0);
  ~SketchPainter();

  void initialize(int, int);

  static const uint pensize_tiny = 2;
  static const uint pensize_small = 6;

  void setSize(int, int);
  PtPen get_pen(void) {return pen;}
  int get_width(void) {return width;}
  int get_height(void) {return height;}
  
  void fill(const PtColor &c);
  void fill(void);
  unsigned short int* frameBuffer(void);

//  void setCloudWork(unsigned long int*, QBitArray*);

  NSString* infoString(void);
  
  void setPen(const PtPen &);
  void setPenColor(const PtColor &);
  void setPenMethod(int);
  int penMethod(void);
  void setPenDensity(uint);
  uint penDensity(void) {return pen.density;};
  void setCloudDensity(uint);
  uint cloudDensity(void) {return pen.cloud_density;};
  void setAntialias(bool);
  void setShowing(bool);
  bool getShowing(void) {return showing;}

  void clearMask(void);
  
  void drawPoint(int x, int y);
  void drawPoint(const PtPair &p);
  void drawLine(int x0, int y0, int x1, int y1);
  void drawLine(const PtPair &p0, const PtPair &p1);
//  void drawPolyline(const QPointArray &pta);
  void drawWaterLine(int, int, int, int, uint = 255);
  void drawWaterLine(const PtPair&, const PtPair&, uint = 255);

  void mirrorHorizontal(void);
  void mirrorVertical(void);
  void rotateCW(void);
  void rotateCCW(void);
  
  void fillRect16(int, int, int, int, unsigned short int);
  void fillRect16(const PtRect&, unsigned short int);
  void fillRect32(int, int, int, int, unsigned long int);
  void fillRect32(const PtRect&, unsigned long int);

  void invertRect(int, int, int, int);
  void invertRect(const PtRect&);
  
  PtColor pickColor(int, int);

  PtColor paperColor(void) {return paper_color;};
  void setPaperColor(PtColor);
  int compositionAlpha(void) {return composition_alpha;}
  void setCompositionAlpha(int a) {composition_alpha = a;}
  int compositionMethod(void) {return composition_method;}
  void setCompositionMethod(int m) {composition_method = m;}

#if 0
  void getNSImageR0(NSImage *, const PtRect& = PtRect());
  void getNSImageR270(NSImage *, const PtRect& = PtRect());
  void getNSImage(NSImage*, int = -1);
  void getNSImage(NSImage*, const PtRect& = PtRect(), int = -1);
  void setNSImage(const NSImage&);
#endif
  void setUIImage(UIImage *);

  UIImage* getUIImage(const PtRect& = PtRect());

//  bool load(const QString &, const char* = 0);
//  bool save(const QString &, const char*);

  static unsigned short int pack_color(const PtColor &c);
  static PtColor unpack_color(unsigned short int);
  static uint32a unpack_color_uint32(uint16 p);
  

protected:
  void draw_line(int, int, int, int, bool = true);
  void draw_line(const PtPair&, const PtPair&, bool = true);
  void draw_diamond_line(int, int, int, int, bool = true);
  void draw_diamond_line(const PtPair&, const PtPair &,
                         bool = true);
  void draw_diamond_line_w1(int, int, int, int);
  void draw_diamond_line_w2(int, int, int, int);
  void draw_water_line(int, int, int, int, uint = 255);
  void draw_water_line(const PtPair&, const PtPair&, uint = 255);
  void draw_water_line_w1(int, int, int, int, uint = 255);
  void draw_point(int, int, unsigned int = 255);
  void draw_diamond(int, int, bool = true);
  void draw_diamond(const PtPair &, bool = true);
  void draw_circle(int, int, bool = true);
  void draw_circle(const PtPair &, bool = true);
  void draw_water_diamond(int, int, uint = 255);
  void draw_water_diamond(const PtPair &, uint = 255);
  void draw_water_circle(int, int, uint = 255);
  void draw_water_circle(const PtPair &, uint = 255);
  void draw_cloud_line(int, int, int, int, bool);
  void draw_cloud_short_line(int, int, int, int, bool);

  PtPair& copyWithShift(uint16*, PtPair &);
  void copyClipboard(PtRect &);
  void pasteClipboard(PtPair &);

  void clear_cloud_work(int, int);
  void set_cloud_flag(int, int, int, int, int, int);
//  void set_cloud_blend(int, int, int, int, int);
  void disperse_rect(int, int, int, int);
  void disperse_h_rect(int, int, int, int);
  inline uint32a pick_dispersed_pixel(uint, uint32a, bool);

  void clip_to_this(int *, int *, int = 0);
  void clip_to_this(int &, int &, int = 0);
  void swap_points(int *, int *, int *, int *);
  void swap_points(int &, int &, int &, int &);
  int get_index(int x, int y);
  PtPair get_point(int);
  inline unsigned long int blend(unsigned long int&,
                                 unsigned long int&,
                                 unsigned long int&, uint&,
                                 uint16, uint16, uint16);
#include "painter.inline"
  
};


#endif	// SKETCHPAINTER_H
