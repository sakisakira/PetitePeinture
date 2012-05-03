#import "filelistcontroller.h"
#import "canvascontroller.h"
#import "pttouchview.h"
#include "ptptformat.h"

@implementation FileListController

int FLCHeaderHeight = 50;
int FLCRowHeight = 82;
int FLCIconWidth = 54;
int FLCIconHeight = 81;

- (void)viewDidLoad {
  ALog(@"filelistcontroller loadview");

  CGRect rect = CGRectMake(0, 0,
			   self.tableView.bounds.size.width,
			   FLCHeaderHeight);
  header_view = [[UIView alloc] initWithFrame:rect];
  header_view.backgroundColor = [UIColor lightGrayColor];
  UILabel *title = [[UILabel alloc] 
		     initWithFrame:CGRectMake(100, 10, 120, 30)];
  title.text = @"Load Image";
  title.textAlignment = UITextAlignmentCenter;
  title.backgroundColor = [UIColor lightGrayColor];
  [header_view addSubview:title];
  [title release];

  cancel_btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  cancel_btn.frame = CGRectMake(10, 10, 80, 30);
  [cancel_btn setTitle:@"cancel"
	      forState:UIControlStateNormal];
  [cancel_btn addTarget:self
	      action:@selector(cancel_pressed:)
	      forControlEvents:UIControlEventTouchUpInside];
  [header_view addSubview:cancel_btn];

  delete_btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  delete_btn.frame = CGRectMake(230, 10, 80, 30);
  [delete_btn setTitle:@"delete"
	      forState:UIControlStateNormal];
  [delete_btn addTarget:self
	      action:@selector(delete_pressed:)
	      forControlEvents:UIControlEventTouchUpInside];
  [header_view addSubview:delete_btn];

  self.tableView.tableHeaderView = header_view;
  [header_view release];
}

- (void)dealloc {
  if (header_view) [header_view release];
  if (fnlist) [fnlist release];
  if (document_dir) [document_dir release];
  [super dealloc];
}

- (UITableViewCell*)tableView:(UITableView*)tblView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  static id tblId = @"PtPtFileListTable";
  if (!fnlist)
    [self loadFileList];

  UITableViewCell *cell = [tblView dequeueReusableCellWithIdentifier:tblId];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero
				     reuseIdentifier:tblId] 
	     autorelease];
  }
	NSFileManager *fm = [NSFileManager defaultManager];
	
  NSString *fn = [fnlist objectAtIndex:indexPath.row];
	UIImage *sicon = nil;

  NSString *icon_path = [[document_dir stringByAppendingPathComponent:fn]
			  stringByAppendingPathExtension:@"jpg"];
	if ([fm fileExistsAtPath:icon_path])
		sicon = [[[UIImage alloc] initWithContentsOfFile:icon_path] autorelease];
	else {
		NSString *ptpt_path = [[document_dir stringByAppendingPathComponent:fn]
													 stringByAppendingPathExtension:@"ptpt"];
		if ([fm fileExistsAtPath:ptpt_path]) {
			PtptFormat ptpt;
			ptpt.load(ptpt_path);
			sicon = ptpt.getThumbnail();
		}
	}

  UIGraphicsBeginImageContext(CGSizeMake(FLCIconWidth, FLCIconHeight));
  [sicon drawInRect:CGRectMake(0, 0, FLCIconWidth, FLCIconHeight)];

  UIImage *dicon = UIGraphicsGetImageFromCurrentImageContext();  
  UIGraphicsEndImageContext();

  UIImageView *iconv = [[UIImageView alloc] initWithImage:dicon];
  iconv.contentMode = UIViewContentModeScaleToFill;
  iconv.frame = CGRectMake(10, 0, FLCIconWidth, FLCIconHeight);
  [cell.contentView addSubview:iconv];
  [iconv release];

  UILabel *title = [[UILabel alloc]
		     initWithFrame:CGRectMake(FLCIconWidth + 20, 0,
					      250, FLCIconHeight)];
  title.text = fn;
  [cell.contentView addSubview:title];
  [title release];

  return cell; 
}

- (NSInteger)tableView:(UITableView*)tblView
 numberOfRowsInSection:(NSInteger)section {
  if (!fnlist)
    [self loadFileList];

  return [fnlist count];
}

