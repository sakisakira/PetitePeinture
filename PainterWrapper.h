//
//  PenStroke.h
//  touchpeinture
//
//  Created by sakira on 11/04/19.
//  Copyright 2011 sakira. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "layeredpainter.h"
#include "canvascontroller.h"
#include "ptpair.h"
#include "ptpen.h"

@interface PenStroke : NSObject {
  @public
  PtPen pen;
  PtRect rect;
  int x0, y0, x1, y1;
}

@end


// PainterWrapper

extern BOOL PainterDrawingInBackground;

@interface PainterWrapper : NSObject {
  CanvasController *_canvasController;
  LayeredPainter *_painter;
  @public
}

@property (retain) NSMutableArray *queuedStrokes;

-(id)initWithPainter:(LayeredPainter*)painter canvasControoler:(CanvasController*)canvas;

-(void) pushLineToQueueWithPenStroke:(PenStroke*)stroke;
-(void) drawLinesInQueue;
-(void) updateInCanvasRect:(NSData*)rectData;
-(void) sendMouseReleaseEvent;
-(BOOL) queueIsEmpty;


@end
