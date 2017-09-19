//
//  MapViewController.m
//  MMapKit
//
//  Created by Malcolm Hall on 10/11/13.
//  Copyright (c) 2013 Malcolm Hall. All rights reserved.
//

#import "MMKMapViewController.h"
#import "MMKMapTypeBarButtonItem.h"
#import <objc/runtime.h>
//#import "CLLocationManager+MMK.h"
#import "MMKAnnotationSegue.h"

NSString * const MHShowAnnotationSegueIdentifier = @"showAnnotation";
NSString * const MHAnnotationCellIdentifier = @"annotation";

// Use & of this to get a unique pointer for this class.
static void * const kMMKMapViewControllerContext = (void *)&kMMKMapViewControllerContext;
static NSString * const kDefaultAnnotationReuseIdentifier = @"Annotation";

@interface MMKMapViewControllerLayoutGuide : NSObject <UILayoutSupport>
@property (nonatomic, assign) CGFloat tableHeight;
@property (nonatomic, assign) CGFloat bottomLayoutGuideLength;
@property (nonatomic, strong) NSLayoutYAxisAnchor *topAnchor;
@property (nonatomic, strong) NSLayoutYAxisAnchor *bottomAnchor;
@property (nonatomic, strong) NSLayoutDimension *heightAnchor;
@end

@implementation MMKMapViewControllerLayoutGuide
-(CGFloat)length{
    return self.tableHeight + self.bottomLayoutGuideLength;
}
@end

//private API for getting the list icon instead of including the png as a resource.
#if MMapKit_USE_PRIVATE_API == 1

@interface UIImage(UIImagePrivate)

+ (UIImage *)kitImageNamed:(NSString*)named; // UIButtonBarListIcon

@end

#endif

//@interface MHAnnotationsSectionInfo : NSObject
//
///* Name of the section
// */
//@property (nonatomic) NSString *name;
//
///* Title of the section (used when displaying the index)
// */
//@property (nullable, nonatomic) NSString *indexTitle;
//
///* Number of objects in section
// */
//@property (nonatomic) NSUInteger numberOfObjects;
//
///* Returns the array of objects in the section.
// */
//@property (nullable, nonatomic) NSMutableArray *objects;
//
//@end // MHAnnotationsSectionInfo
//
//@implementation MHAnnotationsSectionInfo
//
//@end

@interface MMKMapViewController()

@property (nonatomic, strong, readwrite) MMKMapTypeBarButtonItem *mapTypeBarButtonItem;
@property (nonatomic, strong, readwrite) MKUserTrackingBarButtonItem *userTrackingBarButtonItem;
@property (nonatomic, strong, readwrite) UIBarButtonItem *annotationsTableBarButtonItem;
@property (nonatomic, strong, readwrite) NSArray<UIBarButtonItem *> *defaultToolBarItems;
@property (nonatomic, assign) BOOL presentingAnnotationsTable;
@property (nonatomic, strong) NSLayoutConstraint *zeroHeightLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *proportionalHeightLayoutConstraint;

@property (nonatomic, strong) MMKMapViewControllerLayoutGuide *mvcLayoutGuide;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<MKAnnotation>> *annotationsByIndex;

@end

@implementation MMKMapViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)bundle{
    self = [super initWithNibName:nibName bundle:bundle];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // set the default cell reuse identifer here so we can use it internally without copying every time we need it if we were to use an accessor and a nil check.
    self.annotationReuseIdentifier = kDefaultAnnotationReuseIdentifier;
    //self.annotations = [NSMutableArray array];
    self.mvcLayoutGuide = [[MMKMapViewControllerLayoutGuide alloc] init];
    self.annotationsByIndex = [NSMutableDictionary dictionary];
}

-(id<MKAnnotation>)annotationAtIndex:(NSUInteger)index{
    return nil;
}

- (NSInteger)numberOfAnnotations{
    return 0;
}

- (NSUInteger)indexOfAnnotation:(id<MKAnnotation>)annotation{
    return NSNotFound;
}


