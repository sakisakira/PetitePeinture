// PtLoupe.h
// by SAkira <sakira@sun.dhis.portside.net>
// from 2008 September 07

#include "ptcolor.h"

class PtPair;
@class PtView;
@class PtLoupeCross;

@interface PtLoupe : UIView {
@public
  PtPair *_size;
  PtView *ptview;
  PtLoupeCross *cross;
  int _center_x, _center_y;
  UIColor *_fill_color;
 
  UIColor *bound_color;
  bool show_bound;
  float _scale, _alpha;
  
  bool follow_finger;
}

@property float _scale;
@property float _alpha;
@property bool follow_finger;
@property(nonatomic, retain) PtLoupeCross* cross;

- (void)setup:(PtView*)pv;

- (void)setScale:(float)s;
- (void)setBufCenterX:(int)x y:(int)y;
- (void)setFillColor:(PtColor)col;
- (void)setPosCenterX:(int)x y:(int)y;
- (void)set_bound_color:(PtColor)col;

@end

@interface PtLoupeCross : UIView {
@public
}

@end

