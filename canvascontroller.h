#ifndef CANVASCONTROLLER_H
#define CANVASCONTROLLER_H

//#include <qmainwindow.h>
//#include <qwidget.h>
//#include <qvbox.h>
//#include <qpainter.h>
//#include <qpixmap.h>
//#include <qpointarray.h>
//#include <Cocoa/Cocoa.h>
#include <vector>
//#include <qlist.h>
//#include <qcolordialog.h>
//#include <qrect.h>
#include "ptpair.h"
//#include <qimage.h>
//#include <qmenubar.h>

#include "layeredpainter.h"
#include "colorpanel.h"
#include "layerpanel.h"
#include "ptpen.h"
//#include "z_color_adjust.h"

#import "ptview.h"
#import "pttouchview.h"
#import "ptloupe.h"
#import "ptpanelview.h"
#import "undopainter.h"

class SPainter;
class ToolPanel;
//class QDirectPainter;
//class NSTimer;
@class PainterWrapper;

class CanvasController {

public:
  CanvasController(PtView * = nil);
  ~CanvasController();

  static const NSString *kNumOfLayersKey;
  static const NSString *kImageWidthKey;
  static const NSString *kImageHeightKey;
  static const NSString *kCompositionMethodKeyI;
  static const NSString *kPaperAlphaKeyI;
  static const NSString *kPaperRedKeyI;
  static const NSString *kPaperGreenKeyI;
  static const NSString *kPaperBlueKeyI;
  static const NSString *kPixelsKeyI;

  static const NSString *kPencilKey;
  static const NSString *kBrushKey;
  static const NSString *kEraserKey;
  static const NSString *kCloudKey;
  static const NSString *kCurrentLayerIndexKey;

  static const CFTimeInterval autosave_interval;  // seconds
  CFTimeInterval last_saved_time;

#if 0
  void load(const NSString *);
  void save(const NSString *, const char *, bool = true);
  void saveIcon(const NSString *);
  void loadLayer(const NSString *);
  void saveLayer(const NSString *);
#endif

  void loadToCurrentLayer(UIImage*);
  void exportToPhotosAlbum(void);
  void exportCurrentLayerToPhotosAlbum(void);

  //  void applyPressureToWidth(bool f) {apply_press_width = f;}
  //  void applyPressureToDensity(bool f) {apply_press_density = f;}

  void getPenProperties(void);
  void setupPainter(void);

  void archiveCurrentLayer(NSKeyedArchiver*);
  void saveImage(void);
	void savePtpt(void);
  void loadImage(NSString*);
	void loadPtpt(NSString*);
  void saveDefaultsForCurrentLayer(void);
  void saveDefaults(void);
  void loadDefaults(void);
  
  void scaleLayer(uint, uint);
  uint canvasWidth(void);
  uint canvasHeight(void);
  void setSize(int, int);

  // required by PtTouchView
  void setZoom(float, int, int);
  void setShift(int, int);
  void undoOneStep(void);
  void redoOneStep(void);

  //  void adjustColorTable(bool);

  //public slots:
 public:
  void clearImage(bool = true);
  void clearCurrentLayer(void);
  void setPaperColor(void);
  void setUserPalette(void);
  void exchangeColorPaperPen(void);
  void show_tools(bool);
  void show_hide_tools(int = NumOfToolsPosition);
  void show_hide_layers(bool);
  void show_hide_layers(void);

  //  void set_pen_pressure_width(bool);
  //  void set_pen_pressure_density(bool);

  void update_info_rect(void);
  void getColor(uint16);
  void finishColorPanel(void);
  void show_hide_color_panel(void);
  void joinShowingLayers(void);
  void exchangeLayers(int, int);

  void duplicateCurrentLayer(void);
  void deleteCurrentLayer(void);
  void moveUpCurrentLayer(void);
  void moveDownCurrentLayer(void);

  void quit_application(void);
  void set_pen_color_dlg(PtColor);
  void tapping(void);

  void mirrorHorizontal(void);
  void mirrorVertical(void);
  void rotateCW(void);
  void rotateCCW(void);
  void set_select_mode_copy(void);
  void set_select_mode_paste(void);
  void set_select_mode_paste_freeze(void);
  void set_select_mode_paste_cancel(void);
  void undo(void);
  void clearClipboard(void) {sp->getClipboard()->resize(0, 0);}
  void layerChanged(int);

