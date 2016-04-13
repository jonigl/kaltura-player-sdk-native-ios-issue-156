//
//  KCacheManager.m
//  KALTURAPlayerSDK
//
//  Created by Nissim Pardo on 8/23/15.
//  Copyright (c) 2015 Kaltura. All rights reserved.
//

#import "KCacheManager.h"
#import "NSString+Utilities.h"
#import "KPLog.h"
#import "NSMutableDictionary+Cache.h"

NSString *const CacheDirectory = @"KalturaPlayerCache";

#define MB (1024*1024)
#define GB (MB*1024)

@interface KCacheManager ()
@property (nonatomic, readonly) NSString *cachePath;

@property (strong, nonatomic, readonly) NSBundle *bundle;
@property (strong, nonatomic, readonly) NSDictionary *cacheConditions;
@end

@interface NSString (Cache)
@property (nonatomic, readonly) BOOL deleteFile;
@property (nonatomic, readonly) NSString *pathForFile;
@end

@implementation KCacheManager
@synthesize cachePath = _cachePath;
@synthesize bundle = _bundle, cacheConditions = _cacheConditions, withDomain = _withDomain, subStrings = _subStrings;

+ (KCacheManager *)shared {
    KPLogDebug(@"Enter");
    static KCacheManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    KPLogDebug(@"Exit");
    return instance;
}

// The SDK's bundle
- (NSBundle *)bundle {
    KPLogDebug(@"Enter");
    if (!_bundle) {
        _bundle = [NSBundle bundleWithURL:[[NSBundle bundleForClass:self.classForCoder]
                                           URLForResource:@"KALTURAPlayerSDKResources"
                                           withExtension:@"bundle"]];
        
    }
    
    KPLogDebug(@"Exit");
    return _bundle;
}

- (void)setBaseURL:(NSString *)host {
    KPLogDebug(@"Enter");
    _baseURL = [host stringByReplacingOccurrencesOfString:[host lastPathComponent] withString:@""];
    KPLogDebug(@"Exit");
}


// Fetches the White list urls
- (NSDictionary *)cacheConditions {
    KPLogDebug(@"Enter");
    if (!_cacheConditions) {
        NSString *path = [self.bundle pathForResource:@"CachedStrings" ofType:@"plist"];
        _cacheConditions = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    
    KPLogDebug(@"Exit");
    return _cacheConditions;
}

// The url list which have to be checked by the domain first
- (NSDictionary *)withDomain {
    KPLogDebug(@"Enter");
    if (!_withDomain) {
        _withDomain = self.cacheConditions[@"withDomain"];
    }
    
    KPLogDebug(@"Exit");
    return _withDomain;
}


// The url list which should contain substring fron the White list
- (NSDictionary *)subStrings {
    KPLogDebug(@"Enter");
    if (!_subStrings) {
        _subStrings = self.cacheConditions[@"substrings"];
    }
    
    KPLogDebug(@"Exit");
    return _subStrings;
}


// Lazy initialization of the cache folder path
- (NSString *)cachePath {
    KPLogDebug(@"Enter");
    if (!_cachePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); // Get documents folder
        _cachePath = [paths.firstObject stringByAppendingPathComponent:CacheDirectory];
    }
    
    KPLogDebug(@"Exit");
    return _cachePath;
}


// Calculates the size of the cached files
- (float)cachedSize {
    KPLogDebug(@"Enter");
    long long fileSize = 0;
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:CacheManager.cachePath error:nil];
    for (NSString *file in files) {
        fileSize += [[[NSFileManager defaultManager] attributesOfItemAtPath:file.pathForFile error:nil][NSFileSize] integerValue];
    }
    
    KPLogDebug(@"Exit");
    return (float)fileSize / MB;
}


// Returns sorted array of the content of the cache folder
- (NSArray *)files {
    KPLogDebug(@"Enter");
    NSMutableArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:self.cachePath error:nil].mutableCopy;
    [files sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSDate* d1 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj1.pathForFile error:nil][NSFileModificationDate];
        NSDate* d2 = [[NSFileManager defaultManager] attributesOfItemAtPath:obj2.pathForFile error:nil][NSFileModificationDate];
        return [d1 compare:d2];
    }];
    
    KPLogDebug(@"Exit");
    return files;
}

@end

@implementation NSString (Cache)

// returns the full path for a file name
- (NSString *)pathForFile {
    KPLogDebug(@"Enter");
    KPLogDebug(@"Exit");
    return [CacheManager.cachePath stringByAppendingPathComponent:self];
}

