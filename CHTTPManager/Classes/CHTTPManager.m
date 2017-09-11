//
//  CHTTPManager.m
//  CHTTPManager
//
//  Created by Jiuzhou Zhang on 2017/1/16.
//
//

#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>
#import "CHTTPManager.h"

@interface CHTTPRequestParams ()

@property (nonatomic, assign) CHTTPMethod method;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSDictionary *query;
@property (nonatomic, strong) id requestBody;
@property (nonatomic, assign) CHTTPRequestBodyType requestBodyType;
@property (nonatomic, strong) NSArray *acceptContentTypes;
@property (nonatomic, assign) CHTTPResponseBodyType responseBodyType;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) CHTTPCachePolicy cachePolicy;

@end

@implementation CHTTPRequestParams

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.method = CHTTPMethodGet;
        self.requestBodyType = CHTTPRequestBodyTypeJSON;
        self.responseBodyType = CHTTPResponseBodyTypeJSON;
        self.cachePolicy = CHTTPCachePolicyDefault;
    }
    return self;
}

- (CHTTPRequestParams *(^)(CHTTPMethod method))setMethod
{
    return ^(CHTTPMethod method) {
        self.method = method;
        return self;
    };
}

- (CHTTPRequestParams *(^)(NSDictionary *headers))setHeaders
{
    return ^(NSDictionary *headers) {
        self.headers = headers;
        return self;
    };
}

- (CHTTPRequestParams *(^)(NSDictionary *query))setQuery
{
    return ^(NSDictionary *query) {
        self.query = query;
        return self;
    };
}

- (CHTTPRequestParams *(^)(id requestBody))setRequestBody
{
    return ^(NSDictionary *requestBody) {
        self.requestBody = requestBody;
        return self;
    };
}

- (CHTTPRequestParams *(^)(CHTTPRequestBodyType requestBodyType))setRequestBodyType
{
    return ^(CHTTPRequestBodyType requestBodyType) {
        self.requestBodyType = requestBodyType;
        return self;
    };
}

- (CHTTPRequestParams *(^)(NSArray *acceptContentTypes))setAcceptContentTypes
{
    return ^(NSArray *acceptContentTypes) {
        self.acceptContentTypes = acceptContentTypes;
        return self;
    };
}

- (CHTTPRequestParams *(^)(CHTTPResponseBodyType responseBodyType))setResponseBodyType
{
    return ^(CHTTPResponseBodyType responseBodyType) {
        self.responseBodyType = responseBodyType;
        return self;
    };
}

- (CHTTPRequestParams *(^)(NSTimeInterval timeout))setTimeout
{
    return ^(NSTimeInterval timeout) {
        self.timeout = timeout > 0 ? timeout : 0;
        return self;
    };
}

- (CHTTPRequestParams *(^)(CHTTPCachePolicy cache))setCachePolicy
{
    return ^(CHTTPCachePolicy cachePolicy) {
        self.cachePolicy = cachePolicy;
        return self;
    };
}

@end

@interface CTextRequestSerializer : AFHTTPRequestSerializer

@end

@implementation CTextRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(request);

    if ([self.HTTPMethodsEncodingParametersInURI containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    }

    NSMutableURLRequest *mutableRequest = [request mutableCopy];

    [self.HTTPRequestHeaders enumerateKeysAndObjectsUsingBlock:^(id field, id value, BOOL * __unused stop) {
        if (![request valueForHTTPHeaderField:field]) {
            [mutableRequest setValue:value forHTTPHeaderField:field];
        }
    }];

    if (parameters) {
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        }

        [mutableRequest setHTTPBody:[[parameters description] dataUsingEncoding:NSUTF8StringEncoding]];
    }

    return mutableRequest;
}

@end

@interface CTextResponseSerializer : AFHTTPResponseSerializer

@end

