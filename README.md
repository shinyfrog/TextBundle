# TextBundle
`TextBundleWrapper` is a fast and simple Library for reading/writing [TextBundle](http://textbundle.org) files.

## Table of Contents

* [**Installation**](#installation)
	* [Install from sources](#install-from-sources)
	* [Carthage](#carthage)
	* [Framework](#framework)
* [**Usage**](#usage)
	* [TextBundle text content](#reading-the-textbundle-text-content)
	* [TextBundle assets](#reading-the-textbundle-assets)
	* [TextBundle Meta data](#reading-the-textbundle-meta-data)
* [**License**](#license)
* [**Contacts**](#contacts)
## Installation
`TextBundleWrapper` is a single class with no dependencies, you can install it from source code, using [Carthage](https://github.com/Carthage/Carthage) or embedding the `TextBundle.framework` in your project.

### Install from sources
Just download and drag the TextBundleWrapper.{h,m} files in your Xcode project

### Carthage
To install with Carthage, add the following to your Cartfile:
`github "CocoaLumberjack/CocoaLumberjack"`

### Framework
Reference the `TextBundle.xcodeproj` in your project and drag the `TextBundle.framework` inside the `Embedded Binaries`.

## Usage

If you're using TextBundle as a framework, you can `@import CocoaLumberjack` if you’re using swift or `#import <CocoaLumberjack/CocoaLumberjack.h>` for Obj-C.

### Reading the TextBundle text content

``` objective-c
NSError *e = nil;
TextBundleWrapper *tb = [[TextBundleWrapper new] initWithContentsOfURL:fileURL 
                                                               options:NSFileWrapperReadingImmediate 
                                                                 error:&e];

// Reading the plain text content
NSString *text = tb.text;

// The UTI of the text (Markdown, HTML, etc...)
NSString *type = tb.type;
```

### Reading the TextBundle assets

``` objective-c
// Iterating the asset files
[tb.assetsFileWrapper.fileWrappers enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSFileWrapper *fw, BOOL *stop) 
{
    // File name
    NSString *filename = fw.filename;

    // Writing the file somewhere
    [fw writeToURL:URL options:0 originalContentsURL:nil error:nil];
}];
```

### Reading the TextBundle Meta Data
`TextBundleWrapper` conforms to the [TextBundle Specification](http://textbundle.org/spec/), please use the specs as 
reference for properties and their values.

``` objective-c
NSDictionary *metadata = tb.metadata;
```

## Author
[Matteo Rattotti](https://github.com/matteorattotti)

## Licence
`TextBundleWrapper` is available under the MIT license. See the LICENSE file for details.

## Contacts
If you want to ask a technical question, feel free to raise an [issue](https://github.com/shinyfrog/TextBundle/issues) or write to hello@shinyfrog.net.

