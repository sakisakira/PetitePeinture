//  ptttouchview.mm
//  CocoaPeinture
//  by SAkira <sakira@sun.dhis.portside.net>
//  from 2008 Aug 11

#import "pttouchview.h"
#import "canvascontroller.h"
#import "constants.h"
#import "ptpair.h"
#import "layerdlgcontroller.h"
#import "filelistcontroller.h"
#import "toolpanel.h"
#import "singletonjunction.h"
#import "touchpeintureViewController.h"
#import "touchpeintureAppDelegate.h"

@implementation PtTouchView

@synthesize target;
@synthesize action;
@synthesize pendlg;
@synthesize filesheet;
@synthesize img_picker;

NSString *tblId = @"PtPtTable";

- (id)initWithFrame:(CGRect)frameRect {
  if (!(self = [super initWithFrame:frameRect])) return nil;

  btn_info_string = NULL;

  SingletonJunction::touchview = self;

  return self;
}

- (void)setup:(UIView*)view withCanvas:(CanvasController*)c {
  self.opaque = NO;

  CGSize s = [self bounds].size;
  _size = new PtPair(((int)s.width) & ~1, (int)s.height);
  
  ALog(@"pttouchview size %d %d", _size->x, _size->y);

  copy_paste_rect.size.width = 0;

  ptview = view;
  canvas = c;
	
  [self set_base_trans];
  
  animation_duration = 0.05;
  self.multipleTouchEnabled = YES;

  savesheet  = [[UIActionSheet alloc]
                 initWithTitle:@"save and export image"
                 delegate:self
                 cancelButtonTitle:@"cancel" 
                 destructiveButtonTitle:nil
                 otherButtonTitles:@"image to Photos Album",
                 @"current layer to Album",
#ifndef TouchPeintureLite
                @"save all layers",
#else
                @"backup current status",
#endif
                 nil];

  loadsheet  = [[UIActionSheet alloc]
                 initWithTitle:@"load image"
                 delegate:self
                 cancelButtonTitle:@"cancel" 
                 destructiveButtonTitle:nil
                 otherButtonTitles:@"photo album to layer",
		 @"load all layers",
                 nil];
}

