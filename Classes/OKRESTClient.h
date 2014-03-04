//
//  Created by M. Ramón López Torres on 02/06/13.
//  Copyright (c) 2013 M. Ramón López Torres. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OKRESTClient;
@protocol OKRESTClientDelegate <NSObject>

-(void)didFinished:(OKRESTClient *)sender withResponse:(NSString *)response;
-(void)didFinished:(OKRESTClient *)sender withError:(NSError *)error;

@end
@interface OKRESTClient : NSObject

@property (strong, nonatomic) NSString *server;
@property (strong, nonatomic) NSString *phrase;
@property (weak, nonatomic) id<OKRESTClientDelegate> delegate;


-(id)initWithServer:(NSString *)server andPhrase:(NSString *)phrase;
-(NSString *)generateSignature:(NSDictionary *)parameters;
-(NSString *)getDataFrom:(NSString *)resource parameters:(NSDictionary *)parameters;
-(NSString *)postDataTo:(NSString *)resource  parameters:(NSDictionary *)parameters;
-(NSString *)putDataTo:(NSString *)resource parameters:(NSDictionary *)parameters;
-(NSString *)deleteFrom:(NSString *)resource parameters:(NSDictionary *)parameters;
@end

