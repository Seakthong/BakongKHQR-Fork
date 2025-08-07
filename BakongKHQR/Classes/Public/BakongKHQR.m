//
//  BakongKHQR.m
//  BakongKHQR
//
//  Created by Seth Sambo on 12/9/20.
//

#import "BakongKHQR.h"
#import "NSData+CRC-16CCITT.h"
#import "QrCrc16.h"
#import "KHQRData.h"


@interface BakongKHQR()

@end

@implementation BakongKHQR

#pragma mark - Generate Individual
+(KHQRResponse * _Nonnull)generateIndividual: (IndividualInfo * _Nonnull)info {
    Constants.shared.isDecoding = FALSE;
    Constants.shared.isGenerateIndividual = TRUE;
    KHQRData * khqrData;
    @try {
        khqrData = [[KHQRData alloc] initWithQR: [BakongKHQR toString: info]];
    }
    @catch (KHQRException *exception) {
        return [[KHQRResponse alloc] initWithErrorCode: exception.errorCode
                                               message: exception.message
                                                  data: NULL];
    }
    return [[KHQRResponse alloc] initWithErrorCode: NULL
                                           message: NULL
                                              data: khqrData];
}

#pragma mark - Generate Merchant
+(KHQRResponse * _Nonnull)generateMerchant:(MerchantInfo *)info {
    Constants.shared.isDecoding = FALSE;
    Constants.shared.isGenerateIndividual = FALSE;
    KHQRData * khqrData;
    @try {
        khqrData = [[KHQRData alloc] initWithQR: [BakongKHQR toString: info]];
    }
    @catch (KHQRException *exception) {
        return [[KHQRResponse alloc] initWithErrorCode: exception.errorCode
                                               message: exception.message
                                                  data: NULL];
    }
    return [[KHQRResponse alloc] initWithErrorCode: NULL
                                           message: NULL
                                              data: khqrData];
}

#pragma mark

