//
//  Created by M. Ramón López Torres on 02/06/13.
//  Copyright (c) 2013 M. Ramón López Torres. All rights reserved.
//

#import "OKRESTClient.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#define ServerURL @"your.url.com"

@implementation OKRESTClient

+ (NSString *) putDataTo:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [OKRESTClient SendData:resource parameters:parameters postMethod:false];
}

+ (NSString *) postDataTo:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [OKRESTClient SendData:resource parameters:parameters postMethod:true];
}

+ (NSString *)deleteFrom:(NSString *)resource parameters:(NSDictionary *)parameters {
    return [OKRESTClient getOrDelete:resource parameters:parameters deleteMethod:true];
}

+ (NSString *) getDataFrom:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [OKRESTClient getOrDelete:resource parameters:parameters deleteMethod:false];
}

+ (NSString *) getOrDelete:(NSString *)resource parameters:(NSDictionary *)parameters deleteMethod:(Boolean)delete {
    NSString *signature = [OKRESTClient generateSignature:parameters];
    NSString *querystring = [OKRESTClient getQueryString:parameters];
    querystring = [querystring stringByAppendingFormat:@"signature=%@", signature];
    
    NSString *url = [NSString stringWithFormat:@"http://%@/%@?%@", ServerURL, resource, querystring];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    if (delete)
        [request setHTTPMethod:@"DELETE"];
    else
        [request setHTTPMethod:@"GET"];
    
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
  
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        // TODO: Manage errors
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSASCIIStringEncoding];
}

+ (NSString *) SendData:(NSString *)resource parameters:(NSDictionary *)parameters postMethod:(Boolean)post {
    NSString *signature = [OKRESTClient generateSignature:parameters];
    NSString *querystring = [OKRESTClient getQueryString:parameters];

    querystring = [querystring stringByAppendingFormat:@"signature=%@", signature];
    NSData *requestdata = [querystring dataUsingEncoding:NSASCIIStringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    if (post) {
        [request setHTTPMethod:@"POST"];;
    }
    else {
        [request setHTTPMethod:@"PUT"];
    }
    
    NSString *url = [NSString stringWithFormat:@"http://%@/%@", ServerURL, resource];
    
    [request setURL:[NSURL URLWithString:url]];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody: requestdata];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    if([responseCode statusCode] != 200){
        // TODO: Manage errors
    }
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSASCIIStringEncoding];
}


+ (NSString *) getQueryString:(NSDictionary *)parameters{
    NSString *querystring = @"";
    for (NSString *key in parameters) {
        NSObject *value = [parameters objectForKey:key];

        querystring = [querystring stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key, value]];
    }
    
   return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)querystring,NULL,NULL,kCFStringEncodingUTF8);
}


+(NSString *)generateSignature:(NSDictionary *)parameters {
    id mySort = ^(NSString * key1, NSString * key2){
        return [key1 compare:key2];
    };
    
    NSString *signature;
    NSString *jsonString = @"";
    
    if ([parameters count]>0) {
        NSArray *sortedKeys = [[parameters allKeys] sortedArrayUsingComparator:mySort];      
        
        for (NSString *key in sortedKeys) {
            NSObject *value = [parameters objectForKey: key];

            if([jsonString length]==0) {
                jsonString = [NSString stringWithFormat:@"\"%@\":\"%@\"", key, value];
            } else {
                jsonString = [NSString stringWithFormat:@"%@,\"%@\":\"%@\"", jsonString, key, value];
            }
        }
        jsonString = [NSString stringWithFormat:@"{%@}", jsonString];
    }
    

    NSString *key = @"Your secret phrase here";
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [jsonString cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    signature = [HMAC description];
    signature = [signature stringByReplacingOccurrencesOfString:@" " withString:@""];
    signature = [signature stringByReplacingOccurrencesOfString:@"<" withString:@""];
    signature = [signature stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    return signature;

}

@end
