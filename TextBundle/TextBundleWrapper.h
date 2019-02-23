//
//  TextBundle.h
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const TextBundleErrorDomain;

typedef NS_ENUM(NSInteger, TextBundleError)
{
    TextBundleErrorInvalidFormat,
};

@interface TextBundleWrapper : NSObject

@property (strong, nonnull) NSString *text;
@property (strong, nonnull) NSFileWrapper *assetsFileWrapper;

@property (strong) NSNumber *version;
@property (strong) NSString *type;
@property (strong) NSNumber *transient;
@property (strong) NSString *creatorIdentifier;

@property (strong) NSMutableDictionary *metadata;

- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;
- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
