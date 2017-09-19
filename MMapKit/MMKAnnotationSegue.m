//
//  MHMapViewSegue.m
//  MMapKit
//
//  Created by Malcolm Hall on 20/07/2015.
//  Copyright (c) 2015 Malcolm Hall. All rights reserved.
//

#import "MMKAnnotationSegue.h"

@implementation MMKAnnotationSegue

// this changes from the map controllers nav controller to the table controllers nav controller if the table is showing.
- (void)perform
{
    UIViewController *source = (UIViewController *)self.sourceViewController;
    UINavigationController* nav = source.navigationController;
    // use the modal navigation controller instead
    if(source.presentedViewController){
        nav = (UINavigationController *)source.presentedViewController;
    }
    [nav pushViewController:self.destinationViewController animated:YES];
}

@end
