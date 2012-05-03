/*
 **	canvascontroller.mm
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **/

#include <stdio.h>
//#include <qvbox.h>
#include "ptpair.h"
//#include <qpainter.h>
//#import <Cocoa/Cocoa.h>
#import "ptview.h"
//#include <qpixmap.h>
//#include <qdirectpainter_qws.h>
//#include <qarray.h>
#include <vector>
//#include <qimage.h>
//#include <qmenubar.h>
//#include <qstring.h>
//#include <qpopupmenu.h>
//#include <qfileinfo.h>
//#include <qmessagebox.h>
//#include <qtopia/qpeapplication.h>
//#include <qpe/qpeapplication.h>
//#include <qdatetime.h>
//#include <qtimer.h>
//#include <qfile.h>
//#include <qdir.h>

#include "constants.h"
//#include "spainter.h"
//#include "colordialog.h"
#include "layeredpainter.h"
#include "toolpanel.h"
//#include "tspressure.h"
#include "layerpanel.h"
#include "colorpanel.h"
//#include "ptptformat.h"
//#include "filedialog.h"
#include "canvascontroller.h"
#include "clipboard.h"
//#include "z_color_adjust.h"
#import "ptimageutil.h"
#import "ptptformat.h"
#import "PainterWrapper.h"

////////// CanvasController

const NSString *CanvasController::kNumOfLayersKey = @"NumOfLayers";
const NSString *CanvasController::kImageWidthKey = @"ImageWidth";
const NSString *CanvasController::kImageHeightKey = @"ImageHeight";
const NSString *CanvasController::kCompositionMethodKeyI = @"CompositionMethod:%d";
const NSString *CanvasController::kPaperAlphaKeyI = @"PaperAlpha:%d";
const NSString *CanvasController::kPaperRedKeyI = @"PaperRed:%d";
const NSString *CanvasController::kPaperGreenKeyI = @"PaperGreen:%d";
const NSString *CanvasController::kPaperBlueKeyI = @"PaperBlue:%d";
const NSString *CanvasController::kPixelsKeyI = @"PixelsKey:%d";

const NSString *CanvasController::kPencilKey = @"PencilKey";
const NSString *CanvasController::kBrushKey = @"BrushKey";
const NSString *CanvasController::kEraserKey = @"EraserKey";
const NSString *CanvasController::kCloudKey = @"CloudKey";
const NSString *CanvasController::kCurrentLayerIndexKey = @"CurrentLayerIndex";

const CFTimeInterval CanvasController::autosave_interval = 60;

//uint16* CanvasController::_col_adj_table;

CanvasController::CanvasController(PtView *ptview) {
  //  parent = (SPainter*)pparent;
  this->ptview = ptview;
  
  //  setEnabled(TRUE);
  //  setMouseTracking(FALSE);
  //  setFocusPolicy(QWidget::ClickFocus);

  img_modified = true;
//  fullscreen = TRUE;
  pick_color_mode = FALSE;
//  zoom_mode_flag = FALSE;
//  shift_mode = false;
  layer_shift_mode = false;
  select_mode = SelectModeNone;
  pen_mode = 0;
  layer_mode = LayerModeNone;
  shift_x = shift_y = 0;
  zoom = 1.0f;
  opt_panel_type = None;
  panel_position = TopTools;
  pressing_tool = 0;
  _timer = NULL;

  sp = 0;
  //  pix = nil;
  tools = 0;
  x0 = x1 = y0 = y1 = -1;

  pencil = PtPen(PtColor(0, 0, 0), 4);
  pencil.brush_method = SolidBrush;
  pencil.antialias = true;
  brush = PtPen(PtColor(255, 0, 0), 10);
  brush.brush_method = WaterBrush;
  brush.density = 128;
  eraser = PtPen(PtColor(255, 255, 255), 10);
  eraser.brush_method = SolidBrush;
  eraser.antialias = false;
  cloud = PtPen(PtColor(128, 128, 128), 10);
  cloud.brush_method = CloudMidBrush;
  cloud.cloud_density = 128;
  pen = &pencil;

  info_string = nil;

  //  pen_density = 128;
  last_pen_method = SolidBrush;
  //  antialias = true;
  dropping_mouse_release = true;
  apply_press_width = apply_press_density = false;

  //  layers.setNumOfLayers(3);


  //  pts.setAutoDelete(TRUE);

  //  _col_adj_table = _z_col_adjust.adjust_table();

  last_saved_time = 0;

  SingletonJunction::canvas = this;

//  [ptview display];
}

CanvasController::~CanvasController() {
#if 0
  delete sp;
  delete pix;
  [_painterWrapper release];
#endif
}

void CanvasController::setupPainter(void) {
  int w, h;

  ALog(@"CanvasController::setupPainter() started");
//  NSSize vs = [ptview frame].size;
  PtPair vs = [ptview viewSize];
  w = vs.x & ~1;
  h = vs.y;

  dwidth = w;
  dheight = h;
  tools = new ToolPanel(w);
  //  parent->setTools(tools);
  //  parent->setColorPanel(&colorpanel);
  touchview = SingletonJunction::touchview;
  panelview = SingletonJunction::panelview;
  optpanelview = SingletonJunction::optpanelview;

  //  TSPressure::setWidth(dwidth);
  //  TSPressure::setHeight(dheight);

  sp = new LayeredPainter(dwidth, dheight);
  sp->setToolPanel(tools);
  sp->setShowingTools(true);
  
  _painterWrapper = [[PainterWrapper alloc]
                     initWithPainter:sp canvasControoler:this];

  //  ptview->buf = new uint16[dwidth * dheight];
  [ptview setBufferSize:dwidth * dheight];

  //  ALog(@"tools=%d", (int)tools);
  sp->fill();
  sp->setLayer(0);
//  tools = sp->getTools();
  tools->setActive(ToolPanel::PencilI, true);

  set_pen_width(pen->width());
  set_pen();
  set_antialias(true);

  NSInteger num_of_layers = [[NSUserDefaults standardUserDefaults]
			      integerForKey:(NSString*)kNumOfLayersKey];
  if (num_of_layers > 0) {
    loadDefaults();
  } else {
    clearImage(false);
    sp->setLayer(0);
  }

  set_pencil();
  set_pen();
  
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();

  // add by anoda 2003.10.27
  //  parent->ldx();
}

void CanvasController::archiveCurrentLayer(NSKeyedArchiver *archiver) {
  uint layer_index = sp->current();
  
  [archiver encodeInt:sp->compositionMethod()
	    forKey:[NSString stringWithFormat:
			       (NSString*)kCompositionMethodKeyI, layer_index]];
  [archiver encodeInt:sp->compositionAlpha()
	    forKey:[NSString stringWithFormat:
			       (NSString*)kPaperAlphaKeyI, layer_index]];
  PtColor col = sp->paperColor();
  [archiver encodeInt:col.red
        forKey:[NSString stringWithFormat:
                           (NSString*)kPaperRedKeyI, layer_index]];
  [archiver encodeInt:col.green
	    forKey:[NSString stringWithFormat:
            (NSString*)kPaperGreenKeyI, layer_index]];
  [archiver encodeInt:col.blue
	    forKey:[NSString stringWithFormat:
			       (NSString*)kPaperBlueKeyI, layer_index]];

  uint len = sp->get_width() * sp->get_height();
  [archiver encodeBytes:(uint8_t *)sp->frameBufferOfLayer(layer_index)
	    length:(len << 1)
	    forKey:[NSString stringWithFormat:
			       (NSString*)kPixelsKeyI, layer_index]];
}

void CanvasController::saveImage(void) {
  uint last_layer_index = sp->current();

  NSMutableData *data;
  NSKeyedArchiver *archiver;

  data = [[NSMutableData alloc] init];
  archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
  
  int num_of_layers = sp->numOfLayers();

  [archiver encodeInt:num_of_layers
	    forKey:(NSString*)kNumOfLayersKey];
  [archiver encodeInt:sp->get_width()
        forKey:(NSString*)kImageWidthKey];
  [archiver encodeInt:sp->get_height()
	    forKey:(NSString*)kImageHeightKey];

  for (int i = 0; i < num_of_layers; i ++) {
    sp->setLayerTemp(i);
    archiveCurrentLayer(archiver);
  }
  sp->setLayerTemp(last_layer_index);
  [archiver finishEncoding];

  NSString *fn = [[[[NSDate date] description]
		   stringByReplacingOccurrencesOfString:@":"
		   withString:@""]
		  stringByReplacingOccurrencesOfString:@" "
		  withString:@"_"];
  NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
						      NSUserDomainMask, YES)
						     objectAtIndex:0];
  NSString *fpath = [dir stringByAppendingPathComponent:fn];
  NSString *fpath_data = [fpath stringByAppendingPathExtension:@"plist"];
  if (!fpath_data || ![data writeToFile:fpath_data atomically:YES])
    [[[[UIAlertView alloc] initWithTitle:@"file error"
		       message:@"the image cannot be written to file."
		       delegate:nil
		       cancelButtonTitle:@"OK"
		       otherButtonTitles:nil] autorelease] show];
  [archiver release];
  [data release];

  UIImage *img = PtImageUtil::uint16toUIImage(sp->frameBuffer(), dwidth,
					      0, 0, dwidth, dheight);
  NSString *fpath_jpg = [fpath stringByAppendingPathExtension:@"jpg"];
  if (fpath_jpg) {
    [UIImageJPEGRepresentation(img, 0.9) writeToFile:fpath_jpg atomically:YES];
  }
}