- (BOOL)tableView:(UITableView *)tableView 
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return true;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  return  UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
  selected_index = indexPath.row;
  delete_dlg = [[[UIAlertView alloc] initWithTitle:@"delete file"
				     message:@"delete this image file?"
				     delegate:self
				     cancelButtonTitle:@"cancel"
				     otherButtonTitles:@"OK", nil] 
		 autorelease];
  [delete_dlg show];
}

- (void)alertView:(UIAlertView *)alertView 
clickedButtonAtIndex:(NSInteger)buttonIndex {
  if (alertView == delete_dlg && buttonIndex == 1) {
    NSString *fpath = [document_dir 
                       stringByAppendingPathComponent:
                          [fnlist objectAtIndex:selected_index]];
    NSString *fpath_plist = [fpath
                            stringByAppendingPathExtension:@"plist"];
		NSString *fpath_ptpt = [fpath
                            stringByAppendingPathExtension:@"ptpt"];
    NSString *fpath_icon = [fpath
                            stringByAppendingPathExtension:@"jpg"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:fpath_plist])
      [fm removeItemAtPath:fpath_plist error:NULL];
    if ([fm fileExistsAtPath:fpath_ptpt])
      [fm removeItemAtPath:fpath_ptpt error:NULL];
    if ([fm fileExistsAtPath:fpath_icon])
      [fm removeItemAtPath:fpath_icon error:NULL];
    [fnlist removeObjectAtIndex:selected_index];
    [self.tableView reloadData];
  }
}

- (void)tableView:(UITableView *)tableView 
 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  selected_index = indexPath.row;
  NSString *fpath = [document_dir 
                      stringByAppendingPathComponent:
                        [fnlist objectAtIndex:selected_index]];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *fpath_plist, *fpath_ptpt;
  fpath_plist = [fpath stringByAppendingPathExtension:@"plist"];
	fpath_ptpt = [fpath stringByAppendingPathExtension:@"ptpt"];
	if ([manager fileExistsAtPath:fpath_plist])
		canvas->loadImage(fpath_plist);
	else if ([manager fileExistsAtPath:fpath_ptpt])
		canvas->loadPtpt(fpath_ptpt);
	else 
		[[[[UIAlertView alloc] 
			 initWithTitle:@"file not found"
			 message:@"Please check the file name. An PTPT file should have  .ptpt as the extension."
			 delegate:self
			 cancelButtonTitle:nil
			 otherButtonTitles:@"OK", nil] 
			autorelease] show];
	
  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  self.view.hidden = true;
}

- (void)setCanvas:(CanvasController*)c {
  canvas = c;
}

- (void)loadFileList {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
							 NSUserDomainMask, YES)
                                                      objectAtIndex:0];

  self.tableView.rowHeight = FLCRowHeight;
  [delete_btn setTitle:@"delete"
	      forState:UIControlStateNormal];
  [self.tableView setEditing:NO animated:NO];

  if (document_dir)
    [document_dir release];
  document_dir = dir;
  [document_dir retain];
	NSArray *fns = [fm contentsOfDirectoryAtPath:dir error:NULL];
  NSMutableArray *newfns = [NSMutableArray array];
  for (NSString *fn in fns) {
    if ([[fn pathExtension] compare:@"plist"] == NSOrderedSame ||
				[[fn pathExtension] compare:@"ptpt"] == NSOrderedSame) {
      [newfns insertObject:[fn stringByDeletingPathExtension]
	      atIndex:0];
      ALog(@"file found: %@", fn);
    }
  }
  if (fnlist)
    [fnlist release];
  fnlist = newfns;
  [fnlist retain];
}

- (void)cancel_pressed:(id)s {
  self.view.hidden = true;
}

- (void)delete_pressed:(id)s {
  if (!self.tableView.editing) {
    [delete_btn setTitle:@"end delete"
		forState:UIControlStateNormal];
    [self.tableView setEditing:YES animated:YES];
  } else {
    [delete_btn setTitle:@"delete"
		forState:UIControlStateNormal];
    [self.tableView setEditing:NO animated:YES];
  }
}

@end
