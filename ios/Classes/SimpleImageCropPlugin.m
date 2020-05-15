#import "SimpleImageCropPlugin.h"

#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <UIKit/UIKit.h>

@implementation SimpleImageCropPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
                                   methodChannelWithName:@"plugins.lykhonis.com/image_crop"
                                   binaryMessenger:[registrar messenger]];
  SimpleImageCropPlugin* instance = [SimpleImageCropPlugin new];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"cropImage" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* left = (NSNumber*)call.arguments[@"left"];
        NSNumber* top = (NSNumber*)call.arguments[@"top"];
        NSNumber* right = (NSNumber*)call.arguments[@"right"];
        NSNumber* bottom = (NSNumber*)call.arguments[@"bottom"];
        NSNumber* scale = (NSNumber*)call.arguments[@"scale"];
        NSNumber* quality = (NSNumber*)call.arguments[@"quality"];
        CGRect area = CGRectMake(left.floatValue, top.floatValue,
                                 right.floatValue - left.floatValue,
                                 bottom.floatValue - top.floatValue);
        [self cropImage:path area:area scale:scale quality:quality result:result];
    } else if ([@"sampleImage" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* maximumWidth = (NSNumber*)call.arguments[@"maximumWidth"];
        NSNumber* maximumHeight = (NSNumber*)call.arguments[@"maximumHeight"];
        [self sampleImage:path
             maximumWidth:maximumWidth
            maximumHeight:maximumHeight
                   result:result];
    } else if ([@"getImageOptions" isEqualToString:call.method]) {
        NSString* path = (NSString*)call.arguments[@"path"];
        [self getImageOptions:path result:result];
    } else if ([@"requestPermissions" isEqualToString:call.method]){
        [self requestPermissionsWithResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

// - (void)cropImage:(NSString*)path
//              area:(CGRect)area
//             scale:(NSNumber*)scale
//           quality:(NSNumber*)quality
//            result:(FlutterResult)result {
//     [self execute:^{
//         NSURL* url = [NSURL fileURLWithPath:path];

//         CGImageSourceRef imageSource = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
//         if (imageSource == NULL) {
//             result([FlutterError errorWithCode:@"INVALID"
//                                        message:@"Image source cannot be opened"
//                                        details:nil]);
//             return;
//         }
        
//         CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
        
//         if (image == NULL) {
//             result([FlutterError errorWithCode:@"INVALID"
//                                        message:@"Image cannot be opened"
//                                        details:nil]);
//             CFRelease(imageSource);
//             return;
//         }
        
//         size_t width = CGImageGetWidth(image);
//         size_t height = CGImageGetHeight(image);
//         size_t scaledWidth = (size_t) (width * area.size.width * scale.floatValue);
//         size_t scaledHeight = (size_t) (height * area.size.height * scale.floatValue);
//         size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
//         size_t bytesPerRow = CGImageGetBytesPerRow(image) / width * scaledWidth;
//         CGImageAlphaInfo bitmapInfo = CGImageGetAlphaInfo(image);
//         CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
        
//         CGImageRef croppedImage = CGImageCreateWithImageInRect(image,
//                                                                CGRectMake(width * area.origin.x,
//                                                                           height * area.origin.y,
//                                                                           width * area.size.width,
//                                                                           height * area.size.height));
        
//         CFRelease(image);
//         CFRelease(imageSource);
        
//         if (scale.floatValue != 1.0) {
//             CGContextRef context = CGBitmapContextCreate(NULL,
//                                                          scaledWidth,
//                                                          scaledHeight,
//                                                          bitsPerComponent,
//                                                          bytesPerRow,
//                                                          colorspace,
//                                                          bitmapInfo);
            
//             if (context == NULL) {
//                 result([FlutterError errorWithCode:@"INVALID"
//                                            message:@"Image cannot be scaled"
//                                            details:nil]);
//                 CFRelease(croppedImage);
//                 return;
//             }
            
//             CGRect rect = CGContextGetClipBoundingBox(context);
//             CGContextDrawImage(context, rect, croppedImage);
            
//             CGImageRef scaledImage = CGBitmapContextCreateImage(context);
            
//             CGContextRelease(context);
//             CFRelease(croppedImage);
            
//             croppedImage = scaledImage;
//         }
        
//         NSURL* croppedUrl = [self createTemporaryImageUrl];
//         bool saved = [self saveImage:croppedImage url:croppedUrl quality:quality];
//         CFRelease(croppedImage);
        
//         if (saved) {
//             result(croppedUrl.path);
//         } else {
//             result([FlutterError errorWithCode:@"INVALID"
//                                        message:@"Cropped image cannot be saved"
//                                        details:nil]);
//         }
//     }];
// }

- (void)cropImage:(NSString*)path
             area:(CGRect)area
            scale:(NSNumber*)scale
          quality:(NSNumber*)quality
           result:(FlutterResult)result {

    [self execute:^{

        UIImage* inputImage = [UIImage imageWithContentsOfFile:path];

        if (inputImage == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Input image cannot be opened"
                                       details:nil]);
            return;
        }                             

        CGRect cropRect = CGRectMake(inputImage.size.width * area.origin.x,
                                     inputImage.size.height * area.origin.y,
                                     inputImage.size.width * area.size.width,
                                     inputImage.size.height * area.size.height);

        UIImage* resultImage = [self cuttingImageToRect:inputImage toRect:cropRect];

        NSString* resultPath = [self createTemporaryImagePath];
        CGFloat compressionQuality = [quality floatValue]/ 100;

        bool success = [UIImageJPEGRepresentation(resultImage, compressionQuality) writeToFile:resultPath atomically:YES];  

        if (success) {
            // result(resultPath);
            result(@{
                @"path" : resultPath,
                @"width" : @((int) roundf(resultImage.size.width)),
                @"height" : @((int) roundf(resultImage.size.height))
            });
        } else {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Cropped image cannot be saved"
                                       details:nil]);
        }
    }];
}