+(KHQRResponse *)verify:(NSString *)khqrCode {
    @try {
        Constants.shared.isDecoding = FALSE;
        NSString * remaningQR = khqrCode;
        
        // empty string or null will not get pass
        [BakongKHQR checkKhqrException: khqrCode];
        
        // check crc exception
        NSRange range = [khqrCode rangeOfString:@"6304[A-Fa-f0-9]{4}$" options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            NSString * qrWithoutCrc;
            NSString * crcValue = [khqrCode substringFromIndex: khqrCode.length - 8];
            qrWithoutCrc = [khqrCode substringToIndex: khqrCode.length - 4];
            
            CRC * crc = [[CRC alloc] initWithPayloadString: qrWithoutCrc];
            [crc decodeWithQr: crcValue];
        } else {
            // required crc
            KHQRException * exception = [[KHQRException alloc] initWithReason: crcRequired
                                                                    errorCode: [ErrorConstants crcRequiredCode]];
            [exception raise];
        }
        
        // get all tags as list
        NSString * previousTag = @"0";
        NSMutableDictionary * taglist = [[NSMutableDictionary alloc] init];
        BOOL isContinue = TRUE;
        do {
            NSString * tag = [Constants subString:remaningQR toIndex: 2];
            remaningQR = [Constants replaceString:remaningQR withEmptyStringToIndex: 2];
            NSString * length = [Constants subString:remaningQR toIndex: 2];
            remaningQR = [Constants replaceString: remaningQR withEmptyStringToIndex: 2];
            NSString * value = [Constants subString:remaningQR toIndex: length.intValue];
            remaningQR = [Constants replaceString: remaningQR withEmptyStringToIndex: length.intValue];
            NSString * tagLengthValue = [NSString stringWithFormat:@"%@%@%@", tag, length, value];
            
            // check tag in order
//            if (tag.intValue < previousTag.intValue && tag.intValue != 63) {
//                KHQRException * exception = [[KHQRException alloc] initWithReason: tagNotInOrder
//                                                                        errorCode: [ErrorConstants tagNotInOrderCode]];
//                [exception raise];
//            }
            
//            NSLog(@"%@ | %@", tag, tagLengthValue);
            if ([taglist objectForKey: tag]) {
                NSLog(@"%@", taglist); 
                // key already existed found duplicated tag, throw error invalid qr
                KHQRException * exception = [[KHQRException alloc] initWithReason:
                                             qrInvalid
                                        errorCode: [ErrorConstants qrInvalidCode]];
                [exception raise];
            }
            [taglist setValue:tagLengthValue forKey: tag];
            previousTag = tag;
            if (IsEmpty(remaningQR)) {
                isContinue = false;
            }
        } while (isContinue);
        
        // check all required tags
        NSArray * keys = taglist.allKeys;
        for (NSString * _tag in [Constants requiredTags]) {
            int index = [keys indexOfObject: _tag];
            
            if ([_tag isEqualToString: @"29"] || [_tag isEqualToString: @"30"]) {
                if (((int) [keys indexOfObject: @"29"]) < 0 && ((int) [keys indexOfObject: @"30"]) < 0) {
                    [Constants checkEmptyOrNullException: @"" reason: merchantIdrequired];
                }
            }
            if (index < 0 && [_tag isEqualToString: @"00"]) {
                [Constants checkEmptyOrNullException: @"" reason: formatIndicatorRequired];
            }
            else if (index < 0 && [_tag isEqualToString: @"52"]) {
                [Constants checkEmptyOrNullException: @"" reason: merchantCategoryCodeRequired];
            }
            else if (index < 0 && [_tag isEqualToString: @"53"]) {
                [Constants checkEmptyOrNullException: @"" reason: currencyTypeRequired];
            }
            else if (index < 0 && [_tag isEqualToString: @"58"]) {
                [Constants checkEmptyOrNullException: @"" reason: countryCodeRequired];
            }
            else if (index < 0 && [_tag isEqualToString: @"59"]) {
                [Constants checkEmptyOrNullException: @"" reason: merchantNameRequired];
            }
            else if (index < 0 && [_tag isEqualToString: @"60"]) {
                [Constants checkEmptyOrNullException: @"" reason: merchantCityRequired];
            }
        }
        
        // check validation all tags
        MerchantCategoryCode * merchantCategoryCode;
        CurrencyType crType;
        for(NSString* tag in taglist) {
            NSString * tagLengthValue = taglist[tag];
            
//            NSLog(@"%@", tagLengthValue);
            
            if ([tag isEqualToString: @"00"]) {
                FormatIndicator * formatIndicator = [[FormatIndicator alloc] init];
                [formatIndicator decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"01"]) {
                PointInitialize * pointOfInitialize = [[PointInitialize alloc] init];
                [pointOfInitialize decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"15"]) {
                UnionPay * unionPay = [[UnionPay alloc] init];
                [unionPay decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"29"] || [tag isEqualToString: @"30"]) {
                MerchantAccount * merchantAccount = [[MerchantAccount alloc] init];
                [merchantAccount decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"52"]) {
                merchantCategoryCode = [[MerchantCategoryCode alloc] init];
                [merchantCategoryCode decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"53"]) {
                TransactionCurrency * trCurrency = [[TransactionCurrency alloc] init];
                [trCurrency decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"54"]) {
                TransactionAmount * trAmount = [[TransactionAmount alloc] initWithAmount: 0 currencyType: crType];
                [trAmount decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"58"]) {
                CountryCode * countryCode = [[CountryCode alloc] init];
                [countryCode decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"59"]) {
                MerchantName * merchantName = [[MerchantName alloc] init];
                [merchantName decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"60"]) {
                MerchantCity * merchantCity = [[MerchantCity alloc] init];
                [merchantCity decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"62"]) {
                BKAdditionalData * additionalData = [[BKAdditionalData alloc] init];
                [additionalData decodeWithQr: tagLengthValue];
            }
            else if ([tag isEqualToString: @"99"]) {
                ReserveForUse * reserveForUse = [[ReserveForUse alloc] init];
                [reserveForUse decodeWithQr: tagLengthValue];
            }
        }
        
        // If there is no exception, the crc validation is TRUE
        // Since crc is check at first (check required and check isValid)
        return [[KHQRResponse alloc] initWithErrorCode: NULL
                                               message: NULL
                                                  data: [[CRCValidation alloc] initWithStatus: TRUE]];
        
    } @catch (KHQRException *exception) {
        return [[KHQRResponse alloc] initWithErrorCode: exception.errorCode
                                               message: exception.message
                                                  data: NULL];
    }
    
}

