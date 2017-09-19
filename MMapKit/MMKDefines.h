//
//  MCLDefines.h
//  MMapKit
//
//  Created by Malcolm Hall on 13/10/2016.
//  Copyright © 2016 Malcolm Hall. All rights reserved.
//

#ifndef MMapKit_EXTERN
    #ifdef __cplusplus
        #define MMapKit_EXTERN   extern "C" __attribute__((visibility ("default")))
    #else
        #define MMapKit_EXTERN   extern __attribute__((visibility ("default")))
    #endif
#endif

#ifndef MMapKit_USE_PRIVATE_API
    #define MMapKit_USE_PRIVATE_API 1
#endif

#import <MMapKit/MMKDefines+Namespace.h>
