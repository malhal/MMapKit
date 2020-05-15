//
//  MKMapView+MMK.h
//  MMapKit
//
//  Created by Malcolm Hall on 20/04/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <MMapKit/MMKDefines.h>

@interface MKMapView (MMK)

- (void)mmk_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated;

- (MKCoordinateRegion)mmk_coordinateRegionWithMapView:(MKMapView *)mapView
                                centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                    andZoomLevel:(NSUInteger)zoomLevel;

- (double)mmk_zoomLevel;

- (void)mmk_setVisibleMapRectToAnnotations;
- (void)mmk_setVisibleMapRectToAnnotationsAnimated:(BOOL)animated;

@end
