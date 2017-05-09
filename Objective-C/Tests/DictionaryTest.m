//
//  DictionaryTest.m
//  CouchbaseLite
//
//  Created by Pasin Suriyentrakorn on 2/13/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

#import "CBLTestCase.h"

@interface DictionaryTest : CBLTestCase

@end

@implementation DictionaryTest


- (void) testCreateDictionary {
    CBLDictionary* address = [[CBLDictionary alloc] init];
    AssertEqual(address.count, 0u);
    AssertEqualObjects([address toDictionary], @{});
    
    CBLDocument* doc1 = [[CBLDocument alloc] initWithID: @"doc1"];
    [doc1 setObject: address forKey: @"address"];
    AssertEqual([doc1 dictionaryForKey: @"address"], address);
    
    NSError* error;
    Assert([_db saveDocument: doc1 error: &error], @"Saving error: %@", error);
    doc1 = [_db documentWithID: @"doc1"];
    AssertEqualObjects([[doc1 dictionaryForKey: @"address"] toDictionary], @{});
}


- (void) testCreateDictionaryWithNSDictionary {
    NSDictionary* dict = @{@"street": @"1 Main street",
                           @"city": @"Mountain View",
                           @"state": @"CA"};
    CBLDictionary* address = [[CBLDictionary alloc] initWithDictionary: dict];
    AssertEqualObjects([address objectForKey: @"street"], @"1 Main street");
    AssertEqualObjects([address objectForKey: @"city"], @"Mountain View");
    AssertEqualObjects([address objectForKey: @"state"], @"CA");
    AssertEqualObjects([address toDictionary], dict);
    
    CBLDocument* doc1 = [[CBLDocument alloc] initWithID: @"doc1"];
    [doc1 setObject: address forKey: @"address"];
    AssertEqual([doc1 dictionaryForKey: @"address"], address);
    
    NSError* error;
    Assert([_db saveDocument: doc1 error: &error], @"Saving error: %@", error);
    doc1 = [_db documentWithID: @"doc1"];
    AssertEqualObjects([[doc1 dictionaryForKey: @"address"] toDictionary], dict);
}


- (void) testGetValueFromNewEmptyDictionary {
    CBLDictionary* dict = [[CBLDictionary alloc] init];
    
    AssertEqual([dict integerForKey: @"key"], 0);
    AssertEqual([dict floatForKey: @"key"], 0.0f);
    AssertEqual([dict doubleForKey: @"key"], 0.0);
    AssertEqual([dict booleanForKey: @"key"], NO);
    AssertNil([dict blobForKey: @"key"]);
    AssertNil([dict dateForKey: @"key"]);
    AssertNil([dict numberForKey: @"key"]);
    AssertNil([dict objectForKey: @"key"]);
    AssertNil([dict stringForKey: @"key"]);
    AssertNil([dict dictionaryForKey: @"key"]);
    AssertNil([dict arrayForKey: @"key"]);
    AssertEqualObjects([dict toDictionary], @{});
    
    CBLDocument* doc = [[CBLDocument alloc] initWithID: @"doc1"];
    [doc setObject: dict forKey: @"dict"];
    
    NSError* error;
    Assert([_db saveDocument: doc error: &error], @"Saving error: %@", error);
    doc = [_db documentWithID: @"doc1"];
    
    dict = [doc dictionaryForKey: @"dict"];
    AssertEqual([dict integerForKey: @"key"], 0);
    AssertEqual([dict floatForKey: @"key"], 0.0f);
    AssertEqual([dict doubleForKey: @"key"], 0.0);
    AssertEqual([dict booleanForKey: @"key"], NO);
    AssertNil([dict blobForKey: @"key"]);
    AssertNil([dict dateForKey: @"key"]);
    AssertNil([dict numberForKey: @"key"]);
    AssertNil([dict objectForKey: @"key"]);
    AssertNil([dict stringForKey: @"key"]);
    AssertNil([dict dictionaryForKey: @"key"]);
    AssertNil([dict arrayForKey: @"key"]);
    AssertEqualObjects([dict toDictionary], @{});
}


- (void) testSetNestedDictionaries {
    CBLDocument* doc = [[CBLDocument alloc] initWithID: @"doc1"];
    
    CBLDictionary *level1 = [[CBLDictionary alloc] init];
    [level1 setObject: @"n1" forKey: @"name"];
    [doc setObject: level1 forKey: @"level1"];
    
    CBLDictionary *level2 = [[CBLDictionary alloc] init];
    [level2 setObject: @"n2" forKey: @"name"];
    [level1 setObject: level2 forKey: @"level2"];
    
    CBLDictionary *level3 = [[CBLDictionary alloc] init];
    [level3 setObject: @"n3" forKey: @"name"];
    [level2 setObject: level3 forKey: @"level3"];
    
    AssertEqualObjects([doc dictionaryForKey: @"level1"], level1);
    AssertEqualObjects([level1 dictionaryForKey: @"level2"], level2);
    AssertEqualObjects([level2 dictionaryForKey: @"level3"], level3);
    NSDictionary* dict = @{@"level1": @{@"name": @"n1",
                                        @"level2": @{@"name": @"n2",
                                                     @"level3": @{@"name": @"n3"}}}};
    AssertEqualObjects([doc toDictionary], dict);
    
    NSError* error;
    Assert([_db saveDocument: doc error: &error], @"Saving error: %@", error);
    doc = [_db documentWithID: @"doc1"];
    
    Assert([doc dictionaryForKey: @"level1"] != level1);
    level1 = [doc dictionaryForKey: @"level1"];
    level2 = [level1 dictionaryForKey: @"level2"];
    level3 = [level2 dictionaryForKey: @"level3"];
    
    AssertEqualObjects([level1 dictionaryForKey: @"level2"], level2);
    AssertEqualObjects([level2 dictionaryForKey: @"level3"], level3);
    AssertEqualObjects([doc toDictionary], dict);
}


