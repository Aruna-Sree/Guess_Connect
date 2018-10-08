//
//  OTLogUtil.h
//  OnTrack
//


#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif // __OBJC__


#if defined(__cplusplus)
#define UTIL_EXTERN extern "C"
#else
#define UTIL_EXTERN extern
#endif


#define kNSEnableLoggingPref @"enablelogging_preference"
FOUNDATION_EXPORT void deleteLogsFile();
FOUNDATION_EXPORT void OTLog(NSString *format, ...);
FOUNDATION_EXPORT BOOL OTLogIsEnabled();
FOUNDATION_EXPORT void SetOTLogEnabled(BOOL enabled);