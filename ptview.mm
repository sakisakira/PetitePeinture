//  Ptview.mm
//  CocoaPeinture
//  by SAkira <sakira@sun.dhis.portside.net>
//  from 2008 Aug 11

#import "ptview.h"
#import "canvascontroller.h"
#import "constants.h"
#import "ptpair.h"
#import "ptimageutil.h"
#import "sketchpainter.h"
#import "pttouchview.h"

@implementation PtView

@synthesize target;
@synthesize action;
@synthesize touchview;
@synthesize shift_nozoom, scale;

- (id)initWithFrame:(CGRect)frameRect {
  if (!(self = [super initWithFrame:frameRect]))
    return nil;

  [self setup];
  SingletonJunction::view = self;
  return self;
}

- (void)setup {
  CGSize s = [self bounds].size;
  self.scale = 1.0f;
  if ([UIScreen instancesRespondToSelector:@selector(scale)])
    self.scale = [[UIScreen mainScreen] scale];
  _size = new PtPair(((int)(s.width * scale)) & ~1, 
                     (int)(s.height * scale));
  
  ALog(@"PtView size %d, %d", _size->x, _size->y);
	
  buf = 0;

  canvas = new CanvasController(self);
}

- (void)dealloc {
  if (buf) delete[] buf;
  delete canvas;
  [super dealloc];
}

- (PtPair)viewSize {
  return PtPair(_size->x, _size->y);
}

- (void)setBufferSize:(uint)size {
  if (buf)
    delete buf;
  buf = new uint16[size];
}

- (uint16*)buffer {
  return buf;
}

- (void)tapping:(NSTimer*)timer {
  canvas->tapping();
  canvas->reset_timer();
}

- (void)reset_timer:(NSTimer*)timer {
  canvas->reset_timer();
}

- (void)pressingInBtn:(int)btn {
  [touchview doubleTappedInBtn:btn];
}

- (void)setupCanvas {
  if (canvas)
    canvas->setupPainter();
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	CGFloat s_scale = SingletonJunction::view.scale;

  if (!buf)
    return;
  
  if (!canvas) [self setup];
  
  uint x0, y0, w, h;
  
  x0 = CGRectGetMinX(rect) * s_scale;
  y0 = CGRectGetMinY(rect) * s_scale;
  if (x0 >= _size->x) x0 = _size->x - 1;
  if (y0 >= _size->y) y0 = _size->y - 1;
  w = CGRectGetWidth(rect) * s_scale;
  h = CGRectGetHeight(rect) * s_scale;
  if (! w * h) return;
                     
  UIImage *img = PtImageUtil::uint16toUIImage(buf, _size->x, x0, y0, w, h);
  [img drawAtPoint:CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect))];
}

- (PtColor)getColorAtX:(int)x y:(int)y {
  int index = _size->x * y + x;
  return SketchPainter::unpack_color(buf[index]);
}

- (void)showFileAlert {
  [touchview showFileAlert];
}

- (void)showToolAlert {
  [touchview showToolAlert];
}

- (void)loadImage {
  [touchview loadImage];
}


@end

