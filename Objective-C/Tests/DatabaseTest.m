//
//  DatabaseTest.m
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 1/10/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLTestCase.h"
#import "CBLInternal.h"


@interface DatabaseTest : CBLTestCase
@end

@implementation DatabaseTest


- (CBLDatabase*) openDatabase: (NSString*)dbName{
    NSError* error;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: dbName error: &error];
    AssertNil(error);
    AssertNotNil(db, @"Couldn't open db: %@", error);
    AssertEqualObjects(dbName, db.name);
    Assert([db.path.lastPathComponent hasSuffix: @".cblite2"]);
    AssertEqual(0, (long)db.documentCount);
    return db;
}


// hellper method to delete database
- (void)deleteDatabase: (CBLDatabase *)db {
    NSError* error;
    NSString* path = db.path;
    Assert([[NSFileManager defaultManager] fileExistsAtPath: path]);
    Assert([db deleteDatabase:&error]);
    AssertNil(error);
    AssertFalse([[NSFileManager defaultManager] fileExistsAtPath: path]);
}


// helper method to close database
- (void)closeDatabase: (CBLDatabase*)db{
    NSError* error;
    Assert([db close:&error]);
    AssertNil(error);
}


// helper method to save document
- (CBLDocument*) generateDocument: (NSString*)docID {
    CBLDocument* doc = [self createDocument: docID];
    [doc setObject:@1 forKey:@"key"];
    
    [self saveDocument: doc];
    AssertEqual(1, (long)self.db.documentCount);
    AssertEqual(1L, (long)doc.sequence);
    return doc;
}


// helper method to store Blob
- (void) storeBlob: (CBLDatabase*)db doc: (CBLDocument*)doc content: (NSData*)content {
    CBLBlob* blob = [[CBLBlob alloc] initWithContentType: @"text/plain" data: content];
    [doc setObject: blob forKey: @"data"];
    [self saveDocument: doc];
}


// helper methods to verify getDoc
- (void) verifyGetDocument: (NSString*)docID {
    [self verifyGetDocument: docID value: 1];
}


- (void) verifyGetDocument: (NSString*)docID value: (int)value {
    [self verifyGetDocument: self.db docID: docID value: value];
}


- (void) verifyGetDocument: (CBLDatabase*)db docID: (NSString*)docID {
    [self verifyGetDocument: self.db docID: docID value: 1];
}


- (void) verifyGetDocument: (CBLDatabase*)db docID: (NSString*)docID value: (int)value {
    CBLDocument* doc = [db documentWithID: docID];
    AssertNotNil(doc);
    AssertEqualObjects(docID, doc.documentID);
    AssertFalse(doc.isDeleted);
    AssertEqualObjects(@(value), [doc objectForKey: @"key"]);
}


// helper method to save n number of docs
- (void) createDocs: (int)n {
    for(int i = 0; i < n; i++){
        CBLDocument* doc = [self createDocument: [NSString stringWithFormat: @"doc_%03d", i]];
        [doc setObject: @(i) forKey:@"key"];
        [self saveDocument: doc];
    }
    AssertEqual(n, (long)self.db.documentCount);
}


- (void)validateDocs: (int)n {
    for (int i = 0; i < n; i++) {
        [self verifyGetDocument: [NSString stringWithFormat: @"doc_%03d", i] value: i];
    }
}


// helper method to purge doc and verify doc.
- (void) purgeDocAndVerify: (CBLDocument*)doc {
    NSError* error;
    NSString* docID = doc.documentID;
    Assert([self.db purgeDocument: doc error: &error]);
    AssertNil(error);
    AssertEqualObjects(docID, doc.documentID); // docID should be same
    AssertEqual(0L, (long)doc.sequence);       // sequence should be reset to 0
    AssertFalse(doc.isDeleted);                // delete flag should be reset to true
    AssertNil([doc objectForKey:@"key"]);      // content should be empty
}


// helper method to check error
- (void)checkError: (NSError*)error domain: (NSErrorDomain)domain code: (NSInteger)code {
    AssertNotNil(error);
    AssertEqualObjects(domain, error.domain);
    AssertEqual(code, error.code);
}


#pragma mark - Create Database


