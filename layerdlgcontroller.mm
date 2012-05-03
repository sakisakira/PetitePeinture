#import "pttouchview.h"
#import "layerdlgcontroller.h"
#import "layeredpainter.h"
#import "canvascontroller.h"

@implementation LayerDlgController

- (void) dealloc {
  if (fullrect) delete fullrect;
  if (edit_btn) [edit_btn release];
  if (alpha_slider) [alpha_slider release];
  if (show_hide_switch) [show_hide_switch release];
  if (comp_methods0) [comp_methods0 release];
  if (comp_methods1) [comp_methods1 release];
  if (comp_methods2) [comp_methods2 release];
  if (red_slider) [red_slider release];
  if (green_slider) [green_slider release];
  if (blue_slider) [blue_slider release];
  [super dealloc];
}

- (void)loadView {
  [super loadView];

  layer_index = -1;

  done_btn = [[UIBarButtonItem alloc]
	       initWithTitle:@"done"
	       style:UIBarButtonItemStyleDone
	       target:self
	       action:@selector(done_pressed:)];
  self.title = @"Layers Settings";
  [self.navigationItem setLeftBarButtonItem:done_btn
       animated:YES];
  [done_btn release];
  done_btn = NULL;

  edit_btn = [[UIBarButtonItem alloc]
	       initWithTitle:@"edit"
	       style:UIBarButtonItemStyleDone
	       target:self
	       action:@selector(edit_pressed:)];

  CGRect slider_rect;
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    slider_rect = CGRectMake(0, 0, 160, 30);
  } else {
    slider_rect = CGRectMake(0, 0, 300, 30);
  }
  
  alpha_slider = [[UISlider alloc] 
                  initWithFrame:slider_rect];
  alpha_slider.minimumValue = 0.3;
  alpha_slider.maximumValue = 1.0;
  [alpha_slider addTarget:self
		action:@selector(alpha_changed:)
		forControlEvents:UIControlEventValueChanged];

  show_hide_switch = [[UISwitch alloc] init];

  lalpha_slider = [[UISlider alloc] 
                   initWithFrame:slider_rect];
  lalpha_slider.minimumValue = 0;
  lalpha_slider.maximumValue = 255;
  lalpha_slider.continuous = NO;

  comp_methods0 = [[UISegmentedControl alloc]
		     initWithItems:[NSArray arrayWithObjects:
					      @"min", @"mul",
					    @"sat", @"col", 
					    nil]];
  comp_methods1 = [[UISegmentedControl alloc]
		     initWithItems:[NSArray arrayWithObjects:
					    @"nor", @"max", @"mask",
					    @"alpha", nil]];
  comp_methods2 = [[UISegmentedControl alloc]
		     initWithItems:[NSArray arrayWithObjects:
					      @"scrn",
					    @"dodge", nil]];

  red_slider = [[UISlider alloc] 
                initWithFrame:slider_rect];
  red_slider.minimumValue = 0;
  red_slider.maximumValue = 255;
  red_slider.continuous = NO;
  green_slider = [[UISlider alloc] 
                  initWithFrame:slider_rect];
  green_slider.minimumValue = 0;
  green_slider.maximumValue = 255;
  green_slider.continuous = NO;
  blue_slider = [[UISlider alloc] 
                 initWithFrame:slider_rect];
  blue_slider.minimumValue = 0;
  blue_slider.maximumValue = 255;
  blue_slider.continuous = NO;
}

