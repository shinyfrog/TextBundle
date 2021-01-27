//
//  TextBundleTests.m
//  TextBundleTests
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import <XCTest/XCTest.h>
#import <TextBundle/TextBundle.h>

@interface TextBundleTests : XCTestCase

@end

@implementation TextBundleTests

- (void)setUp
{
}

- (void)tearDown
{
}

- (NSURL *)textBundleURLForFilename:(NSString *)filename
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:filename withExtension:@"textbundle"];
}

- (NSURL *)textPackURLForFilename:(NSString *)filename
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:filename withExtension:@"textpack"];
}


#pragma mark - Reading

- (void)testLoadTextOnly
{
    NSURL *fileURL = [self textBundleURLForFilename:@"only text"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    
    XCTAssertNil(e);
    
    XCTAssertEqualObjects(tb.text, @"Text");
    XCTAssertEqualObjects([tb applicationSpecificMetadataFor:nil], nil);
    XCTAssertEqualObjects(tb.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(tb.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertEqual(tb.version, 2);
    XCTAssertEqual(tb.transient, false);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 0);
}


- (void)testLoadTextPlusAttachments
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    NSFileWrapper *assetWrapper = [tb fileWrapperFor:@"oh no.jpg"];
    
    XCTAssertNil(e);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);
    XCTAssertNotNil(assetWrapper);
    XCTAssertNotNil(assetWrapper.regularFileContents);
}

- (void)testLoadMissingInfo
{
    NSURL *fileURL = [self textBundleURLForFilename:@"invalid no info"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(tb);
    XCTAssertEqualObjects(e.domain, @"TextBundle.TextBundleError");
}

- (void)testLoadMissingText
{
    NSURL *fileURL = [self textBundleURLForFilename:@"invalid no text"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(tb);
    XCTAssertEqualObjects(e.domain, @"TextBundle.TextBundleError");
}

#pragma mark - Writing

- (void)testWriteExitingTextBundleToAnotherURL
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test.textbundle"];
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:nil];
    
    NSError *e = nil;
    BOOL success = [tb writeTo:targetURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&e];
    
    XCTAssertTrue(success);
    XCTAssertNil(e);
    
    e = nil;

    TextBundleWrapper *newTB = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(e);

    XCTAssertEqualObjects(newTB.text, @"Text");
    XCTAssertEqualObjects([tb applicationSpecificMetadataFor:nil], nil);
    XCTAssertEqualObjects(newTB.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(newTB.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertEqual(newTB.version, 2);
    XCTAssertEqual(newTB.transient, false);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);
}


- (void)testCreateAndWriteTextBundle
{
    TextBundleWrapper *tb = [TextBundleWrapper new];
    tb.text = @"Some Text";
    
    XCTAssertEqualObjects(tb.text, @"Some Text");
    XCTAssertEqualObjects([tb applicationSpecificMetadataFor:nil], nil);
    XCTAssertEqualObjects(tb.type, @"net.daringfireball.markdown");
    XCTAssertEqual(tb.version, 2);
    XCTAssertEqual(tb.transient, false);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 0);
    
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test2.textbundle"];
    
    NSError *e = nil;
    BOOL success = [tb writeTo:targetURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&e];
    
    XCTAssertNil(e);
    XCTAssertTrue(success);    
}

#pragma mark - Assets

- (void)testAddAssets
{
    NSURL *fileURL = [self textBundleURLForFilename:@"only text"];
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithUrl:fileURL options:NSFileWrapperReadingImmediate error:&e];

    NSURL *assetURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"sample asset" withExtension:@"jpg"];
    NSFileWrapper *assetFileWrapper = [[NSFileWrapper alloc] initWithURL:assetURL options:0 error:nil];
    
    // Adding the first time should add the file to the bundle
    NSString *filename = [tb addAssetFileWrapper:assetFileWrapper];
    XCTAssertEqualObjects(filename, @"sample asset.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);

    // Adding the same filewrapper again should duplicate it with a new name
    filename = [tb addAssetFileWrapper:assetFileWrapper];
    XCTAssertEqualObjects(filename, @"sample asset 2.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 2);

    // Adding a different file with the same name should update the new name
    NSURL *assetURL2 = [[NSBundle bundleForClass:[self class]] URLForResource:@"sample asset 2" withExtension:@"jpg"];
    NSFileWrapper *assetFileWrapper2 = [[NSFileWrapper alloc] initWithURL:assetURL2 options:0 error:nil];
    
    assetFileWrapper2.filename = @"sample asset.jpg";
    assetFileWrapper2.preferredFilename = @"sample asset.jpg";
    filename = [tb addAssetFileWrapper:assetFileWrapper2];
    XCTAssertEqualObjects(filename, @"sample asset 3.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 3);
}


#pragma mark - Metadata

- (void)testMetadata
{
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] init];
    tb.text = @"Some Text";
    
    // Adding some metadata
    [tb addApplicationSpecificMetadata:@"data" for:@"key" identifier:@"test"];

    // Trying to re-read it
    NSDictionary *dict = [tb applicationSpecificMetadataFor:@"test"];
    
    XCTAssertEqualObjects(dict, @{@"key":@"data"});
    
    // Try to overwrite it
    [tb addApplicationSpecificMetadata:@"data2" for:@"key" identifier:@"test"];

    // Reading it again
    dict = [tb applicationSpecificMetadataFor:@"test"];
    
    XCTAssertEqualObjects(dict, @{@"key":@"data2"});
    
    // Removing it
    [tb removeApplicationSpecificMetadataFor:@"key" identifier:@"test"];
    
    // Reading it again
    dict = [tb applicationSpecificMetadataFor:@"test"];
    
    XCTAssertEqualObjects(dict, @{});
}


#pragma mark - Compressed

- (void)testReadTextPack
{
    NSURL *fileURL = [self textPackURLForFilename:@"textpack sample"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper alloc] initWithTextPackURL:fileURL error:&e];
    
    XCTAssertNil(e);
    XCTAssertNotNil(tb);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);
}

- (void)testCreateAndWriteTextPack
{
    TextBundleWrapper *tb = [TextBundleWrapper new];
    tb.text = @"Some Text";
        
    NSURL *targetURL = [[NSFileManager.defaultManager URLForDirectory:NSItemReplacementDirectory
                                                             inDomain:NSUserDomainMask
                                                    appropriateForURL:[NSURL fileURLWithPath:@"test.textpack"]
                                                               create:YES
                                                                error:nil] URLByAppendingPathComponent:@"test.textpack"];
    
    NSError *e = nil;
    BOOL success = [tb writeTextPackTo:targetURL error:&e];
    
    XCTAssertNil(e);
    XCTAssertTrue(success);
}

@end
