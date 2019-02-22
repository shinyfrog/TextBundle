//
//  TextBundle.m
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import "TextBundleWrapper.h"

NSString * const kTextBundleInfoFileName = @"info.json";
NSString * const kTextBundleAssetsFileName = @"assets";

@interface TextBundleWrapper ()

@end

@implementation TextBundleWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.metadata = [NSMutableDictionary dictionary];
        self.version = @(2);
        self.type = @"net.daringfireball.markdown";
    }
    
    return self;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError **)error
{
    self = [self init];
    if (self) {
        
        BOOL success = [self readFromURL:url error:error];
        if (!success) {
            return nil;
        }
    }
    return self;
}


- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error
{
    NSFileWrapper *textBundleFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    
    // Text
    [textBundleFileWrapper addRegularFileWithContents:[self.text dataUsingEncoding:NSUTF8StringEncoding] preferredFilename:[self textFilenameForType:self.type]];
    
    // Info
    [textBundleFileWrapper addRegularFileWithContents:[self jsonDataForMetadata:self.metadata] preferredFilename:kTextBundleInfoFileName];
    
    // Assets
    NSFileWrapper *assetsFileWrapper = [self assetsFilewrapperForFilesURLs:self.assetsURLs];
    if (assetsFileWrapper) {
        [textBundleFileWrapper addFileWrapper:assetsFileWrapper];
    }
    
    return [textBundleFileWrapper writeToURL:url options:NSFileWrapperWritingAtomic originalContentsURL:url error:error];
}


- (BOOL)readFromURL:(NSURL *)url error:(NSError **)error
{
    NSFileWrapper *textBundleFileWrapper = [[NSFileWrapper alloc] initWithURL:url options:NSFileWrapperReadingWithoutMapping error:error];
    
    if (error &&  *error != nil) {
        return NO;
    }
    
    // Info
    NSFileWrapper *infoFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:kTextBundleInfoFileName];
    if (infoFileWrapper) {
        NSData *fileData = [infoFileWrapper regularFileContents];
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:error];
        
        self.metadata          = [jsonObject mutableCopy];
        self.version           = self.metadata[@"version"];
        self.type              = self.metadata[@"type"];
        self.transient         = self.metadata[@"transient"];
        self.creatorIdentifier = self.metadata[@"creatorIdentifier"];

    }
    else {
        return NO;
    }
    
    // Text
    NSFileWrapper *textFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:[self textFileNameInFileWrapper:textBundleFileWrapper]];
    if (textFileWrapper) {
        NSURL *textFileURL = [url URLByAppendingPathComponent:textFileWrapper.filename];
        self.text = [[NSString alloc] initWithContentsOfURL:textFileURL usedEncoding:nil error:error];
    }
    else {
        return NO;
    }
    
    // Assets
    NSFileWrapper *assetsFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:kTextBundleAssetsFileName];
    if (assetsFileWrapper) {
        self.assetsURLs = [[[NSFileManager defaultManager] contentsOfDirectoryAtURL:[url URLByAppendingPathComponent:assetsFileWrapper.filename] includingPropertiesForKeys:nil options:0 error:error] mutableCopy];
    }
    
    return YES;
}

- (NSString *)textFileNameInFileWrapper:(NSFileWrapper*)fileWrapper
{
    __block NSString *filename = nil;
    [[fileWrapper fileWrappers] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSFileWrapper * obj, BOOL *stop)
    {
        if([[obj.filename lowercaseString] hasPrefix:@"text"]) {
            filename = obj.filename;
        }
    }];

    return filename;
}

- (NSString *)textFilenameForType:(NSString *)type
{
    NSString *ext = (__bridge NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)type, kUTTagClassFilenameExtension);
    return [@"text" stringByAppendingPathExtension:ext];
}

- (NSData *)jsonDataForMetadata:(NSDictionary *)metadata
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:metadata
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    return jsonData;
}

- (NSFileWrapper *)assetsFilewrapperForFilesURLs:(NSArray *)filesURLs
{
    NSFileWrapper *assetsFileWrapper = nil;
    
    if (filesURLs && filesURLs.count) {
        assetsFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
        assetsFileWrapper.preferredFilename = kTextBundleAssetsFileName;
        
        for (NSURL *fileURL in filesURLs) {
            NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:fileURL options:NSFileWrapperReadingWithoutMapping error:nil];
            if (fileWrapper) {
                [assetsFileWrapper addFileWrapper:fileWrapper];
            }
        }
    }
    
    return assetsFileWrapper;
}

- (NSNumber *)version { return self.metadata[@"version"]; }
- (void)setVersion:(NSNumber *)version { self.metadata[@"version"] = version; }

- (NSString *)type { return self.metadata[@"type"]; }
- (void)setType:(NSString *)type { self.metadata[@"type"] = type; }

- (NSNumber *)transient { return self.metadata[@"transient"]; }
- (void)setTransient:(NSNumber *)transient { self.metadata[@"transient"] = transient; }

- (NSString *)creatorIdentifier { return self.metadata[@"creatorIdentifier"]; }
- (void)setCreatorIdentifier:(NSString *)creatorIdentifier { self.metadata[@"creatorIdentifier"] = creatorIdentifier; }

@end