- (void) testCreate {
    // create db with default
    CBLDatabase* db =  [self openDatabase: @"db"];
    AssertNotNil(db);
    AssertEqual(0, (long)db.documentCount);
    
    // delete database
    [self deleteDatabase: db];
}


- (void) testCreateWithDefaultOption {
    // create db with default options
    NSError* error;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db"
                                                options: [CBLDatabaseOptions defaultOptions]
                                                  error: &error];
    AssertNil(error);
    AssertNotNil(db, @"Couldn't open db: %@", error);
    AssertEqualObjects(db.name, @"db");
    Assert([db.path.lastPathComponent hasSuffix: @".cblite2"]);
    AssertEqual(0, (long)db.documentCount);
    
    // delete database
    [self deleteDatabase: db];
}


- (void) testCreateWithSpecialCharacterDBNames {
    // create db with default options
    NSError* error;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"`~@#$%^&*()_+{}|\\][=-/.,<>?\":;'"
                                                options: [CBLDatabaseOptions defaultOptions]
                                                  error: &error];
    AssertNil(error);
    AssertNotNil(db, @"Couldn't open db: %@", error);
    AssertEqualObjects(db.name, @"`~@#$%^&*()_+{}|\\][=-/.,<>?\":;'");
    Assert([db.path.lastPathComponent hasSuffix: @".cblite2"]);
    AssertEqual(0, (long)db.documentCount);
    
    // delete database
    [self deleteDatabase: db];
}


- (void) testCreateWithEmpttyDBNames {
    // create db with default options
    NSError* error;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @""
                                                options: [CBLDatabaseOptions defaultOptions]
                                                  error: &error];
    [self checkError: error domain: @"LiteCore" code: 30]; // kC4ErrorWrongFormat
    AssertNil(db, @"Should be fail to open db: %@", error);
}


- (void) testCreateWithCustomDirectory {
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    [CBLDatabase deleteDatabase: @"db" inDirectory: dir error: nil];
    
    AssertFalse([CBLDatabase databaseExists: @"db" inDirectory: dir]);
    
    // create db with custom directory
    NSError* error;
    CBLDatabaseOptions* options = [CBLDatabaseOptions defaultOptions];
    options.directory = dir;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db"
                                                options: options
                                                  error: &error];
    AssertNil(error);
    AssertNotNil(db, @"Couldn't open db: %@", error);
    AssertEqualObjects(db.name, @"db");
    Assert([db.path.lastPathComponent hasSuffix: @".cblite2"]);
    Assert([db.path containsString: dir]);
    Assert([CBLDatabase databaseExists: @"db" inDirectory: dir]);
    AssertEqual(0, (long)db.documentCount);

    // delete database
    [self deleteDatabase: db];
}


- (void) testCreateWithCustomConflictResolver {
    // TODO: DatabaseConfiguration.conflictResolver is not implemented yet.
}


#pragma mark - Get Document


- (void) testGetNonExistingDocWithID {
    AssertNil([self.db documentWithID:@"non-exist"]);
}


- (void) testGetExistingDocWithID {
    NSString* docID = @"doc1";
    
    // store doc
    [self generateDocument: docID];
    
    // validate document by getDocument.
    [self verifyGetDocument: docID];
}


- (void) testGetExistingDocWithIDFromDifferentDBInstance {
    NSString* docID = @"doc1";
    
    // store doc
    [self generateDocument: docID];
    
    // open db with same db name and default option
    CBLDatabase* otherDB = [self openDBNamed: [self.db name]];
    XCTAssertNotEqual(self.db, otherDB);
    
    // get doc from other DB.
    AssertEqual(1, (long)otherDB.documentCount);
    Assert([otherDB documentExists:docID]);
    
    [self verifyGetDocument: otherDB docID: docID];
    
    // close otherDB
    [self closeDatabase: otherDB];
}


- (void) testGetExistingDocWithIDInBatch {
    // save 10 docs
    [self createDocs: 10];
    
    // validate
    NSError* error;
    BOOL success = [self.db inBatch: &error do: ^{
        [self validateDocs: 10];
    }];
    Assert(success);
    AssertNil(error);
}


// TODO: crash in native layer
- (void) CRASH_testGetDocToClosedDB {
    // store doc
    [self generateDocument: @"doc1"];
    
    // close db
    [self closeDatabase: self.db];
    
    CBLDocument* doc = [self.db documentWithID: @"doc1"];
    AssertNil(doc);
}