void CanvasController::savePtpt(void) {
	uint last_layer_index = sp->current();
	int num_of_layers = sp->numOfLayers();
	PtptFormat ptpt(num_of_layers);
	
	ptpt.setThumbnail(sp->getUIImage());
	
	for (int i = 0; i < num_of_layers; i ++) {
		sp->setLayerTemp(i);
		ptpt.setCompositionMethod(i, sp->compositionMethod(i));
		ptpt.setAlpha(i, sp->compositionAlpha(i));
		ptpt.setPaperColor(i, sp->paperColor(i));
		UIImage *img = sp->getUIImageOfCurrentLayer();
		ptpt.addLayer(img);
	}
	sp->setLayerTemp(last_layer_index);
	
	NSString *fn = [[[[NSDate date] description]
									 stringByReplacingOccurrencesOfString:@":"
									 withString:@""]
									stringByReplacingOccurrencesOfString:@" "
									withString:@"_"];
  NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																											 NSUserDomainMask, YES)
									 objectAtIndex:0];
  NSString *fpath = [dir stringByAppendingPathComponent:fn];
  NSString *fpath_data = [fpath stringByAppendingPathExtension:@"ptpt"];
	
	if (!ptpt.save(fpath_data)) 
		[[[[UIAlertView alloc] initWithTitle:@"file error"
																 message:@"the image cannot be written to a ptpt file."
																delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil] autorelease] show];
#if 0  
  UIImage *img = PtImageUtil::uint16toUIImage(sp->frameBuffer(), dwidth,
                                              0, 0, dwidth, dheight);
  NSString *fpath_jpg = [fpath stringByAppendingPathExtension:@"jpg"];
  if (fpath_jpg) {
    [UIImageJPEGRepresentation(img, 0.9) writeToFile:fpath_jpg atomically:YES];
  }  
#endif
}


void CanvasController::loadImage(NSString *fpath) {
  if (PtptFormat::isPtpt(fpath)) {
    loadPtpt(fpath);
    return;
  }
  
  shift_x = shift_y = 0;
  zoom = 1.0f;

  ALog(@"loadImage: fpath: %@", fpath);
  NSData *data = [[NSData alloc]
		   //		   initWithContentsOfFile:fpath];
		   initWithContentsOfMappedFile:fpath];
  NSKeyedUnarchiver *arc = [[NSKeyedUnarchiver alloc]
                             initForReadingWithData:data];
  [data release];
  NSInteger num_of_layers = [arc decodeIntForKey:(NSString*)kNumOfLayersKey];
  if (num_of_layers <= 0) {
    [arc finishDecoding];
    [arc release];
    return;
  }

  while (sp->numOfLayers() > num_of_layers)
    sp->deleteCurrentLayer();

  NSInteger width, height;
  width = [arc decodeIntForKey:(NSString*)kImageWidthKey];
  height = [arc decodeIntForKey:(NSString*)kImageHeightKey];
  sp->setSize(width, height);

  NSInteger comp, alpha, red, green, blue;
  NSUInteger len;
  uint32a *fbuf, *dbuf;
  for (int layer_index = 0; layer_index < num_of_layers; layer_index ++) {
    if (layer_index >= sp->numOfLayers())
      sp->createLayer();
    sp->setLayerTemp(layer_index);
  
    comp = [arc decodeIntForKey:[NSString stringWithFormat:
					   (NSString*)kCompositionMethodKeyI, layer_index]];
    sp->setCompositionMethod(comp);
    alpha = [arc decodeIntForKey:[NSString stringWithFormat:
					   (NSString*)kPaperAlphaKeyI, layer_index]];
    sp->setLayerAlpha(alpha);
    red = [arc decodeIntForKey:[NSString stringWithFormat:
					   (NSString*)kPaperRedKeyI, layer_index]];
    green = [arc decodeIntForKey:[NSString stringWithFormat:
					   (NSString*)kPaperGreenKeyI, layer_index]];
    blue = [arc decodeIntForKey:[NSString stringWithFormat:
					   (NSString*)kPaperBlueKeyI, layer_index]];
    sp->setPaperColor(PtColor(red, green, blue));
    
    dbuf = (uint32a*)[arc decodeBytesForKey:[NSString stringWithFormat:
						   (NSString*)kPixelsKeyI, layer_index]
			  returnedLength:&len];
    fbuf = (uint32a*)sp->frameBufferOfLayer(layer_index);
    for (uint i = 0; i < width * height >> 1; i ++)
      fbuf[i] = dbuf[i];
  }
  [arc finishDecoding];
  [arc release];

  sp->setLayer(0);
  set_pen();
  display_pen();

  sp->updateRect(PtRect(0, 0, width, height));
  sp->backupCurrentLayer();
  updateRect(PtRect(0, 0, width, height));
  update_tools_rect();
}

void CanvasController::loadPtpt(NSString *fpath) {
	shift_x = shift_y = 0;
  zoom = 1.0f;
	PtptFormat ptpt;
	
  ALog(@"loadPtpt: fpath: %@", fpath);
	if (!ptpt.isPtpt(fpath)) return;
	
	ptpt.load(fpath);
	if (ptpt.numOfLayers() == 0) return;
	while (sp->numOfLayers() > ptpt.numOfLayers())
		sp->deleteCurrentLayer();
	
	int width, height;
	UIImage *img = ptpt.layer(0);
	width = img.size.width;
	height = img.size.height;
	sp->setSize(width, height);
	
	uint comp, alpha;
	PtColor color;
	for (int layer_index = 0; layer_index < ptpt.numOfLayers(); 
			 layer_index ++) {
		if (layer_index >= sp->numOfLayers())
			sp->createLayer();
		sp->setLayerTemp(layer_index);
		
		comp = ptpt.compositionMethod(layer_index);
		sp->setCompositionMethod(comp);
		alpha = ptpt.alpha(layer_index);
		sp->setLayerAlpha(alpha);
		color = ptpt.paperColor(layer_index);
		sp->setPaperColor(color);
		sp->loadToCurrentLayer(ptpt.layer(layer_index));
	}
	
	sp->setLayer(0);
	set_pen();
	display_pen();
	
	sp->updateRect(PtRect(0, 0, width, height));
  sp->backupCurrentLayer();
  updateRect(PtRect(0, 0, width, height));
  update_tools_rect();
}

void CanvasController::loadDefaults(void) {
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  NSInteger num_of_layers = [defs integerForKey:(NSString*)kNumOfLayersKey];
  if (num_of_layers <= 0) return;

  NSInteger width, height;
  width = [defs integerForKey:(NSString*)kImageWidthKey];
  height = [defs integerForKey:(NSString*)kImageHeightKey];
  sp->setSize(width, height);

  NSInteger comp, alpha, red, green, blue;
  uint32a *fbuf, *dbuf;
  for (int layer_index = 0; layer_index < num_of_layers; layer_index ++) {
    if (layer_index > 0) {
      sp->createLayer();
      sp->setLayerTemp(layer_index);
    }
    comp = [defs integerForKey:[NSString stringWithFormat:
					   (NSString*)kCompositionMethodKeyI, layer_index]];
    sp->setCompositionMethod(comp);
    alpha = [defs integerForKey:[NSString stringWithFormat:
					   (NSString*)kPaperAlphaKeyI, layer_index]];
    sp->setLayerAlpha(alpha);
    red = [defs integerForKey:[NSString stringWithFormat:
					   (NSString*)kPaperRedKeyI, layer_index]];
    green = [defs integerForKey:[NSString stringWithFormat:
					   (NSString*)kPaperGreenKeyI, layer_index]];
    blue = [defs integerForKey:[NSString stringWithFormat:
					   (NSString*)kPaperBlueKeyI, layer_index]];
    sp->setPaperColor(PtColor(red, green, blue));
    
    dbuf = (uint32a*)[[defs dataForKey:[NSString stringWithFormat:
						   (NSString*)kPixelsKeyI, layer_index]] 
		       bytes];
    fbuf = (uint32a*)sp->frameBufferOfLayer(layer_index);
    for (uint i = 0; i < (width * height >> 1); i ++)
      fbuf[i] = dbuf[i];
  }

  [[defs dataForKey:(NSString*)kPencilKey]
    getBytes:&pencil length:sizeof(pencil)];
  [[defs dataForKey:(NSString*)kBrushKey]
    getBytes:&brush length:sizeof(brush)];
  [[defs dataForKey:(NSString*)kEraserKey]
    getBytes:&eraser length:sizeof(eraser)];
  [[defs dataForKey:(NSString*)kCloudKey]
    getBytes:&cloud length:sizeof(cloud)];

  set_pen();
  display_pen();

  sp->setLayer([defs integerForKey:(NSString*)kCurrentLayerIndexKey]);
  sp->updateRect(PtRect(0, 0, width, height));
}

void CanvasController::saveDefaultsForCurrentLayer(void) {
  uint layer_index = sp->current();
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

  [defs setInteger:sp->compositionMethod()
        forKey:[NSString stringWithFormat:
                           (NSString*)kCompositionMethodKeyI, layer_index]];
  [defs setInteger:sp->compositionAlpha()
        forKey:[NSString stringWithFormat:
                           (NSString*)kPaperAlphaKeyI, layer_index]];
  PtColor col = sp->paperColor();
  [defs setInteger:col.red
        forKey:[NSString stringWithFormat:
                           (NSString*)kPaperRedKeyI, layer_index]];
  [defs setInteger:col.green
        forKey:[NSString stringWithFormat:
                           (NSString*)kPaperGreenKeyI, layer_index]];
  [defs setInteger:col.blue
        forKey:[NSString stringWithFormat:
                           (NSString*)kPaperBlueKeyI, layer_index]];
  uint len = sp->get_width() * sp->get_height();
  //  NSData *data = [NSData dataWithBytesNoCopy:
  //                             sp->frameBufferOfLayer(layer_index)
  //                           length:(len << 1)
  //			 freeWhenDone:YES];
  NSData *data = [NSData dataWithBytes:
			   sp->frameBufferOfLayer(layer_index)
			 length:(len << 1)];
  [defs setObject:data
        forKey:[NSString stringWithFormat:
                           (NSString*)kPixelsKeyI, layer_index]];
}

