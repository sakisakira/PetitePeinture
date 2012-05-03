#import "constants.h"

class CanvasController;
class LayeredPainter;
class PtRect;

@interface LayerDlgController : UITableViewController 
<UINavigationControllerDelegate> {
@public

  UIView *parent;
  UITableView *rootView;
  UINavigationController *layernav;
  PtRect *fullrect;

  CanvasController *canvas;
  LayeredPainter *painter;

  UIBarButtonItem *done_btn, *edit_btn;
  UISlider *alpha_slider;

  NSInteger layer_index;

  UISwitch *show_hide_switch;
  UISlider *lalpha_slider;
  UISegmentedControl *comp_methods0, 
    *comp_methods1, *comp_methods2;
  NSInteger method_index;
  UISlider *red_slider, *green_slider, *blue_slider;

  UITableViewCell *paper_color_cell;
}

- (void)setLayerIndex:(NSInteger)i;
- (void)setParent:(UIView*)p withCanvas:(CanvasController*)c
   withNavigation:(UINavigationController*)n
     withRootView:(UITableView*)v;
- (void)alpha_changed:(id)s;
- (void)done_pressed:(id)s;
- (void)edit_pressed:(id)s;
- (UILabel*)colorLabelAtIndex:(int)i;
- (void)setCellForLayers:(UITableViewCell*)cell 
		 atIndex:(NSInteger)i;
- (void)setCellForLayerSettings:(UITableViewCell*)cell
			atIndex:(NSInteger)i;
- (void)showCompMethod;

- (void)layerCompMethodChanged:(id)s;
- (void)layerShowingChanged:(id)s;
- (void)layerCompAlphaChanged:(id)s;
- (void)layerPaperColorChanged:(id)s;

@end
