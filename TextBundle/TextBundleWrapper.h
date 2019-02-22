//
//  TextBundle.h
//  TextBundle-Mac
//
//  Created by Matteo Rattotti on 22/02/2019.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TextBundleWrapper : NSObject

@property (strong, nonnull) NSString *text;
@property (strong, nullable) NSMutableArray *assetsURLs;

@property (strong, nonatomic) NSNumber *version;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSNumber *transient;
@property (strong, nonatomic) NSString *creatorIdentifier;

@property (strong) NSMutableDictionary *metadata;


- (instancetype)initWithContentsOfURL:(NSURL *)url error:(NSError **)error;

- (BOOL)writeToURL:(NSURL *)url error:(NSError **)error;


@end

NS_ASSUME_NONNULL_END