#pragma mark - Decode
+(KHQRResponse *)decode: (NSString *)qr {
    Constants.shared.isDecoding = TRUE;
    KHQRDecodeData *khqrDecodeData;
    @try {
        Constants.shared.isDecoding = TRUE;
        BakongKHQR * bakongKhqr = [[BakongKHQR alloc] init];
        NSMutableDictionary *dic = [bakongKhqr internalDecode: qr];
        khqrDecodeData = [[KHQRDecodeData alloc]
        initWithFormatIndicator:dic[@"formatIndicator"]
        pointOfInitiation:dic[@"pointOfInitialize"]
        qrType:dic[@"qrType"]
        upiAccountInformation:dic[@"upiAccountInformation"]
        bakongAccountId:dic[@"bakongAccountId"]
        merchantAccountId:dic[@"merchantAccountId"]
        accountInformation:dic[@"accountInformation"]
        acquiringBank:dic[@"acquiringBank"]
        merchantCategoryCode:dic[@"merchantCategoryCode"]
        countryCode:dic[@"countryCode"]
        merchantName:dic[@"merchantName"]
        merchantCity:dic[@"merchantCity"]
        transactionCurrency:dic[@"trCurrency"]
        transactionAmout:dic[@"trAmount"]
        billNumber:dic[@"billNumber"]
        mobileNumber:dic[@"mobileNumber"]
        storeLabel:dic[@"storeLabel"]
        terminalLabel:dic[@"terminalLabel"]
        purposeOfTransaction:dic[@"purposeOfTransaction"]
        merchantAlternateLanguagePreference: dic[@"merchantLanguageAlternatePreference"]
        merchantNameAlternateLanguage: dic[@"merchantNameAlternateLanguage"]
        merchantCityAlternateLanguage: dic[@"merchantCityAlternateLanguage"]
        timestamp:dic[@"reserveForUse"]
        crc:dic[@"crc"]];
    }
    @catch (KHQRException *exception) {
        return [[KHQRResponse alloc] initWithErrorCode: exception.errorCode
                                               message: exception.message
                                                  data: NULL];
    }
    return [[KHQRResponse alloc] initWithErrorCode: NULL
                                           message: NULL
                                              data: khqrDecodeData];
}

