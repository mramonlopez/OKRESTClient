//
//  Created by M. Ramón López Torres on 02/06/13.
//  Copyright (c) 2013 M. Ramón López Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OKRESTClient : NSObject

+(NSString *)generateSignature:(NSDictionary *)parameters;
+(NSString *)getDataFrom:(NSString *)resource parameters:(NSDictionary *)parameters;
+(NSString *)postDataTo:(NSString *)resource  parameters:(NSDictionary *)parameters;
+(NSString *)putDataTo:(NSString *)resource parameters:(NSDictionary *)parameters;
+(NSString *)deleteFrom:(NSString *)resource parameters:(NSDictionary *)parameters;
@end
@interface NSURLRequest (DummyInterface)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end
