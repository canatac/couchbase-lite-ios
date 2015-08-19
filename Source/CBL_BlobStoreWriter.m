//
//  CBL_BlobStoreWriter.m
//  CouchbaseLite
//
//  Created by Jens Alfke on 8/19/15.
//  Copyright © 2015 Couchbase, Inc. All rights reserved.
//

#import "CBL_BlobStoreWriter.h"
#import "CBLSymmetricKey.h"
#import "CBLBase64.h"
#import "CBLMisc.h"

#ifdef GNUSTEP
#import <openssl/md5.h>
#endif


typedef struct {
    uint8_t bytes[MD5_DIGEST_LENGTH];
} CBLMD5Key;


// internal CBL_BlobStore API:
@interface CBL_BlobStore ()
- (NSString*) rawPathForKey: (CBLBlobKey)key;
@property (readonly, nonatomic) NSString* tempDir;
@end


@implementation CBL_BlobStoreWriter
{
    @private
    CBL_BlobStore* _store;
    NSString* _tempPath;
    NSFileHandle* _out;
    UInt64 _length;
    SHA_CTX _shaCtx;
    MD5_CTX _md5Ctx;
    CBLBlobKey _blobKey;
    CBLMD5Key _MD5Digest;
    CBLCryptorBlock _encryptor;
}
@synthesize name=_name, length=_length, blobKey=_blobKey;


- (instancetype) initWithStore: (CBL_BlobStore*)store {
    self = [super init];
    if (self) {
        _store = store;
        SHA1_Init(&_shaCtx);
        MD5_Init(&_md5Ctx);
                
        // Open a temporary file in the store's temporary directory: 
        NSString* filename = [CBLCreateUUID() stringByAppendingPathExtension: @"blobtmp"];
        _tempPath = [[_store.tempDir stringByAppendingPathComponent: filename] copy];
        if (!_tempPath) {
            return nil;
        }
        // -fileHandleForWritingAtPath stupidly fails if the file doesn't exist, so we first have
        // to create it:
        int fd = open(_tempPath.fileSystemRepresentation, O_CREAT | O_TRUNC | O_WRONLY, 0600);
        if (fd < 0) {
            Warn(@"CBL_BlobStoreWriter can't create temp file at %@ (errno %d)", _tempPath, errno);
            return nil;
        }
        close(fd);
        if (![self openFile])
            return nil;
        CBLSymmetricKey* encryptionKey = _store.encryptionKey;
        if (encryptionKey)
            _encryptor = [encryptionKey createEncryptor];
    }
    return self;
}


- (void) appendData: (NSData*)data {
    NSUInteger dataLen = data.length;
    _length += dataLen;
    SHA1_Update(&_shaCtx, data.bytes, dataLen);
    MD5_Update(&_md5Ctx, data.bytes, dataLen);

    if (_encryptor)
        data = _encryptor(data);
    [_out writeData: data];
}


- (void) closeFile {
    [_out closeFile];
    _out = nil;    
}


- (BOOL) openFile {
    if (_out)
        return YES;
    _out = [NSFileHandle fileHandleForWritingAtPath: _tempPath];
    if (!_out) {
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath: _tempPath];
        Warn(@"CBL_BlobStoreWriter: Unable to get a file handle for the temp file at "
             "%@ (exists: %@)", _tempPath, (exists ? @"yes" : @"no"));
        return NO;
    }
    [_out seekToEndOfFile];
    return YES;
}


- (void) reset {
    if (_out) {
        [_out truncateFileAtOffset: 0];
        SHA1_Init(&_shaCtx);
        MD5_Init(&_md5Ctx);
        _length = 0;
    }
}


- (void) finish {
    Assert(_out, @"Already finished");
    if (_encryptor) {
        [_out writeData: _encryptor(nil)];  // write remaining encrypted data & clean up
        _encryptor = nil;
    }
    [self closeFile];
    SHA1_Final(_blobKey.bytes, &_shaCtx);
    MD5_Final(_MD5Digest.bytes, &_md5Ctx);
}


- (NSString*) MD5DigestString {
    return [@"md5-" stringByAppendingString: [CBLBase64 encode: &_MD5Digest
                                                       length: sizeof(_MD5Digest)]];
}


- (NSString*) SHA1DigestString {
    return [@"sha1-" stringByAppendingString: [CBLBase64 encode: &_blobKey
                                                        length: sizeof(_blobKey)]];
}


- (BOOL) verifyDigest: (NSString*)digestString {
    if (digestString == nil)
        return YES;
    NSString* actualDigest;
    if ([digestString hasPrefix: @"md5-"])
        actualDigest = self.MD5DigestString;
    else
        actualDigest = self.SHA1DigestString;
    if ([actualDigest isEqualToString: digestString]) {
        return YES;
    } else {
        Warn(@"Attachment '%@' has incorrect data (digests to %@; expected %@)",
             _name, actualDigest, digestString);
        return NO;
    }
}


- (NSData*) blobData {
    Assert(!_out, @"Not finished yet");
    NSData* data = [NSData dataWithContentsOfFile: _tempPath
                                          options: NSDataReadingMappedIfSafe
                                            error: NULL];
    CBLSymmetricKey* encryptionKey = _store.encryptionKey;
    if (encryptionKey && data)
        data = [encryptionKey decryptData: data];
    return data;
}


- (NSInputStream*) blobInputStream {
    Assert(!_out, @"Not finished yet");
    NSInputStream* stream = [NSInputStream inputStreamWithFileAtPath: _tempPath];
    [stream open];
    CBLSymmetricKey* encryptionKey = _store.encryptionKey;
    if (encryptionKey && stream)
        stream = [encryptionKey decryptStream: stream];
    return stream;
}


- (NSString*) filePath {
    return _store.encryptionKey ? nil : _tempPath;
}


- (BOOL) install {
    if (!_tempPath)
        return YES;  // already installed
    Assert(!_out, @"Not finished");
    // Move temp file to correct location in blob store:
    NSString* dstPath = [_store rawPathForKey: _blobKey];
    if ([[NSFileManager defaultManager] moveItemAtPath: _tempPath
                                                toPath: dstPath error:NULL]) {
        _tempPath = nil;
    } else {
        // If the move fails, assume it means a file with the same name already exists; in that
        // case it must have the identical contents, so we're still OK.
        [self cancel];
    }
    return YES;
}


- (void) cancel {
    [self closeFile];
    _encryptor = nil;
    if (_tempPath) {
        [[NSFileManager defaultManager] removeItemAtPath: _tempPath error: NULL];
        _tempPath = nil;
    }
}


- (void) dealloc {
    [self cancel];      // Close file, and delete it if it hasn't been installed yet
}


@end