- (void) testDictionaryArray {
    CBLDocument* doc = [[CBLDocument alloc] initWithID: @"doc1"];
    NSArray* data = @[@{@"name": @"1"}, @{@"name": @"2"}, @{@"name": @"3"}, @{@"name": @"4"}];
    [doc setDictionary: @{@"dicts": data}];
    
    CBLArray* dicts = [doc arrayForKey: @"dicts"];
    AssertEqual(dicts.count, 4u);
    
    CBLDictionary* d1 = [dicts dictionaryAtIndex: 0];
    CBLDictionary* d2 = [dicts dictionaryAtIndex: 1];
    CBLDictionary* d3 = [dicts dictionaryAtIndex: 2];
    CBLDictionary* d4 = [dicts dictionaryAtIndex: 3];
    
    AssertEqualObjects([d1 stringForKey: @"name"], @"1");
    AssertEqualObjects([d2 stringForKey: @"name"], @"2");
    AssertEqualObjects([d3 stringForKey: @"name"], @"3");
    AssertEqualObjects([d4 stringForKey: @"name"], @"4");
    
    NSError* error;
    Assert([_db saveDocument: doc error: &error], @"Saving error: %@", error);
    doc = [_db documentWithID: @"doc1"];
    
    dicts = [doc arrayForKey: @"dicts"];
    AssertEqual(dicts.count, 4u);
    
    d1 = [dicts dictionaryAtIndex: 0];
    d2 = [dicts dictionaryAtIndex: 1];
    d3 = [dicts dictionaryAtIndex: 2];
    d4 = [dicts dictionaryAtIndex: 3];
    
    AssertEqualObjects([d1 stringForKey: @"name"], @"1");
    AssertEqualObjects([d2 stringForKey: @"name"], @"2");
    AssertEqualObjects([d3 stringForKey: @"name"], @"3");
    AssertEqualObjects([d4 stringForKey: @"name"], @"4");
}


- (void) testReplaceDictionary {
    CBLDocument* doc = [[CBLDocument alloc] initWithID: @"doc1"];
    CBLDictionary *profile1 = [[CBLDictionary alloc] init];
    [profile1 setObject: @"Scott Tiger" forKey: @"name"];
    [doc setObject: profile1 forKey: @"profile"];
    AssertEqualObjects([doc dictionaryForKey: @"profile"], profile1);
    
    CBLDictionary *profile2 = [[CBLDictionary alloc] init];
    [profile2 setObject: @"Daniel Tiger" forKey: @"name"];
    [doc setObject: profile2 forKey: @"profile"];
    AssertEqualObjects([doc dictionaryForKey: @"profile"], profile2);
    
    // Profile1 should be now detached:
    [profile1 setObject: @(20) forKey: @"age"];
    AssertEqualObjects([profile1 objectForKey: @"name"], @"Scott Tiger");
    AssertEqualObjects([profile1 objectForKey: @"age"], @(20));
    
    // Check profile2:
    AssertEqualObjects([profile2 objectForKey: @"name"], @"Daniel Tiger");
    AssertNil([profile2 objectForKey: @"age"]);
    
    // Save:
    NSError* error;
    Assert([_db saveDocument: doc error: &error], @"Saving error: %@", error);
    doc = [_db documentWithID: @"doc1"];
    
    Assert([doc dictionaryForKey: @"profile"] != profile2);
    profile2 = [doc dictionaryForKey: @"profile"];
    AssertEqualObjects([profile2 objectForKey: @"name"], @"Daniel Tiger");
}


- (void) testReplaceDictionaryDifferentType {
    CBLDocument* doc = [[CBLDocument alloc] initWithID: @"doc1"];
    CBLDictionary *profile1 = [[CBLDictionary alloc] init];
    [profile1 setObject: @"Scott Tiger" forKey: @"name"];
    [doc setObject: profile1 forKey: @"profile"];
    AssertEqualObjects([doc dictionaryForKey: @"profile"], profile1);
    
    // Set string value to profile:
    [doc setObject: @"Daniel Tiger" forKey: @"profile"];
    AssertEqualObjects([doc objectForKey: @"profile"], @"Daniel Tiger");
    
    // Profile1 should be now detached:
    [profile1 setObject: @(20) forKey: @"age"];
    AssertEqualObjects([profile1 objectForKey: @"name"], @"Scott Tiger");
    AssertEqualObjects([profile1 objectForKey: @"age"], @(20));

    // Check whether the profile value has no change:
    AssertEqualObjects([doc objectForKey: @"profile"], @"Daniel Tiger");
    
    // Save:
    NSError* error;
    Assert([_db saveDocument: doc error: &error], @"Saving error: %@", error);
    doc = [_db documentWithID: @"doc1"];
    
    AssertEqualObjects([doc objectForKey: @"profile"], @"Daniel Tiger");
}


@end
