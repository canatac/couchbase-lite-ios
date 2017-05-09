//
//  DocumentTest.swift
//  CouchbaseLite
//
//  Created by Jens Alfke on 2/10/17.
//  Copyright © 2017 Couchbase. All rights reserved.
//

import XCTest
import CouchbaseLiteSwift


class DocumentTest: CBLTestCase {
    func populateData(_ doc: Document) {
        doc.set(true, forKey: "true")
        doc.set(false, forKey: "false")
        doc.set("string", forKey: "string")
        doc.set(0, forKey: "zero")
        doc.set(1, forKey: "one")
        doc.set(-1, forKey: "minus_one")
        doc.set(1.1, forKey: "one_dot_one")
        doc.set(dateFromJson(kTestDate), forKey: "date")
        doc.set(NSNull(), forKey: "null")
        
        // Dictionary:
        let dict = DictionaryObject()
        dict.set("1 Main street", forKey: "street")
        dict.set("Mountain View", forKey: "city")
        dict.set("CA", forKey: "state")
        doc.set(dict, forKey: "dict")
        
        // Array:
        let array = ArrayObject()
        array.add("650-123-0001")
        array.add("650-123-0002")
        doc.set(array, forKey: "array")
        
        // Blob
        let content = kTestBlob.data(using: .utf8)!
        let blob = Blob(contentType: "text/plain", data: content)
        doc.set(blob, forKey: "blob")
    }
    
    
    func testCreateDoc() throws {
        let doc1a = Document()
        XCTAssertNotNil(doc1a)
        XCTAssertTrue(doc1a.id.characters.count > 0)
        XCTAssertFalse(doc1a.isDeleted)
        XCTAssertEqual(doc1a.toDictionary().count, 0);
        
        let doc1b = try saveDocument(doc1a)
        XCTAssertTrue(doc1b !== doc1a)
        XCTAssertNotNil(doc1b)
        XCTAssertEqual(doc1a.id, doc1b.id)
    }
    
    
    func testCreateDocWithID() throws {
        let doc1a = Document("doc1")
        XCTAssertNotNil(doc1a)
        XCTAssertEqual(doc1a.id, "doc1")
        XCTAssertFalse(doc1a.isDeleted)
        XCTAssertEqual(doc1a.toDictionary().count, 0);
        
        let doc1b = try saveDocument(doc1a)
        XCTAssertTrue(doc1b !== doc1a)
        XCTAssertNotNil(doc1b)
        XCTAssertEqual(doc1a.id, doc1b.id)
    }
    
    
    func testCreateDocwithEmptyStringID() throws {
        let doc1a = Document("")
        XCTAssertNotNil(doc1a)
        
        var error: NSError? = nil
        do {
            try db.save(doc1a)
        } catch let err as NSError {
            error = err
        }
        
        XCTAssertNotNil(error)
        XCTAssertEqual(error!.code, 38)
        XCTAssertEqual(error!.domain, "LiteCore")
    }
    
    
    func testCreateDocWithNilID() throws {
        let doc1a = Document(nil)
        XCTAssertNotNil(doc1a)
        XCTAssertTrue(doc1a.id.characters.count > 0)
        XCTAssertFalse(doc1a.isDeleted)
        XCTAssertEqual(doc1a.toDictionary().count, 0);
        
        let doc1b = try saveDocument(doc1a)
        XCTAssertTrue(doc1b !== doc1a)
        XCTAssertNotNil(doc1b)
        XCTAssertEqual(doc1a.id, doc1b.id)
    }
    
    
    func testCreateDocWithDict() throws {
        let dict: [String: Any] = ["name": "Scott Tiger",
                                   "age": 30,
                                   "address": ["street": "1 Main street.",
                                               "city": "Mountain View",
                                               "state": "CA"],
                                   "phones": ["650-123-0001", "650-123-0002"]]
        
        let doc1a = Document("doc1", dictionary: dict)
        XCTAssertNotNil(doc1a)
        XCTAssertTrue(doc1a.id.characters.count > 0)
        XCTAssertFalse(doc1a.isDeleted)
        XCTAssertTrue(doc1a.toDictionary() ==  dict)
        
        let doc1b = try saveDocument(doc1a)
        XCTAssertTrue(doc1b !== doc1a)
        XCTAssertNotNil(doc1b)
        XCTAssertEqual(doc1b.id, doc1a.id)
        XCTAssertTrue(doc1b.toDictionary() ==  dict)
    }
    
    
    func testSetDictionaryContent() throws {
        let dict: [String: Any] = ["name": "Scott Tiger",
                                   "age": 30,
                                   "address": ["street": "1 Main street.",
                                               "city": "Mountain View",
                                               "state": "CA"],
                                   "phones": ["650-123-0001", "650-123-0002"]]
        
        var doc = createDocument("doc1")
        doc.setDictionary(dict)
        XCTAssertTrue(doc.toDictionary() ==  dict)
        
        let nuDict: [String: Any] = ["name": "Daniel Tiger",
                                     "age": 32,
                                     "address": ["street": "2 Main street.",
                                                 "city": "Palo Alto",
                                                 "state": "CA"],
                                     "phones": ["650-234-0001", "650-234-0002"]]
        doc.setDictionary(nuDict)
        XCTAssertTrue(doc.toDictionary() ==  nuDict)
        
        doc = try saveDocument(doc)
        XCTAssertTrue(doc.toDictionary() ==  nuDict)
    }
    
    
    func testGetValueFromNewEmptyDoc() throws {
        let doc = createDocument("doc1")
        try saveDocument(doc) { (d) in
            XCTAssertEqual(d.getInt("key"), 0);
            XCTAssertEqual(d.getFloat("key"), 0.0);
            XCTAssertEqual(d.getDouble("key"), 0.0);
            XCTAssertEqual(d.getBoolean("key"), false);
            XCTAssertNil(d.getBlob("key"));
            XCTAssertNil(d.getDate("key"));
            XCTAssertNil(d.getValue("key"));
            XCTAssertNil(d.getString("key"));
            XCTAssertNil(d.getDictionary("key"));
            XCTAssertNil(d.getArray("key"));
            XCTAssertEqual(d.toDictionary().count, 0);
        }
    }
    
    
    func testGetValueFromExistingEmptyDoc() throws {
        var doc = createDocument("doc1")
        doc = try saveDocument(doc)
        
        XCTAssertEqual(doc.getInt("key"), 0);
        XCTAssertEqual(doc.getFloat("key"), 0.0);
        XCTAssertEqual(doc.getDouble("key"), 0.0);
        XCTAssertEqual(doc.getBoolean("key"), false);
        XCTAssertNil(doc.getBlob("key"));
        XCTAssertNil(doc.getDate("key"));
        XCTAssertNil(doc.getValue("key"));
        XCTAssertNil(doc.getString("key"));
        XCTAssertNil(doc.getDictionary("key"));
        XCTAssertNil(doc.getArray("key"));
        XCTAssertEqual(doc.toDictionary().count, 0);
    }
    
    
    func testSaveThenGetFromAnotherDB() throws {
        let doc1a = createDocument("doc1")
        doc1a.set("Scott Tiger", forKey: "name")
        
        try saveDocument(doc1a)
        
        let anotherDb = try createDB()
        
        let doc1b = anotherDb.getDocument("doc1")
        XCTAssertNotNil(doc1b)
        XCTAssertTrue(doc1b !== doc1a)
        XCTAssertEqual(doc1b!.id, doc1a.id)
        XCTAssertTrue(doc1b!.toDictionary() == doc1a.toDictionary())
        
        try anotherDb.close()
    }
    
    
    func testNoCacheNoLive() throws {
        let doc1a = createDocument("doc1")
        doc1a.set("Scott Tiger", forKey: "name")
        
        try saveDocument(doc1a)
        
        let doc1b = db.getDocument("doc1")
        let doc1c = db.getDocument("doc1")
        
        let anotherDb = try createDB()
        let doc1d = anotherDb.getDocument("doc1")
        
        XCTAssertTrue(doc1a !== doc1b)
        XCTAssertTrue(doc1a !== doc1c)
        XCTAssertTrue(doc1a !== doc1d)
        XCTAssertTrue(doc1b !== doc1c)
        XCTAssertTrue(doc1b !== doc1d)
        XCTAssertTrue(doc1c !== doc1d)
        
        XCTAssertTrue(doc1a.toDictionary() == doc1b!.toDictionary())
        XCTAssertTrue(doc1a.toDictionary() == doc1c!.toDictionary())
        XCTAssertTrue(doc1a.toDictionary() == doc1d!.toDictionary())
        
        // Update:
        
        doc1b!.set("Daniel Tiger", forKey: "name")
        try saveDocument(doc1b!)
        
        XCTAssertFalse(doc1b!.toDictionary() == doc1a.toDictionary())
        XCTAssertFalse(doc1b!.toDictionary() == doc1c!.toDictionary())
        XCTAssertFalse(doc1b!.toDictionary() == doc1d!.toDictionary())
        
        try anotherDb.close()
    }
    
    
    func testSetString() throws {
        let doc = createDocument("doc1")
        doc.set("", forKey: "string1")
        doc.set("string", forKey: "string2")
        
        try saveDocument(doc) { (d) in
            XCTAssertEqual(d.getString("string1"), "")
            XCTAssertEqual(d.getString("string2"), "string")
        }
        
        // Update:
        
        doc.set("string", forKey: "string1")
        doc.set("", forKey: "string2")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getString("string1"), "string")
            XCTAssertEqual(d.getString("string2"), "")
        })
    }
    
    
    func testGetString() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertNil(d.getString("null"))
            XCTAssertNil(d.getString("true"))
            XCTAssertNil(d.getString("false"))
            XCTAssertEqual(d.getString("string"), "string");
            XCTAssertNil(d.getString("zero"))
            XCTAssertNil(d.getString("one"))
            XCTAssertNil(d.getString("minus_one"))
            XCTAssertNil(d.getString("one_dot_one"))
            XCTAssertEqual(d.getString("date"), kTestDate);
            XCTAssertNil(d.getString("dict"))
            XCTAssertNil(d.getString("array"))
            XCTAssertNil(d.getString("blob"))
            XCTAssertNil(d.getString("non_existing_key"))
        })
    }
    
    
    func testSetNumber() throws {
        let doc = createDocument("doc1")
        doc.set(1, forKey: "number1")
        doc.set(0, forKey: "number2")
        doc.set(-1, forKey: "number3")
        doc.set(1.1, forKey: "number4")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(doc.getInt("number1"), 1)
            XCTAssertEqual(doc.getInt("number2"), 0)
            XCTAssertEqual(doc.getInt("number3"), -1)
            XCTAssertEqual(doc.getFloat("number4"), 1.1)
            XCTAssertEqual(doc.getDouble("number4"), 1.1)
        })
        
        // Update:
        
        doc.set(0, forKey: "number1")
        doc.set(1, forKey: "number2")
        doc.set(1.1, forKey: "number3")
        doc.set(-1, forKey: "number4")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(doc.getInt("number1"), 0)
            XCTAssertEqual(doc.getInt("number2"), 1)
            XCTAssertEqual(doc.getFloat("number3"), 1.1)
            XCTAssertEqual(doc.getDouble("number3"), 1.1)
            XCTAssertEqual(doc.getInt("number4"), -1)
        })
    }
    
    
    func testGetInteger() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getInt("null"), 0)
            XCTAssertEqual(d.getInt("true"), 1)
            XCTAssertEqual(d.getInt("false"), 0)
            XCTAssertEqual(d.getInt("string"), 0);
            XCTAssertEqual(d.getInt("zero"),0)
            XCTAssertEqual(d.getInt("one"), 1)
            XCTAssertEqual(d.getInt("minus_one"), -1)
            XCTAssertEqual(d.getInt("one_dot_one"), 1)
            XCTAssertEqual(d.getInt("date"), 0)
            XCTAssertEqual(d.getInt("dict"), 0)
            XCTAssertEqual(d.getInt("array"), 0)
            XCTAssertEqual(d.getInt("blob"), 0)
            XCTAssertEqual(d.getInt("non_existing_key"), 0)
        })
    }

    
    func testGetFloat() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getFloat("null"), 0.0)
            XCTAssertEqual(d.getFloat("true"), 1.0)
            XCTAssertEqual(d.getFloat("false"), 0.0)
            XCTAssertEqual(d.getFloat("string"), 0.0);
            XCTAssertEqual(d.getFloat("zero"),0.0)
            XCTAssertEqual(d.getFloat("one"), 1.0)
            XCTAssertEqual(d.getFloat("minus_one"), -1.0)
            XCTAssertEqual(d.getFloat("one_dot_one"), 1.1)
            XCTAssertEqual(d.getFloat("date"), 0.0)
            XCTAssertEqual(d.getFloat("dict"), 0.0)
            XCTAssertEqual(d.getFloat("array"), 0.0)
            XCTAssertEqual(d.getFloat("blob"), 0.0)
            XCTAssertEqual(d.getFloat("non_existing_key"), 0.0)
        })
    }
    
    
    func testGetDouble() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getDouble("null"), 0.0)
            XCTAssertEqual(d.getDouble("true"), 1.0)
            XCTAssertEqual(d.getDouble("false"), 0.0)
            XCTAssertEqual(d.getDouble("string"), 0.0);
            XCTAssertEqual(d.getDouble("zero"),0.0)
            XCTAssertEqual(d.getDouble("one"), 1.0)
            XCTAssertEqual(d.getDouble("minus_one"), -1.0)
            XCTAssertEqual(d.getDouble("one_dot_one"), 1.1)
            XCTAssertEqual(d.getDouble("date"), 0.0)
            XCTAssertEqual(d.getDouble("dict"), 0.0)
            XCTAssertEqual(d.getDouble("array"), 0.0)
            XCTAssertEqual(d.getDouble("blob"), 0.0)
            XCTAssertEqual(d.getDouble("non_existing_key"), 0.0)
        })
    }
    
    
    func testSetGetMinMaxNumbers() throws {
        let doc = createDocument("doc1")
        doc.set(Int.min, forKey: "min_int")
        doc.set(Int.max, forKey: "max_int")
        doc.set(Float.leastNormalMagnitude, forKey: "min_float")
        doc.set(Float.greatestFiniteMagnitude, forKey: "max_float")
        doc.set(Double.leastNormalMagnitude, forKey: "min_double")
        doc.set(Double.greatestFiniteMagnitude, forKey: "max_double")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getInt("min_int"), Int.min);
            XCTAssertEqual(d.getInt("max_int"), Int.max);
            XCTAssertEqual(d.getValue("min_int") as! Int, Int.min);
            XCTAssertEqual(d.getValue("max_int") as! Int, Int.max);
            
            XCTAssertEqual(d.getFloat("min_float"), Float.leastNormalMagnitude);
            XCTAssertEqual(d.getFloat("max_float"), Float.greatestFiniteMagnitude);
            XCTAssertEqual(d.getValue("min_float") as! Float, Float.leastNormalMagnitude);
            XCTAssertEqual(d.getValue("max_float") as! Float, Float.greatestFiniteMagnitude);
            
            XCTAssertEqual(d.getDouble("min_double"), Double.leastNormalMagnitude);
            XCTAssertEqual(d.getDouble("max_double"), Double.greatestFiniteMagnitude);
            XCTAssertEqual(d.getValue("min_double") as! Double, Double.leastNormalMagnitude);
            XCTAssertEqual(d.getValue("max_double") as! Double, Double.greatestFiniteMagnitude);
        })
    }
    
    
    func failingTestSetGetFloatNumbers() throws {
        let doc = createDocument("doc1")
        doc.set(1.00, forKey: "number1")
        doc.set(1.49, forKey: "number2")
        doc.set(1.50, forKey: "number3")
        doc.set(1.51, forKey: "number4")
        doc.set(1.99, forKey: "number5")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getInt("number1"), 1);
            XCTAssertEqual(d.getFloat("number1"), 1.00);
            XCTAssertEqual(d.getDouble("number1"), 1.00);
            
            XCTAssertEqual(d.getInt("number2"), 1);
            XCTAssertEqual(d.getFloat("number2"), 1.49);
            XCTAssertEqual(d.getDouble("number2"), 1.49);
            
            XCTAssertEqual(d.getInt("number3"), 1);
            XCTAssertEqual(d.getFloat("number3"), 1.50);
            XCTAssertEqual(d.getDouble("number3"), 1.50);
            
            XCTAssertEqual(d.getInt("number4"), 1);
            XCTAssertEqual(d.getFloat("number4"), 1.51);
            XCTAssertEqual(d.getDouble("number4"), 1.51);
            
            XCTAssertEqual(d.getInt("number5"), 1);
            XCTAssertEqual(d.getFloat("number5"), 1.99);
            XCTAssertEqual(d.getDouble("number5"), 1.99);
        })
    }
    
    
    func testSetBoolean() throws {
        let doc = createDocument("doc1")
        doc.set(true, forKey: "boolean1")
        doc.set(false, forKey: "boolean2")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getBoolean("boolean1"), true);
            XCTAssertEqual(d.getBoolean("boolean2"), false);
        })
        
        // Update:
        
        doc.set(false, forKey: "boolean1")
        doc.set(true, forKey: "boolean2")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getBoolean("boolean1"), false);
            XCTAssertEqual(d.getBoolean("boolean2"), true);
        })
    }
    
    
    func testGetBoolean() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getBoolean("null"), false)
            XCTAssertEqual(d.getBoolean("true"), true)
            XCTAssertEqual(d.getBoolean("false"),false)
            XCTAssertEqual(d.getBoolean("string"), true);
            XCTAssertEqual(d.getBoolean("zero"), false)
            XCTAssertEqual(d.getBoolean("one"), true)
            XCTAssertEqual(d.getBoolean("minus_one"), true)
            XCTAssertEqual(d.getBoolean("one_dot_one"), true)
            XCTAssertEqual(d.getBoolean("date"), true)
            XCTAssertEqual(d.getBoolean("dict"), true)
            XCTAssertEqual(d.getBoolean("array"), true)
            XCTAssertEqual(d.getBoolean("blob"), true)
            XCTAssertEqual(d.getBoolean("non_existing_key"), false)
        })
    }
    
    
    func testSetDate() throws {
        let doc = createDocument("doc1")
        let date = Date()
        let dateStr = jsonFromDate(date)
        XCTAssertTrue(dateStr.characters.count > 0)
        doc.set(date, forKey: "date")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getValue("date") as! String, dateStr);
            XCTAssertEqual(d.getString("date"), dateStr);
            XCTAssertEqual(jsonFromDate(d.getDate("date")!), dateStr);
        })
        
        // Update:
        
        let nuDate = Date(timeInterval: 60.0, since: date)
        let nuDateStr = jsonFromDate(nuDate)
        doc.set(nuDate, forKey: "date")
        
        try saveDocument(doc, eval: { (d) in
            XCTAssertEqual(d.getValue("date") as! String, nuDateStr);
            XCTAssertEqual(d.getString("date"), nuDateStr);
            XCTAssertEqual(jsonFromDate(d.getDate("date")!), nuDateStr);
        })
    }
    
    
    func testGetDate() throws {
        let doc = createDocument("doc1")
        populateData(doc)
        try saveDocument(doc, eval: { (d) in
            XCTAssertNil(d.getDate("null"))
            XCTAssertNil(d.getDate("true"))
            XCTAssertNil(d.getDate("false"))
            XCTAssertNil(d.getDate("string"), "string");
            XCTAssertNil(d.getDate("zero"))
            XCTAssertNil(d.getDate("one"))
            XCTAssertNil(d.getDate("minus_one"))
            XCTAssertNil(d.getDate("one_dot_one"))
            XCTAssertEqual(jsonFromDate(d.getDate("date")!), kTestDate);
            XCTAssertNil(d.getDate("dict"))
            XCTAssertNil(d.getDate("array"))
            XCTAssertNil(d.getDate("blob"))
            XCTAssertNil(d.getDate("non_existing_key"))
        })
    }
    
    
    func testSetBlob() throws {
        
    }
    
    
    /*
    func testBlob() throws {
        let content = "12345".data(using: String.Encoding.utf8)!
        let data = Blob(contentType: "text/plain", data: content)
        doc["data"] = data
        doc["name"] = "Jim"
        try doc.save()

        try reopenDB()

        XCTAssertEqual(doc["name"], "Jim")
        XCTAssert(doc.getValue("data") as? Blob != nil)
        let data2: Blob? = doc["data"]
        XCTAssert(data2 != nil)
        XCTAssertEqual(data2?.contentType, "text/plain")
        XCTAssertEqual(data2?.length, 5)
        XCTAssertEqual(data2?.content, content)

        //TODO: Reading from NSInputStream in Swift is ugly. Define our own API?
        let input = data2!.contentStream!
        input.open()
        var buffer = Array<UInt8>(repeating: 0, count: 10)
        let bytesRead = input.read(&buffer, maxLength: 10)
        XCTAssertEqual(bytesRead, 5)
        XCTAssertEqual(buffer[0...4], [49, 50, 51, 52, 53])
    }
    */
}
