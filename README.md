# CHTTPManager

[![CI Status](http://img.shields.io/travis/nbyh100@sina.com/CHTTPManager.svg?style=flat)](https://travis-ci.org/nbyh100@sina.com/CHTTPManager)
[![Version](https://img.shields.io/cocoapods/v/CHTTPManager.svg?style=flat)](http://cocoapods.org/pods/CHTTPManager)
[![License](https://img.shields.io/cocoapods/l/CHTTPManager.svg?style=flat)](http://cocoapods.org/pods/CHTTPManager)
[![Platform](https://img.shields.io/cocoapods/p/CHTTPManager.svg?style=flat)](http://cocoapods.org/pods/CHTTPManager)

## Example
```
[CHTTPManager requestWithURL:@"http://www.mocky.io/v2/59b640850f00003e03712378"
                      params:[CHTTPRequestParams new]
 .setMethod(CHTTPMethodPost)
 .setQuery(@{@"one": @"1", @"two": @"2"})
 .setRequestBody(@{@"foo": @"bar", @"hello": @"world"})
 .setRequestBodyType(CHTTPRequestBodyTypeJSON)
 .setResponseBodyType(CHTTPResponseBodyTypeJSON)
 ]
.then(^(id response) {
    NSLog(@"Response: %@", response);
});`
```

## Author

nbyh100@sina.com

## License

CHTTPManager is available under the MIT license. See the LICENSE file for more info.
