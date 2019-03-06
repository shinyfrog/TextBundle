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

#pragma mark - Reading

- (void)testLoadTextOnly
{
    NSURL *fileURL = [self textBundleURLForFilename:@"only text"];
    
    
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(e);
    
    XCTAssertEqualObjects(tb.text, @"Text");
    XCTAssertEqualObjects(tb.metadata, @{});
    XCTAssertEqualObjects(tb.version, @(2));
    XCTAssertEqualObjects(tb.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(tb.transient, @(0));
    XCTAssertEqualObjects(tb.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 0);
}


- (void)testLoadTextPlusAttachments
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    NSFileWrapper *assetWrapper = [tb fileWrapperForAssetFilename:@"oh no.jpg"];
    
    XCTAssertNil(e);
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);
    XCTAssertNotNil(assetWrapper);
    XCTAssertNotNil(assetWrapper.regularFileContents);
}

- (void)testLoadMissingInfo
{
    NSURL *fileURL = [self textBundleURLForFilename:@"invalid no info"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(tb);
    XCTAssertEqualObjects(e.domain, TextBundleErrorDomain);
    XCTAssertEqual(e.code, TextBundleErrorInvalidFormat);
}

- (void)testLoadMissingText
{
    NSURL *fileURL = [self textBundleURLForFilename:@"invalid no text"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(tb);
    XCTAssertEqualObjects(e.domain, TextBundleErrorDomain);
    XCTAssertEqual(e.code, TextBundleErrorInvalidFormat);
}

#pragma mark - Writing

- (void)testWriteExitingTextBundleToAnotherURL
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test.textbundle"];
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:nil];

    NSError *e = nil;
    BOOL success = [tb writeToURL:targetURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&e];
    
    XCTAssertTrue(success);
    XCTAssertNil(e);
    
    e = nil;

    TextBundleWrapper *newTB = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];
    
    XCTAssertNil(e);

    XCTAssertEqualObjects(newTB.text, @"Text");
    XCTAssertEqualObjects(newTB.metadata, @{});
    XCTAssertEqualObjects(newTB.version, @(2));
    XCTAssertEqualObjects(newTB.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(newTB.transient, @(0));
    XCTAssertEqualObjects(newTB.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);
}


- (void)testCreateAndWriteTextBundle
{
    TextBundleWrapper *tb = [TextBundleWrapper new];
    tb.text = @"Some Text";
    
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test.textbundle"];
    
    NSError *e = nil;
    BOOL success = [tb writeToURL:targetURL options:NSFileWrapperWritingAtomic originalContentsURL:nil error:&e];
    
    XCTAssertNil(e);
    XCTAssertTrue(success);    
}

#pragma mark - Assets

- (void)testAddAssets
{
    NSURL *fileURL = [self textBundleURLForFilename:@"only text"];
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL options:NSFileWrapperReadingImmediate error:&e];

    NSURL *assetURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"sample asset" withExtension:@"jpg"];
    NSFileWrapper *assetFileWrapper = [[NSFileWrapper alloc] initWithURL:assetURL options:0 error:nil];
    
    // Adding the first time should add the file to the bundle
    NSString *filename = [tb addAssetFileWrapper:assetFileWrapper];
    XCTAssertEqualObjects(filename, @"sample asset.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);

    // Adding the same filewrapper again should do nothing
    filename = [tb addAssetFileWrapper:assetFileWrapper];
    XCTAssertEqualObjects(filename, @"sample asset.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 1);

    // Adding a different file with the same name should update the new name
    NSURL *assetURL2 = [[NSBundle bundleForClass:[self class]] URLForResource:@"sample asset 2" withExtension:@"jpg"];
    NSFileWrapper *assetFileWrapper2 = [[NSFileWrapper alloc] initWithURL:assetURL2 options:0 error:nil];
    
    assetFileWrapper2.filename = @"sample asset.jpg";
    assetFileWrapper2.preferredFilename = @"sample asset.jpg";
    filename = [tb addAssetFileWrapper:assetFileWrapper2];
    XCTAssertEqualObjects(filename, @"sample asset 2.jpg");
    XCTAssertEqual(tb.assetsFileWrapper.fileWrappers.count, 2);
}


@end
