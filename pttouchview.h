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

class CanvasController;
@class LayerDlgController;
@class FileListController;

extern NSString *tblId;

@interface PtTouchView : UIView
<UIActionSheetDelegate, UIAlertViewDelegate,
   UITableViewDataSource, UITableViewDelegate,
   UINavigationControllerDelegate,
   UIImagePickerControllerDelegate> {
@public
  PtPair* _size;
  CanvasController *canvas;

  NSString *btn_info_string;
  CGRect copy_paste_rect;

  CGPoint _spt0, _spt1, _spt2;
  CGPoint _ept0, _ept1, _ept2;
  UITouch *_st0, *_st1, *_st2;
  bool _moved, _prev_moved;
  uint _sPenWidth;

  id _timer;

  NSTimeInterval animation_duration;
  float diffx, diffy, scale;
  CGAffineTransform base_trans;

  UIView *ptview;

  UITableView *pendlg;
  UISlider *pen_width_slider, *pen_density_slider,
    *cloud_density_slider;
  UISwitch *pen_antialias_switch;
  UISegmentedControl *cloud_method_btns;

  UIView *layerview;
  LayerDlgController *layerdlgc;
  UINavigationController *layernav;

  FileListController *filelistc;

  UIAlertView *newimg_dlg, *clearlayer_dlg;
  UIActionSheet *filesheet, *savesheet, *loadsheet;

  UIImagePickerController *img_picker;
  UIPopoverController *_img_picker_popover;

  id target;
  SEL action;
}

@property(assign, readwrite) id target;
@property(nonatomic, retain) UITableView *pendlg;
@property SEL action;
@property(retain) UIActionSheet *filesheet;
@property(nonatomic, retain) UIImagePickerController *img_picker;

- (void)setup:(UIView*)view withCanvas:(CanvasController*)canvas;
- (void)setupTables;
- (void)applicationWillTerminate:(UIApplication*)application;
- (void)clear_btn_info_string:(NSTimer*)timer;

- (void)set_diff_scale:(NSSet*)touches;
- (void)set_base_trans;
- (void)transformWith:(NSSet*)touches;
- (void)changePenWidth:(NSSet*)touches;
- (void)transformCancel;
- (void)checkSwipeHorizontal;
- (void)checkSwipeVertical;
- (void)updateEPt:(NSSet*)touches;
- (bool)isDoubleTap:(UITouch*)touch;
- (void)doubleTappedInBtn:(int)btn;
- (void)showLayerDialog;
- (void)showFileAlert;
- (void)showToolAlert;

- (float)conv_width:(float)w;
- (float)unconv_width:(float)w;

- (void)pen_width_changed:(id)s;
- (void)pen_density_changed:(id)s;
- (void)cloud_density_changed:(id)s;
- (void)pen_antialias_changed:(id)s;
- (void)cloud_method_changed:(id)s;

- (void)loadImage;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (void)showMessage:(NSString*)msg;

@end