void CanvasController::saveDefaults(void) {
  uint last_layer_index = sp->current();

  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
  int num_of_layers = sp->numOfLayers();

  [defs setInteger:num_of_layers
        forKey:(NSString*)kNumOfLayersKey];
  [defs setInteger:sp->get_width()
        forKey:(NSString*)kImageWidthKey];
  [defs setInteger:sp->get_height()
        forKey:(NSString*)kImageHeightKey];

  for (int i = 0; i < num_of_layers; i ++) {
    sp->setLayerTemp(i);
    saveDefaultsForCurrentLayer();
  }
  sp->setLayerTemp(last_layer_index);

  [defs setObject:[NSData dataWithBytes:&pencil
			  length:sizeof(pencil)]
	forKey:(NSString*)kPencilKey];
  [defs setObject:[NSData dataWithBytes:&brush
			  length:sizeof(brush)]
	forKey:(NSString*)kBrushKey];
  [defs setObject:[NSData dataWithBytes:&eraser
			  length:sizeof(eraser)]
	forKey:(NSString*)kEraserKey];
  [defs setObject:[NSData dataWithBytes:&cloud
			  length:sizeof(cloud)]
	forKey:(NSString*)kCloudKey];
  [defs setInteger:last_layer_index
            forKey:(NSString*)kCurrentLayerIndexKey];
  
  [defs synchronize];

  UIImage *img = PtImageUtil::uint16toUIImage(ptview->buf, dwidth,
					     0, 0, dwidth, dheight);
  NSData *pngdata = UIImagePNGRepresentation(img);

  NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																											 NSUserDomainMask, YES)
									 objectAtIndex:0];
  NSString *pngpath = [dir stringByAppendingPathComponent:@"Default.png"];
  ALog(@"pngpath:%@", pngpath);
  bool success;
  success = [pngdata writeToFile:pngpath atomically:YES];
#if 0
  NSFileManager *fm = [NSFileManager defaultManager];
  [fm removeItemAtPath:pngpath error:NULL];
  NSMutableDictionary *attr = [[NSMutableDictionary alloc] init];
  [attr setObject:[NSNumber numberWithInteger:0600]
        forKey:@"NSFilePosixPermissions"];
  [fm changeFileAttributes:attr atPath:pngpath];
  bool success;
  success = [fm
    createFileAtPath:pngpath contents:pngdata attributes:attr];
  [attr release];
#endif
  ALog(@"png saved: %d", success);
 }

void CanvasController::convert_geometry(int* x, int* y) {
  CGFloat s_scale = SingletonJunction::view.scale;
  *x = (int)(shift_x * s_scale + (*x / zoom));
  *y = (int)(shift_y * s_scale + (*y / zoom));
}

void CanvasController::disconvert_geometry(int* x, int* y) {
  CGFloat s_scale = SingletonJunction::view.scale;
  *x = (int)((*x - shift_x * s_scale) * zoom);
  *y = (int)((*y - shift_y * s_scale) * zoom);
}

PtPair CanvasController::convert_geometry(const PtPair &p) {
  int x = p.x;
  int y = p.y;

  convert_geometry(&x, &y);

  return PtPair(x, y);
}

void CanvasController::update_panel_rect(const PtPair &size,
                               uint16 *buf16) {
  CGFloat s_scale = SingletonJunction::view.scale;
  
  if (!panel_position) {
    if (!panelview.hidden) {
      CGRect rect = panelview.frame;
      if (rect.origin.y < dheight / (2 * s_scale))
        rect.origin.y = - size.y;
      else
        rect.origin.y = dheight / s_scale;
      [UIView beginAnimations:@"PtPtPanelView" context:NULL];
      [UIView setAnimationBeginsFromCurrentState:YES];
      [UIView setAnimationDuration:0.1];
      panelview.frame = rect;
      [UIView commitAnimations];
    }
    return;
  }
  
  int x0, y0;

  if (panel_position == TopTools) {
    x0 = dwidth / s_scale - size.x;
    y0 = 0;
  } else {
    x0 = 0;
    y0 = dheight / s_scale - size.y;
  }

  [UIView beginAnimations:@"PtPtPanelView" context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.1];
  panelview.frame = CGRectMake(x0, y0, size.x, size.y);
  [UIView commitAnimations];

  panelview.buf = buf16;
  [panelview setNeedsDisplay];
  panelview.hidden = false;
}

void CanvasController::update_optional_panel_rect(const PtPair &size,
                                        uint16 *buf16) {
  if (!panel_position) {
    optpanelview.hidden = true;
    return;
  }

	CGFloat s_scale = SingletonJunction::view.scale;
  int x0, y0;
  //  int x, y, l, ti, i, w2, fw2;
  //  unsigned long int *buf, *fbuf;

  if (panel_position == TopTools) {
    x0 = dwidth / s_scale - size.x;
    y0 = tools_rect.h;
  } else {
    x0 = 0;
    y0 = dheight / s_scale - tools_rect.h - size.y;
  }

  optpanelview.frame = CGRectMake(x0, y0, size.x, size.y);
  optpanelview.buf = buf16;
  if (optpanelview.img)
    [optpanelview.img release];
  optpanelview.img = NULL;
  [optpanelview setNeedsDisplay];
  optpanelview.hidden = false;
}

void CanvasController::update_optional_panel_rect(UIImage *panel_img) {
  if (!panel_position) {
    optpanelview.hidden = true;
    return;
  }
	CGFloat s_scale = SingletonJunction::view.scale;

  int x0, y0;
  CGSize size = panel_img.size;
  if (panel_position == TopTools) {
    x0 = dwidth - size.width;
    y0 = tools_rect.h;
  } else {
    x0 = 0;
    y0 = dheight / s_scale - tools_rect.h - size.height;
  }

  optpanelview.frame = CGRectMake(x0, y0, size.width, size.height);

  if (optpanelview.img)
    [optpanelview.img release];
  optpanelview.img = [panel_img retain];
  optpanelview.buf = NULL;
  [optpanelview setNeedsDisplay];
  optpanelview.hidden = false;
}

void CanvasController::update_tools_rect(void) {
  update_panel_rect(tools->size(), tools->infoImage());
}

void CanvasController::update_colorpanel_rect(void) {
  if (!panel_position) return;

  update_optional_panel_rect(colorpanel.size(),
                    colorpanel.infoImage());
}

void CanvasController::update_layers_rect(void) {
  if (opt_panel_type != Layers) return;

  UIImage *img = layers.getImage();
  update_optional_panel_rect(img);
  
  PtPair pt;
  if (panel_position == TopTools)
    pt = tools_rect.bottomRight() + PtPair(-layers.width(), 1);
  else
    pt = tools_rect.topRight() +
      PtPair(-layers.width(), -layers.height());

  layers.setTopLeft(pt);
  optpanelview.frame = CGRectMake(pt.x, pt.y, 
				  img.size.width, img.size.height);
}

void CanvasController::update_optional_panel(void) {
  if (!panel_position) {
    optpanelview.hidden = true;
    return;
  }

  switch (opt_panel_type) {
  case Layers:
    optpanelview.hidden = true;
    update_layers_rect();
    break;
  case Color:
    update_colorpanel_rect();
    break;
  default:
    optpanelview.hidden = true;
    break;
  }
}

void CanvasController::update_panels(void) {
  update_tools_rect();
  update_optional_panel();
}

void CanvasController::updateView(const PtRect &rect) {
//    [ptview setNeedsDisplay];
	CGFloat s_scale = SingletonJunction::view.scale;
  [ptview setNeedsDisplayInRect:CGRectMake(rect.x / s_scale, 
																					 rect.y / s_scale, 
																					 rect.w / s_scale, 
																					 rect.h / s_scale)];
//	ALog(@"update rect (%d, %d) %d x %d", rect.x, rect.y, rect.w, rect.h);
}

void CanvasController::updateRect(const PtRect &rect) {
  ptview->buf = sp->frameBuffer();

  updateView(rect);
}

void CanvasController::clear_btn_info_string(float delay) {
  [NSTimer scheduledTimerWithTimeInterval:delay
	   target:touchview
	   selector:@selector(clear_btn_info_string:)
	   userInfo:nil
	   repeats:NO];
}

void CanvasController::mousePressEvent(const PtPair &orig_e) {
  if (PainterDrawingInBackground) return;
  
	CGFloat s_scale = SingletonJunction::view.scale;
	PtPair e(orig_e.x / s_scale, orig_e.y / s_scale);
	
  if (select_mode == SelectModeCopy) {
    select_copy_press_event(orig_e);
    return;
  } else if (select_mode == SelectModePaste) {
    if (panel_position && tools_rect.contains(e.x, e.y))
      panel_event(e);
    else
      select_paste_press_event(orig_e);
    return;
  }

  show_tools(true);
  if (panel_position) {
    if (tools_rect.contains(e.x, e.y)) {
      _timer = [NSTimer scheduledTimerWithTimeInterval:press_delay/1000.0
			target:ptview
			selector:@selector(tapping:)
			userInfo:nil
			repeats:NO];
      panel_event(e);
      if (x0 == PanelEventIndex) return;
    } else if (opt_panel_type &&
               opt_panel_rect.contains(e.x, e.y)) {
      if (opt_panel_type == Layers) 
        layerpanel_event(e);
      else if (opt_panel_type == Color)
        colorpanel_event(e);

      return;
    }
  }

  show_hide_layers(false);

  int x = orig_e.x;
  int y = orig_e.y;
  convert_geometry(&x, &y);
	
  //  sp->backupCurrentLayer();

  px1 = x1 = orig_e.x;
  py1 = y1 = orig_e.y;
  convert_geometry(&x1, &y1);

  x1 = max(0, min(x1, sp->get_width() - 1));
  y1 = max(0, min(y1, sp->get_height() - 1));

  px0 = px1;
  py0 = py1;
  x0 = x1;
  y0 = y1;

  //  pts.clear();

  //  hideInfo();
  
  show_tools(false);
  mouseMoveEvent(orig_e);
}

