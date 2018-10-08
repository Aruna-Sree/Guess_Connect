//
//  OTLogUtil.m
//  OnTrack
//


#import "OTLogUtil.h"

NSFileHandle *handler = nil;

void WriteToFilemessageAs(NSString* msg)
{
    [handler seekToEndOfFile];
    
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [handler writeData:data];
}

void Init()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *strFilePath = [NSString stringWithFormat:@"%@/Logfile.txt", documentsDirectory];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:strFilePath])
    {
        [[NSFileManager defaultManager]createFileAtPath:strFilePath contents:nil attributes:nil];
    }
    handler = [NSFileHandle fileHandleForWritingAtPath:strFilePath];
    
}
FOUNDATION_EXPORT void
deleteLogsFile(){
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"Logfile.txt"];
    NSError *error;
    [fileManager removeItemAtPath:filePath error:&error];
    handler = nil;
}
FOUNDATION_EXPORT void
OTLog(NSString *format, ...)
{
    #if DEBUG
    va_list ap;
    va_start(ap, format);
    NSLogv(format, ap);
    va_end(ap);
    #endif
    if (OTLogIsEnabled() == YES)
    {
        va_list ap;
        va_start(ap, format);
        NSLogv(format, ap);
        va_end(ap);
        if (handler == nil){
            Init();
        }
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yyyy hh:mm:ss a"];
        
        NSString *logString = [[NSString alloc] initWithFormat:format arguments:ap];
        NSString* contentInFile = [NSString stringWithFormat: @"\n%@   %@",[formatter stringFromDate:[NSDate date]], logString];
        WriteToFilemessageAs(contentInFile);
        
    }
}


FOUNDATION_EXPORT BOOL
OTLogIsEnabled()
{
   
	return(
           [[NSUserDefaults standardUserDefaults]
			boolForKey:@"DEBUG"]
           );
}


FOUNDATION_EXPORT void
SetOTLogEnabled(BOOL enabled){
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:@"DEBUG"];
}

