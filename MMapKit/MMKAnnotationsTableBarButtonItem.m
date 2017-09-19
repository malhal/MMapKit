//
//  MMKAnnotationsTableBarButtonItem.m
//  MMapKit
//
//  Created by Malcolm Hall on 20/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import "MMKAnnotationsTableBarButtonItem.h"

@interface MMKAnnotationsTableBarButtonItem() <UITableViewDataSource, UITableViewDelegate>

@property (strong) UINavigationController *navigationController;
@property (strong) NSArray* annotations;
@property (strong) UIPopoverController *popover;

- (UIViewController *)_viewControllerContainingView:(UIView *)view;

@end

 //private API for getting the list icon instead of including the png as a resource.
#if defined(JB)

@interface UIImage (UIImagePrivate)
+ (UIImage *)kitImageNamed:(NSString *)named; // UIButtonBarListIcon
@end

#endif


@implementation MMKAnnotationsTableBarButtonItem

- (id)initWithMapView:(MKMapView *)mapView image:(UIImage *)image{
    
    // find a default image if one wasn't set
    if(!image){
        #if defined(JB)
            image = [UIImage kitImageNamed:@"UIButtonBarListIcon"];
        #else
            image = [UIImage imageNamed:@"UIButtonBarListIcon"];
        #endif
    }

    if(image){
        self = [super initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(_annotationsTableButtonItemTapped:)];
    }else{
        self = [super initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(_annotationsTableButtonItemTapped:)];
    }
    
    if (self) {
        self.mapView = mapView;
    }
    return self;
}

- (id)initWithMapView:(MKMapView *)mapView {
    return [self initWithMapView:mapView image:nil];
}

- (UIViewController *)_viewControllerContainingView:(UIView*)view {
    
    UIResponder *responder = view;
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return (UIViewController *)responder;
}

- (void)_doneButtonItemTapped:(id)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_annotationsTableButtonItemTapped:(id)sender{
    UITableViewController *a = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
    a.tableView.delegate = self;
    a.tableView.dataSource = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        a.clearsSelectionOnViewWillAppear = NO;
    }
    
    //not needed because it inherits the tint from the nav controller's view.
    //if (_originatingNavigationController != nil) {
   // a.view.tintColor = _originatingNavigationController.topViewController.view.tintColor;
    //}
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        a.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonItemTapped:)];
    }
    
    UIViewController *containerViewController = [self _viewControllerContainingView:self.mapView];

    //this tries to create an automatic title.
    //first try and get nav bar title
    a.title = containerViewController.navigationItem.title;
    //then try and get tab bar title
    if(!a.title){
        a.title = containerViewController.title;
        //then try if they set a title on this bar button item
        if(!a.title){
            a.title = self.title;
            //default to results
            if(!a.title){
                a.title = @"Results";
            }
        }
    }
    
    if([self.mapView.delegate respondsToSelector:@selector(annotationsForAnnotationsTableViewController:)]){
        self.annotations = [(id<MKMapViewAnnotationsTableDelegate>)self.mapView.delegate annotationsForAnnotationsTableViewController:a];
    }else{
        //remove the current user annotation.
        NSMutableArray* array = [NSMutableArray arrayWithArray: self.mapView.annotations];
        [array removeObject:self.mapView.userLocation];
        self.annotations = array;
    }
    
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:a];
    
    UINavigationController *originatingNavigationController = containerViewController.navigationController;
    if (originatingNavigationController != nil) {
        self.navigationController.toolbar.tintColor = originatingNavigationController.toolbar.tintColor;
        self.navigationController.navigationBar.barStyle = originatingNavigationController.navigationBar.barStyle;
        self.navigationController.navigationBar.translucent = originatingNavigationController.navigationBar.translucent;
        self.navigationController.navigationBar.tintColor = originatingNavigationController.navigationBar.tintColor;
        self.navigationController.extendedLayoutIncludesOpaqueBars = originatingNavigationController.extendedLayoutIncludesOpaqueBars;
        self.navigationController.view.tintColor = originatingNavigationController.view.tintColor;
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.navigationController];
        [_popover presentPopoverFromBarButtonItem:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else{
        [containerViewController presentViewController:self.navigationController animated:YES completion:nil];
    }
}

- (void)_tableViewDidLoadRows:(UITableView*)tableView{
    if(_mapView.selectedAnnotations.count){
        NSInteger index = [self.annotations indexOfObject:_mapView.selectedAnnotations.firstObject];
        [tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_tableViewDidLoadRows:) object:tableView];
    [self performSelector:@selector(_tableViewDidLoadRows:) withObject:tableView afterDelay:0];
    //return self.searchDisplayController.isActive ? _searchScans.count : _wifiScans.count;
    return _annotations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
     static NSString *CellIdentifier = @"ScanCell";
     static NSString *SearchCellIdentifier = @"SearchScanCell";
     
     BOOL sa = tableView == self.searchDisplayController.searchResultsTableView;
     
     NSString *ident = sa ? SearchCellIdentifier : CellIdentifier;
     
     WiFiScanCell *cell = [tableView dequeueReusableCellWithIdentifier:ident forIndexPath:indexPath];
     
     cell.scan = self.searchDisplayController.isActive ? [_searchScans objectAtIndex:indexPath.row] : [_wifiScans objectAtIndex:indexPath.row];
     
     return cell;
     */
    
    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //only add the detail accessorty if there is a control tapped handler
		if([self.mapView.delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]){
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
    }
    
    id<MKAnnotation> annotation = [_annotations objectAtIndex:indexPath.row];
    
	cell.textLabel.text = annotation.title;
	cell.detailTextLabel.text = annotation.subtitle;
    
    UIImage *image = nil;
    //try to get an image for the table
    if([_mapView.delegate respondsToSelector:@selector(imageForAnnotation:)]){
       image = [(id<MKMapViewAnnotationsTableDelegate>)_mapView.delegate imageForAnnotation:annotation];
    }else{
        //view may be nil if annotation isn't on the map
        MKAnnotationView* view = [_mapView viewForAnnotation:annotation];
        if([view.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]){
            UIImageView* imageView = (UIImageView*)view.leftCalloutAccessoryView;
            cell.imageView.image = imageView.image;
        }else if([view isKindOfClass:[MKAnnotationView class]]){
            cell.imageView.image = view.image;
        }
    }
    cell.imageView.image = image;
    
    //oops only a pin if on the map currently
    //cell.imageView.image = view.image;
    return cell;
    
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<MKAnnotation> annotation = [_annotations objectAtIndex:indexPath.row];
    [self.mapView selectAnnotation:annotation animated:NO];
    [self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, 50.0, 50.0f) animated:NO];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    id<MKAnnotation> annotation = [_annotations objectAtIndex:indexPath.row];
    
    //forward this onto the map delegate
    if([self.mapView.delegate respondsToSelector:@selector(mapView:annotationView:calloutAccessoryControlTapped:)]){
        //casts to control to prevent a warning.
        MKAnnotationView* view = [self.mapView viewForAnnotation:annotation];
        // create a dummy view for when the annotation isn't on the map yet.
        if(!view){
            view = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:nil];
        }
        [self.mapView.delegate mapView:self.mapView annotationView:view calloutAccessoryControlTapped:(UIControl *)self];
    }
}

@end

