//
//  ReserveForUse.m
//  BakongKHQR
//
//  Created by Seth Sambo on 1/11/21.
//

#import "ReserveForUse.h"
#import "KHQRMerchantPresentedCodes.h"

@interface ReserveForUse()

@property (strong, nonatomic) NSString * milliseconds;

@end

@implementation ReserveForUse

@synthesize tag;
@synthesize value;

#pragma mark - Init
-(id)initWithMilliseconds:(NSString *)millisecond {
    self = [super init];
    if (self) {
        _milliseconds = millisecond;
    }
    return self;
}

#pragma mark - Decode
-(NSString *) decodeWithQr: (NSString *)qr {
    NSString * tagFromQR = [qr substringToIndex: self.tag.length];
    NSString * remaningQR = @"";
        
    // ex: 991700131612343224123 -> timestamp = 1612343224123
    if ([tagFromQR isEqualToString: self.tag]) {
        remaningQR = [qr stringByReplacingCharactersInRange: NSMakeRange(0, 2) withString: @""];
    
        // for Length + RFU_GLOBALLY_UNIQUE_IDENTIFIER
        remaningQR = [remaningQR stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString: @""];
        
        // extract length
        NSInteger valueLength = [remaningQR substringToIndex: 2].intValue;
        remaningQR = [remaningQR stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString: @""];
        _milliseconds = [remaningQR substringToIndex: valueLength];
        
        remaningQR = [remaningQR stringByReplacingCharactersInRange:NSMakeRange(0, valueLength) withString: @""];
        return remaningQR;
    }
    return qr;
}


#pragma mark - Helper functions
-(NSString *) globalUniqueIdentifierTag {
    return RFU_GLOBALLY_UNIQUE_IDENTIFIER;
}

#pragma mark - Protocol
-(NSString *) tag {
    return RFU_TAG;
}

-(NSString *) value {
    return _milliseconds;
}

- (NSString *)toString {
    NSString * uniqueIdentifierTag = [self globalUniqueIdentifierTag];
    long totalLengthCount = self.tag.length + uniqueIdentifierTag.length + self.value.length;
    long timeStamplengthCount = self.value.length;
    
    NSString * totalLengthString = [NSString stringWithFormat:@"%02ld", totalLengthCount];
    NSString * lengthString = [NSString stringWithFormat:@"%02ld", timeStamplengthCount];
    NSString* toStringValue = [NSString stringWithFormat: @"%@%@%@%@%@",
                               self.tag, totalLengthString, uniqueIdentifierTag, lengthString, self.value];
    return toStringValue;
}

@end
