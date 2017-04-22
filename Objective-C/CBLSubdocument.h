//
//  CBLSubdocument.h
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 4/11/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBLDictionary.h"
#import "CBLReadOnlySubdocument.h"

NS_ASSUME_NONNULL_BEGIN

@interface CBLSubdocument : CBLReadOnlySubdocument <CBLDictionary>

+ (instancetype) subdocument;

- (instancetype) init;

- (instancetype) initWithDictionary: (NSDictionary<NSString*,id>*)dictionary;

@end

NS_ASSUME_NONNULL_END
