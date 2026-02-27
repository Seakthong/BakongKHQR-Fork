//
//  ReserveForUse.h
//  BakongKHQR
//
//  Created by Seth Sambo on 1/11/21.
//

#import <Foundation/Foundation.h>
#import "../Protocols/TagLengthStringProtocol.h"
#import "Enums.h"

@interface ReserveForUse : NSObject<TagLengthStringProtocol>

-(id)initWithMilliseconds :(NSString *)millisecond;
-(NSString *) decodeWithQr: (NSString *)qr;

@end

