//
//  CRC.h
//  BakongKHQR
//
//  Created by Seth Sambo on 12/15/20.
//

#import <Foundation/Foundation.h>
#import "../Protocols/TagLengthStringProtocol.h"

@interface CRC : NSObject<TagLengthStringProtocol>

-(id)initWithPayloadString :(NSString *)payload;
-(void)setQRString: (NSString *)payload;
-(NSString *) decodeWithQr: (NSString *)qr;

@end