#pragma mark - Generate Deeplink
+(KHQRResponse *)generateDeepLink:(NSString *)url
                               qr: (NSString *)qr
                       sourceInfo:(SourceInfo * _Nullable)sourceInfo {
    
    KHQRResponse __block *khqrResponse;
    
    // check internet connection
    if (![BakongKHQR connectedToInternet]) {
        return [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants connectionTimeoutErrorCode]
                                               message: [ErrorConstants connectionTimeoutErrorMessage]
                                                  data: NULL];
    }
    
    // checck url empty and valid url
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL: [NSURL URLWithString: url]];
    if (IsEmpty(url) || !canOpenURL) {
        return [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants invalidDeepLinkURLCode]
                                               message: [ErrorConstants invalidDeepLinkURLMessage]
                                                  data: NULL];
    }
    
    // check valid qr code
    if ([BakongKHQR verify: qr].status.code == [NSNumber numberWithInt: 1]) {
        return [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants qrInvalidCode]
                                               message: [ErrorConstants qrInvalidMessage]
                                                  data: NULL];
    }
    
    //check source info data
    if (IsEmpty(sourceInfo) == FALSE) {
        if (IsEmpty(sourceInfo.appIconURL) || IsEmpty(sourceInfo.appName) || IsEmpty(sourceInfo.appDeepLinkCallback)) {
            return [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants invalidDeepSourceInfoErrorCode]
                                                   message: [ErrorConstants invalidDeepSourceInfoErrorMessage]
                                                      data: NULL];
        }
    }
    
    dispatch_semaphore_t  sem;
    sem = dispatch_semaphore_create(0);
    
    NSError * error;
    NSURLSession * session = [NSURLSession sessionWithConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: url]
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: [Constants timeoutInterval]];
    // setup request headers
    [request addValue: @"application/json" forHTTPHeaderField: @"Content-Type"];
    [request setHTTPMethod: @"POST"];
    
    // set request parameters
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    [params setObject:qr forKey:@"qr"];
    
    if (sourceInfo.appIconURL && sourceInfo.appName && sourceInfo.appDeepLinkCallback) {
        [params setObject:@{
            @"appIconUrl": sourceInfo.appIconURL,
            @"appName": sourceInfo.appName,
            @"appDeepLinkCallback": sourceInfo.appDeepLinkCallback} forKey:@"sourceInfo"];
    }
    
    NSData * postData = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    [request setHTTPBody: postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest: request
                                                    completionHandler:^(NSData *data,
                                                                        NSURLResponse *response,
                                                                        NSError *error) {
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 200) {
            NSError *parseError = nil;
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
            if (parseError == NULL) {
                NSDictionary *data = [responseDictionary objectForKey: @"data"];
                if([data isEqual:[NSNull null]] == FALSE) {
                    NSString *link = [data objectForKey:@"shortLink"];
                    khqrResponse = [[KHQRResponse alloc] initWithErrorCode: NULL
                                                                   message: NULL
                                                                      data: [[KHQRDeepLinkData alloc] initWithShortLink: link]];
                } else {
                    khqrResponse = [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants internalServerErrorCode]
                                                                   message: [ErrorConstants internalServerErrorMessage]
                                                                      data: NULL];
                }
                
            } else {
                // parse failed
                khqrResponse = [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants internalServerErrorCode]
                                                               message: [ErrorConstants internalServerErrorMessage]
                                                                  data: NULL];
            }
        }
        else {
            if (httpResponse.statusCode == 401 || httpResponse.statusCode == 500) {
                // server not reponse or other http error
                khqrResponse = [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants connectionTimeoutErrorCode]
                                                               message: [ErrorConstants connectionTimeoutErrorMessage]
                                                                  data: NULL];
            }
            khqrResponse = [[KHQRResponse alloc] initWithErrorCode: [ErrorConstants internalServerErrorCode]
                                                           message: [ErrorConstants internalServerErrorMessage]
                                                              data: NULL];
        }
        dispatch_semaphore_signal(sem);
    }];
    
    [postDataTask resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return khqrResponse;
}