- (void)setLayerIndex:(NSInteger)i {
  layer_index = i;
  alpha_slider.value = parent.alpha;
  if (i < 0) {
    done_btn.title = @"done";
    self.title = @"Layers";
    edit_btn.title = @"edit";
    [self.tableView setEditing:NO animated:NO];
    [self.navigationItem setRightBarButtonItem:edit_btn
	 animated:YES];
  } else {
    done_btn.title = @"layers";
    self.title = [NSString stringWithFormat:
			     @"Layer %d Settings", i];

    show_hide_switch.on = painter->getShowing(layer_index);
    [show_hide_switch addTarget:self
                      action:@selector(layerShowingChanged:)
                      forControlEvents:UIControlEventValueChanged];
    lalpha_slider.value = painter->compositionAlpha(layer_index);
    [lalpha_slider addTarget:self
                   action:@selector(layerCompAlphaChanged:)
                   forControlEvents:UIControlEventValueChanged];
    method_index = painter->compositionMethod(layer_index);
    [self showCompMethod];
    [comp_methods0 addTarget:self
		  action:@selector(layerCompMethodChanged:)
		  forControlEvents:UIControlEventValueChanged];
    [comp_methods1 addTarget:self
		  action:@selector(layerCompMethodChanged:)
		  forControlEvents:UIControlEventValueChanged];
    [comp_methods2 addTarget:self
		  action:@selector(layerCompMethodChanged:)
		  forControlEvents:UIControlEventValueChanged];

    PtColor pcol = painter->paperColor(layer_index);
    red_slider.value = pcol.red;
    green_slider.value = pcol.green;
    blue_slider.value = pcol.blue;
    [red_slider addTarget:self
                action:@selector(layerPaperColorChanged:)
                forControlEvents:UIControlEventValueChanged];
    [green_slider addTarget:self
                  action:@selector(layerPaperColorChanged:)
                  forControlEvents:UIControlEventValueChanged];
    [blue_slider addTarget:self
                 action:@selector(layerPaperColorChanged:)
                 forControlEvents:UIControlEventValueChanged];
  }
}

- (void)setParent:(UIView*)p 
       withCanvas:(CanvasController*)c 
   withNavigation:(UINavigationController*)n 
     withRootView:(UITableView*)v {
  if (p) {
    parent = p;
    alpha_slider.value = p.alpha;
  }
  if (c) {
    canvas = c;
    painter = canvas->layeredPainter();
    fullrect = new PtRect(0, 0, 
                          c->canvasWidth(),
                          c->canvasHeight());
  }
  if (n) {
    layernav = n;
  }
  if (v) {
    rootView = v;
  }
}

- (void)alpha_changed:(id)s {
  if (parent)
    parent.alpha = alpha_slider.value;
}

- (void)done_pressed:(id)s {
  if (layer_index < 0) {
    parent.hidden = true;
    canvas->show_hide_layers();
    canvas->update_tools_rect();
  } else {
    [rootView reloadData];
    [layernav popViewControllerAnimated:YES];
  }
}

- (void)edit_pressed:(id)s {
  if (!self.tableView.editing) {
    edit_btn.title = @"end edit";
    [self.tableView setEditing:YES animated:YES];
  } else {
    edit_btn.title = @"edit";
    [self.tableView setEditing:NO animated:YES];
    [self.tableView reloadData];
  }
}

- (UITableViewCell*)tableView:(UITableView*)tblView
        cellForRowAtIndexPath:(NSIndexPath*)indexPath {
  static id tblId0 = @"PtPtLayerDlg0";
  static id tblId1 = @"PtPtLayerDlg1";
  static id tblIdL = @"PtPtLayerDlgL";

  UITableViewCell *cell = nil;
  id tblId;
  if (indexPath.row == 0)
    tblId = tblId0;
  else if (indexPath.row == 1)
    tblId = tblId1;
  else {
    if (layer_index < 0)
      tblId = tblIdL;
    else
      tblId = [NSString stringWithFormat:@"PtPtLayerDlgS%d", indexPath.row];
  }

  cell = [self.tableView dequeueReusableCellWithIdentifier:tblId];
  if (!cell)
//    cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero
//                                     reuseIdentifier:tblId] autorelease];
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tblId] autorelease];

  if (indexPath.row == 0) {
    cell.textLabel.text = @"settng trasparency";
    cell.accessoryView = alpha_slider;
  } else if (indexPath.row == 1) {
    cell.textLabel.text = @"";
    cell.accessoryView = nil;
  } else if (painter) {
    if (layer_index < 0)
      [self setCellForLayers:cell 
	    atIndex:indexPath.row];
    else
      [self setCellForLayerSettings:cell
	    atIndex:indexPath.row];
  }

  return cell;
}

