//
//  MMKAnnotationsTableBarButtonItem.h
//  MMapKit
//
//  Created by Malcolm Hall on 20/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

// This gives you a button you can put on a map view view controller that gives a modal table view of the map annotations.
// just add self.mapView.annotationsTableButtonItem to the toolbar items array.
// then implement the delegate.

//Note: mapView viewForAnnotation is used to attempt to get an image to use, however if the marker is not on the map then this is not possible, so be sure to implement the imageForAnnotation delegate to ensure there is always an image.

/*
 
 //This is an example of yhow you can push the details table onto the annotations table when the info accessory is tapped while the modal table is up.
 
 //You must check the type of the control when deciding which navigation controller to push on. When the accessory in the table view was tapped, it fires this same delegate except the control param is the bar button item. So you can cast that to the button item and then get the navigation controller it is using for the table.
 
 - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
 
    NearbyDetailsViewController* n = [[NearbyDetailsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    n.hotspot = view.annotation;
    if(view.rightCalloutAccessoryView == control){
        //came from the map annotation
        [self.navigationController pushViewController:n animated:YES];
    }else{
        //came from the accessory on the table cell in the annotations table 
        DLAnnotationsTableBarButtonItem* a = (DLAnnotationsTableBarButtonItem*)control;
        [a.navigationController pushViewController:n animated:YES];
 }
 }
 
 */

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MMapKit/MMKDefines.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MMKAnnotationsTableBarButtonItemDelegate;

@interface MMKAnnotationsTableBarButtonItem : UIBarButtonItem

- (instancetype)initWithMapView:(MKMapView *)mapView image:(nullable UIImage *)image;

//uses private kitImageNamed: UIButtonBarListIcon
- (instancetype)initWithMapView:(MKMapView *)mapView;

@property (nonatomic, strong) MKMapView *mapView;

@property (nonatomic, strong, readonly) UINavigationController *navigationController;

@end

@protocol MKMapViewAnnotationsTableDelegate <MKMapViewDelegate>

@optional
//supply a custom set of annotations e.g. an array removing the MKUserLocationAnnotation
- (NSArray *)annotationsForAnnotationsTableViewController:(UITableViewController *)tableViewController;

//supply an image for the annotation to support showing images for off-map annotation views.
- (UIImage *)imageForAnnotation:(id<MKAnnotation>)annotation;

@end

NS_ASSUME_NONNULL_END
