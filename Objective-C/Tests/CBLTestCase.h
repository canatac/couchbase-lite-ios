//
//  CBLTestCase.h
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 1/10/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CouchbaseLite.h"

#define Assert             XCTAssert
#define AssertNil          XCTAssertNil
#define AssertNotNil       XCTAssertNotNil
#define AssertEqual        XCTAssertEqual
#define AssertEqualObjects XCTAssertEqualObjects
#define AssertFalse        XCTAssertFalse

#define Log                NSLog
#define Warn(FMT, ...)     NSLog(@"WARNING: " FMT, ##__VA_ARGS__)

@interface CBLTestCase : XCTestCase {
@protected
    CBLDatabase* _db;
}

@property (readonly, atomic) CBLDatabase* db;

- (CBLDatabase*) openDBNamed: (NSString*)name;

- (void) reopenDB;

/** Create a new document with the given document ID. */
- (CBLDocument*) createDocument: (NSString*)documentID;

/** Create a new document with the given document ID and dictionary content. */
- (CBLDocument*) createDocument:(NSString *)documentID dictionary: (NSDictionary*)dictionary;

/** Save a document return a new instance of the document from the database. */
- (CBLDocument*) saveDocument: (CBLDocument*)document;

/** Save a document return a new instance of the document from the database. The eval block
 will be called twice before save and after save. When calling the eval block after save, 
 the new instance of the document will be given. */
- (CBLDocument*) saveDocument: (CBLDocument*)doc eval: (void(^)(CBLDocument*))block;

/** Reads a bundle resource file into an NSData. */
- (NSData*) dataFromResource: (NSString*)resourceName ofType: (NSString*)type;

/** Reads a bundle resource file into an NSString. */
- (NSString*) stringFromResource: (NSString*)resourceName ofType: (NSString*)type;

/** Loads the database with documents read from a JSON resource file in the test bundle.
    Each line of the file should be a complete JSON object, which will become a document.
    The document IDs will be of the form "doc-#" where "#" is the line number, starting at 1. */
- (void) loadJSONResource: (NSString*)resourceName;

@end
