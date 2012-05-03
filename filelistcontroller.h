#import "constants.h"

class CanvasController;

extern int FLCHeaderHeight;
extern int FLCRowHeight;
extern int FLCIconWidth, FLCIconHeight;

@interface FileListController : UITableViewController 
<UIAlertViewDelegate> {
@public;
  UIView *header_view;
  UIButton *cancel_btn, *delete_btn;

  NSMutableArray *fnlist;
  NSString *document_dir;

  UIAlertView *delete_dlg;
  NSUInteger selected_index;

  CanvasController *canvas;
}

- (void)setCanvas:(CanvasController*)canvas;
- (void)loadFileList;

- (void)cancel_pressed:(id)s;
- (void)delete_pressed:(id)s;

@end