// Unarchive the stored headers
- (NSDictionary *)cachedResponseHeaders {
    KPLogDebug(@"Enter");
    NSString *contentId = self.extractLocalContentId;
    NSString *path = self.md5.appendPath;
    if (contentId.length) {
        path = [contentId appendPath];
    }
    
    NSString *pathForHeaders = [path stringByAppendingPathComponent:@"headers"];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:pathForHeaders];
    if (data) {
        [self setDateAttributeAtPath:pathForHeaders];
        NSDictionary *cached = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        KPLogDebug(@"Exit");
        return cached;
    }
    
    KPLogDebug(@"Exit");
    return nil;
}

// Fetches the page content from the file system
- (NSData *)cachedPage {
    KPLogDebug(@"Enter");
    NSString *contentId = self.extractLocalContentId;
    NSString *path = self.md5.appendPath;
    
    if (contentId) {
        path = contentId.appendPath;
    }
    
    NSString *pathForData = [path stringByAppendingPathComponent:@"data"];
    NSData *data = [[NSFileManager defaultManager] contentsAtPath:pathForData];
    
    if (data) {
        [self setDateAttributeAtPath:pathForData];
    }
    
    KPLogDebug(@"Exit");
    return data;
}



- (void)setDateAttributeAtPath: (NSString *)path {
    KPLogDebug(@"Enter");
    NSError *err = nil;
    [[NSFileManager defaultManager] setAttributes:@{NSFileModificationDate: [NSDate date]} ofItemAtPath:path error:&err];
    
    if (err) {
        KPLogError(err.localizedDescription);
    }
    
    KPLogDebug(@"Exit");
}

- (NSString *)appendPath {
    KPLogDebug(@"Enter");
    KPLogDebug(@"Exit");
    return [CacheManager.cachePath stringByAppendingPathComponent:self];
}


/**
 Deletes file by name
 @return BOOL YES if the file deleted succesfully
 */
- (BOOL)deleteFile {
    KPLogDebug(@"Enter");
    NSString *path = self.pathForFile;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path
                                                   error:&error];
        if (!error) {
            KPLogDebug(@"Exit");
            return YES;
        } else {
            KPLogError(@"%@", error);
        }
    }
    
    KPLogDebug(@"Exit");
    return NO;
}

@end

@implementation CachedURLParams

- (long long)freeDiskSpace {
    KPLogDebug(@"Enter");
    KPLogDebug(@"Exit");
    return [[[[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil] objectForKey:NSFileSystemFreeSize] longLongValue];
}

- (void)storeCacheResponse {
    KPLogDebug(@"Enter");
    float cachedSize = CacheManager.cachedSize;
    
    // if the cache size is too big, erases the least used files
    if (cachedSize > ((float)[self freeDiskSpace] / MB) ||
        cachedSize > CacheManager.maxCacheSize) {
        float overflowSize = cachedSize - CacheManager.maxCacheSize + (float)self.data.length / MB;
        NSArray *files = CacheManager.files;
        for (NSString *fileName in files) {
            if (overflowSize > 0) {
                NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[CacheManager.cachePath stringByAppendingPathComponent:fileName]
                                                                                                error:nil];
                if (fileName.deleteFile) {
                    overflowSize -= [fileDictionary fileSize];
                }
            } else {
                break;
            }
        }
    }
    
    // Create Kaltura's folder if not already exists
    NSString *pageFolderPath = self.url.absoluteString.md5.appendPath;
    if (self.url.absoluteString.extractLocalContentId) {
        pageFolderPath = self.url.absoluteString.extractLocalContentId.appendPath;
    }

    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:pageFolderPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    KPLogError(@"%@",[error localizedDescription]);
    
    if (!error) {
        // Store the page
        NSMutableDictionary *attributes = [NSMutableDictionary new];
        attributes.allHeaderFields = self.response.allHeaderFields;
        attributes.statusCode = self.response.statusCode;
        NSString *pathForHeaders = [pageFolderPath stringByAppendingPathComponent:@"headers"];
        NSString *pathForData = [pageFolderPath stringByAppendingPathComponent:@"data"];
        
        [[NSFileManager defaultManager] createFileAtPath:pathForHeaders
                                                contents:[NSKeyedArchiver archivedDataWithRootObject:attributes.copy]
                                              attributes:attributes.copy];
        [[NSFileManager defaultManager] createFileAtPath:pathForData
                                                contents:self.data
                                              attributes:attributes.copy];
    } else {
        KPLogError(@"Failed to create Directory", error);
    }
    
    KPLogDebug(@"Exit");
}

- (NSMutableData *)data {
    KPLogDebug(@"Enter");
    if (!_data) {
        _data = [[NSMutableData alloc] init];
    }
    
    KPLogDebug(@"Exit");
    return _data;
}

@end