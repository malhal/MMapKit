#import "MKMapView+MMK.h"

#define MERCATOR_OFFSET 268435456
#define MERCATOR_RADIUS 85445659.44705395

@implementation MKMapView (MMK)

#pragma mark -
#pragma mark Map conversion methods

double longitudeToPixelSpaceX(double longitude)
{
    return round(MERCATOR_OFFSET + MERCATOR_RADIUS * longitude * M_PI / 180.0);
}

double latitudeToPixelSpaceY(double latitude)
{
	if (latitude == 90.0) {
		return 0;
	} else if (latitude == -90.0) {
		return MERCATOR_OFFSET * 2;
	} else {
		return round(MERCATOR_OFFSET - MERCATOR_RADIUS * logf((1 + sinf(latitude * M_PI / 180.0)) / (1 - sinf(latitude * M_PI / 180.0))) / 2.0);
	}
}

double pixelSpaceXToLongitude(double pixelX)
{
    return ((round(pixelX) - MERCATOR_OFFSET) / MERCATOR_RADIUS) * 180.0 / M_PI;
}

double pixelSpaceYToLatitude(double pixelY)
{
    return (M_PI / 2.0 - 2.0 * atan(exp((round(pixelY) - MERCATOR_OFFSET) / MERCATOR_RADIUS))) * 180.0 / M_PI;
}

#pragma mark -
#pragma mark Helper methods

- (MKCoordinateSpan)mmk_coordinateSpanWithMapView:(MKMapView *)mapView
                             centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                 andZoomLevel:(NSUInteger)zoomLevel
{
    //return  MKCoordinateSpanMake(0, 360/pow(2, zoomLevel)*mapView.frame.size.width/256);
    
    // convert center coordiate to pixel space
    double centerPixelX = longitudeToPixelSpaceX(centerCoordinate.longitude);
    double centerPixelY = latitudeToPixelSpaceY(centerCoordinate.latitude);
    
    // determine the scale value from the zoom level
    NSInteger zoomExponent = 20 - zoomLevel;
    double zoomScale = pow(2, zoomExponent);
    
    // scale the map’s size in pixel space
    CGSize mapSizeInPixels = mapView.bounds.size;
    double scaledMapWidth = mapSizeInPixels.width * zoomScale;
    double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
    // figure out the position of the top-left pixel
    double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    double topLeftPixelY = centerPixelY - (scaledMapHeight / 2);
    
    // find delta between left and right longitudes
    CLLocationDegrees minLng = pixelSpaceXToLongitude(topLeftPixelX);
    CLLocationDegrees maxLng = pixelSpaceXToLongitude(topLeftPixelX + scaledMapWidth);
    CLLocationDegrees longitudeDelta = maxLng - minLng;
    
    // find delta between top and bottom latitudes
    CLLocationDegrees minLat = pixelSpaceYToLatitude(topLeftPixelY);
    CLLocationDegrees maxLat =  pixelSpaceYToLatitude(topLeftPixelY + scaledMapHeight);
    CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
    // create and return the lat/lng span
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    return span;
}

#pragma mark -
#pragma mark Public methods

- (void)mmk_setCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate
                  zoomLevel:(NSUInteger)zoomLevel
                   animated:(BOOL)animated
{
    // clamp large numbers to 28
    zoomLevel = MIN(zoomLevel, 28);
    
    // use the zoom level to compute the region
    MKCoordinateSpan span = [self mmk_coordinateSpanWithMapView:self centerCoordinate:centerCoordinate andZoomLevel:zoomLevel];
    MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
    
    // set the region like normal
    [self setRegion:region animated:animated];
}

//KMapView cannot display tiles that cross the pole (as these would involve wrapping the map from top to bottom, something that a Mercator projection just cannot do).
- (MKCoordinateRegion)mmk_coordinateRegionWithMapView:(MKMapView *)mapView
                                centerCoordinate:(CLLocationCoordinate2D)centerCoordinate
                                    andZoomLevel:(NSUInteger)zoomLevel
{
	// clamp lat/long values to appropriate ranges
	centerCoordinate.latitude = MIN(MAX(-90.0, centerCoordinate.latitude), 90.0);
	centerCoordinate.longitude = fmod(centerCoordinate.longitude, 180.0);
    
	// convert center coordiate to pixel space
	double centerPixelX = longitudeToPixelSpaceX(centerCoordinate.longitude);
	double centerPixelY = latitudeToPixelSpaceY(centerCoordinate.latitude);
    
	// determine the scale value from the zoom level
	NSInteger zoomExponent = 20 - zoomLevel;
	double zoomScale = pow(2, zoomExponent);
    
	// scale the map’s size in pixel space
	CGSize mapSizeInPixels = mapView.bounds.size;
	double scaledMapWidth = mapSizeInPixels.width * zoomScale;
	double scaledMapHeight = mapSizeInPixels.height * zoomScale;
    
	// figure out the position of the left pixel
	double topLeftPixelX = centerPixelX - (scaledMapWidth / 2);
    
	// find delta between left and right longitudes
	CLLocationDegrees minLng = pixelSpaceXToLongitude(topLeftPixelX);
	CLLocationDegrees maxLng = pixelSpaceXToLongitude(topLeftPixelX + scaledMapWidth);
	CLLocationDegrees longitudeDelta = maxLng - minLng;
    
	// if we’re at a pole then calculate the distance from the pole towards the equator
	// as MKMapView doesn’t like drawing boxes over the poles
	double topPixelY = centerPixelY - (scaledMapHeight / 2);
	double bottomPixelY = centerPixelY + (scaledMapHeight / 2);
	BOOL adjustedCenterPoint = NO;
	if (topPixelY > MERCATOR_OFFSET * 2) {
		topPixelY = centerPixelY - scaledMapHeight;
		bottomPixelY = MERCATOR_OFFSET * 2;
		adjustedCenterPoint = YES;
	}
    
	// find delta between top and bottom latitudes
	CLLocationDegrees minLat = pixelSpaceYToLatitude(topPixelY);
	CLLocationDegrees maxLat = pixelSpaceYToLatitude(bottomPixelY);
	CLLocationDegrees latitudeDelta = -1 * (maxLat - minLat);
    
	// create and return the lat/lng span
	MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
	MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
	// once again, MKMapView doesn’t like drawing boxes over the poles
	// so adjust the center coordinate to the center of the resulting region
	if (adjustedCenterPoint) {
		region.center.latitude = pixelSpaceYToLatitude((bottomPixelY + topPixelY) / 2.0);
	}
    
	return region;
}

- (double)mmk_zoomLevel {
    MKCoordinateRegion region = self.region;
    
    double centerPixelX = longitudeToPixelSpaceX(region.center.longitude);
    double topLeftPixelX = longitudeToPixelSpaceX(region.center.longitude - region.span.longitudeDelta / 2);
    
    double scaledMapWidth = (centerPixelX - topLeftPixelX) * 2;
    CGSize mapSizeInPixels = self.bounds.size;
    double zoomScale = scaledMapWidth / mapSizeInPixels.width;
    double zoomExponent = log(zoomScale) / log(2);
    double zoomLevel = 20 - zoomExponent;
    
    return zoomLevel;
}

//this is NO for backwards compat
-(void)mmk_setVisibleMapRectToAnnotations{
    [self mmk_setVisibleMapRectToAnnotationsAnimated:NO];
}

-(void)mmk_setVisibleMapRectToAnnotationsAnimated:(BOOL)animated{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in self.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    // add extra padding round edges
    [self setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(10, 10, 10, 10) animated:YES];
}

@end
