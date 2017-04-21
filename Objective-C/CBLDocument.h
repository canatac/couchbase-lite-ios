//
//  CBLDocument.h
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 12/29/16.
//  Copyright © 2016 Couchbase. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CBLReadOnlyDocument.h"
#import "CBLDictionary.h"
@class CBLDatabase;
@protocol CBLConflictResolver;

NS_ASSUME_NONNULL_BEGIN

/** A Couchbase Lite document.
    A document has key/value properties like an NSDictionary; their API is defined by the
    protocol CBLProperties. To learn how to work with properties, see that protocol's
    documentation. */
@interface CBLDocument : CBLReadOnlyDocument <CBLDictionary>

/**  */
- (instancetype) init;

/**  */
- (instancetype) initWithID: (NSString*)documentID;

@end

/** Define Subscription methods for CBLDocument. */
@interface CBLDocument (Subscripts)

/** Same as objectForKey: */
 - (nullable id) objectForKeyedSubscript: (NSString*)key;

/** Same as setObject:forKey: */
 - (void) setObject: (nullable id)value forKeyedSubscript: (NSString*)key;

@end

NS_ASSUME_NONNULL_END
