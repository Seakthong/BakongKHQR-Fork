//
//  CRCValidation.h
//  BakongKHQR
//
//  Created by Seth Sambo on 12/22/20.
//

#import <Foundation/Foundation.h>
#import "ResponseProtocol.h"

@interface CRCValidation : NSObject<ResponseProtocol>

@property (nonatomic, assign) BOOL valid;

-(id _Nonnull )initWithStatus: (BOOL)status;
-(BOOL)isEqualTo: (CRCValidation * _Nonnull)crcValidation;

@end
