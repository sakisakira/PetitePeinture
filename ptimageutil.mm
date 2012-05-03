/*
  PtImageUtil
  by Saki Sakira <sakira@sun.dhis.portside.net>
  from 2008 September 4
 */

#include "ptimageutil.h"
#include "sketchpainter.h"
#include "ptcolor.h"
#include "singletonjunction.h"
#include "ptview.h"

CGColorSpaceRef PtImageUtil::colorspace = nil;

UIImage* PtImageUtil::uint16toUIImage(unsigned short int* buf, int imgw,
			 int x0, int y0, int w, int h) {
  CGFloat s_scale = SingletonJunction::view.scale;
//  s_scale = 1.0; // comment out for Retina
  
  CGDataProviderRef providerref;
  providerref = 
    CGDataProviderCreateWithData(NULL, 
				 buf + y0 * imgw + x0, 
				 imgw * 2 * h, NULL);
  if (!colorspace) colorspace = CGColorSpaceCreateDeviceRGB();
  CGImageRef imgref = 
    CGImageCreate(w, h, 5, 16, imgw * 2, 
      colorspace,
		  kCGBitmapByteOrder16Host,
		  providerref, NULL, NO, kCGRenderingIntentDefault);
  CGDataProviderRelease(providerref);

  UIImage *img;
  if (s_scale == 1.0)
    img = [UIImage imageWithCGImage:imgref];
  else
    img = [UIImage imageWithCGImage:imgref
                              scale:s_scale
                        orientation:UIImageOrientationUp];
  CGImageRelease(imgref);
  
  return img;
}

uint16* PtImageUtil::UIImagetoUint16(UIImage *img, 
                                     int *imgw, int *imgh) {
  CGImageRef cgimg = img.CGImage;
  int w = CGImageGetWidth(cgimg);
  int h = CGImageGetHeight(cgimg);

  UInt8* sbuf = new UInt8[w * h * 4];
  uint16* dbuf = new uint16[w * h];
  CGContextRef cont;
  if (!colorspace) colorspace = CGColorSpaceCreateDeviceRGB();
  cont = CGBitmapContextCreate(sbuf, w, h, 8, w * 4,
                               colorspace,
                               kCGImageAlphaNoneSkipFirst);
  CGContextDrawImage(cont, CGRectMake(0, 0, w, h), cgimg);
  CGContextRelease(cont);

  int x, y, index;
  PtColor col;
  for (y = 0; y < h; y ++) {
    index = y * w;
    for (x = 0; x < w; x ++, index ++) {
      col.setRgb(sbuf[index * 4 + 1],
                 sbuf[index * 4 + 2],
                 sbuf[index * 4 + 3]);
      dbuf[index] = SketchPainter::pack_color(col);
    }
  }
  delete[] sbuf;

  if (imgw) *imgw = w;
  if (imgh) *imgh = h;

  return dbuf;
}