- (void)setupTables {
  CGFloat sw, sh, w_margin, h_margin;
  sw = [[UIScreen mainScreen] applicationFrame].size.width;
  sh = [[UIScreen mainScreen] applicationFrame].size.height;
  w_margin = 25;
  h_margin = 100;

  pendlg = [[UITableView alloc]
             initWithFrame:CGRectMake(w_margin, h_margin, 
                                      sw - w_margin * 2, 
				      sh - h_margin * 2)
             style:UITableViewStylePlain];
  pendlg.delegate = self;
  pendlg.dataSource = self;
  pendlg.backgroundColor = [UIColor lightGrayColor];
  pendlg.hidden = true;
  [self addSubview:pendlg];

  CGRect w_rect, d_rect, c_rect;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    w_rect = CGRectMake(0, 0, 160, 30);
    d_rect = CGRectMake(0, 0, 120, 30);
    c_rect = CGRectMake(0, 0, 120, 30);
  } else {
    w_rect = CGRectMake(0, 0, 300, 30);
    d_rect = CGRectMake(0, 0, 300, 30);
    c_rect = CGRectMake(0, 0, 300, 30);    
  }
  pen_width_slider = [[UISlider alloc] 
                      initWithFrame:w_rect];
  pen_width_slider.minimumValue = 0.0;
  pen_width_slider.maximumValue = 1.0;
  [pen_width_slider addTarget:self 
		    action:@selector(pen_width_changed:)
		    forControlEvents:UIControlEventValueChanged];
  pen_density_slider = [[UISlider alloc]
                        initWithFrame:d_rect];
  pen_density_slider.minimumValue = 0;
  pen_density_slider.maximumValue = 256;
  [pen_density_slider addTarget:self 
		    action:@selector(pen_density_changed:)
		    forControlEvents:UIControlEventValueChanged];
  cloud_density_slider = [[UISlider alloc]
                          initWithFrame:c_rect];
  cloud_density_slider.minimumValue = 0;
  cloud_density_slider.maximumValue = 255;
  [cloud_density_slider addTarget:self 
		    action:@selector(cloud_density_changed:)
		    forControlEvents:UIControlEventValueChanged];
  pen_antialias_switch = [[UISwitch alloc] init];
  [pen_antialias_switch addTarget:self
			action:@selector(pen_antialias_changed:)
			forControlEvents:UIControlEventValueChanged];
  cloud_method_btns = [[UISegmentedControl alloc] 
			initWithItems:[NSArray arrayWithObjects:
						 @"weak", @"mid", @"wide", nil]];
  [cloud_method_btns addTarget:self
		     action:@selector(cloud_method_changed:)
		     forControlEvents:UIControlEventValueChanged];

  ALog(@"layerview start");
  layerview = [[UIView alloc] initWithFrame:self.frame];
  layerview.alpha = 0.8;
  layerview.hidden = true;
  layerdlgc = [[LayerDlgController alloc]
		initWithStyle:UITableViewStylePlain];
  layernav = [[UINavigationController alloc]
	       initWithRootViewController:layerdlgc];
  layernav.delegate = layerdlgc;
  [layerview addSubview:layernav.view];
  UITableView *layerdlg = layerdlgc.tableView;
  layerdlg.backgroundColor = [UIColor lightGrayColor];
  [layerview addSubview:layerdlg];
  [layerdlgc setParent:layerview withCanvas:canvas
	     withNavigation:layernav
             withRootView:layerdlgc.tableView];
  [layerdlgc setLayerIndex:-1];
  [self addSubview:layerview];

  filelistc = [[FileListController alloc]
                initWithStyle:UITableViewStylePlain];
  [filelistc setCanvas:canvas];
  filelistc.tableView.delegate = filelistc;
  filelistc.tableView.hidden = true;
  [self addSubview:filelistc.view];

  self.img_picker = [[[UIImagePickerController alloc] init] autorelease];
  self.img_picker.delegate = self;
	self.img_picker.view.userInteractionEnabled = YES;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    Class popoverctrl = NSClassFromString(@"UIPopoverController");
    if (popoverctrl)
      _img_picker_popover = [[popoverctrl alloc]
												 initWithContentViewController:self.img_picker];
	} else {
		_img_picker_popover = nil;
//		[self addSubview:self.img_picker.view];
//		self.img_picker.view.hidden = YES;
	}
}

- (void)dealloc {
  if (btn_info_string) [btn_info_string release];

  if (pendlg) [pendlg release];
  if (layernav) [layernav release];
  if (layerdlgc) [layerdlgc release];
  if (layerview) [layerview release];
  if (filelistc) [filelistc release];
  if (savesheet) [savesheet release];
	self.img_picker = nil;
  if (_img_picker_popover) [_img_picker_popover release];
  if (loadsheet) [loadsheet release];
  [super dealloc];
}

- (void)clear_btn_info_string:(NSTimer*)timer {
  btn_info_string = NULL;
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
  [[UIColor clearColor] set];
  UIRectFill(rect);

  if (btn_info_string) {
    CGRect rect = [self bounds];
    rect.origin.y = rect.size.height / 2;
    UIFont *tfont = [UIFont boldSystemFontOfSize:50];

    [[UIColor whiteColor] set];
    [btn_info_string drawInRect:rect
		     withFont:tfont
		     lineBreakMode:UILineBreakModeMiddleTruncation
		     alignment:UITextAlignmentCenter];

    rect.origin.x += 2;
    rect.origin.y += 2;
    [[UIColor blackColor] set];
    [btn_info_string drawInRect:rect
		     withFont:tfont
		     lineBreakMode:UILineBreakModeMiddleTruncation
		     alignment:UITextAlignmentCenter];
  }

	
  if (!CGRectIsEmpty(copy_paste_rect)) {
    [[UIColor blackColor] set];
    UIRectFrame(copy_paste_rect);
  }
}

- (void)applicationWillTerminate:(UIApplication*)application {
  canvas->saveDefaults();
}

