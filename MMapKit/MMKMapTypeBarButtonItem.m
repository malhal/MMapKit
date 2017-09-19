//
//  MMKMapTypeBarButtonItem.m
//  MMapKit
//
//  Created by Malcolm Hall on 11/11/13.
//  Copyright (c) 2013 Malcolm Hall. All rights reserved.
//

#import "MMKMapTypeBarButtonItem.h"

static void * const kMMKMapTypeBarButtonItemContext = (void *)&kMMKMapTypeBarButtonItemContext;

@interface MMKMapTypeBarButtonItem()

@property (nonatomic, assign) BOOL ignoreChange;

@end

@implementation MMKMapTypeBarButtonItem

- (id)initWithMapView:(MKMapView *)mapView{
    self = [super init];
    if (self) {
        _mapView = mapView;
        
        UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"Standard", @"Hybrid", @"Satellite"]];
        //sc.autoresizingMask = UIViewAutoresizingFlexibleWidth; // width can go to zero when rotating from landscape
        [sc addTarget:self action:@selector(mapTypeSegmentChanged:) forControlEvents:UIControlEventValueChanged];
        self.customView = sc;
        //listen for changes to the map's type
        [mapView addObserver:self forKeyPath:NSStringFromSelector(@selector(mapType))
                     options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                     context:kMMKMapTypeBarButtonItemContext];

        //just set the segment to the current map type.
        int i = self.mapView.mapType;
        if(i > 0){
            //trick to switch order of satellite and hybrid
            i = (i % 2) + 1;
        }
        sc.selectedSegmentIndex = i;
    }
    return self;
}

- (void)mapTypeSegmentChanged:(UISegmentedControl *)sender {
    
    NSInteger i = sender.selectedSegmentIndex;
    if(i > 0){
        //trick to switch order of satellite and hybrid
        i = (i % 2) + 1;
    }
    
    // update the map preventing it from changing the segment index.
    self.ignoreChange = YES;
    self.mapView.mapType = i;
    self.ignoreChange = NO;
    
    // forward the action to the buttons target.
    if([self.target respondsToSelector:self.action]){
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.target performSelector:self.action withObject:self];
#pragma clang diagnostic pop
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // if it was our observation
    if(context == kMMKMapTypeBarButtonItemContext){
        if (!self.ignoreChange){
            UISegmentedControl* s = (UISegmentedControl*)self.customView;
            int i = self.mapView.mapType;
            if(i > 0){
                //trick to switch order of satellite and hybrid
                i = (i % 2) + 1;
            }
            s.selectedSegmentIndex = i;
        }
    }else{
        // if necessary, pass the method up the subclass hierarchy.
        if([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]){
            [super observeValueForKeyPath:keyPath
                                 ofObject:object
                                   change:change
                                  context:context];
        }
    }
}

- (void)dealloc
{
    [_mapView removeObserver:self forKeyPath:NSStringFromSelector(@selector(mapType))];
}



@end