void CanvasController::mouseMoveEvent(const PtPair &orig_e) {
  //  NSPoint ept = getNSPointFromNSEvent(e);
	CGFloat s_scale = SingletonJunction::view.scale;
	PtPair e(orig_e.x / s_scale, orig_e.y / s_scale);

  if (select_mode == SelectModeCopy) {
    select_copy_move_event(orig_e);
    return;
  } else if (select_mode == SelectModePaste) {
    select_paste_move_event(orig_e);
    return;
  } else if (select_mode) return;

  if (pen_mode && panel_position &&
      !tools_rect.contains(e.x, e.y)) {
    pressing_tool = 0;
    panel_move_event(e);
    return;
  } else if (layer_mode && panel_position &&
             opt_panel_type == Layers &&
             !layers.rect().contains(e.x, e.y)) {
    pressing_tool = 0;
    layerpanel_move_event(e);
    return;
  } else if (opt_panel_rect.contains(e.x, e.y) &&
             opt_panel_type == Color && x0 < 0) {
    pressing_tool = 0;
    colorpanel_move_event(e);

    return;
  }

  if (tools->is_panel_b &&
      tools_rect.contains(e.x, e.y)) {
    panel_move_event(e);
    return;
  }

  if (x0 < 0) return;
  //  pressing_tool = 0;

  PtPen ppen(*pen);

  int nzx, nzy;

  x0 = x1; y0 = y1;
  px0 = px1; py0 = py1;
  
  nzx = px1 = x1 = orig_e.x;
  nzy = py1 = y1 = orig_e.y;
  convert_geometry(&x1, &y1);
  
  if (dropping_mouse_release &&
      (px0 - px1) * (px0 - px1)
      + (py0 - py1) * (py0 - py1) > 90000) {
    px0 = px1; py0 = py1;
    x0 = x1; y0 = y1;
  }

  if (layer_shift_mode) {
    layer_shift_image_by_mouse();
    if (x1 < 0) x1 = 0;
    if (y1 < 0) y1 = 0;
    if (x1 >= dwidth) x1 = dwidth - 1;
    if (y1 >= dheight) y1 = dheight - 1;
    x0 = x1; y0 = y1;
    return;
  }

  x1 = max(0, min(x1, sp->get_width() - 1));
  y1 = max(0, min(y1, sp->get_height() - 1));

  if (pick_color_mode) {
    show_tools(true);

    PtColor pcol;
    if (tools_rect.contains(e.x, e.y)) {
      pcol = tools->getColor(e.x - tools_rect.left(),
			    e.y - tools_rect.top());
    } else {
      pcol = [ptview getColorAtX:x1 y:y1];
    }
    set_pen();
    pen->setColor(pcol);

    loupe.alpha = 1.0;
    [loupe setPosCenterX:px1 y:py1];
  } else {
    sp->setPen(ppen, false);
    if (x0 != x1 || y0 != y1) {
//      sp->drawLine(x0, y0, x1, y1, true);

      int min_x, max_x, min_y, max_y;
      int pwz;
      pwz = (pen->width() / 2) + 1;
      if (x0 <= x1) {
        min_x = x0 - pwz;
        max_x = x1 + pwz;
      } else {
        min_x = x1 - pwz;
        max_x = x0 + pwz;
      }
      if (y0 <= y1) {
        min_y = y0 - pwz;
        max_y = y1 + pwz;
      } else {
        min_y = y1 - pwz;
        max_y = y0 + pwz;
      }
  
      PtRect rect(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1);
      rect = rect & PtRect(0, 0, dwidth, dheight);
//      updateRect(rect);
      
      PenStroke *stroke = [[[PenStroke alloc] init] autorelease];
      stroke->pen = ppen;
      stroke->rect = rect;
      stroke->x0 = x0;
      stroke->y0 = y0;
      stroke->x1 = x1;
      stroke->y1 = y1;
      
      @synchronized(this->_painterWrapper.queuedStrokes) {
        ALog(@"queue size %d", [_painterWrapper.queuedStrokes count]);
        [this->_painterWrapper pushLineToQueueWithPenStroke:stroke];
        if (!PainterDrawingInBackground) {
          PainterDrawingInBackground = YES;
#ifndef TouchPeintureLite
          dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
          dispatch_async(queue, ^{
            [this->_painterWrapper drawLinesInQueue];
          });
#else
          [this->_painterWrapper
           performSelectorInBackground:@selector(drawLinesInQueue) 
           withObject:nil];
#endif
        }
      }
    }

    if (loupe.follow_finger) {
      loupe.alpha = 0.5;
      [loupe setPosCenterX:px1 y:py1];
    } else {
      loupe.alpha = 1.0;
      if (panel_position == BottomTools) 
        [loupe setPosCenterX:loupe->_size->x * loupe->_scale * s_scale / 2
                           y:dheight + loupe->_size->y * loupe->_scale * s_scale / 2];
      else
        [loupe setPosCenterX:loupe->_size->x * loupe->_scale * s_scale / 2
                           y:0 - loupe->_size->y * loupe->_scale * s_scale / 2];
    }
  }

  loupe.hidden = false;
  if (panel_position &&
      tools_rect.contains(e.x, e.y)) {
    [loupe setFillColor:pen->color()];
  } else {
    if (pen == &pencil || pen == &brush)
      [loupe set_bound_color:pen->color()];
    else
      [loupe set_bound_color:PtColor(0, 0, 0)];
    [loupe setBufCenterX:x1 y:y1];
  }
  [loupe setScale:4.0];
  [loupe setNeedsDisplay];

  img_modified = true;
}

void CanvasController::mouseReleaseEvent(const PtPair &orig_e) {
  this->y0 = -1;
  if (PainterDrawingInBackground) return;
  
	CGFloat s_scale = SingletonJunction::view.scale;
	PtPair e(orig_e.x / s_scale, orig_e.y / s_scale);
	
  if (pick_color_mode)
      pick_color(orig_e);

  loupe.hidden = true;
  //  show_tools(false);

  if (touchview->btn_info_string) {
    [touchview->btn_info_string release];
    clear_btn_info_string();
  }

  sp->setPen(*pen, true, true);
  //  sp->setPenDensity(pen_density, true, true);

  if (select_mode ||
      (panel_position && tools->is_panel_b &&
       tools_rect.contains(e.x, e.y))) {
    panel_release_event(e);
    update_panels();
    [ptview setNeedsDisplay];
    return;
  }

  if (layer_shift_mode) {
    sp->updateRect(PtRect(0, 0, dwidth, dheight));
    updateRect(PtRect(0, 0, dwidth, dheight));
    [ptview setNeedsDisplay];
  }
  
  pressing_tool = 0;

  if (pen_mode) {
    if (tools_rect.contains(e.x, e.y)) {
      switch (pen_mode) {
      case PenModeDensity:
	//	if (parent->noviceMode() && sp->numOfLayers() == 2 &&
	//	    sp->current() == 0)
	if (0)
	  sp->setLayer(1);

        set_brush();
        break;
      case PenModeCloud:
        set_cloud();
        break;
      case PenModeColor:
        set_pick_mode();
        break;
      case PenModeMove:
	set_shift_mode();
	break;
      }
      pen_mode = 0;
    } else {
      if (pen_mode == PenModeMove) {
	set_layer_shift_mode();
	pen_mode = 0;
      } else {
	pen_mode = 0;
	display_pen();
      }
    }

    update_info_string();

    update_info_rect();
    update_panels();  // added
    [ptview setNeedsDisplay];
    return;
  } else if (layer_mode) {
    layerpanel_release_event(e);
    update_info_rect();
    update_panels();  //  added
    [ptview setNeedsDisplay];
    return;
  }

  if (opt_panel_type == Color &&
      panel_position &&
      opt_panel_rect.contains(e.x, e.y) && x0 < 0) {
    colorpanel_release_event(e);
    update_info_rect();
    update_panels();  //  added
    [ptview setNeedsDisplay];
    return;
  }

  if (x0 >= 0 || img_modified)
    sp->backupCurrentLayer();

  x0 = x1 = y0 = y1 = -1;
  px0 = px1 = py0 = py1 = -1;

  CFTimeInterval now = CFAbsoluteTimeGetCurrent();
  if (last_saved_time == 0) {
    last_saved_time = now;
  } else if (last_saved_time + autosave_interval <= now) {
#ifndef TouchPeintureLite
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
      saveDefaultsForCurrentLayer();
    });
#else
    saveDefaultsForCurrentLayer();
#endif
    last_saved_time = now;
  }

  sp->clearMask();
  sp->setPen(*pen);

  display_pen();

  //  parent->setFullScreen();
  update_info_rect();
  update_panels();
//  [ptview setNeedsDisplay]; // commented out at 2012.04.10
}

void CanvasController::mousePressEventCancelled(void) {
  //  tools->clearSelection();
  //  display_pen();

  select_mode = SelectModeNone;
  touchview->copy_paste_rect.size.width = 0;
  sp->setClipboardPasteMode(false);

  pick_color_mode = false;

  sp->cancelCurrentLayer();
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  loupe.hidden = true;
  [ptview setNeedsDisplay];
  [touchview setNeedsDisplay];

  x0 = x1 = y0 = y1 = -1;
  px0 = px1 = py0 = py1 = -1;
}

int CanvasController::getToolBtnIndex(int x, int y) {
  return tools->getIndex(x, y);
}