- (UILabel*)colorLabelAtIndex:(int)index {
  UILabel *label = [[[UILabel alloc] 
		      initWithFrame:CGRectMake(0, 0, 30, 30)]
		     autorelease];
  label.text = @" ";
  PtColor pcol = painter->paperColor(index);
  UIColor* ucol = [UIColor colorWithRed:pcol.red / 255.0
			  green:pcol.green / 255.0
			  blue:pcol.blue / 255.0
			  alpha:1.0];
  label.backgroundColor = ucol;

  return label;
}
  
- (NSInteger)tableView:(UITableView*)tblView 
 numberOfRowsInSection:(NSInteger)section {

  if (painter) {
    if (layer_index < 0)
      return painter->numOfLayers() + 2;
    else
      return 12;
  } else
    return 2;
}

- (BOOL)tableView:(UITableView *)tableView 
canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if (layer_index >= 0) return false;

  if (indexPath.row == 0) 
    return false;
  else
    return true;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView 
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (layer_index >= 0)
    return  UITableViewCellEditingStyleNone;

  if (indexPath.row == 0)
    return  UITableViewCellEditingStyleNone;
  else if (indexPath.row == 1)
    return  UITableViewCellEditingStyleInsert;
  else
    return  UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView 
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (layer_index >= 0) return;

  if (editingStyle == UITableViewCellEditingStyleInsert) {
    painter->createLayer();
    canvas->updateRect(*fullrect);
    NSIndexPath *newip = [[indexPath indexPathByRemovingLastIndex]
                           indexPathByAddingIndex:2];
    [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newip]
                 withRowAnimation:UITableViewRowAnimationFade];
  } else if (editingStyle == UITableViewCellEditingStyleDelete) {
    int l_index = painter->numOfLayers() - 1 
        - (indexPath.row - 2);
    painter->deleteLayer(l_index);
    canvas->updateRect(*fullrect);
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
               withRowAnimation:UITableViewRowAnimationFade];
    [tableView reloadData];
  }
}

- (BOOL)tableView:(UITableView *)tableView 
canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  if (layer_index >= 0) return false;

  if (indexPath.row < 2) 
    return false;
  else
    return true;

}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)fromIndexPath 
      toIndexPath:(NSIndexPath *)toIndexPath {
  if (layer_index >= 0) return;

  int from_li = painter->numOfLayers() - 1 
        - (fromIndexPath.row - 2);
  int to_li = painter->numOfLayers() - 1 
        - (toIndexPath.row - 2);

  painter->exchangeLayers(from_li, to_li);
  canvas->updateRect(*fullrect);
  //  [tableView reloadData]; // do not comment-out. or crash 
}

- (void)tableView:(UITableView *)tableView 
 didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
  if (layer_index < 0) {
    if (newIndexPath.row > 1) {
      LayerDlgController *newvc = 
        [[LayerDlgController alloc] 
          initWithStyle:UITableViewStylePlain];
      int l_index = painter->numOfLayers() - 1 
        - (newIndexPath.row - 2);
      [newvc setParent:parent withCanvas:canvas
             withNavigation:layernav
             withRootView:rootView];
      [layernav pushViewController:newvc animated:YES];
      [newvc setLayerIndex:l_index];
      [newvc.tableView reloadData];
      [newvc release];
    }
  }
}

- (void)setCellForLayers:(UITableViewCell*)cell
		 atIndex:(NSInteger)index {
  int l_index;
  NSArray *infos = painter->infoStrings();

  l_index = painter->numOfLayers() - 1 
    - (index - 2);
  NSString *infostr = [infos objectAtIndex:l_index];
  cell.textLabel.text = [[NSString stringWithFormat:
                           @"%d: ", l_index]  
                              stringByAppendingString:infostr];
  cell.accessoryView = [self colorLabelAtIndex:l_index];
}