- (void)set_diff_scale:(NSSet*)touches {
  // assuming [touches count] == 2

  //  [self updateEPt:touches];

  float sdist, edist;
  diffx = (((double)_ept0.x + _ept1.x) - ((double)_spt0.x + _spt1.x)) / 2;
  diffy = (((double)_ept0.y + _ept1.y) - ((double)_spt0.y + _spt1.y)) / 2;
  sdist = sqrt((_spt0.x - _spt1.x) * (_spt0.x - _spt1.x) +
               (_spt0.y - _spt1.y) * (_spt0.y - _spt1.y));
  edist = sqrt((_ept0.x - _ept1.x) * (_ept0.x - _ept1.x) +
               (_ept0.y - _ept1.y) * (_ept0.y - _ept1.y));
  //  ALog(@"diffx %f diffy %f sdist %f edist %f", diffx, diffy, sdist, edist);
  if (sdist == 0.0)
    scale = 1.0;
  else
    scale = edist / sdist;
  
  //  if (sdist*sdist <= diffx*diffx + diffy*diffy)
  //    scale = 1.0;

  if (scale > 16) scale = 16.0;
  if (scale < 1.0/8) scale = 1.0/8;
}

- (void)set_base_trans {
  CGAffineTransform trans;
  float z = canvas->zoom;
  float s_x = canvas->shift_x;
  float s_y = canvas->shift_y;
  float cx = _size->x / 2;
  float cy = _size->y / 2;

  trans = CGAffineTransformMakeTranslation(- cx, - cy);
  trans = CGAffineTransformScale(trans, z, z);
  trans = CGAffineTransformTranslate(trans, - s_x, - s_y);
  trans = CGAffineTransformTranslate(trans, cx, cy);

  base_trans = trans;
  [UIView beginAnimations:@"PtPtMainView" context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:0.1];
  ptview.transform = base_trans;
  [UIView commitAnimations];
}

- (void)transformWith:(NSSet*)touches {
  [self set_diff_scale:touches];
  CGAffineTransform trans;

  float zoom = canvas->zoom;
  float s_x = canvas->shift_x - diffx / zoom;
  float s_y = canvas->shift_y - diffy / zoom;
  float z = zoom * scale;
  float cx = _size->x / 2;
  float cy = _size->y / 2;

  trans = CGAffineTransformMakeTranslation(- cx * scale, - cy * scale);
  trans = CGAffineTransformScale(trans, z, z);
  trans = CGAffineTransformTranslate(trans, - s_x, - s_y);
  trans = CGAffineTransformTranslate(trans, cx, cy);
  
  [UIView beginAnimations:@"PtPtMainView" context:NULL];
  [UIView setAnimationBeginsFromCurrentState:YES];
  [UIView setAnimationDuration:animation_duration];
  ptview.transform = trans;
  [UIView commitAnimations];
}

- (void)changePenWidth:(NSSet*)touches {
  [self set_diff_scale:touches];
  canvas->set_pen_width(round(_sPenWidth * scale));
}

- (void)touchesBegan:(NSSet*)touches withEvent:event {
  UITouch *t;
  CGPoint pt;
	CGFloat s_scale = SingletonJunction::view.scale;

  if (!pendlg.hidden || !layerview.hidden) return;
  
  _prev_moved = _moved;
  _moved = false;

  for (t in touches)
    if (t) {
      if (!_st0 && !_st1 && !_st2) {
	_st0 = t;
	_spt0 = [t locationInView:self];
      } else if (!_st1 && !_st2 && t != _st0) {
	_st1 = t;
	_spt1 = [t locationInView:self];
	_sPenWidth = canvas->get_pen_width();
        canvas->mousePressEventCancelled();
	_timer = @"canceled";
      } else if (!_st2 && t != _st0 && t != _st1) {
	_st2 = t;
	_spt2 = [t locationInView:self];
	[self transformCancel];
      }
    }

  if (_st0 && !_st1) {
    t = [touches anyObject];
    pt = [t locationInView:self];
    if ([t tapCount] == 2 &&
	[self isDoubleTap:t]) {  // double tap
      canvas->mousePressEventCancelled();
      if (canvas->tools_rect.contains(pt.x, pt.y)) {
	int px, py;
	px = pt.x - canvas->tools_rect.x;
	py = pt.y - canvas->tools_rect.y;
	[self doubleTappedInBtn:canvas->getToolBtnIndex(px, 
																									py)];
      }
    } else {
      canvas->mousePressEvent(PtPair(pt.x * s_scale, pt.y * s_scale));
      _timer = canvas->_timer;
    }
  }
}

