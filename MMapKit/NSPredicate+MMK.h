//
//  NSPredicate+Region.h
//  MMapKit
//
//  Created by Malcolm Hall on 26/04/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <MMapKit/MMKDefines.h>

@interface NSPredicate (MMK)

+ (NSPredicate *)mmk_predicateWithCoordinateRegion:(MKCoordinateRegion)region;
+ (NSPredicate *)mmk_predicateWithCoordinateRegion:(MKCoordinateRegion)region keyPrefix:(NSString *)keyPrefix;

@end
