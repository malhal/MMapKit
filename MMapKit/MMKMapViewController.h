//
//  MapViewController.h
//  MMapKit
//
//  Created by Malcolm Hall on 10/11/13.
//  Copyright (c) 2013 Malcolm Hall. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MMapKit/MMKDefines.h>

NS_ASSUME_NONNULL_BEGIN

//Create a navigation based app.
//In the storyboard delete the master (table) view controller.
//Drag in a view controller and hook it up as the root in the navigation controlller.
//On navigation controller also check "Shows toolbar".
//In code change MasterViewController to be a subclass of MMKMapViewController and delete all table code.
//That's it!

// To show a detail view controller when tapping the callout accessory or list view disclosure button,
// Add the new view controller and control drag from the map controller to the new one,
// Choose 'annotation detail' segue and set the identifer showAnnotation, class MMKAnnotationSegue, kind Custom.
// If this is not configured correctly then the annotation view disclosure button and table accessory will not appear when running in private API mode.

typedef NS_ENUM(NSInteger, MMKannotationsTablePresentationStyle) {
    MMKAnnotationsTablePresentationStyleModal,
    MMKAnnotationsTablePresentationStyleSheet
};

MMapKit_EXTERN NSString * const MHShowAnnotationSegueIdentifier; // The default is 'showAnnotation' so set that identifier in the storyboard manual segue.
MMapKit_EXTERN NSString * const MHAnnotationCellIdentifier; // To use a custom cell in the table view that is hooked up to the outlet use the identifier 'annotation'

@class MMKMapTypeBarButtonItem;

@interface MMKMapViewController : UIViewController<MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong, readonly) MKMapView *mapView;

@property (nonatomic, strong, readonly) MKUserTrackingBarButtonItem *userTrackingBarButtonItem;

@property (nonatomic, strong, readonly) MMKMapTypeBarButtonItem *mapTypeBarButtonItem;

@property (nonatomic, strong, readonly) UIBarButtonItem *annotationsTableBarButtonItem;

// contains the arrow, map type segmented and annotation table, with appropriate spacers.
@property (nonatomic, strong, readonly) NSArray<UIBarButtonItem *> *defaultToolBarItems;

// defaults to "Annotation"
@property (nonatomic, copy) NSString *annotationReuseIdentifier;

// a default table view will be created if one isn't set in the storyboard, hence strong.
@property (nonatomic, weak) IBOutlet UITableView *annotationsTableView;

// if this is changed while the table is presented the behavior is undefined.
@property (nonatomic, assign) MMKannotationsTablePresentationStyle annotationsTablePresentationStyle;

- (void)presentAnnotationsTable;

- (void)dismissAnnotationsTable;

// tapping the callout disclousure on a annotation view or the table cell accessory calls this. The default implementation calls performSegueWithIdentifier:MHShowAnnotationDetailSegueIdentifier
// and catches the exception if it doesn't exist.
- (void)showDetailForAnnotation:(id<MKAnnotation>)annotation;

// override to customise the detail controller. Internally this uses prepareForSegue so if you override that then you must call super.
- (void)prepareForAnnotationDetailViewController:(UIViewController *)viewController annotation:(id<MKAnnotation>)annotation;

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender NS_REQUIRES_SUPER;

// inserts to table then adds to map. The annotation must have been added to annotations before calling these methods.
- (void)insertAnnotationsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
- (void)deleteAnnotationsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;
//- (void)reloadAnnotationsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (void)reloadData;

// the default is nil
- (id<MKAnnotation>)annotationAtIndex:(NSUInteger)index;
// the default is 0
- (NSUInteger)indexOfAnnotation:(id<MKAnnotation>)annotation;
// the default is 0
- (NSInteger)numberOfAnnotations;
// the default is nil
- (UITableViewCell *)cellForAnnotation:(id<MKAnnotation>)annotation;

@end

NS_ASSUME_NONNULL_END
