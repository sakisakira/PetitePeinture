//
//  PtView.h
//  CocoaPeinture
//
//  Created by SAkira on 08/08/10.
//  Copyright 2008. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "constants.h"
#import "ptpair.h"
#import "ptcolor.h"

class CanvasController;
@class PtTouchView;

@interface PtView : UIView {
@public
  PtPair* _size;
  CGFloat scale;
  uint16 *buf;
  CanvasController *canvas;
  PtTouchView *touchview;
  
  bool shift_nozoom;

  id target;
  SEL action;
}
@property(assign, readwrite) id target;
@property SEL action;
@property(retain) PtTouchView *touchview;
@property bool shift_nozoom;
@property(assign) CGFloat scale;

- (void)setup;
- (PtPair)viewSize;
- (void)setBufferSize:(uint)size;
- (uint16*)buffer;
- (void)setupCanvas;
- (PtColor)getColorAtX:(int)x y:(int)y;

- (void)showFileAlert;
- (void)showToolAlert;
- (void)loadImage;

- (void)pressingInBtn:(int)btn;
- (void)tapping:(NSTimer*)timer;
- (void)reset_timer:(NSTimer*)timer;

@end
