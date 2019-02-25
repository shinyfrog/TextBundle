# TextBundle
Library for reading/writing [TextBundle](http://textbundle.org) files

Installation

`TextBundleWrapper` is a single class with no dependencies, just download and drag the TextBundleWrapper.{h,m} files in your 
Xcode project or reference the `TextBundle.xcodeproj` in your project and drag the `TextBundle.framework` inside the 
`Embedded Binaries`.

## Reading a TextBundle file

``` objective-c
#import <TextBundle/TextBundle.h>

NSError *e = nil;
TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL 
                                                               options:NSFileWrapperReadingImmediate 
                                                                 error:&e];

// Reading the plain text content
NSString *text = tb.text;

// Iterating the asset files
[tb.assetsFileWrapper.fileWrappers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSFileWrapper *fw, BOOL *stop) 
{
    // File name
    NSString *filename = fw.filename;

    // Writing the file somewhere
    [fw writeToURL:URL options:0 originalContentsURL:nil error:nil];
}];

```


## Properties and Meta data

TextBundleWrapper conforms to the [TextBundle Specification](http://textbundle.org/spec/), please use the specs as 
reference for properties and their values.