- (void)touchesMoved:(NSSet*)touches withEvent:event {
  UITouch *t;
  CGPoint pt;
	CGFloat s_scale = SingletonJunction::view.scale;
	
  _moved = true;
  [self updateEPt:touches];
  
  if (_st0 && !_st1 && !_st2) {
    t = [touches anyObject];
    pt = [t locationInView:self];
    canvas->mouseMoveEvent(PtPair(pt.x * s_scale, 
																	pt.y * s_scale));
  } else if (_st0 && _st1 && !_st2) {
    if (canvas->tools_rect.contains(_spt0.x, _spt0.y)) {
      [self changePenWidth:touches];
    } else {
      [self transformWith:touches];
    }
  }
}

- (void)touchesEnded:(NSSet*)touches withEvent:event {
  [self transformCancel];
	CGFloat s_scale = SingletonJunction::view.scale;

  if (_st0 && !_st1 && !_st2) {
    UITouch* t = [touches anyObject];
    CGPoint pt = [t locationInView:self];
    canvas->mouseReleaseEvent(PtPair(pt.x * s_scale, pt.y * s_scale));
    _st0 = NULL;
  } else if (_st0 && _st1 && !_st2 &&
	     ([touches containsObject:_st0] || 
	      [touches containsObject:_st1])) {
    if (!canvas->tools_rect.contains(_spt0.x, _spt0.y)) {
      [self set_diff_scale:[event touchesForView:self]];
      CGFloat zoom = canvas->zoom;
      canvas->shift_x -= diffx / zoom - (scale - 1) / (scale * zoom) * _size->x/2;
      canvas->shift_y -= diffy / zoom - (scale - 1) / (scale * zoom) * _size->y/2;
      canvas->zoom = zoom * scale;
      if ((zoom - 1.0f) * (canvas->zoom - 1.0f) < 0.0f) {
	canvas->zoom = 1.0f;
	canvas->shift_x = 0;
	canvas->shift_y = 0;
      }
      canvas->adjust_shift();
      [self set_base_trans];
    }
    _st0 = NULL;
  } else if (_st0 && _st1 && _st2 &&
	     ([touches containsObject:_st0] || 
	      [touches containsObject:_st1] ||
	      [touches containsObject:_st2])) {
    [self set_diff_scale:[event touchesForView:self]];
    [self checkSwipeHorizontal];
    [self checkSwipeVertical];
    _st0 = NULL;
  }

  if ([touches count] == [[event touchesForView:self] count]) {
    _st0 = _st1 = _st2 = NULL;
  }
}  

- (void)checkSwipeHorizontal {
  CGFloat dx, dy;

  dy = abs(_spt0.y - _ept0.y);
  dy = max(dy, (float)abs(_spt1.y - _ept1.y));
  dy = max(dy, (float)abs(_spt2.y - _ept2.y));
  if (dy < _size->y / 4) {
    dx = _spt0.x - _ept0.x;
    dx += _spt1.x - _ept1.x;
    dx += _spt2.x - _ept2.x;
    if (dx > _size->x * 3 / 4)
      canvas->undoOneStep();
    else if (dx < - _size->x * 3 / 4)
      canvas->redoOneStep();
  }
}

- (void)checkSwipeVertical {
 CGFloat dx, dy;
  dx = abs(_spt0.x - _ept0.x);
  dx = max(dx, (float)abs(_spt1.x - _ept1.x));
  dx = max(dx, (float)abs(_spt2.x - _ept2.x));
  if (dx < _size->x / 4) {
    dy  = _spt0.y - _ept0.y;
    dy += _spt1.y - _ept1.y;
    dy += _spt2.y - _ept2.y;
    if (dy > _size->y * 3 / 4)
      canvas->show_hide_tools(CanvasController::TopTools);
    else if (dy < - _size->y * 3 / 4)
      canvas->show_hide_tools(CanvasController::BottomTools);
  }
}

