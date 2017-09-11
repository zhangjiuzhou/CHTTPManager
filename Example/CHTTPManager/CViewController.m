//
//  CViewController.m
//  CHTTPManager
//
//  Created by nbyh100@sina.com on 09/11/2017.
//  Copyright (c) 2017 nbyh100@sina.com. All rights reserved.
//

#import <CHTTPManager/CHTTPManager.h>
#import "CViewController.h"

@interface CViewController ()

@end

@implementation CViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

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
    });
}

@end
