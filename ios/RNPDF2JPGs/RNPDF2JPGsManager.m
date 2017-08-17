//
//  RNPDF2JPGsManager.m
//  RNPDF2JPGsManager
//
//  Created by starcwl on 8/16/17.
//  Copyright © 2017 zijingcloud. All rights reserved.
//

#import "RNPDF2JPGsManager.h"
#import "PDFView.h"
#import "UIImage+PDF.h"
#import "NSDate+Utilities.h"

@implementation RNPDF2JPGsManager

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(extractJPGsFromPDFWithURI:(NSString *)pdfPath
                  resolver:(RCTPromiseResolveBlock)resovle
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    NSMutableArray *pathArray = [[NSMutableArray alloc] init];

    BOOL fileExists = [[NSFileManager defaultManager] isReadableFileAtPath:pdfPath];

    if (!fileExists) {
        return reject(@"ENOENT", [NSString stringWithFormat:@"ENOENT: no such file or directory, open '%@'", pdfPath], nil);
    }

    NSError *error = nil;

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pdfPath error:&error];

    if (error) {
        return [self reject:reject withError:error];
    }

    if ([attributes objectForKey:NSFileType] == NSFileTypeDirectory) {
        return reject(@"EISDIR", @"EISDIR: illegal operation on a directory, read", nil);
    }


    CGFloat imageWidth = 1280;
    CGFloat imageHeight = 720;

    NSInteger pages = [PDFView pageCountForURL:[PDFView resourceURLForName:pdfPath]];

    for(NSInteger page = 0; page < pages; page++)
    {
        CGSize imageSize = CGSizeMake(imageWidth, imageHeight);
        UIImage *image = [UIImage imageWithPDFNamed:pdfPath atSize:imageSize atPage:page];
        NSString *filePath = [self getRandomDatePathAtPage:page];
        BOOL success = [UIImageJPEGRepresentation(image, 0.1) writeToFile:filePath atomically:NO];
        [pathArray addObject:filePath];
        if(!success){
            return reject(@"ECANCELED", [NSString stringWithFormat:@"ECANCELED: Operation canceled when writing to path '%@'", filePath], nil);
        }
    }

    resovle(pathArray);
}


- (NSString *)getRandomDatePathAtPage:(NSInteger)page{
    NSDate *now = [NSDate date];
    NSString *fileName = [NSString stringWithFormat:@"%@_%d",now.shortString, page];
    NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    return filePath;
}

- (void)reject:(RCTPromiseRejectBlock)reject withError:(NSError *)error
{
    NSString *codeWithDomain = [NSString stringWithFormat:@"E%@%zd", error.domain.uppercaseString, error.code];
    reject(codeWithDomain, error.localizedDescription, error);
}

@end