- (UIImage *)cuttingImageToRect:(UIImage *)image toRect:(CGRect)rect {
    CGFloat (^rad)(CGFloat) = ^CGFloat(CGFloat deg) {
        return deg / 180.0f * (CGFloat) M_PI;
    };

    // determine the orientation of the image and apply a transformation to the crop rectangle to shift it to the correct position
    CGAffineTransform rectTransform;
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -image.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -image.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -image.size.width, -image.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    };

    // adjust the transformation scale based on the image scale
    rectTransform = CGAffineTransformScale(rectTransform, image.scale, image.scale);

    // apply the transformation to the rect to create a new, shifted rect
    CGRect transformedCropSquare = CGRectApplyAffineTransform(rect, rectTransform);
    // use the rect to crop the image
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, transformedCropSquare);
    // create a new UIImage and set the scale and orientation appropriately
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    // memory cleanup
    CGImageRelease(imageRef);

    return result;
}

- (void)sampleImage:(NSString*)path
       maximumWidth:(NSNumber*)maximumWidth
      maximumHeight:(NSNumber*)maximumHeight
             result:(FlutterResult)result {
    [self execute:^{
        NSURL* url = [NSURL fileURLWithPath:path];
        CGImageSourceRef image = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
        if (image == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source cannot be opened"
                                       details:nil]);
            return;
        }

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil);

        if (properties == NULL) {
            CFRelease(image);
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source properties cannot be copied"
                                       details:nil]);
            return;
        }

        NSNumber* width = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
        NSNumber* height = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
        CFRelease(properties);

        double widthRatio = MIN(1.0, maximumWidth.doubleValue / width.doubleValue);
        double heightRatio = MIN(1.0, maximumHeight.doubleValue / height.doubleValue);
        double ratio = MAX(widthRatio, heightRatio);
        NSNumber* maximumSize = @(MAX(width.doubleValue * ratio, height.doubleValue * ratio));

        CFDictionaryRef options = (__bridge CFDictionaryRef) @{
                                                               (id) kCGImageSourceCreateThumbnailWithTransform: @YES,
                                                               (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                               (id) kCGImageSourceThumbnailMaxPixelSize : maximumSize
                                                               };
        CGImageRef sampleImage = CGImageSourceCreateThumbnailAtIndex(image, 0, options);
        CFRelease(image);

        if (sampleImage == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image sample cannot be created"
                                       details:nil]);
            return;
        }

        NSURL* sampleUrl = [self createTemporaryImageUrl];
        bool saved = [self saveImage:sampleImage url:sampleUrl quality:[NSNumber numberWithInt:100]];
        CFRelease(sampleImage);
        
        if (saved) {
            result(sampleUrl.path);
        } else {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image sample cannot be saved"
                                       details:nil]);
        }
    }];
}

- (void)getImageOptions:(NSString*)path result:(FlutterResult)result {
    [self execute:^{
        NSURL* url = [NSURL fileURLWithPath:path];
        CGImageSourceRef image = CGImageSourceCreateWithURL((CFURLRef) url, NULL);
        
        if (image == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source cannot be opened"
                                       details:nil]);
            return;
        }

        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil);
        CFRelease(image);
        
        if (properties == NULL) {
            result([FlutterError errorWithCode:@"INVALID"
                                       message:@"Image source properties cannot be copied"
                                       details:nil]);
            return;
        }

        NSNumber* width = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
        NSNumber* height = (NSNumber*) CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
        CFRelease(properties);

        result(@{ @"width": width,  @"height": height });
    }];
}

- (void)requestPermissionsWithResult:(FlutterResult)result {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            result(@YES);
        } else {
            result(@NO);
        }
    }];
}

- (bool)saveImage:(CGImageRef)image url:(NSURL*)url quality:(NSNumber*)quality {

    float compression = [quality floatValue] / 100;
    CFStringRef myKeys[1];
    CFTypeRef   myValues[1];
    CFDictionaryRef options = NULL;
    myKeys[0] = kCGImageDestinationLossyCompressionQuality;
    myValues[0] = CFNumberCreate(NULL, kCFNumberFloatType, &compression);
    options = CFDictionaryCreate( NULL, (const void **)myKeys, (const void **)myValues, 1,
                               &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef) url, kUTTypeJPEG, 1, NULL);
    CGImageDestinationAddImage(destination, image, options);
    
    bool finilized = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    return finilized;
}

- (NSURL*)createTemporaryImageUrl {
    NSString* temproraryDirectory = NSTemporaryDirectory();
    NSString* guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString* sampleName = [[@"image_crop_" stringByAppendingString:guid] stringByAppendingString:@".jpg"];
    NSString* samplePath = [temproraryDirectory stringByAppendingPathComponent:sampleName];
    return [NSURL fileURLWithPath:samplePath];
}

- (NSString*)createTemporaryImagePath {
    NSString* temproraryDirectory = NSTemporaryDirectory();
    NSString* guid = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString* sampleName = [[@"image_crop_" stringByAppendingString:guid] stringByAppendingString:@".jpg"];
    NSString* samplePath = [temproraryDirectory stringByAppendingPathComponent:sampleName];
    return samplePath;
}

- (void)execute:(void (^)(void))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

@end
