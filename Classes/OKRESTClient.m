//
//  Created by M. Ramón López Torres on 02/06/13.
//  Copyright (c) 2013 M. Ramón López Torres. All rights reserved.
//

#import "OKRESTClient.h"
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#define ServerURL @"your.url.com"
#define PHRASE @""

@implementation OKRESTClient
@synthesize delegate = _delegate;
@synthesize server = _server;
@synthesize phrase = _phrase;

-(id)initWithServer:(NSString *)server andPhrase:(NSString *)phrase {
    self = [super init];
    
    if (self) {
        _server = server;
        _phrase = phrase;
    }
    
	return self;
}

- (NSString *) putDataTo:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [self SendData:resource parameters:parameters postMethod:false];
}

- (NSString *) postDataTo:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [self SendData:resource parameters:parameters postMethod:true];
}

- (NSString *)deleteFrom:(NSString *)resource parameters:(NSDictionary *)parameters {
    return [self getOrDelete:resource parameters:parameters deleteMethod:true];
}

- (NSString *) getDataFrom:(NSString *)resource parameters:(NSDictionary *)parameters{
    return [self getOrDelete:resource parameters:parameters deleteMethod:false];
}

- (NSString *) getOrDelete:(NSString *)resource parameters:(NSDictionary *)parameters deleteMethod:(Boolean)delete {
    NSString *signature = [self generateSignature:parameters];
    NSString *querystring = [self getQueryString:parameters];
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
  
    if (self.delegate) {
        [NSURLConnection sendAsynchronousRequest:request queue:Nil completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             if (error) {
                 [self.delegate didFinished:self withError:error];
             } else if([httpResponse statusCode] != 200){
                 // TODO: Manage errors (better)
                 NSError * newError = [[NSError alloc] initWithDomain:@"OKRESTClient" code:[httpResponse statusCode] userInfo:nil];
                 [self.delegate didFinished:self withError:newError];
             } else {
                 NSString *response = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                 [self.delegate didFinished:self withResponse:response];
             }
         }];
    } else {
        NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
        
        if([responseCode statusCode] != 200){
            // TODO: Manage errors
        }
        
        return [[NSString alloc] initWithData:oResponseData encoding:NSASCIIStringEncoding];
    }
    
    return Nil;
}

- (NSString *) SendData:(NSString *)resource parameters:(NSDictionary *)parameters postMethod:(Boolean)post {
    NSString *signature = [self generateSignature:parameters];
    NSString *querystring = [self getQueryString:parameters];

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
    
    if (self.delegate) {
        [NSURLConnection sendAsynchronousRequest:request queue:Nil completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
         {
             NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
             if (error) {
                 [self.delegate didFinished:self withError:error];
             } else if([httpResponse statusCode] != 200){
                 // TODO: Manage errors (better)
                 NSError * newError = [[NSError alloc] initWithDomain:@"OKRESTClient" code:[httpResponse statusCode] userInfo:nil];
                 [self.delegate didFinished:self withError:newError];
             } else {
                 NSString *response = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                 [self.delegate didFinished:self withResponse:response];
             }
         }];
    } else {
        NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
        
        if([responseCode statusCode] != 200){
            // TODO: Manage errors
        }
        
        return [[NSString alloc] initWithData:oResponseData encoding:NSASCIIStringEncoding];
    }
    
    return Nil;
}


- (NSString *) getQueryString:(NSDictionary *)parameters{
    NSString *querystring = @"";
    for (NSString *key in parameters) {
        NSObject *value = [parameters objectForKey:key];

        querystring = [querystring stringByAppendingString:[NSString stringWithFormat:@"%@=%@&",key, value]];
    }
    
   return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)querystring,NULL,NULL,kCFStringEncodingUTF8);
}


-(NSString *)generateSignature:(NSDictionary *)parameters {
    if ([PHRASE isEqualToString:@""]) {
        return nil;
    }
    
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
    
    const char *cPhrase  = [PHRASE cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [jsonString cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cPhrase, strlen(cPhrase), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    signature = [HMAC description];
    signature = [signature stringByReplacingOccurrencesOfString:@" " withString:@""];
    signature = [signature stringByReplacingOccurrencesOfString:@"<" withString:@""];
    signature = [signature stringByReplacingOccurrencesOfString:@">" withString:@""];
    
    return signature;
}

@end