- (void)transformCancel {
  ptview.transform = base_trans;
}

- (void)touchesCancelled:(NSSet*)touches withEvent:event {
  [self transformCancel];
  canvas->mousePressEventCancelled();
  _st0 = _st1 = _st2 = NULL;
}

- (void)actionSheet:(UIActionSheet*)sheet 
        clickedButtonAtIndex:(NSInteger)index {
  if (sheet == filesheet) {
    switch (index) {
    case 0: // new image
      newimg_dlg = [[[UIAlertView alloc] initWithTitle:@"new image"
				     message:@"clear this image?"
				     delegate:self
				     cancelButtonTitle:@"cancel"
				     otherButtonTitles:@"OK", nil] 
		 autorelease];
      [newimg_dlg show];
      break;
    case 1: // save
      [savesheet showInView:self];
      break;
    case 2: // load
#ifndef TouchPeintureLite
      [loadsheet showInView:self];
#else
      [self loadImage];
#endif
      break;
    case 3: // delete current layer
      clearlayer_dlg = [[[UIAlertView alloc] initWithTitle:@"clear layer"
				     message:@"clear current layer?"
				     delegate:self
				     cancelButtonTitle:@"cancel"
				     otherButtonTitles:@"OK", nil] 
		 autorelease];
      [clearlayer_dlg show];
      break;
    case 4: // cancel
      break;
    }
  } else if (sheet == savesheet) {
    switch (index) {
    case 0: // export image to photos album
      canvas->exportToPhotosAlbum();
      break;
    case 1: // export current layer to photos album
      canvas->exportCurrentLayerToPhotosAlbum();
      break;
    case 2:  // save all layers or backup current status (trial)
#ifndef TouchPeintureLite
//      canvas->saveImage();
        canvas->savePtpt();
#else
      canvas->saveDefaults();
#endif
      break;
    case 3: // cancel
      break;
    }
  } else if (sheet == loadsheet) {
    switch (index) {
    case 0: // photo album to layer
      [self loadImage];
      break;
    case 1: // load all layer
      [filelistc loadFileList];
      [filelistc.tableView reloadData];
      filelistc.view.hidden = false;
      break;
    case 2: // cancel
      break;
    }
  }
}

- (void)alertView:(UIAlertView*)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView == newimg_dlg) {
    if (buttonIndex == 1)
      canvas->clearImage();
  } else if (alertView == clearlayer_dlg) {
    if (buttonIndex == 1)
      canvas->clearCurrentLayer();
  }
}

- (void)updateEPt:(NSSet*)touches {
  for (UITouch *t in touches) {
    if (!t) {
    } else if (t == _st0) {
      _ept0 = [t locationInView:self];
    } else if (t == _st1) {
      _ept1 = [t locationInView:self];
    } else if (t == _st2) {
      _ept2  = [t locationInView:self];
    }
  }
}

- (bool)isDoubleTap:(UITouch*)touch {
  static const uint diffmax = 5;
  CGPoint pt1 = [touch locationInView:self];
  CGPoint pt0 = [touch previousLocationInView:self];

  return ((abs(pt0.x - pt1.x) <= diffmax) &&
	  (abs(pt0.y - pt1.y) <= diffmax) &&
          !_prev_moved && !_moved);
}

- (void)doubleTappedInBtn:(int)btn {
  if (_st1 || _timer != canvas->_timer) return;
  //  if (_st1) return;

  switch (btn) {
  case ToolPanel::PencilI:
  case ToolPanel::BrushI:
  case ToolPanel::EraserI:
  case ToolPanel::CloudI:
    canvas->mousePressEventCancelled();
    _st0 = NULL;
    if (pendlg.hidden) {
      pendlg.hidden = false;
      [pendlg reloadData];
    }
    break;
  case ToolPanel::LayerI:
    canvas->mousePressEventCancelled();
    _st0 = NULL;
    [self showLayerDialog];
    break;
  case ToolPanel::PaletteI:
  case ToolPanel::PenInfoI:
  case ToolPanel::SelectI:
    canvas->mousePressEventCancelled();
    _st0 = NULL;
    canvas->show_hide_color_panel();
    canvas->mouseReleaseEvent(PtPair());
    //    [self showFileAlert];
    break;
  }
}