- (void)showDetailForAnnotation:(id<MKAnnotation>)annotation{
    // do the default segue if exists.
    @try {
        [self performSegueWithIdentifier:MHShowAnnotationSegueIdentifier sender:annotation];
    }
    @catch (NSException *exception) {
        NSLog(@"Warning you must hookup a custom segue to a detail view controller with class %@ and identifier %@", NSStringFromClass([MMKAnnotationSegue class]), MHShowAnnotationSegueIdentifier);
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender{
    if([segue.identifier isEqualToString:MHShowAnnotationSegueIdentifier]){
        [self prepareForAnnotationDetailViewController:segue.destinationViewController annotation:sender];
    }
    // allow interaction after we have prevented possible duplicate taps
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.annotationsTableView.userInteractionEnabled = YES;
//    });
}

//-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
//    // prevent duplicate taps
//    self.annotationsTableView.userInteractionEnabled = NO;
//    return YES;
//}


- (void)prepareForAnnotationDetailViewController:(UIViewController *)viewController annotation:(id<MKAnnotation>)annotation{
    // the default implementatino does nothing
}

- (void)insertAnnotationsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    // convert to table index paths
    NSMutableArray *fixedIndexPaths = [NSMutableArray array];
    NSMutableArray *annotations = [NSMutableArray array];
    for(NSIndexPath *indexPath in indexPaths){
        NSInteger index = [indexPath indexAtPosition:0];
        // add to array for table
        [fixedIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        // add to array for map
        id<MKAnnotation> annotation = [self annotationAtIndex:index];
        [annotations addObject:annotation];
        //[self.annotationsOnMap insertObject:annotation atIndex:index];
        self.annotationsByIndex[@(index)] = annotation;
    }
    //[self.annotationsOnMap addObjectsFromArray:annotations];
    [self.mapView addAnnotations:annotations];
    [self.annotationsTableView insertRowsAtIndexPaths:fixedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

// we need to supply the annotations, because if this is called from a fetch controller delete then the annotation has already gone so cannot
// use annotationAtIndex:index like the insert does.
- (void)deleteAnnotationsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    NSMutableArray* fixedIndexPaths = [NSMutableArray array];
    NSMutableArray* annotations = [NSMutableArray array];
    for(NSIndexPath* indexPath in indexPaths){
        NSInteger index = [indexPath indexAtPosition:0];
        [fixedIndexPaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        //[annotations addObject:[self annotationAtIndex:index]]; // crashes on the fetched controller delegate delete because its already gone.
        //[self.annotationsOnMap removeObjectAtIndex:index];
        id<MKAnnotation> annotation = self.annotationsByIndex[@(index)];
        [annotations addObject:annotation];
        [self.annotationsByIndex removeObjectForKey:@(index)];
    }
    [self.mapView removeAnnotations:annotations];
    [self.annotationsTableView deleteRowsAtIndexPaths:fixedIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
}


//
//-(UITableViewController*)annotationsTableViewController{
//    if(_annotationsTableViewController){
//        return _annotationsTableViewController;
//    }
//    // try to get the relationship
//    @try {
//        [self performSegueWithIdentifier:@"empty" sender:nil];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"Segue not found: %@", exception);
//    }
//    // now its either a valid one or nil.
//    return _annotationsTableViewController;
//}

- (MKMapView *)mapView{
    return (MKMapView *)self.view;
}


-(void)reloadData{
    
    NSInteger number = [self numberOfAnnotations];
    NSMutableDictionary<NSNumber *, id<MKAnnotation>> *annotationsByIndex = [NSMutableDictionary dictionary];
    for(NSInteger i=0;i<number;i++){
        id<MKAnnotation> annotation = [self annotationAtIndex:i];
        if(annotation){
            annotationsByIndex[@(i)] = annotation;
        }
    }
    
    NSMutableArray* removeAnnotations = [NSMutableArray array];
    NSMutableArray* addAnnotations = [NSMutableArray array];
    
    // find the annotations to remove from the map
    //for(id<MKAnnotation> annotation in self.mapView.annotations){
    for(NSNumber *index in self.annotationsByIndex.allKeys){
        id<MKAnnotation> annotation = self.annotationsByIndex[index];
        // todo check if kind of class that that the results controller is supposed to be returning.
        //if([annotation isEqual:self.mapView.userLocation]){
            // do nothing with user
        //}
        if(annotationsByIndex[index]){
            // already on map
        }else{
            [removeAnnotations addObject:annotation];
            [self.annotationsByIndex removeObjectForKey:index];
        }
    }
    // find the annotations to add to the map
    //for(id<MKAnnotation> annotation in annotations){
    //for(NSIndexPath *indexPath in indexPaths){
    for(NSNumber *index in annotationsByIndex.allKeys){
        id<MKAnnotation> annotation = annotationsByIndex[index];
        //if([self.annotationsByIndexPath.allValues containsObject:annotation]){
        if(self.annotationsByIndex[index]){
            // already on the map
        }
        else{
            [addAnnotations addObject:annotation];
            self.annotationsByIndex[index] = annotation;
        }
    }
    [self.mapView removeAnnotations:removeAnnotations];
    [self.mapView addAnnotations:addAnnotations];
    
    [self.annotationsTableView reloadData];
}

- (BOOL)canPerformShowAnnotationDetailSegue
{
#if MMapKit_USE_PRIVATE_API == 1
    static BOOL kCanPerformShowAnnotationDetailSegue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *segueTemplates = [self valueForKey:@"storyboardSegueTemplates"];
        NSArray *filteredArray = [segueTemplates filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier = %@ AND segueClassName = %@", MHShowAnnotationSegueIdentifier, NSStringFromClass(MMKAnnotationSegue.class)]];
        kCanPerformShowAnnotationDetailSegue = filteredArray.count > 0;
    });
    return kCanPerformShowAnnotationDetailSegue;
#else
    return YES; // the exception will be caught if the manual segue was not configured correctly
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //magic to work without a view set in the storboard or in code.
    //check if a view has been set in the storyboard, like what UITableViewController does.
    //check if don't have a map view
    if(![self.view isKindOfClass:[MKMapView class]]){
        //check if the default view was loaded. Default view always has no background color.
        if([self.view isKindOfClass:[UIView class]] && !self.view.backgroundColor){
            // replace the view with the map view
            self.view = [[MKMapView alloc] initWithFrame:CGRectZero];
        }else{
            // todo: make a proper exception.
            [NSException raise:@"MapViewController already has a view that is not a map view" format:@"Found a %@. Either remove this view from the storyboard or replace it with a map view", self.view.class];
        }
    }
    self.mapView.delegate = self;
    
    self.userTrackingBarButtonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    self.mapTypeBarButtonItem = [[MMKMapTypeBarButtonItem alloc] initWithMapView:self.mapView];
    
    // find a default image if one wasn't set
    UIImage *image;
#if MMapKit_USE_PRIVATE_API == 1
        // get the image that shows a list icon from UIKit.
        image = [UIImage kitImageNamed:@"UIButtonBarListIcon"];
#else
        image = [UIImage imageNamed:@"UIButtonBarListIcon" inBundle:[NSBundle bundleForClass:MMKMapViewController.class] compatibleWithTraitCollection:nil];
#endif
    
    // safety in case for some reason the image wasn't in the bundle.
    if(image){
        self.annotationsTableBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(annotationsTableBarButtonTapped:)];
    }else{
        self.annotationsTableBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(annotationsTableBarButtonTapped:)];
    }

    UIBarButtonItem *spacer1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *spacer2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.defaultToolBarItems = @[self.userTrackingBarButtonItem, spacer1, self.mapTypeBarButtonItem, spacer2, self.annotationsTableBarButtonItem];
    
    // set items if there are none already.
    if(!self.toolbarItems.count){
        self.toolbarItems = self.defaultToolBarItems;
    }
    
    // When they tap the tracking button request authorization
    [self.mapView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(showsUserLocation))
                      options:(NSKeyValueObservingOptionNew |
                               NSKeyValueObservingOptionOld)
                      context:kMMKMapViewControllerContext];
    
    if(self.mapView.showsUserLocation){
        //[CLLocationManager mmk_requestLocationAuthorizationIfNotDetermined];
    }
    
    // reload after subclass has done viewDidLoad
    [self performSelector:@selector(reloadData) withObject:nil afterDelay:0];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    //_annotationsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.dataSource = self;
    tableView.delegate = self;
    self.annotationsTableView = tableView;

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:_annotationReuseIdentifier];
    if(!pin){
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:self.annotationReuseIdentifier];
        // add button if necessary
        if([self canPerformShowAnnotationDetailSegue]){
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            UIImage *image = [[UIImage imageNamed:@"DisclosureArrow" inBundle:[NSBundle bundleForClass:MMKMapViewController.class] compatibleWithTraitCollection:nil] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [rightButton setImage:image forState:UIControlStateNormal];
            [rightButton sizeToFit];
            pin.rightCalloutAccessoryView = rightButton;
        }
    }
    pin.annotation = annotation;
    pin.canShowCallout = annotation.title ? YES : NO;
    return pin;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    [self showDetailForAnnotation:view.annotation];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    // dont select if not showing because it will crash if not loaded yet. It will be selected on first load anyway.
//    if(!self.presentingAnnotationsTable){
//        return;
//    }
    if(view.annotation == mapView.userLocation){
        return;
    }
    NSInteger index = [self indexOfAnnotation:view.annotation];
    if(index == NSNotFound){
        return;
    }
    [self.annotationsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

- (void)dealloc
{
    // remove the observer to prevent a crash somehint that is dealloced cannot still be observing.
    [self.mapView removeObserver:self forKeyPath:@"showsUserLocation"];
}

// New in iOS 8 this technique results in this warning shown:
// Trying to start MapKit location updates without prompting for location authorization. Must call -[CLLocationManager requestWhenInUseAuthorization] or -[CLLocationManager requestAlwaysAuthorization] first.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    // if it was our observation
    if(context == kMMKMapViewControllerContext){
        //if([keyPath isEqualToString:NSStringFromSelector(@selector(showsUserLocation))]){
        if([[change objectForKey:NSKeyValueChangeNewKey] boolValue]){
            //[CLLocationManager mmk_requestLocationAuthorizationIfNotDetermined];
        }
        //}
    }
    else{
        // if necessary, pass the method up the subclass hierarchy.
        if([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]){
            [super observeValueForKeyPath:keyPath
                                 ofObject:object
                                   change:change
                                  context:context];
        }
    }
}

-(void)tableViewDidLoadRows:(UITableView *)tableView{
    if(self.mapView.selectedAnnotations.count){
        NSInteger index = [self indexOfAnnotation:self.mapView.selectedAnnotations.firstObject];
        [self.annotationsTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // after its loaded select the cell so if they override cellForAnnotation they don't need to set selected.
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tableViewDidLoadRows:) object:tableView];
    [self performSelector:@selector(tableViewDidLoadRows:) withObject:tableView afterDelay:0];
    NSInteger i = [self numberOfAnnotations];
    return i;
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
    id<MKAnnotation> annotation = [self annotationAtIndex:indexPath.row];
    return [self cellForAnnotation:annotation];
}

- (UITableViewCell *)cellForAnnotation:(id<MKAnnotation>)annotation{
    UITableViewCell *cell = [self.annotationsTableView dequeueReusableCellWithIdentifier:MHAnnotationCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:MHAnnotationCellIdentifier];
        if([self canPerformShowAnnotationDetailSegue]){
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
            cell.backgroundColor = [UIColor clearColor];
        }
    }
    cell.textLabel.text = annotation.title;
    cell.detailTextLabel.text = annotation.subtitle;
    
    cell.selected = (annotation == self.mapView.selectedAnnotations.firstObject);
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<MKAnnotation> annotation = [self annotationAtIndex:indexPath.row];
    [self.mapView selectAnnotation:annotation animated:NO];
    //[self.mapView setRegion:MKCoordinateRegionMakeWithDistance(annotation.coordinate, 50.0, 50.0f) animated:NO];
    [self.mapView setCenterCoordinate:annotation.coordinate animated:YES];
    // only dismiss if its full screen.
    if(self.annotationsTablePresentationStyle == MMKAnnotationsTablePresentationStyleModal){
        [self dismissAnnotationsTable];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    id<MKAnnotation> annotation = [self annotationAtIndex:indexPath.row];
    [self showDetailForAnnotation:annotation];
}

- (void)annotationsTableBarButtonTapped:(id)sender{
    if(self.presentingAnnotationsTable){
        [self dismissAnnotationsTable];
    }else{
        [self presentAnnotationsTable];
    }
}

- (void)doneButtonTapped:(id)sender{
    [self dismissAnnotationsTable];
}

- (void)dismissAnnotationsTable{
    self.presentingAnnotationsTable = NO;
    [self willDismissAnnotationsTable];
    if(self.annotationsTablePresentationStyle == MMKAnnotationsTablePresentationStyleModal){
        [self dismissViewControllerAnimated:YES completion:^{
            [self didDismissAnnotationsTable];
        }];
    }
    else{
        UITableView *tableView = self.annotationsTableView;
        [UIView animateWithDuration:0.3 animations:^{
            self.zeroHeightLayoutConstraint.priority = UILayoutPriorityDefaultHigh;
            self.proportionalHeightLayoutConstraint.priority = UILayoutPriorityDefaultLow;
            [tableView layoutIfNeeded]; // animate to the new frame
        }];
    }
}

- (void)viewDidLayoutSubviews {
    // iOS 9 fix, the problem was the bottomLayoutGuide was requested before the table's frame has changed to the new height after rotation.
    if(self.mvcLayoutGuide.tableHeight != self.annotationsTableView.frame.size.height){
        [self.mapView performSelector:@selector(setNeedsLayout) withObject:nil afterDelay:1];
    }
}

-(id<UILayoutSupport>)bottomLayoutGuide{
    
    id<UILayoutSupport> i = [super bottomLayoutGuide];

    self.mvcLayoutGuide.bottomAnchor = i.bottomAnchor;
    self.mvcLayoutGuide.topAnchor = i.topAnchor;
    self.mvcLayoutGuide.heightAnchor = i.heightAnchor;
    self.mvcLayoutGuide.bottomLayoutGuideLength = [i length];
    self.mvcLayoutGuide.tableHeight = self.annotationsTableView.frame.size.height;
    
    return self.mvcLayoutGuide;
}

- (void)presentAnnotationsTable{
    self.presentingAnnotationsTable = YES;
    
    UITableView *tableView = self.annotationsTableView;
    
    // create a default table if one wasn't set.
    if(!tableView){
        tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        //_annotationsTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.annotationsTableView = tableView;
    }
    
    // ensure we are the datasource and the delegate.
    tableView.dataSource = self;
    tableView.delegate = self;

    tableView.contentInset = UIEdgeInsetsZero; // fixes white gap that gets bigger every time its shown.
    tableView.scrollIndicatorInsets = UIEdgeInsetsZero; // fixes scroll indicators getting smaller and smaller.
    
    if(self.annotationsTablePresentationStyle == MMKAnnotationsTablePresentationStyleModal){
        UITableViewController *a = [[UITableViewController alloc] init];
        a.tableView = tableView;
        
        // todo check on this
        //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            a.clearsSelectionOnViewWillAppear = NO;
        //}
        
        //not needed because it inherits the tint from the nav controller's view.
        //if (_originatingNavigationController != nil) {
        // a.view.tintColor = _originatingNavigationController.topViewController.view.tintColor;
        //}
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            a.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonTapped:)];
        }
        //this tries to create an automatic title.
        //first try and get nav bar title
        a.title = self.navigationItem.title;
        //then try and get tab bar title
        if(!a.title){
            a.title = self.title;
            //then try if they set a title on this bar button item
            if(!a.title){
                a.title = self.annotationsTableBarButtonItem.title;
                //default to results
                if(!a.title){
                    a.title = @"Results";
                }
            }
        }
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:a];
        
        UINavigationController *originatingNavigationController = self.navigationController;
        if (originatingNavigationController != nil) {
            navigationController.toolbar.tintColor = originatingNavigationController.toolbar.tintColor;
            navigationController.navigationBar.barStyle = originatingNavigationController.navigationBar.barStyle;
            navigationController.navigationBar.translucent = originatingNavigationController.navigationBar.translucent;
            navigationController.navigationBar.tintColor = originatingNavigationController.navigationBar.tintColor;
            navigationController.extendedLayoutIncludesOpaqueBars = originatingNavigationController.extendedLayoutIncludesOpaqueBars;
            navigationController.view.tintColor = originatingNavigationController.view.tintColor;
        }
        
    //    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    //        self.popover = [[UIPopoverController alloc] initWithContentViewController:self.navigationController];
    //        [_popover presentPopoverFromBarButtonItem:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    //    }
    //    else{
    //        [containerViewController presentViewController:self.navigationController animated:YES completion:nil];
    //    }
    //    [self presentViewController:navigationController animated:YES completion:nil];
        [self showDetailViewController:navigationController sender:self];
    }
    else if(self.annotationsTablePresentationStyle == MMKAnnotationsTablePresentationStyleSheet){
        [self.view addSubview:tableView];
        if(!tableView.constraints.count){
            NSLayoutConstraint *leading = [tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor];
            NSLayoutConstraint *trailing = [tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor];
            NSLayoutConstraint *bottom = [tableView.bottomAnchor constraintEqualToAnchor:super.bottomLayoutGuide.topAnchor];
            //NSLayoutConstraint *bottom = [tableView.bottomAnchor constraintEqualToAnchor:self.mapView.bottomAnchor];
            
            // when presenting make it a proportion of the superview
            self.proportionalHeightLayoutConstraint = [tableView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:0.4];
            self.proportionalHeightLayoutConstraint.priority = UILayoutPriorityDefaultLow;
            
            // when hiding make it zero height.
            self.zeroHeightLayoutConstraint = [tableView.heightAnchor constraintEqualToConstant:0];
            self.zeroHeightLayoutConstraint.priority = UILayoutPriorityDefaultHigh;
            
            
            NSArray<NSLayoutConstraint*>* constraintsToActivate = @[leading, trailing, bottom, self.proportionalHeightLayoutConstraint, self.zeroHeightLayoutConstraint];
            [constraintsToActivate enumerateObjectsUsingBlock:^(NSLayoutConstraint * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.active = YES;
            }];
            tableView.translatesAutoresizingMaskIntoConstraints = NO;
            // show it in its initial hidden position.
            [tableView layoutIfNeeded];
            
            // since this is the first time also add the blurred background
            UIVisualEffectView* blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight]];
            blurView.frame = tableView.frame;
            blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            tableView.backgroundView = blurView;
            
            tableView.backgroundColor = [UIColor clearColor];
        }
        // present the table expanding from the bottom.
        [UIView animateWithDuration:0.3 animations:^{
            self.zeroHeightLayoutConstraint.priority = UILayoutPriorityDefaultLow;
            self.proportionalHeightLayoutConstraint.priority = UILayoutPriorityDefaultHigh;
            [tableView layoutIfNeeded]; // animate to the new frame
        }];
    }else{
        self.presentingAnnotationsTable = NO;
    }
}

- (void)willDismissAnnotationsTable{
    // default implementation does nothing
}

- (void)didDismissAnnotationsTable{
    // default implementation does nothing
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

// Category for requesting authorization
/*
@implementation MKMapView(Authorization)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(setShowsUserLocation:);
        SEL swizzledSelector = @selector(mh_setShowsUserLocation:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

#pragma mark - Method Swizzling

- (void)mh_setShowsUserLocation:(BOOL)showsUserLocation{
    if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        BOOL always = NO;
        if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]){
            always = YES;
        }
        else if(![[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]){
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Location usage description missing from Info.plist" userInfo:nil];
        }
        static CLLocationManager* lm = nil;
        static dispatch_once_t once;
        dispatch_once(&once, ^ {
            // Code to run once
            lm = [[CLLocationManager alloc] init];
        });
        if(always){
            [lm requestAlwaysAuthorization];
        }else{
            [lm requestWhenInUseAuthorization];
        }
    }
    [self mh_setShowsUserLocation:showsUserLocation];
}

@end
*/