@implementation CTextResponseSerializer

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error
{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@interface PMKPromise (CHTTPManager)

@property (nonatomic, strong) NSURLSessionTask *http_task;
@property (nonatomic, assign, readonly) long long http_taskID;

@end

@implementation PMKPromise (CHTTPManager)

- (void)setHttp_task:(NSURLSessionTask *)http_task
{
    objc_setAssociatedObject(self, @selector(http_task), http_task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURLSessionTask *)http_task
{
    return objc_getAssociatedObject(self, @selector(http_task));
}

- (void)setHttp_taskID:(long long)http_taskID
{
    objc_setAssociatedObject(self, @selector(http_taskID), @(http_taskID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (long long)http_taskID
{
    return [objc_getAssociatedObject(self, @selector(http_taskID)) longLongValue];
}

@end

@interface CHTTPManager ()

@property (nonatomic, strong) NSMutableArray *reuseableSessionManagers;

@end

@implementation CHTTPManager

+ (PMKPromise *)requestWithURL:(NSString *)URL params:(CHTTPRequestParams *)params
{
    return [[[self class] sharedInstance] _requestWithURL:URL params:params];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.reuseableSessionManagers = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)sharedInstance
{
    static CHTTPManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

- (PMKPromise *)_requestWithURL:(NSString *)URL
                         params:(CHTTPRequestParams *)params
{
    __block NSURLSessionTask *task;
    static long long taskID = 0;

    AFHTTPSessionManager *sessionManager = [self _dequeueResuableSessionManager];

    PMKPromise *promise = [PMKPromise new:^(PMKFulfiller fulfill, PMKRejecter reject) {
        NSString *theURL = URL;
        CHTTPMethod method = params.method;
        NSDictionary *headers = params.headers;
        NSDictionary *query = params.query;
        NSDictionary *body = params.requestBody;
        CHTTPRequestBodyType bodyType = params.requestBodyType;
        NSArray *acceptContentTypes = params.acceptContentTypes;
        CHTTPResponseBodyType responseBodyType = params.responseBodyType;
        double timeout = params.timeout;
        CHTTPCachePolicy *cachePolicy = params.cachePolicy ? : CHTTPCachePolicyDefault;

        if (query && query.allKeys.count > 0) {
            NSString *queryString = AFQueryStringFromParameters(query);
            theURL = [NSString stringWithFormat:@"%@%@%@", URL, [URL rangeOfString:@"?"].location == NSNotFound ? @"?" : @"&", queryString];
        }

        AFHTTPRequestSerializer *reqSerializer = [self _requestSerializerWithType:bodyType];
        if (headers) {
            for (NSString *field in headers) {
                [reqSerializer setValue:headers[field] forHTTPHeaderField:field];
            }
        }
        if (timeout > 0) {
            reqSerializer.timeoutInterval = timeout;
        }
        reqSerializer.cachePolicy = [self _cachePolicyWithType:cachePolicy];

        AFHTTPResponseSerializer *resSerializer = [self _responseSerializerWithType:responseBodyType];
        if (acceptContentTypes) {
            resSerializer.acceptableContentTypes = [NSSet setWithArray:acceptContentTypes];
        }

        sessionManager.requestSerializer = reqSerializer;
        sessionManager.responseSerializer = resSerializer;

        task = [self _taskWithSessionManager:sessionManager
                                         url:theURL
                                      method:method
                                        body:body
                                    progress:nil
                                     fulfill:fulfill
                                      reject:reject];
        [task resume];
    }];

    promise.http_task = task;
    promise.http_taskID = taskID++;

    return promise;
}

- (AFHTTPSessionManager *)_dequeueResuableSessionManager
{
    if (self.reuseableSessionManagers.count > 0) {
        AFHTTPSessionManager *sessionManager = self.reuseableSessionManagers.firstObject;
        [self.reuseableSessionManagers removeObjectAtIndex:0];
        return sessionManager;
    } else {
        return [[AFHTTPSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    }
}

- (void)_enqueueResuableSessionManager:(AFHTTPSessionManager *)sessionManager
{
    if (self.reuseableSessionManagers.count < 20) {
        [self.reuseableSessionManagers addObject:sessionManager];
    } else {
        [sessionManager invalidateSessionCancelingTasks:NO];
    }
}

- (AFHTTPRequestSerializer *)_requestSerializerWithType:(CHTTPRequestBodyType)requestBodyType
{
    switch (requestBodyType) {
        case CHTTPRequestBodyTypeText:
            return [CTextRequestSerializer serializer];

        case CHTTPRequestBodyTypeJSON:
            return [AFJSONRequestSerializer serializer];

        case CHTTPRequestBodyTypeForm:
        default:
            return [AFHTTPRequestSerializer serializer];
    }
}

- (AFHTTPResponseSerializer *)_responseSerializerWithType:(CHTTPResponseBodyType)responseBodyType
{
    switch (responseBodyType) {
        case CHTTPResponseBodyTypeText:
            return [CTextResponseSerializer serializer];

        case CHTTPResponseBodyTypeJSON:
            return [AFJSONResponseSerializer serializer];

        case CHTTPResponseBodyTypeBlob:
        default:
            return [AFHTTPResponseSerializer serializer];
    }
}

- (NSURLRequestCachePolicy)_cachePolicyWithType:(CHTTPCachePolicy)cachePolicyType
{
    switch (cachePolicyType) {
        case CHTTPCachePolicyIgnoreCache:
            return NSURLRequestReloadIgnoringCacheData;

        default:
            return NSURLRequestUseProtocolCachePolicy;
    }
}

- (NSURLSessionTask *)_taskWithSessionManager:(AFHTTPSessionManager *)sessionManager
                                          url:(NSString *)url
                                       method:(CHTTPMethod)method
                                         body:(id)params
                                     progress:(void (^)(double progress))progress
                                      fulfill:(PMKFulfiller)fulfill
                                       reject:(PMKRejecter)reject
{
    __weak typeof(self) weakSelf = self;
    switch (method) {
        case CHTTPMethodPost:
            return [sessionManager POST:url
                             parameters:params
                               progress:^(NSProgress * _Nonnull uploadProgress) {
                                   if (progress) {
                                       progress(uploadProgress.fractionCompleted);
                                   }
                               } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                   __strong typeof(self) strongSelf = weakSelf;
                                   [strongSelf _enqueueResuableSessionManager:sessionManager];
                                   fulfill(responseObject);
                               } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                   __strong typeof(self) strongSelf = weakSelf;
                                   [strongSelf _enqueueResuableSessionManager:sessionManager];
                                   reject(error);
                               }];

        case CHTTPMethodGet:
        default:
            return [sessionManager GET:url
                            parameters:nil
                              progress:^(NSProgress * _Nonnull downloadProgress) {
                                  if (progress) {
                                      progress(downloadProgress.fractionCompleted);
                                  }
                              } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                  __strong typeof(self) strongSelf = weakSelf;
                                  [strongSelf _enqueueResuableSessionManager:sessionManager];
                                  fulfill(responseObject);
                              } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                  __strong typeof(self) strongSelf = weakSelf;
                                  [strongSelf _enqueueResuableSessionManager:sessionManager];
                                  reject(error);
                              }];
    }
}

@end