- (void)showFileAlert {
  filesheet = [[UIActionSheet alloc]
		initWithTitle:@"File Management"
		delegate:self
		cancelButtonTitle:@"cancel"
		destructiveButtonTitle:nil
		otherButtonTitles:@"New Image",
                @"Save", 
		@"Load",
		@"Delete Current Layer", nil];
  [filesheet showInView:self];
  [filesheet release];
}

- (void)showToolAlert {
  NSString *ver_str = [[[NSBundle mainBundle] infoDictionary]
                       objectForKey:@"CFBundleShortVersionString"];
  NSString *build_str = [[[NSBundle mainBundle] infoDictionary]
                         objectForKey:@"CFBundleVersion"];
  UIAlertView *about_dlg;
  about_dlg = [[[UIAlertView alloc]
#ifndef TouchPeintureLite
                 initWithTitle:@"petite peinture"
#else
                 initWithTitle:@"petite peinture lite"
#endif
                 message:[NSString stringWithFormat:
                          @"version %@\nbuild %@\n\nhttp://sun.dhis.portside.net/\niphone_ptpt.html\n\ntwitter: sakira", ver_str, build_str]
                 delegate:nil
                 cancelButtonTitle:nil
                 otherButtonTitles:@"OK", nil]
                autorelease];
  [about_dlg show];
}

- (void)showLayerDialog {
	[layerdlgc setParent:layerview 
		   withCanvas:canvas
		   withNavigation:layernav
                   withRootView:layerdlgc.tableView];
        [layerdlgc setLayerIndex:-1];
	[layerdlgc.tableView reloadData];
        canvas->updateRect(PtRect(0, 0, _size->x, _size->y));
	layerview.hidden = false;
}

- (UITableViewCell*)tableView:(UITableView*)tblView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  static id tblidstring = @"PtPtPenString";
  static id tblidslider_w = @"PtPtPenSliderWidth";
  static id tblidslider_d = @"PtPtPenSliderDensity";
  static id tblidslider_b = @"PtPtPenSliderBrightness";
  static id tblidswitch = @"PtPtPenSwitch";
  static id tblidbtns = @"PtPtPenButtons";
  static id tbliddone = @"PtPtPenDone";

  UITableViewCell *cell = nil;
  if (tblView == pendlg) {
    switch (indexPath.row) {
    case 0:
      cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidstring];
      if (!cell)
				//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidstring] autorelease];
      if (canvas->pen == &(canvas->pencil))
	cell.textLabel.text = @"pencil";
      else if (canvas->pen == &(canvas->brush))
	cell.textLabel.text = @"brush";
      else if (canvas->pen == &(canvas->eraser))
	cell.textLabel.text = @"eraser";
      else if (canvas->pen == &(canvas->cloud))
	cell.textLabel.text = @"cloud";
      break;
    case 1:
      cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidstring];
      if (!cell)
	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidstring] autorelease];
      cell.textLabel.text = @"";
      break;
    case 2:
      cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidslider_w];
      if (!cell)
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidslider_w] autorelease];
      cell.textLabel.text = @"width";
      pen_width_slider.value = [self unconv_width:canvas->get_pen_width()];
      cell.accessoryView = pen_width_slider;
      break;
    case 3:
      if (canvas->pen == &(canvas->pencil) ||
	  canvas->pen == &(canvas->eraser)) {
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidswitch];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
			   reuseIdentifier:tblidswitch] autorelease];
	cell.textLabel.text = @"antialias";
	pen_antialias_switch.on = canvas->pen->antialias;
	cell.accessoryView = pen_antialias_switch;
      } else if (canvas->pen == &(canvas->brush)) {
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidslider_d];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidslider_d] autorelease];
	cell.textLabel.text = @"density";
	pen_density_slider.value = canvas->get_pen_density();
	cell.accessoryView = pen_density_slider;
      } else if (canvas->pen == &(canvas->cloud)) {
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidslider_b];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidslider_b] autorelease];
	cell.textLabel.text = @"brightness";
	cloud_density_slider.value = canvas->get_cloud_density();
	cell.accessoryView = cloud_density_slider;
      }
      break;
    case 4:
      if (canvas->pen == &(canvas->cloud)) {
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidbtns];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidbtns] autorelease];
        cell.textLabel.text = @"";
	cloud_method_btns.selectedSegmentIndex = 
	  canvas->get_pen_method() - CloudWeakBrush;
	cell.accessoryView = cloud_method_btns;
      } else {
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tblidstring];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tblidstring] autorelease];
        cell.textLabel.text = @"";
        cell.accessoryView = nil;
      }
      break;
    case 5:
	cell = [self.pendlg dequeueReusableCellWithIdentifier:tbliddone];
	if (!cell)
	  cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:tbliddone] autorelease];
      cell.textLabel.text = @"done";
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
  }
  return cell;
}

