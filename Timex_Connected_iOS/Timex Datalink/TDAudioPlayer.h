//
//  TDAudioPlayer.h
//  Timex Connected
//
//  Created by Lev Verbitsky on 2/10/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol TDAudioPlayerDelegate;

@interface TDAudioPlayer : NSObject
{
    id <TDAudioPlayerDelegate> delegate;
}
+(TDAudioPlayer *) sharedPlayer;

- (void) initWithURL: (NSURL *) songURL andRepeatCount: (NSInteger) loopNumber andVolume: (float) volume previewOnly: (BOOL) previewFlag delegate: (id <TDAudioPlayerDelegate>) del;
- (BOOL) stop;

@end

@protocol TDAudioPlayerDelegate
- (void) FinishedPlayingSound;
- (void) ErrorPlayingSound;
@end