void CanvasController::panel_event(const PtPair &e) {
  int x, y, last_x0;

  last_x0 = x0;
  x0 = PanelEventIndex;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x - tools_rect.x;
  y = e.y - tools_rect.y;
  
  pressing_tool = tools->getIndex(x, y);
  
  switch (pressing_tool) {
  case ToolPanel::PanelSwitchI:
    tools->setActive(ToolPanel::PanelSwitchI);
    update_tools_rect();
    return;
    break;
  case ToolPanel::SelectI:
    set_select_mode();
    touchview->btn_info_string = @"Select";
    return;
    break;
  case ToolPanel::CloudI:
    set_cloud_mode();
    previous_value = sp->cloudDensity();
    touchview->btn_info_string = @"Cloud";
    break;
  case ToolPanel::EraserI:
    set_eraser_mode();
    touchview->btn_info_string = @"Eraser";
    break;
  case ToolPanel::BrushI:
    set_brush_mode();
    previous_value = pen->density;
    touchview->btn_info_string = @"Brush";
    break;
  case ToolPanel::PencilI:
    set_pencil_mode();
    touchview->btn_info_string = @"Pencil";
    break;
  case ToolPanel::PenInfoI:
    set_peninfo_mode();
    touchview->btn_info_string = @"ColorPicker";
    break;
  case ToolPanel::LayerI:
    show_hide_layers();
    touchview->btn_info_string = @"Layer";
    break;
  case ToolPanel::PaletteI:
    touchview->btn_info_string = @"Palette";
    pick_color_mode = true;
    pen_mode = PenModeNone;
    x0 = 0;
    return;
    break;
  }

  [touchview setNeedsDisplay];
  clear_btn_info_string();

  if (select_mode) {
    select_mode = SelectModeCancel;
    set_select_mode();
  }
  //  unset_layer_shift_mode();
//  unset_shift_mode();
}

void CanvasController::colorpanel_event(const PtPair &e) {
  x0 = ColorPanelEventIndex;

  reset_timer();
  colorpanel_move_event(e, false);
}

void CanvasController::layerpanel_event(const PtPair &e) {
 // int x, y, c;
  int x, y;
  uint l;

  x0 = LayerPanelEventIndex;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x - opt_panel_rect.x;
  y = e.y - opt_panel_rect.y;

//  layers.editing = l = layers.layerNum(opt_panel_rect.h - y);
  layers.editing = l = layers.layerNum(y);
  //  ALog(@"CanvasController::layerpanel_event %d %d", y, l);

  switch (layers.typeNum(x)) {
  case LayerPanel::Show:
    sp->setShowing(l, !sp->getShowing(l));
    img_modified = true;
    updateRect(PtRect(0, 0, dwidth, dheight));
    [ptview setNeedsDisplay];
    break;
#if 0
  case LayerPanel::Composition:
    c = (layers.composition(l) + 1) % NumOfComposition;
    sp->setCompositionMethod(l, c);
    updateRect(PtRect(0, 0, dwidth, dheight));
    img_modified = true;
    [ptview setNeedsDisplay];
    break;
  case LayerPanel::Alpha:
    layer_mode = LayerModeAlpha;
    break;
  case LayerPanel::Tab:
    layer_mode = LayerModeTab;
    break;
#endif
  }
  layer_mode = LayerModeTab;  // added for touchpeinture
}

void CanvasController::panel_move_event(const PtPair &e) {
  int x, y;

  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x - tools_rect.x;
  y = e.y - tools_rect.y;

  int diff;
  
  int index = tools->getIndex(x, y);
  switch (index) {
  case ToolPanel::SelectI:
  case ToolPanel::FileI:
  case ToolPanel::ToolI:
    tools->setActive(index, true);
    break;
  case ToolPanel::SettingI:
    tools->setActive(ToolPanel::ToolI, true);
    break;
  }
  
  switch (pen_mode) {
  case PenModeDensity:
    tools->setActive(ToolPanel::BrushI, true);
    set_pen_density(300 * x / dwidth - 10);
    diff = (int)pen->density - previous_value;
    info_string = [[[NSString alloc]
		     initWithFormat:@"%d %+d",pen->density,diff]
		     autorelease];
    update_tools_rect();
    update_info_string(true);
    break;
  case PenModeCloud:
    tools->setActive(ToolPanel::CloudI, true);
    set_cloud_density(300 * x / dwidth - 10);
    diff = (int)cloud.cloud_density - previous_value;
    info_string = [[[NSString alloc]
		     initWithFormat:@"%d %+d",sp->cloudDensity(),diff]
		     autorelease];
    update_tools_rect();
    update_info_string(true);
    break;
  case PenModeColor:
    set_color_panel();
    tools->setActive(ToolPanel::PenInfoI, false);
    pen_mode = 0;
    break;
  }

  update_tools_rect();
}

void CanvasController::colorpanel_move_event(const PtPair &e, bool move) {
  if (x0 != ColorPanelEventIndex) return;
	
	CGFloat s_scale = SingletonJunction::view.scale;
	PtPair orig_e(e.x * s_scale, e.y * s_scale);
  int x, y;
	
  if (_timer) {
    return;
  } else {
    _timer = [NSTimer 
	       scheduledTimerWithTimeInterval:50/1000.0
	       target:ptview
	       selector:@selector(reset_timer:)
	       userInfo:nil
	       repeats:NO];
  }

  x = e.x - opt_panel_rect.x;
  y = e.y - opt_panel_rect.y;

  colorpanel.clicked(x, y, move);
  update_optional_panel();

  loupe.alpha = 1.0;
  [loupe setPosCenterX:orig_e.x y:orig_e.y];
  loupe.hidden = false;
  [loupe setFillColor:pen->color()];
  [loupe setScale:4.0];
  [loupe setNeedsDisplay];
}

void CanvasController::layerpanel_move_event(const PtPair &e) {
  int x;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x;

  if (layer_mode == LayerModeAlpha) {
    set_layer_alpha(layers.editing, 300 * x / dwidth - 10);
  }
}

void CanvasController::panel_release_event(const PtPair &e) {
  int x, y;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x - tools_rect.x;
  y = e.y - tools_rect.y;

  if (select_mode == SelectModeCopy) {
    CGFloat s_scale = SingletonJunction::view.scale;
    PtPair se(e.x * s_scale, e.y * s_scale);
    select_copy_release_event(se);
    return;
  } else if (select_mode) return;

  switch (tools->getIndex(x, y)) {
  case ToolPanel::SelectI:
    set_select_mode();
    touchview->btn_info_string = @"Select";
    [touchview setNeedsDisplay];
    clear_btn_info_string();
    return;
    break;
  case ToolPanel::FileI:
    [ptview showFileAlert];
    break;
  case ToolPanel::ToolI:
    [ptview showToolAlert];
    break;
  case ToolPanel::SettingI:
    break;
  }

  tools->clearSelection();
  display_pen();
}

void CanvasController::colorpanel_release_event(const PtPair &e) {
  int x, y;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x = e.x - opt_panel_rect.x;
  y = e.y - opt_panel_rect.y;

  colorpanel.released(x, y);
}

void CanvasController::layerpanel_release_event(const PtPair &e) {
  int y;
  uint l;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  //  y = e.y - layers.y();
  y = e.y - opt_panel_rect.y;
  l = layers.layerNum(y);
  //  ALog(@"CanvasController::layerpanel_release_event: layernum: %d", l);

  if (opt_panel_type == Layers && layers.rect().contains(e.x, e.y)) {
    if (layers.editing == l)
      sp->setLayer(l);
    else if (layer_mode == LayerModeTab) {
      //      exchangeLayers(layers.editing, l);
    }
  } else
   fix_layer_alpha();

  layer_mode = LayerModeNone;
}

void CanvasController::joinShowingLayers(void) {
#if 0
  if (!QMessageBox::warning(this, "PetitePeinture",
                         "Join all showing layers?\n\n",
                         "OK", "Cancel"))
    sp->joinShowingLayers();
#endif
  eraser.setColor(sp->paperColor());
}

void CanvasController::exchangeLayers(int i0, int i1) {
  sp->exchangeLayers(i0, i1);

  img_modified = true;

  eraser.setColor(sp->paperColor());
}

void CanvasController::moveUpCurrentLayer(void) {
  int c = sp->current();
  exchangeLayers(c, c + 1);
}

void CanvasController::moveDownCurrentLayer(void) {
  int c = sp->current();
  exchangeLayers(c - 1, c);
}

void CanvasController::duplicateCurrentLayer(void) {
  sp->duplicateCurrentLayer();
}

void CanvasController::deleteCurrentLayer(void) {
  sp->deleteCurrentLayer();

  img_modified = true;
}

void CanvasController::update_info_string(bool bg) {
  if (!info_string) return;

  PtRect r = tools_rect;
  int x, y;
  x = r.w / 2 - 10;
  y = 0;

  if (panelview->info_string)
    [panelview->info_string release];
  panelview->info_string = info_string;
  [panelview->info_string retain];
  info_string = nil;
}

void CanvasController::update_info_rect(void) {
	CGFloat s_scale = SingletonJunction::view.scale;
	
  if (panel_position) {
    PtPair size = tools->size();
    PtPair osize;
    int x0, y0, ox0, oy0;

    switch (opt_panel_type) {
    case Layers:
      osize = layers.size();
      break;
    case Color:
      osize = colorpanel.size();
      break;
    default:
      break;
    }

    if (panel_position == HideTools) {
      ox0 = x0 = dwidth / s_scale;
      oy0 = y0 = dheight / s_scale;
    } else if (panel_position == TopTools) {
      x0 = dwidth / s_scale - size.x;
      y0 = 0;
      ox0 = dwidth / s_scale - osize.x;
      oy0 = size.y;
    } else if (panel_position == BottomTools) {
      x0 = 0;
      y0 = dheight / s_scale - size.y;
      ox0 = (opt_panel_type == Layers) ? dwidth / s_scale - osize.x : 0;
      oy0 = y0 - osize.y;
    }
    
    [UIView beginAnimations:@"PtPtPanelView" context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.1];
    tools_rect = PtRect(x0, y0,
			size.x, size.y);
    panelview.frame = CGRectMake(x0, y0, size.x, size.y);

    opt_panel_rect = PtRect(ox0, oy0,
			    osize.x, osize.y);
    optpanelview.frame = CGRectMake(ox0, oy0, osize.x, osize.y);
    [UIView commitAnimations];
  }
  update_panels();
  update_info_string();
}

