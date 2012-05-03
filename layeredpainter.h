#ifndef LAYEREDPAINTER_H
#define LAYEREDPAINTER_H

#include <vector>
#include "sketchpainter.h"
#include "constants.h"
#include "clipboard.h"
#include "ptpen.h"
//#include "undopainter.h"

class ToolPanel;
class UndoPainter;


class LayeredPainter : public SketchPainter {
    
  std::vector<SketchPainter*> layers;
  SketchPainter *temp_layer, *backup_layer;
  UndoPainter *undo_layer;
  static PtBitArray *alpha_mask;
  uint cur;
  ToolPanel *tools;
  //  PtRect info_rect;
  PtRect tools_rect;
  bool showing_info, showing_tools;
  std::vector<int> sqrt_tbl;
  
  NSMutableArray *_lineQueue;

public:
  static const int short_shift = 8;

  LayeredPainter(int w = 0, int h = 0);
  ~LayeredPainter();

  void setSize(int, int);
  void setPen(const PtPen &, bool tool = true, bool = false);
  PtPen getPen(void);
  void setPenDensity(int, bool tool = true, bool = false);
  uint getPenDensity(void);
  void setPenMethod(int);
  int getPenMethod(void);
  void clearMask(void);
  
  void setToolPanelActive(int, bool);
  void setToolPanel(ToolPanel *t);

  PtColor paperColor(int i) {return layers[i]->paperColor();};
  PtColor paperColor(void) {return layers[cur]->paperColor();};
  void setPaperColor(PtColor);
  void setPaperColor(int, PtColor);
  void clear(void);
  void fill(const PtColor &c = PtColor(255, 255, 255), bool = true);
  void setLayer(int = -1);
  void setLayerTemp(int i) {cur = i;}
  void setLayerAlpha(int);
  void setLayerAlpha(int, int);
  void switchLayer(int = 1);
  void setCompositionMethod(int);
  void setCompositionMethod(int, int);
  int compositionMethod(void) {return layers[cur]->compositionMethod();}
  int compositionMethod(int i) {return layers[i]->compositionMethod();}
  int compositionAlpha(void) {return layers[cur]->compositionAlpha();}
  int compositionAlpha(int i) {return layers[i]->compositionAlpha();}
  void updateRect(const PtRect &r);
  int numOfLayers(void) {return layers.size();}
  uint current(void) {return cur;}

  uint16* frameBufferOfLayer(int i) {return layers[i]->frameBuffer();}
  
  void joinShowingLayers(void);
  void backupCurrentLayer(void);
  void cancelCurrentLayer(void);
  void restoreCurrentLayer(void);
  void exchangeCurrentLayer();
  void undo(uint);

  void copyTempLayerToUndoLayer(void);
  PtPair undo(void);
  PtPair redo(void);

  bool getShowing(void);
  void setShowing(bool);
  bool getShowing(int);
  void setShowing(int, bool);

  void createLayer(void);
  void duplicateCurrentLayer(void);
  void deleteCurrentLayer(void);
  void deleteLayer(int);
  
  void exchangeLayers(int, int);

  void drawPoint(int, int);
  void drawLine(int, int, int, int, bool = false);
//  void drawPolyline(const QPointArray &pta);


//  PtRect& showPenInfo(void);
//  PtRect& hideInfo(void);

  NSMutableArray* infoStrings(void);

  void mirrorHorizontal(void);
  void mirrorVertical(void);
  void rotateCW(void);
  void rotateCCW(void);

  PtPair shiftCurrentLayer(PtPair &, PtRect &);
  PtPair shiftCurrentLayer(PtPair &);
  void shiftAllLayers(PtPair &, bool enque = true);
  void shiftUndoLayer(PtPair &);
  void unshiftCurrentLayer(void);
  void fixShiftCurrentLayer(bool = true);
  void scaleCurrentLayer(uint, uint);

  void copyClipboard(PtRect &, uint);
  void pasteClipboard(PtPair &, uint);
  void copyClipboard(PtRect &rect) {copyClipboard(rect, cur);}
  void pasteClipboard(PtPair &pt) {pasteClipboard(pt, cur);}
  bool clipboardPasteMode(void) {return clipboard.pasteMode();}
  void setClipboardPasteMode(bool pm) {clipboard.setPasteMode(pm);}
  PtRect clipboardRect(void) {return clipboard.rect();}
  PPClipboard* getClipboard(void) {return &clipboard;}

  void setShowingTools(bool);

#if 0
  bool loadPtpt(NSString *);
	bool load(const QString *, const char* = 0);
  bool loadLayer(const QString &);
  bool save(const QString &, const char*);
  bool savePtpt(const QString &);
  bool saveLayer(const QString &);
  static bool fileExists(const QString &);
#endif

  void loadToCurrentLayer(UIImage *);
  UIImage* getUIImageOfCurrentLayer(const PtRect & = PtRect());

protected:
  void setup_sqrt_tbl(void);
  void prepare_layer(SketchPainter *);
  void prepare_current(void);

  inline uint16 update_over16(uint16 c0, uint16 c1,
                              uint16 paper_col, uint alpha) {
    if (c1 == paper_col)
      return c0;
    else
      return tighten((disperse(c0) * (32 - alpha)
                      + disperse(c1) * alpha) >> 5);
  }
  inline uint32a update_over32(uint32a, uint32a, uint16, uint);
  void update_rect_copy(uint32a*, const PtRect &);
  void update_rect_min(uint32a*, uint32a*, const PtRect &);
  void update_rect_max(uint32a*, uint32a*, const PtRect &);
  void update_rect_mul(uint32a*, uint32a*, const PtRect &);
  void update_rect_screen(uint32a*, uint32a*, const PtRect &);
  void update_rect_sat(uint16*, uint16*, const PtRect &);
  void update_rect_col(uint16*, uint16*, const PtRect &);
  void update_rect_dodge(uint16*, uint16*, const PtRect &);
  void update_rect_normal(SketchPainter*, SketchPainter*,
                          const PtRect &);
  void update_rect_mask(uint16*, uint16*, uint16*, const PtRect &);
  void update_rect_clipboard(void);
  void copy_entire_buf(SketchPainter&, SketchPainter&);
  void copy_entire_buf_with_scaling(
    SketchPainter&, SketchPainter&, uint, uint);
  void exchange_entire_buf(SketchPainter&, SketchPainter&);
  void draw_line_with_alpha(int, int, int, int,
                            SketchPainter*, SketchPainter*);

#include "painter.inline"
  
#if 0
signals:
  void toolPanelChanged(void);
  void showingChanged(int, bool);
  void compositionChanged(int, int);
  void alphaChanged(int, int);
  void currentChanged(int);
  void numOfLayersChanged(int);
#endif
  
};

#endif //	 LAYEREDPAINTER_H
