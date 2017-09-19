//
//  MMKDefines+Namespace.h
//  MMapKit
//
//  Generated using MHNamespaceGenerator on 19/09/2017
//

#if !defined(__MMAPKIT_NAMESPACE_APPLY) && defined(MMAPKIT_NAMESPACE) && defined(MMAPKIT_NAMESPACE_LOWER)
    #define __MMAPKIT_NAMESPACE_REWRITE(ns, s) ns ## _ ## s
    #define __MMAPKIT_NAMESPACE_BRIDGE(ns, s) __MMAPKIT_NAMESPACE_REWRITE(ns, s)
    #define __MMAPKIT_NAMESPACE_APPLY(s) __MMAPKIT_NAMESPACE_BRIDGE(MMAPKIT_NAMESPACE, s)
	#define __MMAPKIT_NAMESPACE_APPLY_LOWER(s) __MMAPKIT_NAMESPACE_BRIDGE(MMAPKIT_NAMESPACE_LOWER, s)
// Classes
    #define MMKAnnotationSegue __MMAPKIT_NAMESPACE_APPLY(MMKAnnotationSegue)
    #define MMKAnnotationsTableBarButtonItem __MMAPKIT_NAMESPACE_APPLY(MMKAnnotationsTableBarButtonItem)
    #define MMKEmptySegue __MMAPKIT_NAMESPACE_APPLY(MMKEmptySegue)
    #define MMKFetchedResultsMapViewController __MMAPKIT_NAMESPACE_APPLY(MMKFetchedResultsMapViewController)
    #define MMKMapTypeBarButtonItem __MMAPKIT_NAMESPACE_APPLY(MMKMapTypeBarButtonItem)
    #define MMKMapViewController __MMAPKIT_NAMESPACE_APPLY(MMKMapViewController)
    #define MMKMapViewControllerLayoutGuide __MMAPKIT_NAMESPACE_APPLY(MMKMapViewControllerLayoutGuide)
// Categories
    #define MMK __MMAPKIT_NAMESPACE_APPLY(MMK)
    #define mmk_coordinateRegionWithMapView __MMAPKIT_NAMESPACE_APPLY_LOWER(mmk_coordinateRegionWithMapView)
    #define mmk_coordinateSpanWithMapView __MMAPKIT_NAMESPACE_APPLY_LOWER(mmk_coordinateSpanWithMapView)
    #define mmk_predicateWithCoordinateRegion __MMAPKIT_NAMESPACE_APPLY_LOWER(mmk_predicateWithCoordinateRegion)
    #define mmk_setCenterCoordinate __MMAPKIT_NAMESPACE_APPLY_LOWER(mmk_setCenterCoordinate)
    #define mmk_zoomLevel __MMAPKIT_NAMESPACE_APPLY_LOWER(mmk_zoomLevel)
// Externs
#endif
