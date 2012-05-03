/*
 **	layerpanel.mm
 **	written by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 September 4
 */

//#include <qpainter.h>
//#import <Cocoa/Cocoa.h>

#include "constants.h"
#include "layerpanel.h"
#include "singletonjunction.h"

LayerPanel::LayerPanel(int n) {
  top_left_point.x = 0;
  top_left_point.y = 0;

  show = false;

//  pix = 0;

  setNumOfLayers(n);
  SingletonJunction::layerpanel = this;
}

void LayerPanel::setNumOfLayers(int n) {
  num_of_layers = n;
  
  showing_rects.resize(n);
  composition_rects.resize(n);
  alpha_rects.resize(n);
  //  tab_rects.resize(n);

  showings.resize(n);
  compositions.resize(n);
  alphas.resize(n);

  UIFont *tfont = [UIFont boldSystemFontOfSize:fontSize];
  //  uint font_h = (tfont.capHeight + tfont.ascender);
  uint font_h = tfont.leading;
  if (n >= 1) {
    PtRect srect = PtRect(0, 0, 12 * 2, font_h);
    PtRect crect = PtRect(12 * 2, 0, 12 * 2, font_h);
    PtRect arect = PtRect(12 * 4, 0, 12 * 3, font_h);
    //    PtRect trect = PtRect(12 * 7, 0, 12 * 1, 16);

    int h = srect.h;
    _size = PtPair(srect.w + crect.w +
		   arect.w,
		   h * n);
    for (int i = n - 1; i >= 0; i --) {
      showing_rects[i] = srect;
      composition_rects[i] = crect;
      alpha_rects[i] = arect;
      //      tab_rects[i] = trect;
      srect.moveBy(0, h);
      crect.moveBy(0, h);
      arect.moveBy(0, h);
      //      trect.moveBy(0, h);
    }
  }
}

bool LayerPanel::showing(int i) {
  return showings[i];
}

void LayerPanel::setShowing(int i, bool f) {
  showings[i] = f;
}

void LayerPanel::setShow(bool f) {
  show = f;
}

int LayerPanel::composition(int i) {
  return compositions[i];
}

void LayerPanel::setComposition(int l, int c) {
  compositions[l] = c;
}

int LayerPanel::alpha(int i) {
  return alphas[i];
}

void LayerPanel::setAlpha(int i, int a) {
  alphas[i] = a;
}

void LayerPanel::setTopLeft(PtPair &pt) {
  top_left_point = pt;
}

PtRect LayerPanel::rect(void) {
  if (show)
    return PtRect(top_left_point.x, top_left_point.y, 
		  _size.x, _size.y);
  else
    return PtRect(0, 0, 0, 0);
}

PtPair LayerPanel::size(void) {
	return _size;
}

NSString* LayerPanel::compositionString(int c) {
  static NSString *cstr;

  switch (c) {
  case MinComposition:
    cstr = @"_";
    break;
  case MulComposition:
    cstr = @"*";
    break;
  case ScreenComposition:
    cstr = @"/";
    break;
  case SatComposition:
    cstr = @"S";
    break;
  case ColComposition:
    cstr = @"C";
    break;
  case DodgeComposition:
    cstr = @"D";
    break;
  case NormalComposition:
    cstr = @"N";
    break;
  case MaxComposition:
    cstr = @"^";
    break;
  case MaskComposition:
    cstr = @"M";
    break;
  case AlphaChannelComposition:
    cstr = @"A";
    break;
  }

  return cstr;
}

UIImage* LayerPanel::getImage(void) {
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL, _size.x, _size.y, 8, 
					       _size.x * 4, 
					       colorSpace, 
					       kCGImageAlphaPremultipliedLast);
  CGColorSpaceRelease(colorSpace);
  if (context == NULL)
 		return nil;
		
  CGContextTranslateCTM(context, 0, _size.y);
  CGContextScaleCTM(context, 1.0, -1.0);
  UIGraphicsPushContext(context);

  [[UIColor whiteColor] set];
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.7);
  CGContextFillRect(context, CGRectMake(0, 0, _size.x, _size.y));

  if (current >= 0 && current < (int)num_of_layers) {
    PtRect r;

    CGContextSetBlendMode(context, kCGBlendModeXOR);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);

    r = showing_rects[current];
    CGContextFillRect(context, CGRectMake(r.x, r.y, r.w, r.h));
    r = composition_rects[current];
    CGContextFillRect(context, CGRectMake(r.x, r.y, r.w, r.h));
    r = alpha_rects[current];
    CGContextFillRect(context, CGRectMake(r.x, r.y, r.w, r.h));
    //    r = tab_rects[current];
    //    CGContextFillRect(context, CGRectMake(r.x, r.y, r.w, r.h));
  }

  // Create and return the UIImage object
  UIFont *tfont = [UIFont boldSystemFontOfSize:fontSize];
  CGContextSetBlendMode(context, kCGBlendModeNormal);
  [[UIColor blackColor] set];

  CGPoint pt;
  for (uint i = 0; i < num_of_layers; i ++) {
    pt = CGPointMake(showing_rects[i].x, showing_rects[i].y);
    if (showings[i])
      [@"S" drawAtPoint:pt withFont:tfont];
    else
      [@"H" drawAtPoint:pt withFont:tfont];

    [compositionString(compositions[i])
     drawAtPoint:CGPointMake(composition_rects[i].x,
			     composition_rects[i].y)
     withFont:tfont];
    [[[[NSString alloc] initWithFormat:@"%d",alphas[i]] autorelease]
     drawAtPoint:CGPointMake(alpha_rects[i].x,
			     alpha_rects[i].y)
     withFont:tfont];
#if 0
    [@"@" drawAtPoint:CGPointMake(tab_rects[i].x,
                                  tab_rects[i].y)
     withFont:tfont];
#endif
  }

  CGImageRef cgImage = CGBitmapContextCreateImage(context);	
  UIImage *uiImage = [[UIImage alloc] initWithCGImage:cgImage];
  UIGraphicsPopContext();
  CGContextRelease(context);
  CGImageRelease(cgImage);

  return [uiImage autorelease];
}

uint LayerPanel::layerNum(int y) {
  for (int i = 0; i < num_of_layers; i ++)
    if (y >= showing_rects[i].top())
      return i;

  return num_of_layers;
}

uint LayerPanel::typeNum(int x) {
  if (x <= showing_rects[0].right())
    return Show;
  else if (x <= composition_rects[0].right())
    return Composition;
  else
    return Alpha;
#if 0
  else if (x <= alpha_rects[0].right())
    return Alpha;
  else
    return Tab;
#endif
}
