//
//  TextBundle.m
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import "TextBundleWrapper.h"

// Filenames constants
NSString * const kTextBundleInfoFileName = @"info.json";
NSString * const kTextBundleAssetsFileName = @"assets";

// Metadata constants
NSString * const kTextBundleVersion = @"version";
NSString * const kTextBundleType = @"type";
NSString * const kTextBundleTransient = @"transient";
NSString * const kTextBundleCreatorIdentifier = @"creatorIdentifier";

// Error constants
NSString * const TextBundleErrorDomain = @"TextBundleErrorDomain";

@implementation TextBundleWrapper

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.metadata = [NSMutableDictionary dictionary];
        self.version = @(2);
        self.type = @"net.daringfireball.markdown";
        
        self.assetsFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
        self.assetsFileWrapper.preferredFilename = kTextBundleAssetsFileName;
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

#pragma mark - Writing

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error
{
    NSFileWrapper *textBundleFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
    
    // Text
    [textBundleFileWrapper addRegularFileWithContents:[self.text dataUsingEncoding:NSUTF8StringEncoding] preferredFilename:[self textFilenameForType:self.type]];
    
    // Info
    [textBundleFileWrapper addRegularFileWithContents:[self jsonDataForMetadata:self.metadata] preferredFilename:kTextBundleInfoFileName];
    
    // Assets
    if (self.assetsFileWrapper && self.assetsFileWrapper.fileWrappers.count) {
        [textBundleFileWrapper addFileWrapper:self.assetsFileWrapper];
    }
    
    return [textBundleFileWrapper writeToURL:url options:NSFileWrapperWritingAtomic originalContentsURL:url error:error];
}

#pragma mark - Reading

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
        self.version           = self.metadata[kTextBundleVersion];
        self.type              = self.metadata[kTextBundleType];
        self.transient         = self.metadata[kTextBundleTransient];
        self.creatorIdentifier = self.metadata[kTextBundleCreatorIdentifier];
        
        [self.metadata removeObjectForKey:kTextBundleVersion];
        [self.metadata removeObjectForKey:kTextBundleType];
        [self.metadata removeObjectForKey:kTextBundleTransient];
        [self.metadata removeObjectForKey:kTextBundleCreatorIdentifier];
    }
    else {
        if (error) {
            *error = [NSError errorWithDomain:TextBundleErrorDomain code:TextBundleErrorInvalidFormat userInfo:nil];
        }

        return NO;
    }
    
    // Text
    NSFileWrapper *textFileWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:[self textFileNameInFileWrapper:textBundleFileWrapper]];
    if (textFileWrapper) {
        NSURL *textFileURL = [url URLByAppendingPathComponent:textFileWrapper.filename];
        self.text = [[NSString alloc] initWithContentsOfURL:textFileURL usedEncoding:nil error:error];
    }
    else {
        if (error) {
            *error = [NSError errorWithDomain:TextBundleErrorDomain code:TextBundleErrorInvalidFormat userInfo:nil];
        }
        
        return NO;
    }
    
    // Assets
    NSFileWrapper *assetsWrapper = [[textBundleFileWrapper fileWrappers] objectForKey:kTextBundleAssetsFileName];
    if (assetsWrapper) {
        self.assetsFileWrapper = assetsWrapper;
    }
    
    return YES;
}

#pragma mark - Text

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

#pragma mark - Metadata

- (NSData *)jsonDataForMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *allMetadata = [NSMutableDictionary dictionary];
    [allMetadata addEntriesFromDictionary:metadata];
    
    if (self.version)           { allMetadata[kTextBundleVersion] = self.version;                     }
    if (self.type)              { allMetadata[kTextBundleType] = self.type;                           }
    if (self.transient)         { allMetadata[kTextBundleTransient] = self.transient;                 }
    if (self.creatorIdentifier) { allMetadata[kTextBundleCreatorIdentifier] = self.creatorIdentifier; }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allMetadata
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    return jsonData;
}

@end
