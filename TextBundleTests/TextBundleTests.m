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

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSURL *)textBundleURLForFilename:(NSString *)filename
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:filename withExtension:@"textbundle"];
}

- (void)testLoadTextOnly
{
    NSURL *fileURL = [self textBundleURLForFilename:@"only text"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL error:&e];
    
    NSDictionary *expectedMetadata = @{
                                       @"version":@(2),
                                       @"type":@"net.daringfireball.markdown",
                                       @"transient":@(0),
                                       @"creatorIdentifier":@"net.shinyfrog.TextBundleTest",
                                       };
    
    XCTAssertNil(e);
    
    XCTAssertEqualObjects(tb.text, @"Text");
    XCTAssertEqualObjects(tb.metadata, expectedMetadata);
    XCTAssertEqualObjects(tb.version, @(2));
    XCTAssertEqualObjects(tb.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(tb.transient, @(0));
    XCTAssertEqualObjects(tb.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertNil(tb.assetsURLs);
}


- (void)testLoadTextPlusAttachments
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    
    NSError *e = nil;
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL error:&e];
    
    XCTAssertNil(e);
    XCTAssertTrue(tb.assetsURLs.count == 1);
}



- (void)testWriteExitingTextBundleToAnotherURL
{
    NSURL *fileURL = [self textBundleURLForFilename:@"text plus attachments"];
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test.textbundle"];
    TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL error:nil];

    NSError *e = nil;
    BOOL success = [tb writeToURL:targetURL error:&e];
    
    XCTAssertTrue(success);
    XCTAssertNil(e);
    
    e = nil;

    TextBundleWrapper *newTB = [[TextBundleWrapper new] initWithContentsOfURL:targetURL error:&e];
    
    XCTAssertNil(e);

    NSDictionary *expectedMetadata = @{
                                       @"version":@(2),
                                       @"type":@"net.daringfireball.markdown",
                                       @"transient":@(0),
                                       @"creatorIdentifier":@"net.shinyfrog.TextBundleTest",
                                       };

    XCTAssertEqualObjects(newTB.text, @"Text");
    XCTAssertEqualObjects(newTB.metadata, expectedMetadata);
    XCTAssertEqualObjects(newTB.version, @(2));
    XCTAssertEqualObjects(newTB.type, @"net.daringfireball.markdown");
    XCTAssertEqualObjects(newTB.transient, @(0));
    XCTAssertEqualObjects(newTB.creatorIdentifier, @"net.shinyfrog.TextBundleTest");
    XCTAssertTrue(newTB.assetsURLs.count == 1);
}


- (void)testCreateAndWriteTextBundle
{
    TextBundleWrapper *tb = [TextBundleWrapper new];
    tb.text = @"Some Text";
    
    NSURL *targetURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"test.textbundle"];
    
    NSError *e = nil;
    BOOL success = [tb writeToURL:targetURL error:&e];
    
    XCTAssertNil(e);
    XCTAssertTrue(success);    
}

@end