#pragma mark - Private functions
+(NSString *) toString:(id<AccountTypeProtocol> _Nonnull)info {
    @try {
        //fixed tags
        FormatIndicator * formatIndicator = [[FormatIndicator alloc] initWithVersion: [Constants version]];
        MerchantCategoryCode * merchantCategoryCode = [[MerchantCategoryCode alloc] initWithCode: [Constants defaultMerchantCategoryCode]];
        CountryCode * countryCode = [[CountryCode alloc] initWithCountryCode: [Constants defaultCountryCode]];
        
        MerchantCity * merchantCity;
        if (IsEmpty(info.merchantCity)) {
            merchantCity = [[MerchantCity alloc] initWithMerchantCity: [Constants defaultCity]];
        } else {
            merchantCity = [[MerchantCity alloc] initWithMerchantCity: info.merchantCity];
        }
        
        // user input tags
        MerchantAccount * merchantAccount;
        
        if ([info isKindOfClass: [MerchantInfo class]]) {
            merchantAccount = [[MerchantAccount alloc] initWithAccountId: info.accountId
                                                              merchantId: info.merchantId
                                                           acquiringBank: info.acquiringBank];
        } else {
            merchantAccount = [[MerchantAccount alloc] initWithAccountId: info.accountId
                                                      accountInformation: info.accountInformation
                                                           acquiringBank: info.acquiringBank];
        }
        
        MerchantName * merchantName = [[MerchantName alloc] initWithName: info.merchantName];
        TransactionCurrency * trCurrency = [[TransactionCurrency alloc] initWithCurrency: info.currencyType];
        NSMutableArray * array = [[NSMutableArray alloc] initWithObjects: merchantAccount,
                                  merchantCategoryCode,
                                  trCurrency,
                                  countryCode,
                                  merchantCity,
                                  formatIndicator,
                                  merchantName
                                  , nil];
        
        // UnionPay
        if (info.upiAccountInformation) {
            UnionPay * unionPay = [[UnionPay alloc]
                                   initWithUpiAccountInformation:info.upiAccountInformation
                                   currencyType:info.currencyType];
            [array addObject: unionPay];
        }
        
        // include transaction amount in qr string only if has amount
        // has amount then -> dynamicQR(30), otherwise staticQR(29)
        if (info.amount) {
            TransactionAmount * trAmount = [[TransactionAmount alloc]
                                            initWithAmount: info.amount
                                            currencyType: info.currencyType];
            PointInitialize * pointOfInitialize = [[PointInitialize alloc] initWithQrType: [Constants dynamicQR]];
            [array addObjectsFromArray:@[trAmount, pointOfInitialize]];
        } else {
            PointInitialize * pointOfInitialize = [[PointInitialize alloc] initWithQrType: [Constants staticQR]];
            [array addObject: pointOfInitialize];
        }
        
        // Reserve for future use
        long long milliseconds = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
        ReserveForUse * reserveForUse = [[ReserveForUse alloc] initWithMilliseconds: [NSString stringWithFormat:@"%lld", milliseconds]];
        [array addObject: reserveForUse];
        
        // additional data
        if (info.billNumber || info.mobileNumber || info.storeLabel || info.terminalLabel || info.purposeOfTransaction) {
            BKAdditionalData * additionalData = [[BKAdditionalData alloc] init];
            if (info.billNumber) { [additionalData setBillNumber: info.billNumber]; }
            if (info.mobileNumber) { [additionalData setMobileNumber: info.mobileNumber]; }
            if (info.storeLabel) { [additionalData setStoreLabel: info.storeLabel]; }
            if (info.terminalLabel) { [additionalData setTerminalLabel: info.terminalLabel]; }
            if (info.purposeOfTransaction) { [additionalData setPurposeOfTransaction: info.purposeOfTransaction]; }
            [array addObject: additionalData];
        }
        
        // merchant information alternate language 
        if (info.merchantNameAlternateLanguage || info.merchantCityAlternateLanguage) {
            if (info.merchantAlternateLanguagePreference) {
                MerchantLanguageTemplate * template = [[MerchantLanguageTemplate alloc] init];
                [template setMerchantLanguageAlternatePreference: info.merchantAlternateLanguagePreference];
                [template setMerchantNameAlternateLanguage: info.merchantNameAlternateLanguage];
                if (info.merchantCityAlternateLanguage) {
                    [template setMerchantCityAlternateLanguage: info.merchantCityAlternateLanguage];
                }
                [array addObject: template];
            } else {
                // language preference null
                KHQRException * exception = [ [KHQRException alloc]
                    initWithReason: merchantLanguagePreferenceRequired
                    errorCode: [ErrorConstants merchantLanguagePreferenceRequiredCode]];
                [exception raise];
            }
        } else {
            if (info.merchantAlternateLanguagePreference) {
                MerchantLanguageTemplate * template = [[MerchantLanguageTemplate alloc] init];
                [template setMerchantLanguageAlternatePreference: info.merchantAlternateLanguagePreference];
                [array addObject:template];
            }
        }
            
        // sort by tag
        NSArray * myArray = [array sortedArrayUsingComparator: ^ NSComparisonResult(id<TagLengthStringProtocol> a, id<TagLengthStringProtocol> b) {
            return [a.tag compare: b.tag];
        }];
        
        NSMutableString * payloadString = [[NSMutableString alloc] init];
        for (id<TagLengthStringProtocol> obj in myArray) {
            [payloadString appendString: [obj toString]];
        }
        
        // add crc
        [payloadString appendString: @"6304"];
        CRC * crc = [[CRC alloc] initWithPayloadString: payloadString];
        [payloadString appendString: [crc value]];
        
        return payloadString;
    }
    @catch (KHQRException *exception) {
        @throw exception;
    }
    return @"";
}