  void setPencil(int w) {set_pencil(); set_pen_width(w);}
  void setBrush(int w) {set_brush(); set_pen_width(w);}
  void setEraser(int w) {set_eraser(); set_pen_width(w);}
  void setCloud(int w) {set_cloud(); set_pen_width(w);}

#if 0
 signals:
  void pencilWidthChanged(int);
  void brushWidthChanged(int);
  void eraserWidthChanged(int);
  void cloudWidthChanged(int);
#endif

public:
  //  void paintEvent(QPaintEvent *);
  void mousePressEvent(const PtPair &);
  void mouseMoveEvent(const PtPair &);
  void mouseReleaseEvent(const PtPair &);
  void mousePressEventCancelled(void);
  //  void keyPressEvent(QKeyEvent *);
  //  void keyReleaseEvent(QKeyEvent *);
  float getZoom(void) {return zoom;};
  void setPtLoupe(PtLoupe *l) {loupe = l;};

  int getToolBtnIndex(int x, int y);
	
  id _timer;

  void reset_timer(void) {_timer = 0;};

  void clear_btn_info_string(float delay = 0.5f);

protected:
  PtView *ptview;
  PtTouchView *touchview;
  PtLoupe *loupe;
  PtPanelView *panelview;
  PtPanelView *optpanelview;

  //  SPainter *parent;

  int x0, y0, x1, y1;
  int px0, py0, px1, py1;
  int min_x, min_y, max_x, max_y;
 public:
  int dwidth, dheight, xoff, yoff;
  PtPen pencil, brush, eraser, cloud, *pen;
  LayeredPainter* layeredPainter(void) {return sp;}
 protected:
  //  QList<QPoint> pts;
#if 0
  QPixmap *pix;
  QImage img;
#endif
//  NSBitmapImageRep* pix;
  LayeredPainter *sp;
  ToolPanel *tools;
  ColorPanel colorpanel;
  LayerPanel layers;
  bool pick_color_mode;
  bool layer_shift_mode, img_modified;
  enum {SelectModeNone = 0, SelectModeCopy, SelectModePaste, SelectModeCancel};
  uint select_mode;
  enum {PenModeNone = 0, PenModeDensity, PenModeCloud, PenModeWidth,
	PenModeColor, PenModeMove, 
        NumOfPenMode};
  uint pen_mode;
  //  int pen_width_diff;
  enum {LayerModeNone = 0, LayerModeAlpha, LayerModeTab};
  uint layer_mode;
  PainterWrapper *_painterWrapper;

 public:
  NSString* info_string;
  int shift_x, shift_y;
  float zoom;
  enum {HideTools = 0, TopTools, BottomTools, NumOfToolsPosition};
  PtRect tools_rect;
  int panel_position;
  PtRect opt_panel_rect;
  enum OptionalPanelType {None = 0, Tools, Color, Layers, Num};
  OptionalPanelType opt_panel_type;
 protected:
  int last_pen_method;
  //  int pen_density;
  int previous_value;
  //  bool antialias, dropping_mouse_release;
  bool dropping_mouse_release;
  bool apply_press_width, apply_press_density;
//  bool use_pen_pressure;
//  bool show_layers;
  bool sync_width, separate_pen;
  uint leftright;
  int pressing_tool;
  static const int press_delay = 500;
  static const int press_repeat = 50;
  PtRect copy_rect, pcopy_rect;
  //  ZColorAdjust _z_col_adjust;
  //  static uint16 *_col_adj_table;

  static CGRect PtRectToCGRect(const PtRect &);

 public:
  void updateRect(const PtRect &);
  uint get_pen_width(void) {return pen->width();}
  void set_pen_width(int);
  void set_pen_density(int);
  uint get_pen_density(void) {return pen->density;}
  void set_cloud_density(int);
  uint get_cloud_density(void) {return cloud.cloud_density;}
  void set_pen_method(uint i) {pen->brush_method = i; sp->setPenMethod(i);}
  uint get_pen_method(void) {return pen->brush_method;}
  void set_antialias(bool);
  void adjust_shift(void);
  bool drawing(void) {return (y0 >= 0);};