// TODO: crash in native layer
- (void) CRASH_testGetDocToDeletedDB {
    // store doc
    [self generateDocument: @"doc1"];
    
    // delete db
    [self deleteDatabase: self.db];
    
    CBLDocument* doc = [self.db documentWithID: @"doc1"];
    AssertNil(doc);
}


#pragma mark - Save Document


- (void) _testSaveNewDocWithID: (NSString*)docID {
    // store doc
    [self generateDocument: docID];
    
    AssertEqual(1, (long)self.db.documentCount);
    Assert([self.db documentExists: docID]);
    
    // validate doc
    [self verifyGetDocument: docID];
}


- (void) testSaveNewDocWithID {
    [self _testSaveNewDocWithID: @"doc1"];
}


- (void) testSaveNewDocWithSpecialCharactersDocID {
    [self _testSaveNewDocWithID: @"`~@#$%^&*()_+{}|\\][=-/.,<>?\":;'"];
}


- (void) testSaveDoc {
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // update doc
    [doc setObject:@2 forKey:@"key"];
    [self saveDocument: doc];
    
    AssertEqual(1, (long)self.db.documentCount);
    Assert([self.db documentExists: docID]);
    
    // verify
    [self verifyGetDocument: docID value: 2];
}


- (void) testSaveDocInDifferentDBInstance {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db with default
    CBLDatabase* otherDB = [self openDBNamed: [self.db name]];
    AssertEqual(1, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    // update doc & store it into different instance
    [doc setObject: @2 forKey: @"key"];
    AssertFalse([otherDB saveDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
    
    // close otherDB
    [self closeDatabase: otherDB];
}


// TODO: DB close & delete operation causes internal error with transaction level.
- (void) CRASH_testSaveDocInDifferentDB {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db with default
    CBLDatabase* otherDB =  [self openDatabase:@"otherDB"];
    AssertEqual(0, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    // update doc & store it into different db
    [doc setObject: @2 forKey: @"key"];
    AssertFalse([otherDB saveDocument: doc error: &error]);
    [self checkError: error domain:@"CouchbaseLite" code: 403]; // forbidden
    
    // close otherDB
    [self closeDatabase: otherDB];
    
    // delete otherDB
    [self deleteDatabase: otherDB];
}


- (void) testSaveSameDocTwice {
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // second store
    [self saveDocument: doc];
    
    AssertEqualObjects(docID, doc.documentID);
    AssertEqual(1, (long)self.db.documentCount);
}


- (void) testSaveInBatch {
    NSError* error;
    BOOL success = [self.db inBatch: &error do: ^{
        // save 10 docs
        [self createDocs: 10];
    }];
    Assert(success);
    AssertEqual(10, (long)self.db.documentCount);
    
    [self validateDocs: 10];
}


// TODO: cause crash
- (void) CRASH_testSaveDocToClosedDB {
    NSError* error;
    
    // close db
    [self closeDatabase: self.db];
    
    CBLDocument* doc = [self createDocument: @"doc1"];
    [doc setObject:@1 forKey:@"key"];
    
    AssertFalse([self.db saveDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


// TODO: cause crash
- (void) CRASH_testSaveDocToDeletedDB {
    NSError* error;
    
    // delete db
    [self deleteDatabase: self.db];
    
    CBLDocument* doc = [self createDocument: @"doc1"];
    [doc setObject: @1 forKey: @"key"];
    AssertFalse([self.db saveDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


#pragma mark - Delete Document


- (void) testDeletePreSaveDoc {
    NSError* error;
    CBLDocument* doc = [self createDocument: @"doc1"];
    [doc setObject: @1 forKey: @"key"];
    
    AssertFalse([self.db deleteDocument: doc error: &error]);
    [self checkError:error domain: @"LiteCore" code: 12]; // Not Found
    AssertEqual(0, (long)self.db.documentCount);
}


- (void) testDeleteDoc {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    Assert([self.db deleteDocument: doc error: &error]);
    AssertNil(error);
    AssertEqual(0, (long)self.db.documentCount);
    
    AssertEqualObjects(docID, doc.documentID);
    Assert(doc.isDeleted);
    AssertEqual(2, (int)doc.sequence);
    AssertNil([doc objectForKey: @"key"]);
}


- (void) testDeleteDocInDifferentDBInstance {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db with same name
    CBLDatabase* otherDB = [self openDBNamed: [self.db name]];
    Assert([otherDB documentExists:docID]);
    AssertEqual(1, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    AssertFalse([otherDB deleteDocument: doc error: &error]);
    [self checkError:error domain: @"CouchbaseLite" code: 403]; // forbidden
    
    AssertEqual(1, (long)otherDB.documentCount);
    AssertEqual(1, (long)self.db.documentCount);
    AssertFalse(doc.isDeleted);
    
    // close otherDB
    [self closeDatabase: otherDB];
}


- (void)CRASH_testDeleteDocInDifferentDB {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db with different name
    CBLDatabase* otherDB = [self openDatabase: @"otherDB"];
    AssertFalse([otherDB documentExists: docID]);
    AssertEqual(0, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    AssertFalse([otherDB deleteDocument: doc error: &error]);
    [self checkError:error domain: @"CouchbaseLite" code: 403]; // forbidden
    
    AssertEqual(0, (long)otherDB.documentCount);
    AssertEqual(1, (long)self.db.documentCount);
    
    AssertFalse(doc.isDeleted);
    
    // close otherDB
    [self closeDatabase: otherDB];
    // delete otherDB
    [self deleteDatabase: otherDB];
}


- (void) testDeleteSameDocTwice {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument:docID];
    
    // first time deletion
    Assert([self.db deleteDocument: doc error: &error]);
    AssertNil(error);
    AssertEqual(0, (long)self.db.documentCount);
    AssertNil([doc objectForKey: @"key"]);
    AssertEqual(2, (int)doc.sequence);
    Assert(doc.isDeleted);
    
    // second time deletion
    Assert([self.db deleteDocument: doc error: &error]);
    AssertNil(error);
    AssertEqual(0, (long)self.db.documentCount);
    AssertNil([doc objectForKey: @"key"]);
    AssertEqual(3, (int)doc.sequence);
    Assert(doc.isDeleted);
}


- (void) testDeleteDocInBatch {
    // save 10 docs
    [self createDocs: 10];
    
    NSError* error;
    BOOL success = [self.db inBatch: &error do: ^{
        for(int i = 0; i < 10; i++){
            NSError* err;
            NSString* docID = [[NSString alloc] initWithFormat: @"doc_%03d", i];
            CBLDocument* doc = [self.db documentWithID: docID];
            Assert([self.db deleteDocument: doc error: &err]);
            AssertNil(err);
            AssertNil([doc objectForKey: @"key"]);
            Assert(doc.isDeleted);
            AssertEqual(9 - i, (long)self.db.documentCount);
        }
    }];
    Assert(success);
    AssertNil(error);
    AssertEqual(0, (long)self.db.documentCount);
}


// TODO: cause crash
- (void)CRASH_testDeleteDocToClosedDB {
    NSError* error;

    // store doc
    CBLDocument* doc = [self generateDocument: @"doc1"];
    
    // close db
    [self closeDatabase: self.db];
    
    // delete doc from db.
    AssertFalse([self.db deleteDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


// TODO: cause crash
- (void)CRASH_testDeleteDocToDeletedDB {
    NSError* error;

    // store doc
    CBLDocument* doc = [self generateDocument:@"doc1"];
    
    // delete db
    [self deleteDatabase: self.db];
    
    // delete doc from db.
    AssertFalse([self.db deleteDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


#pragma mark - Purge Document


- (void) testPurgePreSaveDoc {
    NSError* error;
    CBLDocument* doc = [self createDocument: @"doc1"];
    AssertFalse([self.db purgeDocument: doc error: &error]);
    [self checkError: error domain: @"LiteCore" code: 12]; // Not Found
    AssertEqual(0, (long)self.db.documentCount);
}


- (void) testPurgeDoc {
    NSString* docID = @"doc1";
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // Purge Doc
    // Note: After purge: sequence -> 2
    [self purgeDocAndVerify: doc];
    AssertEqual(0, (long)self.db.documentCount);
    
    // Save to check sequence number -> 3
    [self saveDocument: doc];
    AssertEqual(3L, (long)doc.sequence);
}


- (void) testPurgeDocInDifferentDBInstance {
    NSError* error;
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db instance with same name
    CBLDatabase* otherDB = [self openDBNamed: [self.db name]];
    Assert([otherDB documentExists:docID]);
    AssertEqual(1, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    // purge document against other db instance
    AssertFalse([otherDB purgeDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
    AssertEqual(1, (long)otherDB.documentCount);
    AssertEqual(1, (long)self.db.documentCount);
    AssertFalse(doc.isDeleted);
    
    // close otherDB
    [self closeDatabase: otherDB];
}


- (void) CRASH_testPurgeDocInDifferentDB {
    NSError* error;
    NSString* docID = @"doc1";
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // create db with different name
    CBLDatabase* otherDB =  [self openDatabase: @"otherDB"];
    AssertFalse([otherDB documentExists: docID]);
    AssertEqual(0, (long)otherDB.documentCount);
    XCTAssertNotEqual(self.db, otherDB);
    
    // purge document against other db
    AssertFalse([otherDB purgeDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
    
    AssertEqual(0, (long)otherDB.documentCount);
    AssertEqual(1, (long)self.db.documentCount);
    AssertFalse(doc.isDeleted);
    
    Assert([otherDB close: &error]);
    [self deleteDatabase: otherDB];
}


- (void) testPurgeSameDocTwice {
    NSString* docID = @"doc1";
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // get document for second purge
    CBLDocument* doc1 = [self.db documentWithID: docID];
    AssertNotNil(doc1);
    
    // Purge Doc first time
    [self purgeDocAndVerify: doc];
    AssertEqual(0, (long)self.db.documentCount);
    
    // Purge Doc second time
    [self purgeDocAndVerify: doc1];
    AssertEqual(0, (long)self.db.documentCount);
}


- (void) testPurgeDocInBatch {
    // save 10 docs
    [self createDocs: 10];

    NSError* error;
    BOOL success = [self.db inBatch: &error do: ^{
        for(int i = 0; i < 10; i++){
            //NSError* err;
            NSString* docID = [[NSString alloc] initWithFormat: @"doc_%03d", i];
            CBLDocument* doc = [self.db documentWithID: docID];
            [self purgeDocAndVerify: doc];
            AssertEqual(9 - i, (long)self.db.documentCount);
        }
    }];
    Assert(success);
    AssertNil(error);
    AssertEqual(0, (long)self.db.documentCount);
}


// TODO: cause crash
- (void) CRASH_testPurgeDocToClosedDB {
    // store doc
    CBLDocument* doc = [self generateDocument: @"doc1"];
    
    // close db
    [self closeDatabase:self.db];
    
    // purge doc
    NSError* error;
    AssertFalse([self.db purgeDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


// TODO: cause crash
- (void) CRASH_testPurgeDocToDeletedDB {
    // store doc
    CBLDocument* doc = [self generateDocument: @"doc1"];
   
    // delete db
    [self deleteDatabase: self.db];
    
    // purge doc
    NSError* error;
    AssertFalse([self.db purgeDocument: doc error: &error]);
    [self checkError: error domain: @"CouchbaseLite" code: 403]; // forbidden
}


#pragma mark - Close Database


- (void) testClose {
    // close db
    [self closeDatabase: self.db];
}


- (void) testCloseTwice {
    // close db twice
    [self closeDatabase: self.db];
    [self closeDatabase: self.db];
}


- (void) testCloseThenAccessDoc {
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // clsoe db
    [self closeDatabase: self.db];
    
    // content should be accessible & modifiable without error
    AssertEqualObjects(docID, doc.documentID);
    AssertEqualObjects(@(1), [doc objectForKey: @"key"]);
    [doc setObject:@(2) forKey: @"key"];
    [doc setObject: @"value" forKey: @"key1"];
}


- (void)testCloseThenAccessBlob {
    // store doc with blob
    CBLDocument* doc = [self generateDocument: @"doc1"];
    [self storeBlob: self.db doc: doc content: [@"12345" dataUsingEncoding: NSUTF8StringEncoding]];
    
    // clsoe db
    [self closeDatabase: self.db];
    
    // content should be accessible & modifiable without error
    Assert([[doc objectForKey: @"data"] isKindOfClass: [CBLBlob class]]);
    CBLBlob* blob = [doc objectForKey: @"data"];
    AssertEqual(blob.length, 5ull);
    AssertNil(blob.content);
}


- (void) testCloseThenGetDatabaseName {
    // clsoe db
    [self closeDatabase: self.db];
    AssertEqualObjects(@"testdb", self.db.name);
}


- (void) testCloseThenGetDatabasePath {
    // clsoe db
    [self closeDatabase:self.db];
    
    AssertNil(self.db.path);
}


- (void) testCloseThenCallInBatch {
    NSError* error;
    BOOL sucess = [self.db inBatch: &error do: ^{
        NSError* err;
        [self.db close: &err];
        // 25 -> kC4ErrorNotInTransaction: Function cannot be called while in a transaction
        [self checkError: err domain: @"LiteCore" code: 25];
    }];
    Assert(sucess);
    AssertNil(error);
}


- (void) CRASH_testCloseThenDeleteDatabase {
    [self closeDatabase: self.db];
    [self deleteDatabase: self.db];
}


#pragma mark - Delete Database


- (void) testDelete {
    // delete db
    [self deleteDatabase: self.db];
}


- (void) CRASH_testDeleteTwice {
    // delete db twice
    [self deleteDatabase: self.db];
    [self deleteDatabase: self.db];
}


- (void) testDeleteThenAccessDoc {
    NSString* docID = @"doc1";
    
    // store doc
    CBLDocument* doc = [self generateDocument: docID];
    
    // delete db
    [self deleteDatabase: self.db];
    
    // content should be accessible & modifiable without error
    AssertEqualObjects(docID, doc.documentID);
    AssertEqualObjects(@(1), [doc objectForKey: @"key"]);
    [doc setObject: @(2) forKey: @"key"];
    [doc setObject: @"value" forKey: @"key1"];
}


- (void) testDeleteThenAccessBlob {
    // store doc with blob
    CBLDocument* doc = [self generateDocument: @"doc1"];
    [self storeBlob: self.db doc: doc content: [@"12345" dataUsingEncoding: NSUTF8StringEncoding]];
    
    // delete db
    [self deleteDatabase: self.db];
    
    // content should be accessible & modifiable without error
    Assert([[doc objectForKey: @"data"] isKindOfClass: [CBLBlob class]]);
    CBLBlob* blob = [doc objectForKey: @"data"];
    AssertEqual(blob.length, 5ull);
    AssertNil(blob.content);
    // TODO: TO BE CLARIFIED: Instead of returning nil, should it return Forbidden error?
}


- (void) testDeleteThenGetDatabaseName {
    // delete db
    [self deleteDatabase: self.db];
    AssertEqualObjects(@"testdb", self.db.name);
}


- (void) testDeleteThenGetDatabasePath{
    // delete db
    [self closeDatabase: self.db];
    AssertNil(self.db.path);
}


- (void) testDeleteThenCallInBatch {
    NSError* error;
    BOOL sucess = [self.db inBatch: &error do:^{
        NSError* err;
        [self.db deleteDatabase: &err];
        // 25 -> kC4ErrorNotInTransaction: Function cannot be called while in a transaction
        [self checkError: err domain: @"LiteCore" code: 25];
    }];
    Assert(sucess);
    AssertNil(error);
}


- (void) testDeleteDBOpendByOtherInstance {
    NSError* error;
    
    // open db with same db name and default option
    CBLDatabase* otherDB = [self openDBNamed: [self.db name]];
    XCTAssertNotEqual(self.db, otherDB);
    
    // delete db
    AssertFalse([self.db deleteDatabase: &error]);
    // 24 -> kC4ErrorBusy: Database is busy/locked
    [self checkError: error domain: @"LiteCore" code: 24];
}


#pragma mark - Delate Database (static)


- (void) testDeleteWithDefaultDirDB {
    NSError* error;
    
    // open db with default dir
    CBLDatabase* db = [self openDatabase:@"db"];
    NSString* path = db.path;
    
    // close db before delete
    [self closeDatabase: db];
    
    // delete db with nil directory
    Assert([CBLDatabase deleteDatabase: @"db" inDirectory: nil error: &error]);
    AssertNil(error);
    AssertFalse([[NSFileManager defaultManager] fileExistsAtPath: path]);
}


- (void) testDeleteOpeningDBWithDefaultDir {
    NSError* error;
    
    // open db with default dir
    [self openDatabase: @"db"];
    
    // delete db with nil directory
    AssertFalse([CBLDatabase deleteDatabase: @"db" inDirectory: nil error: &error]);
    // 24 -> kC4ErrorBusy: Database is busy/locked
    [self checkError: error domain: @"LiteCore" code: 24];
}


- (void) testDeleteByStaticMethod {
    NSError* error;
    
    // create db with custom directory
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    CBLDatabaseOptions* options = [CBLDatabaseOptions defaultOptions];
    options.directory = dir;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db"
                                                options: options
                                                  error: &error];
    AssertNotNil(db);
    AssertNil(error);
    
    NSString* path = db.path;
    
    // close db before delete
    [self closeDatabase: db];
    
    Assert([CBLDatabase deleteDatabase: @"db" inDirectory: dir error:&error]);
    AssertNil(error);
    AssertFalse([[NSFileManager defaultManager] fileExistsAtPath: path]);
}


- (void) testDeleteOpeningDBByStaticMethod {
    NSError* error;
    
    // create db with custom directory
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    CBLDatabaseOptions* options = [CBLDatabaseOptions defaultOptions];
    options.directory = dir;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db"
                                                options: options
                                                  error: &error];
    AssertNotNil(db);
    AssertNil(error);
    
    AssertFalse([CBLDatabase deleteDatabase: @"db" inDirectory: dir error: &error]);
    // 24 -> kC4ErrorBusy: Database is busy/locked
    [self checkError: error domain: @"LiteCore" code: 24];
}


- (void) testDeleteNonExistingDBWithDefaultDir {
    // Expectation: No operation
    NSError* error;
    Assert([CBLDatabase deleteDatabase: @"notexistdb" inDirectory: nil error: &error]);
    AssertNil(error);
}


- (void) testDeleteNonExistingDB {
    // Expectation: No operation
    NSError* error;
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    Assert([CBLDatabase deleteDatabase: @"notexistdb" inDirectory: dir error: &error]);
    AssertNil(error);
}


#pragma mark - Database Existing


- (void) CRASH_testDatabaseExistsWithDefaultDir {
    AssertFalse([CBLDatabase databaseExists: @"db" inDirectory: nil]);
    
    // open db with default dir
    CBLDatabase* db = [self openDatabase: @"db"];
    
    Assert([CBLDatabase databaseExists: @"db" inDirectory: nil]);
    
    // close db
    [self closeDatabase: db];
    
    Assert([CBLDatabase databaseExists: @"db" inDirectory: nil]);
    
    // deleete db
    [self deleteDatabase: db];
    
    AssertFalse([CBLDatabase databaseExists: @"db" inDirectory: nil]);
}


- (void) testDatabaseExistsWithDir {
    NSError* error;
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    
    AssertFalse([CBLDatabase databaseExists:@"db" inDirectory:dir]);
    
    // create db with custom directory
    CBLDatabaseOptions* options = [CBLDatabaseOptions defaultOptions];
    options.directory = dir;
    CBLDatabase* db = [[CBLDatabase alloc] initWithName: @"db"
                                                options: options
                                                  error: &error];
    AssertNotNil(db);
    AssertNil(error);
    NSString* path = db.path;
    
    Assert([CBLDatabase databaseExists: @"db" inDirectory: dir]);
    
    // close db
    [self closeDatabase: db];
    
    Assert([CBLDatabase databaseExists: @"db" inDirectory: dir]);
    
    // delete db
    Assert([CBLDatabase deleteDatabase: @"db" inDirectory: dir error: &error]);
    AssertNil(error);
    AssertFalse([[NSFileManager defaultManager] fileExistsAtPath: path]);
    
    AssertFalse([CBLDatabase databaseExists: @"db" inDirectory: dir]);
}


- (void) testDatabaseExistsAgainstNonExistDBWithDefaultDir {
    AssertFalse([CBLDatabase databaseExists: @"nonexist" inDirectory: nil]);
}


- (void) testDatabaseExistsAgainstNonExistDB {
    NSString* dir = [NSTemporaryDirectory() stringByAppendingPathComponent: @"CouchbaseLite"];
    AssertFalse([CBLDatabase databaseExists: @"nonexist" inDirectory: dir]);
}


@end
