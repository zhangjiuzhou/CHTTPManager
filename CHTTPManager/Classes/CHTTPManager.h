//
//  CHTTPManager.h
//  CHTTPManager
//
//  Created by Jiuzhou Zhang on 2017/1/16.
//
//

#import <Foundation/Foundation.h>
#import <PromiseKit/PromiseKit.h>

typedef NS_ENUM(NSInteger, CHTTPMethod) {
    CHTTPMethodGet,
    CHTTPMethodPost
};

typedef NS_ENUM(NSInteger, CHTTPRequestBodyType) {
    CHTTPRequestBodyTypeText,
    CHTTPRequestBodyTypeForm,
    CHTTPRequestBodyTypeJSON
};

typedef NS_ENUM(NSInteger, CHTTPResponseBodyType) {
    CHTTPResponseBodyTypeText,
    CHTTPResponseBodyTypeJSON,
    CHTTPResponseBodyTypeBlob
};

typedef NS_ENUM(NSInteger, CHTTPCachePolicy) {
    CHTTPCachePolicyDefault,
    CHTTPCachePolicyIgnoreCache
};

@interface CHTTPRequestParams : NSObject

@property (nonatomic, assign, readonly) CHTTPMethod method;
@property (nonatomic, strong, readonly) NSDictionary *headers;
@property (nonatomic, strong, readonly) NSDictionary *query;
@property (nonatomic, strong, readonly) NSDictionary *requestBody;
@property (nonatomic, assign, readonly) CHTTPRequestBodyType requestBodyType;
@property (nonatomic, strong, readonly) NSArray *acceptContentTypes;
@property (nonatomic, assign, readonly) CHTTPResponseBodyType responseBodyType;
@property (nonatomic, assign, readonly) NSTimeInterval timeout;
@property (nonatomic, assign, readonly) CHTTPCachePolicy cachePolicy;

- (CHTTPRequestParams *(^)(CHTTPMethod method))setMethod;
- (CHTTPRequestParams *(^)(NSDictionary *headers))setHeaders;
- (CHTTPRequestParams *(^)(NSDictionary *query))setQuery;
- (CHTTPRequestParams *(^)(id requestBody))setRequestBody;
- (CHTTPRequestParams *(^)(CHTTPRequestBodyType requestBodyType))setRequestBodyType;
- (CHTTPRequestParams *(^)(NSArray *acceptContentTypes))setAcceptContentTypes;
- (CHTTPRequestParams *(^)(CHTTPResponseBodyType responseBodyType))setResponseBodyType;
- (CHTTPRequestParams *(^)(NSTimeInterval timeout))setTimeout;
- (CHTTPRequestParams *(^)(CHTTPCachePolicy cachePolicy))setCachePolicy;

@end

@interface PMKPromise (CHTTPManager)

@property (nonatomic, strong, readonly) NSURLSessionTask *http_task;
@property (nonatomic, assign, readonly) long long http_taskID;

@end

@interface CHTTPManager : NSObject

+ (PMKPromise *)requestWithURL:(NSString *)URL
                        params:(CHTTPRequestParams *)params;

@end