#pragma mark - Helper functions
+ (BOOL)connectedToInternet {
    NSString *urlString = @"https://www.google.com/";
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    NSHTTPURLResponse __block *response;
    
    dispatch_semaphore_t  sem;
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData* _data,
                                                         NSURLResponse* _response,
                                                         NSError* _error) {
        response = (NSHTTPURLResponse *) _response;
        dispatch_semaphore_signal(sem);
    }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return (response.statusCode == 200) ? YES : NO;
}

// empty qr value empty or null will throw exception
+ (void) checkKhqrException: (NSString *) qr {
    if (IsEmpty(qr) || qr.length < 8) {
        KHQRException * exception = [[KHQRException alloc] initWithReason: qrInvalid
                                                                errorCode: [ErrorConstants qrInvalidCode]];
        [exception raise];
    }
}

- (NSMutableDictionary *) internalDecode: (NSString* )qr {
    NSString * remaningQR = qr;
    BOOL isContinue = TRUE;
    NSMutableDictionary * tagDic = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * valueDic = [[NSMutableDictionary alloc] init];
    @try {
        // check crc exception
        NSRange range = [qr rangeOfString:@"6304[A-Fa-f0-9]{4}$" options:NSRegularExpressionSearch];
        if (range.location != NSNotFound) {
            NSString * crcValue = [qr substringFromIndex: qr.length - 8];
            NSString * crc = [Constants replaceString:crcValue withEmptyStringToIndex: 4];
            [valueDic setValue: crc forKey:@"crc"];
        }
        
        // all tags as list
        NSString * previousTag = @"0";
        do {
            NSString * tag = [Constants subString:remaningQR toIndex: 2];
            remaningQR = [Constants replaceString:remaningQR withEmptyStringToIndex: 2];
            NSString * length = [Constants subString:remaningQR toIndex: 2];
            remaningQR = [Constants replaceString: remaningQR withEmptyStringToIndex: 2];
            NSString * value = [Constants subString:remaningQR toIndex: length.intValue];
            remaningQR = [Constants replaceString: remaningQR withEmptyStringToIndex: length.intValue];
            NSString * tagLengthValue = [NSString stringWithFormat:@"%@%@%@", tag, length, value];
            
            [tagDic setValue:tagLengthValue forKey: tag];
            previousTag = tag;
            if (IsEmpty(remaningQR)) {
                isContinue = false;
            }
        } while (isContinue);
        
        MerchantCategoryCode * merchantCategoryCode;
        CurrencyType crType;
        // decode
        for(NSString* tag in tagDic) {
            NSString * tagLengthValue = tagDic[tag];
            //            NSLog(@"%@", tagLengthValue);
            
            if ([tag isEqualToString: @"00"]) {
                FormatIndicator * formatIndicator = [[FormatIndicator alloc] init];
                [formatIndicator decodeWithQr: tagLengthValue];
                [valueDic setValue: formatIndicator.value forKey:@"formatIndicator"];
            }
            else if ([tag isEqualToString: @"01"]) {
                PointInitialize * pointOfInitialize = [[PointInitialize alloc] init];
                [pointOfInitialize decodeWithQr: tagLengthValue];
                [valueDic setValue: pointOfInitialize.value forKey:@"pointOfInitialize"];
            }
            else if ([tag isEqualToString: @"15"]) {
                UnionPay * unionPay = [[UnionPay alloc] init];
                [unionPay decodeWithQr: tagLengthValue];
                [valueDic setValue: unionPay.value forKey:@"upiAccountInformation"];
            }
            else if ([tag isEqualToString: @"29"] || [tag isEqualToString: @"30"]) {
                MerchantAccount * merchantAccount = [[MerchantAccount alloc] init];
                [merchantAccount decodeWithQr: tagLengthValue];
                [valueDic setValue: merchantAccount.getType == Individual ? @"29" : @"30" forKey:@"qrType"];
                [valueDic setValue: merchantAccount.getAccountId forKey:@"bakongAccountId"];
                [valueDic setValue: merchantAccount.getAccountInformation forKey:@"accountInformation"];
                [valueDic setValue: merchantAccount.getMerchantId forKey:@"merchantAccountId"];
                [valueDic setValue: merchantAccount.getAcquiringBank forKey:@"acquiringBank"];
            }
            else if ([tag isEqualToString: @"52"]) {
                merchantCategoryCode = [[MerchantCategoryCode alloc] init];
                [merchantCategoryCode decodeWithQr: tagLengthValue];
                [valueDic setValue: merchantCategoryCode.value forKey:@"merchantCategoryCode"];
            }
            else if ([tag isEqualToString: @"53"]) {
                TransactionCurrency * trCurrency = [[TransactionCurrency alloc] init];
                [trCurrency decodeWithQr: tagLengthValue];
                [valueDic setValue: merchantCategoryCode.value forKey:@"merchantCategoryCode"];
                
                crType = [trCurrency value].intValue == 116 ? Khr : Usd;
                [valueDic setValue: [trCurrency value] forKey:@"trCurrency"];
            }
            else if ([tag isEqualToString: @"54"]) {
                TransactionAmount * trAmount = [[TransactionAmount alloc] initWithAmount: 0 currencyType: crType];
                [trAmount decodeWithQr: tagLengthValue];
                [valueDic setValue: trAmount.value forKey:@"trAmount"];
            }
            else if ([tag isEqualToString: @"58"]) {
                CountryCode * countryCode = [[CountryCode alloc] init];
                [countryCode decodeWithQr: tagLengthValue];
                [valueDic setValue: countryCode.value forKey:@"countryCode"];
            }
            else if ([tag isEqualToString: @"59"]) {
                MerchantName * merchantName = [[MerchantName alloc] init];
                [merchantName decodeWithQr: tagLengthValue];
                [valueDic setValue: merchantName.value forKey:@"merchantName"];
            }
            else if ([tag isEqualToString: @"60"]) {
                MerchantCity * merchantCity = [[MerchantCity alloc] init];
                [merchantCity decodeWithQr: tagLengthValue];
                [valueDic setValue: merchantCity.value forKey:@"merchantCity"];
            }
            else if ([tag isEqualToString: @"62"]) {
                BKAdditionalData * additionalData = [[BKAdditionalData alloc] init];
                [additionalData decodeWithQr: tagLengthValue];
                [valueDic setValue: [additionalData getBillNumber] forKey:@"billNumber"];
                [valueDic setValue: [additionalData getMobileNumber] forKey:@"mobileNumber"];
                [valueDic setValue: [additionalData getStoreLabel] forKey:@"storeLabel"];
                [valueDic setValue: [additionalData getTerminalLabel] forKey:@"terminalLabel"];
                [valueDic setValue: [additionalData getPurposeOfTransaction] forKey:@"purposeOfTransaction"];
            }
            else if ([tag isEqualToString: @"64"]) {
                MerchantLanguageTemplate * template = [[MerchantLanguageTemplate alloc] init];
                [template decodeWithQr: tagLengthValue];
                [valueDic setValue: [template getMerchantLanguageAlternatePreference] forKey:@"merchantLanguageAlternatePreference"];
                [valueDic setValue: [template getMerchantNameAlternateLanguage] forKey:@"merchantNameAlternateLanguage"];
                [valueDic setValue: [template getMerchantCityAlternateLanguage] forKey:@"merchantCityAlternateLanguage"];
            }
            else if ([tag isEqualToString: @"99"]) {
                ReserveForUse * reserveForUse = [[ReserveForUse alloc] init];
                [reserveForUse decodeWithQr: tagLengthValue];
                [valueDic setValue: reserveForUse.value forKey:@"reserveForUse"];
            }
        }
    }
    @catch (KHQRException *exception) {
        @throw exception;
        return false;
    }
    return valueDic;
}

+ (QrCrc16 *) getQrCrc16: (NSString* )code {
    // extract crc
    NSString *crc = [code substringFromIndex: MAX((int)[code length]-4, 0)];
    // extract qrCode's content without crc
    NSString *codeWithoutCrc = [code stringByReplacingOccurrencesOfString: crc
                                                               withString: @""];
    
    QrCrc16* crc16 = [[QrCrc16 alloc] initWithCode: codeWithoutCrc
                                           crcCode: crc];
    return crc16;
}

@end