- (void)setCellForLayerSettings:(UITableViewCell*)cell
			atIndex:(NSInteger)index {
  switch (index) {
  case 2:
      cell.textLabel.text = @"show";
    cell.accessoryView = show_hide_switch;
    break;
  case 3:
    cell.textLabel.text = @"layer alpha";
    cell.accessoryView = lalpha_slider;
    break;
  case 4:
    cell.textLabel.text = @"composition method";
    cell.accessoryView = nil;
    break;
  case 5:
    cell.textLabel.text = @"";
    cell.accessoryView = comp_methods0;
    break;
  case 6:
    cell.textLabel.text = @"";
    cell.accessoryView = comp_methods1;
    break;
  case 7:
    cell.textLabel.text = @"";
    cell.accessoryView = comp_methods2;
    break;
  case 8:
    cell.textLabel.text = @"paper color";
    cell.accessoryView = NULL;
    cell.backgroundColor = [UIColor  colorWithRed:red_slider.value / 255.0
                                     green:green_slider.value / 255.0
                                     blue:blue_slider.value / 255.0
                                     alpha:1.0];
    paper_color_cell = cell;
    break;
  case 9:
    cell.textLabel.text = @"red";
    cell.accessoryView = red_slider;
    break;
  case 10:
    cell.textLabel.text = @"green";
    cell.accessoryView = green_slider;
    break;
  case 11:
    cell.textLabel.text = @"blue";
    cell.accessoryView = blue_slider;
    break;
  }
}

- (void)layerCompMethodChanged:(id)s {
  static bool clearing = false;
  if (clearing) return;

  if (s == comp_methods0) {
    method_index = comp_methods0.selectedSegmentIndex;
    clearing = true;
    comp_methods1.selectedSegmentIndex = UISegmentedControlNoSegment;
    comp_methods2.selectedSegmentIndex = UISegmentedControlNoSegment;
    clearing = false;
  } else if (s == comp_methods1) {
    method_index = comp_methods1.selectedSegmentIndex + 4;
    clearing = true;
    comp_methods0.selectedSegmentIndex = UISegmentedControlNoSegment;
    comp_methods2.selectedSegmentIndex = UISegmentedControlNoSegment;
    clearing = false;
  } else if (s == comp_methods2) {
    method_index = comp_methods2.selectedSegmentIndex + 8;
    clearing = true;
    comp_methods0.selectedSegmentIndex = UISegmentedControlNoSegment;
    comp_methods1.selectedSegmentIndex = UISegmentedControlNoSegment;
    clearing = false;
  }

  painter->setCompositionMethod(layer_index, method_index);
  canvas->updateRect(*fullrect);
}

- (void)showCompMethod {
  if (method_index < 0)
    return;
  else if (method_index < 4)
    comp_methods0.selectedSegmentIndex = method_index;
  else if (method_index < 8)
    comp_methods1.selectedSegmentIndex = method_index - 4;
  else if (method_index < NumOfComposition)
    comp_methods2.selectedSegmentIndex = method_index - 8;
}

- (void)layerShowingChanged:(id)s {
  painter->setShowing(layer_index, show_hide_switch.on);
  canvas->updateRect(*fullrect);
}

- (void)layerCompAlphaChanged:(id)s {
  painter->setLayerAlpha(layer_index, lalpha_slider.value);
  canvas->updateRect(*fullrect);
}

- (void)layerPaperColorChanged:(id)s {
  int r, g, b;
  r = red_slider.value;
  g = green_slider.value;
  b = blue_slider.value;
  painter->setPaperColor(layer_index, PtColor(r, g, b));
  canvas->updateRect(*fullrect);
  paper_color_cell.backgroundColor = [UIColor  colorWithRed:r / 255.0
			  green:g / 255.0
			  blue:b / 255.0
			  alpha:1.0];
}

@end