 protected:
  void set_pen(void);
  void set_pencil(void);
  void set_brush(void);
  void set_eraser(void);
  void set_cloud(void);
  void display_pen(void);

  void set_pencil_mode(void);
  void set_eraser_mode(void);
  void set_brush_mode(void);
  void set_cloud_mode(void);

  void set_layer_alpha(int);
  void set_layer_alpha(int, int);
  void fix_layer_alpha(void);
 public:
  void set_color_panel(void);
 protected:
  void set_peninfo_mode(void);
  void set_pick_mode(void);
  //  void pick_color(QMouseEvent*);
  void pick_color(const PtPair &);
  void set_select_mode(void);
  void set_move_mode(void);
  void set_shift_mode(void);
  void set_undo_mode(void);
  void set_layer_shift_mode(void);
  void unset_shift_mode(void);
  void unset_layer_shift_mode(void);
  void zoom_mode(void);
  //  void set_zoom(int, int);
  //  void set_unzoom(void);
  void set_shift_by_center(int, int);
  void adjust_loupe(void);
  void shift_image(int x, int y);
  void shift_image_by_mouse(void);
  void layer_shift_image(int, int);
  void layer_shift_image_by_mouse(void);
  void select_copy_press_event(const PtPair &);
  void select_copy_move_event(const PtPair &);
  void select_copy_release_event(const PtPair &);
  void select_paste_press_event(const PtPair &);
  void select_paste_move_event(const PtPair &, bool = true);
  void draw_paste_rectangle(void);
  //  void hideInfo(void);
  void update_info_string(bool = false);
  void panel_event(const PtPair &e);
  void panel_move_event(const PtPair &e);
  void panel_release_event(const PtPair &e);
  void layerpanel_event(const PtPair &);
  void layerpanel_move_event(const PtPair &e);
  void layerpanel_release_event(const PtPair &e);
  void colorpanel_event(const PtPair &);
  void colorpanel_move_event(const PtPair &e, bool move = true);
  void colorpanel_release_event(const PtPair &e);

private:
  static const int PanelEventIndex = -2;
  static const int ColorPanelEventIndex = -3;
  static const int LayerPanelEventIndex = -4;

  void update_panel_rect(const PtPair&, uint16*);
  void update_optional_panel_rect(const PtPair&, uint16*);
  void update_optional_panel_rect(UIImage *);
  void update_panel_rect(void);
 public:
  void update_tools_rect(void);
 private:
  void update_colorpanel_rect(void);
  void update_layers_rect(void);
  void update_optional_panel(void);
  void update_panels(void);
  void update_image_info(void);
  void convert_geometry(int*, int*);
  void disconvert_geometry(int*, int*);
  PtPair convert_geometry(const PtPair&);
  //  NSPoint getNSPointFromPtPair(const PtPair &);
  void updateView(const PtRect&);

  inline void add_each_color(uint32a a, uint32a &r, uint32a &g, uint32a &b) {
    r += (a >> 11) & 0x001f001f;
    g += (a >>  6) & 0x001f001f;
    b += (a >>  1) & 0x001f001f;
  }

#if 0
  inline uint32a pack_each_color(uint32a &r, uint32a &g, uint32a &b) {
    r = (r >> -zoom * 2 - 1) & 0x001f001f;
    g = (g >> -zoom * 2 - 1) & 0x001f001f;
    b = (b >> -zoom * 2 - 1) & 0x001f001f;
    r = ((r & 0xffff) + (r >> 16)) & 0x3e;
    g = ((g & 0xffff) + (g >> 16)) & 0x3e;
    b = ((b & 0xffff) + (b >> 16)) & 0x3e;
    return (r << 10) | (g << 5) | b;
  }
#endif

#if 0
  inline uint32a adjust(uint32a s) {
    return (((uint32)_col_adj_table[s >> 16]) << 16) |
      _col_adj_table[s & 0xffff];
  }
  inline uint16 adjust(uint16 s) {
    return _col_adj_table[s];
  }
#endif
//  inline uint32a adjust(uint32a s) {return s;}
  inline uint32a adjust(uint32a s) {return s;}
  inline uint16 adjust(uint16 s) {return s;}

#include "painter.inline"

};  // CanvasController

#endif		// CANVASCONTROLLER_H
