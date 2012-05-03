//
//  PenStroke.mm
//  touchpeinture
//
//  Created by sakira on 11/04/19.
//  Copyright 2011 sakira. All rights reserved.
//

#import "PainterWrapper.h"


#pragma mark PenStroke

@implementation PenStroke

@end


#pragma mark PainterWrapper

BOOL PainterDrawingInBackground = NO;

@implementation PainterWrapper

@synthesize queuedStrokes;

#pragma mark life cycle

-(id)initWithPainter:(LayeredPainter*)painter canvasControoler:(CanvasController *)canvas {
  if ((self = [super init])) {
    self->_painter = painter;
    self->_canvasController = canvas;
    self.queuedStrokes = [NSMutableArray arrayWithCapacity:512];
  }
  return self;
}

-(void) dealloc {
  self->_painter = NULL;  // do not dealloc
  self.queuedStrokes = nil;
  [super dealloc];
}

#pragma mark managing lines

-(void) pushLineToQueueWithPenStroke:(PenStroke *)stroke {
    [self.queuedStrokes addObject:stroke];
}

-(void) drawLinesInQueue {
  PenStroke *stroke;
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  while (![self queueIsEmpty]) {
    NSAutoreleasePool *pool_ = [[NSAutoreleasePool alloc] init];
    stroke = (PenStroke*)[self.queuedStrokes objectAtIndex:0];
    _painter->setPen(stroke->pen, false);
    _painter->drawLine(stroke->x0, stroke->y0,
                       stroke->x1, stroke->y1, true);
    NSData *rectData = 
    [[NSData alloc] initWithBytes:(void*)(&(stroke->rect))
                           length:sizeof(PtRect)];
    [self performSelectorOnMainThread:@selector(updateInCanvasRect:)
                           withObject:rectData 
                        waitUntilDone:NO];
    @synchronized(self.queuedStrokes) {
      [self.queuedStrokes removeObjectAtIndex:0];
    }
    [rectData release];
    [pool_ drain];
  }
  
  PainterDrawingInBackground = NO;

  if (!_canvasController->drawing()) {
    [self performSelectorOnMainThread:@selector(sendMouseReleaseEvent) 
                           withObject:nil 
                        waitUntilDone:NO];
  }
  [pool drain];
}

-(void) updateInCanvasRect:(NSData*)rectData {
  PtRect rect;
  [rectData getBytes:&rect length:sizeof(PtRect)];
  self->_canvasController->updateRect(rect);
}

-(void) sendMouseReleaseEvent {
  PtPair point(0, 0);
  self->_canvasController->mouseReleaseEvent(point);
}


-(BOOL) queueIsEmpty {
    return ([self.queuedStrokes count] == 0);
}


@end