void CanvasController::set_antialias(bool a) {
  sp->setAntialias(a);
  pen->antialias = a;
}

void CanvasController::set_pen_width(int w) {
  if (x0 >= 0) return;
  
  w = max(1, min(SingletonJunction::penWidthMax, w));

  if (sync_width && pen != &eraser) {
    pencil.setWidth(w);
    brush.setWidth(w);
    cloud.setWidth(w);
  } else {
    pen->setWidth(w);
  }

  sp->setPen(*pen);
  //  info_rect = sp->showPenInfo();
  info_string =  [[[NSString alloc] initWithFormat:@"%d",w]
		  autorelease];
  update_info_rect();

  //  SingletonJunction::pencilWidthChanged(pencil.width());
  //  SingletonJunction::brushWidthChanged(brush.width());
  //  SingletonJunction::eraserWidthChanged(eraser.width());
  //  SingletonJunction::cloudWidthChanged(cloud.width());
}

void CanvasController::set_pen_density(int d) {
  if (x0 >= 0) return;

  if (d < 0)
    d = 0;
  else if (d > 256)
    d = 256;
  
  sp->setPenDensity(d);
  pen->density = d;

  sp->setPen(*pen);
//  info_rect = sp->showPenInfo();
  info_string = [[[NSString alloc] initWithFormat:@"d %d",pen->density]
		 autorelease];
  update_info_rect();
}

void CanvasController::set_cloud_density(int d) {
  if (x0 >= 0) return;

  if (d < 0)
    d = 0;
  else if (d > 255)
    d = 255;

  sp->setCloudDensity(d);
  sp->setPenMethod(NumOfBrushes);
  cloud.cloud_density = d;

  info_string = [[[NSString alloc] initWithFormat:@"%d",d]
		 autorelease];
//  info_rect = sp->showPenInfo();
  update_info_rect();
}

void CanvasController::set_eraser_mode(void) {
  if (x0 >= 0) return;

  set_eraser();
}

void CanvasController::set_pen(void) {
  switch (last_pen_method) {
  case SolidBrush:
  case EraserBrush:
    set_pencil();
    break;
  case WaterBrush:
    set_brush();
    break;
  }
}

void CanvasController::display_pen(void) {
  if (pen == &pencil)
    set_pencil();
  else if (pen == &brush)
    set_brush();
  else if (pen == &eraser)
    set_eraser();
  else if (pen == &cloud)
    set_cloud();
}

void CanvasController::set_pencil(void) {
  if (x0 >= 0) return;

  pen = &pencil;

  tools->clearSelection();
  tools->setActive(ToolPanel::PencilI, true);
  sp->setPenMethod(SolidBrush);
  sp->setPen(*pen);

  //  info_rect = sp->showPenInfo();
  info_string = [[[NSString alloc] initWithFormat:@"%d",pen->width()]
		 autorelease];
  update_info_rect();

  last_pen_method = SolidBrush;
}

void CanvasController::set_brush(void) {
  if (x0 >= 0) return;

  pen = &brush;

  tools->clearSelection();
  tools->setActive(ToolPanel::BrushI, true);
  sp->setPenMethod(WaterBrush);
  sp->setPen(*pen);

  //  info_rect = sp->showPenInfo();
  info_string = [[[NSString alloc] 
		 initWithFormat:@"%d %d",pen->width(),pen->density]
		 autorelease];
  update_info_rect();

  last_pen_method = WaterBrush;
}

void CanvasController::set_eraser(void) {
  if (x0 >= 0) return;

  eraser.setColor(sp->paperColor());
  pen = &eraser;

  tools->clearSelection();
  tools->setActive(ToolPanel::EraserI, true);
  sp->setPenMethod(EraserBrush);
  sp->setPen(*pen);

  //  info_rect = sp->showPenInfo();
  info_string = [[[NSString alloc] initWithFormat:@"%d",pen->width()]
    		 autorelease];
  update_info_rect();
}

void CanvasController::set_brush_mode(void) {
  if (x0 >= 0) return;

  set_brush();
  pen_mode = PenModeDensity;
}

void CanvasController::set_pencil_mode(void) {
  if (x0 >= 0) return;

  set_pencil();
}

void CanvasController::set_cloud(void) {
  if (x0 >= 0) return;

  pen = &cloud;

  tools->clearSelection();
  tools->setActive(ToolPanel::CloudI, true);
  sp->setPenMethod(CloudWideBrush);
  sp->setPen(*pen);

  //  info_rect = sp->showPenInfo();
  info_string = [[[NSString alloc] 
		 initWithFormat:@"%d %d",pen->width(),cloud.cloud_density]
   		 autorelease];
  update_info_rect();
}

void CanvasController::set_cloud_mode(void) {
  if (x0 >= 0) return;

  set_cloud();
  tools->clearSelection();
  
  pen_mode = PenModeCloud;
}

void CanvasController::set_layer_alpha(int alpha) {
  if (x0 >= 0) return;

  if (alpha < 0)
    alpha = 0;
  else if (alpha > 255)
    alpha = 255;
  
  sp->setLayerAlpha(alpha);

  updateRect(PtRect(0, 0, dwidth, dheight));

  info_string = [[[NSString alloc] initWithFormat:@"%d",alpha]
		 autorelease];
  update_info_string();
}

void CanvasController::set_layer_alpha(int l, int alpha) {
  if (x0 >= 0) return;

  if (alpha < 0)
    alpha = 0;
  else if (alpha > 255)
    alpha = 255;
  
  sp->setLayerAlpha(l, alpha);

  updateRect(PtRect(0, 0, dwidth, dheight));

  info_string = [[[NSString alloc] initWithFormat:@"%d",alpha]
		 autorelease];
  update_info_string();
}

void CanvasController::fix_layer_alpha(void) {
  sp->setLayer();

  update_info_rect();
  //  info_string = nil;

  layer_mode = LayerModeNone;
}

void CanvasController::set_color_panel(void) {
  opt_panel_type = Color;

  colorpanel.setInitColor(pen->color());
  
  //  update_info_rect();
  
  //  updateRect(PtRect(0, 0, dwidth, dheight));
  //  repaint();
  [ptview setNeedsDisplay];
  info_string = @"colorpanel";
  //  updateRect(PtRect(0, 0, dwidth, dheight));

  update_info_rect();
  update_colorpanel_rect();
}

void CanvasController::finishColorPanel(void) {
  opt_panel_type = None;
  

  update_info_rect();

  updateRect(PtRect(0, 0, dwidth, dheight));
  //  repaint();
  [ptview setNeedsDisplay];
}

void CanvasController::show_hide_color_panel(void) {
  if (opt_panel_type == Color)
    finishColorPanel();
  else
    set_color_panel();
}

void CanvasController::setUserPalette(void) {
  ALog(@"canvas::setUserPalette");
  tools->setColorPalette();
  update_tools_rect();
}

void CanvasController::getColor(uint16 col) {
  set_pen();
  pen->setColor(SketchPainter::unpack_color(col));
  set_pen();
}

void CanvasController::set_pen_color_dlg(PtColor col) {
#if 0
  bool last_fullscreen;
  //  ColorDialog d(this, col, "Pen Color");

  last_fullscreen = fullscreen;
  fullscreen = FALSE;
  
  if (d.exec()) {
    set_pen();
    pen->setColor(col);
    set_pen();
  }

  parent->enableFullscreen();
  
  opt_panel_type = None;
  fullscreen = last_fullscreen;
#endif
}

void CanvasController::setPaperColor(void) {
#if 0
  bool last_fullscreen;
  QColor col = sp->paperColor();
  ColorDialog d(this, col, "Paper Color");

  last_fullscreen = fullscreen;
  fullscreen = false;

  if (d.exec()) {
    sp->setPaperColor(col);
    img_modified = true;
  }

  fullscreen = last_fullscreen;
#endif
}

void CanvasController::exchangeColorPaperPen(void) {
  PtColor pa_col = sp->paperColor();
  PtColor pe_col = brush.color();

  set_pen();
  pen->setColor(pa_col);
  sp->setPaperColor(pe_col);

  set_eraser();
  set_pen();

  //  repaint();
  [ptview setNeedsDisplay];
}

void CanvasController::set_peninfo_mode(void) {
  pen_mode = PenModeColor;

  tools->setActive(ToolPanel::PenInfoI, true);
  update_panels();
}

void CanvasController::set_pick_mode(void) {
  pick_color_mode = TRUE;

  tools->setActive(ToolPanel::PenInfoI, true);
  update_panels();

  //  hideInfo();
}

void CanvasController::pick_color(const PtPair &orig_e) {
  CGFloat s_scale = SingletonJunction::view.scale;
  
  PtPair p(convert_geometry(orig_e));
  PtPair e(orig_e.x / s_scale, orig_e.y / s_scale);

  tools->setActive(ToolPanel::PenInfoI, false);

  if (!tools_rect.contains(e.x, e.y) &&
      !opt_panel_rect.contains(e.x, e.y)) {
    PtColor pcol = [ptview getColorAtX:p.x y:p.y];
    set_pen();
    pen->setColor(pcol);
    colorpanel.setColor(pcol);
    set_pen();
  }

  pick_color_mode = FALSE;
}

void CanvasController::set_shift_by_center(int x, int y) {
  int px, py;

  px = x;
  py = y;

  px -= (int)(dwidth / (zoom * 2));
  py -= (int)(dheight / (zoom * 2));
  
  shift_x = px;
  shift_y = py;
  
  adjust_shift();
}

void CanvasController::adjust_shift(void) {
  CGFloat s_scale = SingletonJunction::view.scale;
  
  if (zoom > ZoomMax) zoom = ZoomMax;
  if (zoom < ZoomMin) zoom = ZoomMin;

  if ((sp->get_width() * zoom >= dwidth) ||
      (sp->get_height() * zoom >= dheight)) {
    int pw, ph;

    pw = sp->get_width() / zoom;
    ph = sp->get_height() / zoom;

    shift_x = max(shift_x, - pw / 2);
    shift_y = max(shift_y, - ph / 2);

    shift_x = min(shift_x, sp->get_width() - pw / 2);
    shift_y = min(shift_y, sp->get_height() - ph / 2);
  } else {
    shift_x = - (dwidth - sp->get_width() * zoom) / (zoom * 2 * s_scale);
    shift_y = - (dheight - sp->get_height() * zoom) / (zoom * 2 * s_scale);
  }
}