- (NSInteger)tableView:(UITableView*)tblView 
 numberOfRowsInSection:(NSInteger)section {
  if (tblView == pendlg) {
    return 6;
  }

  return 0;
}

- (void)tableView:(UITableView*)tblView 
didSelectRowAtIndexPath:(NSIndexPath*)indexPath {
  if (tblView == pendlg) {
    if (indexPath.row == 5) {
      pendlg.hidden = true;
    }
  }
}

- (float)conv_width:(float)w {
  return (SingletonJunction::penWidthMax - 1) * w * w + 1;
}

- (float)unconv_width:(float)w {
  return sqrt((w - 1) / (SingletonJunction::penWidthMax - 1));
}

- (void)pen_width_changed:(id)sender {
  canvas->set_pen_width(ceil([self conv_width:pen_width_slider.value]));
}

- (void)pen_density_changed:(id)sender {
  canvas->set_pen_density((int)pen_density_slider.value);
}

- (void)cloud_density_changed:(id)sender {
  canvas->set_cloud_density((int)cloud_density_slider.value);
}

- (void)pen_antialias_changed:(id)sender {
  canvas->set_antialias(pen_antialias_switch.on);
}

- (void)cloud_method_changed:(id)sender {
  canvas->set_pen_method(CloudWeakBrush + 
			 cloud_method_btns.selectedSegmentIndex);
}

- (void)loadImage {
	if (_img_picker_popover) {
		[_img_picker_popover 
		 presentPopoverFromRect:CGRectMake(0, 0, 1, 1)
		 inView:self
		 permittedArrowDirections:UIPopoverArrowDirectionAny
		 animated:YES];
	} else {
//		self.img_picker.view.hidden = NO;
		touchpeintureAppDelegate *appd = [UIApplication sharedApplication].delegate;
		touchpeintureViewController *vc = appd.viewController;
		[vc presentModalViewController:img_picker
													animated:YES];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker 
	didFinishPickingImage:(UIImage *)image 
		  editingInfo:(NSDictionary *)editingInfo {
  if (picker == self.img_picker) {
		if (_img_picker_popover) {
			[_img_picker_popover dismissPopoverAnimated:YES];
		} else {
//			self.img_picker.view.hidden = YES;
			[img_picker dismissModalViewControllerAnimated:YES];
		}
    canvas->loadToCurrentLayer(image);
  }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  if (picker == self.img_picker) {
		if (_img_picker_popover) {
			[_img_picker_popover dismissPopoverAnimated:YES];
		} else {
//			self.img_picker.view.hidden = YES;
			[img_picker dismissModalViewControllerAnimated:YES];
		}
  }	
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {}

- (void)showMessage:(NSString*)msg {
  UIAlertView *dlg;
  dlg = [[[UIAlertView alloc]
	   initWithTitle:@"petite peinture"
	   message:msg
	   delegate:nil
	   cancelButtonTitle:nil
	   otherButtonTitles:@"OK", nil]
	  autorelease];
  [dlg show];
}

@end