void CanvasController::shift_image(int x, int y) {
  shift_x += x;
  shift_y += y;

  adjust_shift();

  updateRect(PtRect(0, 0, dwidth, dheight));
}

void CanvasController::shift_image_by_mouse(void) {
  int x, y;

  x = (int)((px0 - px1) / zoom);
  y = (int)((py0 - py1) / zoom);
  shift_image(x, y);
}

void CanvasController::layer_shift_image(int dx, int dy) {
  PtPair pt(dx, dy);
  PtRect rect(0, 0, dwidth, dheight);
  
  rect = rect & PtRect(x1 - 100, y1 - 100, 200, 200);
  sp->shiftCurrentLayer(pt, rect);
  sp->backupCurrentLayer();

  updateRect(rect);
}

void CanvasController::layer_shift_image_by_mouse(void) {
  int x, y;

  x = (int)((px0 - px1) / zoom);
  y = (int)((py0 - py1) / zoom);
  layer_shift_image(x, y);
}

void CanvasController::undo(void) {
    sp->exchangeCurrentLayer();
    img_modified = true;
    //    repaint();
    [ptview setNeedsDisplay];
}

void CanvasController::set_select_mode(void) {
  if (select_mode == SelectModeNone) {
    select_mode = SelectModeCopy;
    sp->setToolPanelActive(ToolPanel::SelectI, true);
    touchview->copy_paste_rect.size.width = 0;
  } else if (select_mode == SelectModePaste) {
    PPClipboard *cb = sp->getClipboard();
    PtPair ppt(cb->x(), cb->y());

    sp->pasteClipboard(ppt);
    sp->setClipboardPasteMode(false);

    sp->updateRect(PtRect(0, 0, dwidth, dheight));
    updateRect(PtRect(0, 0, dwidth, dheight));
    
    sp->setToolPanelActive(ToolPanel::SelectI, false);

    select_mode = SelectModeNone;
    touchview->copy_paste_rect.size.width = 0;
  } else {
    sp->setToolPanelActive(ToolPanel::SelectI, false);

    select_mode = SelectModeNone;
    touchview->copy_paste_rect.size.width = 0;
    sp->setClipboardPasteMode(false);

    sp->updateRect(PtRect(0, 0, dwidth, dheight));
    updateRect(PtRect(0, 0, dwidth, dheight));
    [touchview setNeedsDisplay];
  }
}

void CanvasController::set_select_mode_copy(void) {
  select_mode = SelectModeCopy;
  sp->setClipboardPasteMode(false);
}

void CanvasController::set_select_mode_paste(void) {
  select_mode = SelectModePaste;
  sp->setClipboardPasteMode(true);
}

void CanvasController::set_select_mode_paste_freeze(void) {
  if (select_mode == SelectModePaste)
    set_select_mode();
}

void CanvasController::set_select_mode_paste_cancel(void) {
  if (select_mode == SelectModePaste)
    sp->setToolPanelActive(ToolPanel::SelectI, false);

  select_mode = SelectModeNone;
  touchview->copy_paste_rect.size.width = 0;
  sp->setClipboardPasteMode(false);

  sp->updateRect(PtRect(0, 0, dwidth, dheight));
  updateRect(PtRect(0, 0, dwidth, dheight));
  [touchview setNeedsDisplay];
}

void CanvasController::select_copy_press_event(const PtPair &e) {
  int x, y;
  CGFloat s_scale = SingletonJunction::view.scale;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  pcopy_rect.x = e.x / s_scale;
  pcopy_rect.y = e.y / s_scale;
  pcopy_rect.w = 0;

  x = e.x;
  y = e.y;

  convert_geometry(&x, &y);

  copy_rect.x = x;
  copy_rect.y = y;
  copy_rect.w = 0;

  //  sp->setToolPanelActive(ToolPanel::SelectI, false);
}

CGRect CanvasController::PtRectToCGRect(const PtRect &r) {
  return CGRectMake(r.x, r.y, r.w, r.h);
}

void CanvasController::select_copy_move_event(const PtPair &e) {
  static int x, y;
  CGFloat s_scale = SingletonJunction::view.scale;
  //  NSPoint ept = getNSPointFromNSEvent(e);
  x = e.x / s_scale;
  y = e.y / s_scale;
  
  touchview->copy_paste_rect = PtRectToCGRect(pcopy_rect);
  [ptview setNeedsDisplayInRect:PtRectToCGRect(pcopy_rect)];
  pcopy_rect.w = x - pcopy_rect.x + 1;
  pcopy_rect.h = y - pcopy_rect.y + 1;
  touchview->copy_paste_rect = PtRectToCGRect(pcopy_rect);
//  [touchview setNeedsDisplayInRect:PtRectToCGRect(pcopy_rect)];
  [touchview setNeedsDisplayInRect:CGRectMake(0, 0, dwidth / s_scale, dheight / s_scale)];
}

void CanvasController::select_copy_release_event(const PtPair &e) {
  int x, y;
//  CGFloat s_scale = SingletonJunction::view.scale;
  //  NSPoint ept = getNSPointFromNSEvent(e);
  x = e.x;
  y = e.y;
  convert_geometry(&x, &y);

  int x0, y0, x1, y1;
  x0 = min(x, copy_rect.x);
  x1 = max(x, copy_rect.x);
  y0 = min(y, copy_rect.y);
  y1 = max(y, copy_rect.y);
//  ALog(@"release (%d - %d) (%d - %d)", x0, x1, y0, y1);

  copy_rect.x = x0;
  copy_rect.w = x1 - copy_rect.x + 1;
  copy_rect.y = y0;
  copy_rect.h = y1 - copy_rect.y + 1;

//  PtRect rect = copy_rect * s_scale;
  sp->copyClipboard(copy_rect);

  //  sp->setToolPanelActive(ToolPanel::SelectI, false);

  select_mode = SelectModePaste;
  sp->setClipboardPasteMode(true);
}

void CanvasController::select_paste_press_event(const PtPair &e) {
  int x, y;
  //  NSPoint ept = getNSPointFromNSEvent(e);
  x = e.x;
  y = e.y;
  convert_geometry(&x, &y);

//  PtRect rect = sp->clipboardRect();
//  ALog(@"clipboardrect %d %d %d %d, pt : %d %d",
//        rect.x, rect.y, rect.w, rect.h, x, y);
  
  if (sp->clipboardRect().contains(x, y)) {
    sp->setClipboardPasteMode(true);
    select_paste_move_event(e, false);
  } else {
    set_select_mode_paste_cancel();
  }
}

void CanvasController::select_paste_move_event(const PtPair &e, bool move) {
//  CGFloat s_scale = SingletonJunction::view.scale;
  static int x0, x1, y0, y1;
  //  NSPoint ept = getNSPointFromNSEvent(e);

  x0 = e.x;
  y0 = e.y;
  convert_geometry(&x0, &y0);

  if (!move) {
    x1 = x0;
    y1 = y0;
  }

  PPClipboard *cb = sp->getClipboard();
  PtRect rect0 = cb->rect();
  cb->setX(cb->x() + (x0 - x1));
  cb->setY(cb->y() + (y0 - y1));
  PtRect rect1 = cb->rect();

  sp->updateRect(rect0 & PtRect(0, 0, dwidth, dheight));
  sp->updateRect(rect1 & PtRect(0, 0, dwidth, dheight));

  updateRect(PtRect(0, 0, dwidth, dheight));

  x1 = x0;
  y1 = y0;

  draw_paste_rectangle();
}

void CanvasController::draw_paste_rectangle(void) {
  CGFloat s_scale = SingletonJunction::view.scale;
  PPClipboard *cb = sp->getClipboard();
  PtRect r0 = cb->rect();

//  updateRect(r0);

  int x, y, w, h;
  x = (int)((r0.x - shift_x * s_scale) * zoom);
  y = (int)((r0.y - shift_y * s_scale) * zoom);
  w = (int)((r0.w + 1) * zoom);
  h = (int)((r0.h + 1) * zoom);

  //  if (!fullscreen) y -= parent->menuHeight();
  PtRect r1(x, y, w, h);
	r1 = r1 & PtRect(0, 0, dwidth, dheight);
	PtRect r2 = r1 * (1 / s_scale);

  touchview->copy_paste_rect = PtRectToCGRect(r2);
//  [touchview setNeedsDisplayInRect:PtRectToCGRect(r2)];
  [touchview setNeedsDisplayInRect:CGRectMake(0, 0, dwidth / s_scale, dheight / s_scale)];
//  updateRect(r2);
}

void CanvasController::set_move_mode(void) {
if (layer_shift_mode)
    set_layer_shift_mode();
  else
    pen_mode = PenModeMove;
}

void CanvasController::set_shift_mode(void) {
  update_panels();

  if (zoom <= 1.0f) {
    PtPair pt(shift_x, shift_y);
    sp->shiftAllLayers(pt);
    shift_x = shift_y = 0;
    //    repaint();
    updateRect(PtRect(0, 0, dwidth, dheight));
    [ptview setNeedsDisplay];
    info_string = @"set shift mode";
  }

  //  hideInfo();
}

void CanvasController::set_layer_shift_mode(void) {
  layer_shift_mode = !layer_shift_mode;
  dropping_mouse_release = !layer_shift_mode;

  update_panels();

  if (!layer_shift_mode)
    sp->fixShiftCurrentLayer();

  //  hideInfo();
}

void CanvasController::unset_shift_mode(void) {
  update_panels();

  if (zoom <= 1.0f) {
    shift_x = shift_y = 0;
    updateRect(PtRect(0, 0, dwidth, dheight));
  }

  //  hideInfo();
}

void CanvasController::unset_layer_shift_mode(void) {
  layer_shift_mode = false;
  dropping_mouse_release = !layer_shift_mode;

  update_panels();

  sp->unshiftCurrentLayer();
  updateRect(PtRect(0, 0, dwidth, dheight));

  //  hideInfo();
}

void CanvasController::setZoom(float dz, int cx, int cy) {
  float last_zoom = zoom;
  float _zoom = max(min(zoom * dz, ZoomMax), ZoomMin);
  if (last_zoom > 1.0f && _zoom < 1.0f) _zoom = 1.0f;
  info_string = @"zoom";
  if (_zoom > 1.0f) {
    convert_geometry(&cx, &cy);
    zoom = _zoom;
    set_shift_by_center(cx, cy);
  } else {
    zoom = _zoom;
    shift_x = shift_y = 0;
  }
  [ptview setNeedsDisplay];
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
}

void CanvasController::setShift(int dx, int dy) {
  if (zoom > 1.0f) {
    info_string = @"shift";
    shift_x += dx;
    shift_y += dy;
    adjust_shift();
    [ptview setNeedsDisplay];
    updateRect(PtRect(0, 0, dwidth, dheight));
    update_panels();
  } else {
    shift_x = shift_y = 0;
    if (ptview->shift_nozoom) {
      PtPair pt(dx, dy);
      sp->shiftAllLayers(pt);
      [ptview setNeedsDisplay];
      updateRect(PtRect(0, 0, dwidth, dheight));
      update_panels();
    }
  }
}

void CanvasController::undoOneStep(void) {
  PtPair step = sp->undo();
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  touchview->btn_info_string = 
    [[NSString alloc] initWithFormat:@"undo %d/%d", step.x, step.y];
  [ptview setNeedsDisplay];
  [touchview setNeedsDisplay];
  clear_btn_info_string();
}

void CanvasController::redoOneStep(void) {
  PtPair step = sp->redo();
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  touchview->btn_info_string = 
    [[NSString alloc] initWithFormat:@"redo %d/%d", step.x, step.y];
  [ptview setNeedsDisplay];
  [touchview setNeedsDisplay];
  clear_btn_info_string();
}

void CanvasController::show_tools(bool show) {
  if (show && panel_position != HideTools) {
    CGFloat s_scale = SingletonJunction::view.scale;
    tools_rect.w = dwidth / s_scale;
    panelview.hidden = false;
    optpanelview.hidden = false;
  } else {
    tools_rect.w = 0;
    panelview.hidden = true;
    optpanelview.hidden = true;
  }
}

void CanvasController::show_hide_tools(int direction) {
  //  hideInfo();

  if (direction == NumOfToolsPosition) {
    panel_position = (panel_position + 1) % NumOfToolsPosition;
    if (!panel_position) panel_position = 1;
  } else {
    if (panel_position != direction)
      panel_position = direction;
    else
      panel_position = HideTools;
  }
    
  sp->setShowingTools(panel_position);

  info_string = [panelview->info_string copy];
  [info_string autorelease];
  updateRect(PtRect(0, 0, dwidth, dheight));
  update_info_rect();
  [ptview setNeedsDisplay];
}

void CanvasController::show_hide_layers(bool s) {
  if (s && opt_panel_type != Layers) 
    show_hide_layers();
  if (!s && opt_panel_type == Layers)
    show_hide_layers();
}

void CanvasController::show_hide_layers(void) {
  if (opt_panel_type == Layers) {
    opt_panel_type = None;
    layers.setShow(false);
  } else {
    opt_panel_type = Layers;
    layers.setShow(true);
  }

  update_info_rect();
  [ptview setNeedsDisplay];
}

#if 0
void CanvasController::hideInfo(void) {
  if (panel_position) return;
  
  if (info_rect.w) {
    info_rect = sp->hideInfo();
    update_info_rect();

    info_rect.w = 0;
  }
}
#endif

void CanvasController::loadToCurrentLayer(UIImage *img) {
  sp->loadToCurrentLayer(img);

  shift_x = shift_y = 0;
  zoom = 1.0f;

  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  [ptview setNeedsDisplay];

  img_modified = true;
}

#if 0
void CanvasController::load(const QString &fn) {
  sp->load(fn);

  zoom = shift_x = shift_y = 0;
  img_modified = true;
}

void CanvasController::loadLayer(const QString &fn) {
  sp->loadLayer(fn);

  zoom = shift_x = shift_y = 0;
  img_modified = true;
}

void CanvasController::save(const QString &fn, const char* ft,
                  bool warn) {
  QString fn2(fn);
  QFileInfo info(fn);

  info.setFile(fn2);

  if (warn && LayeredPainter::fileExists(fn2))
    if (QMessageBox::warning(this, "PetitePeinture",
                             "File " + info.fileName() + " exists.\n" +
                             "Want to overwrite it?\n\n",
                             "Save", "Cancel"))
      return;

  if (!sp->save(fn2, ft))
    QMessageBox::warning(this, "PetitePeinture",
                         "FAILED to save the file " +
                         info.fileName() + "!\n",
                         "OK");
}

void CanvasController::saveIcon(const QString &fn) {
  PtptFormat ptpt(1);

  QImage img;
  sp->getQImage(&img, -1);
  ptpt.setThumbnail(img);
  ptpt.saveThumbnail(fn);
}

void CanvasController::saveLayer(const QString &fn) {
  QString fn2(fn);
  QFileInfo info(fn);

  if (info.extension().isEmpty())
    fn2 += ".png";

  info.setFile(fn2);

  if (LayeredPainter::fileExists(fn2))
    if (QMessageBox::warning(this, "PetitePeinture",
                             "File " + info.fileName() + " exists.\n" +
                             "Want to overwrite?\n\n",
                             "Save", "Cancel"))
      return;

  if (!sp->saveLayer(fn2))
    QMessageBox::warning(this, "PetitePeinture",
                         "FAILED to save the file " +
                         info.fileName() + "!\n",
                         "OK");
}
#endif

void CanvasController::exportToPhotosAlbum(void) {
  UIImageWriteToSavedPhotosAlbum(sp->getUIImage(), nil, nil, nil);
}

void CanvasController::exportCurrentLayerToPhotosAlbum(void) {
  UIImageWriteToSavedPhotosAlbum(sp->getUIImageOfCurrentLayer(),
                                 nil, nil, nil);
}

void CanvasController::clearImage(bool modify) {
  setSize(0, 0);
  sp->clear();

  //  if (parent->noviceMode()) {
  if (0) {
    sp->createLayer();
    sp->setCompositionMethod(1, MulComposition);
  }

  while (sp->numOfLayers() < 3)
    sp->createLayer();

  sp->setLayer(0);

  [NSUserDefaults resetStandardUserDefaults];

  zoom = 1.0f;
  shift_x = shift_y = 0;
  [touchview set_base_trans];

  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  [ptview setNeedsDisplay];

  img_modified = modify;
}

void CanvasController::clearCurrentLayer(void) {
#if 0
  if (QMessageBox::warning(this, "PetitePeinture",
                           "Discard current layer?\n\n",
                           "Clear Layer", "Cancel"))
    return;
  
  sp->fill(sp->paperColor(), false);
  img_modified = true;
  repaint();
#endif

  sp->fill(sp->paperColor(), false);
  sp->backupCurrentLayer();

  updateRect(PtRect(0, 0, dwidth, dheight));
  update_panels();
  [ptview setNeedsDisplay];
}

void CanvasController::quit_application(void) {
#if 0
  bool last_fullscreen;

  last_fullscreen = fullscreen;
  fullscreen = FALSE;
  
  if (!QMessageBox::warning(this, "PetitePeinture",
                           "Quit this application?\n\n",
                            "Quit", "Cancel")) {
    parent->quit_application();
  }

  fullscreen = last_fullscreen;
#endif
}

void CanvasController::tapping(void) {
  if (pressing_tool != ToolPanel::PaletteI)
    [ptview pressingInBtn:pressing_tool];
}

void CanvasController::mirrorHorizontal(void) {
  sp->mirrorHorizontal();

  sp->backupCurrentLayer();
  img_modified = true;
}

void CanvasController::mirrorVertical(void) {
  sp->mirrorVertical();
  
  sp->backupCurrentLayer();
  img_modified = true;
}

void CanvasController::rotateCW(void) {
  sp->rotateCW();

  sp->backupCurrentLayer();
  img_modified = true;
}

void CanvasController::rotateCCW(void) {
  sp->rotateCCW();

  sp->backupCurrentLayer();
  img_modified = true;
}

void CanvasController::scaleLayer(uint sx, uint sy) {
  sp->scaleCurrentLayer(sx, sy);

  img_modified = true;
}

uint CanvasController::canvasWidth(void) {
  if (sp)
    return sp->get_width();
  else
    return 0;
}

uint CanvasController::canvasHeight(void) {
  if (sp)
    return sp->get_height();
  else
    return 0;
}

void CanvasController::setSize(int w, int h) {
  int _w, _h;

  _w = w & -16;
  _h = h & -16;
  _w = max(_w, dwidth);
  _h = max(_h, dheight);

  sp->setSize(_w, _h);

  shift_x = shift_y = 0;
}

void CanvasController::getPenProperties(void) {
  switch (sp->getPenMethod()) {
  case SolidBrush:
  case EraserBrush:
    set_pencil();
    break;
  case WaterBrush:
    set_brush();
    break;
  case CloudWideBrush:
    set_cloud();
    break;
  }

  PtPen sp_pen = sp->getPen();
  pen->setWidth(sp_pen.width());
  pen->setColor(sp_pen.color());

  set_pen_density(sp->getPenDensity());

  sp->setPen(*pen);
}

void CanvasController::layerChanged(int) {
  if (separate_pen)
    getPenProperties();
}
