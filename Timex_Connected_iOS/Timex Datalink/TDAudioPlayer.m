//
//  TDAudioPlayer.m
//  Timex Connected
//
//  Created by Lev Verbitsky on 2/10/14.
//  Copyright (c) 2014 iDevices, LLC. All rights reserved.
//

#import "TDAudioPlayer.h"

#define PREVIEW_TIMEOUT_TIME 8.0

@interface TDAudioPlayer()<AVAudioPlayerDelegate>
{
    AVAudioPlayer * player;
    NSTimer       * previewTimerEngine;
}
@end

static TDAudioPlayer * s_sharedPlayer = nil;

@implementation TDAudioPlayer

+(TDAudioPlayer*) sharedPlayer
{
    if ( s_sharedPlayer == nil )
    {
        s_sharedPlayer = [[TDAudioPlayer alloc] init];
    }
    
    return s_sharedPlayer;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void) initWithURL: (NSURL *) songURL andRepeatCount: (NSInteger) loopNumber andVolume: (float) volume previewOnly: (BOOL) previewFlag delegate: (id <TDAudioPlayerDelegate>) del
{
    BOOL needsDelay = FALSE;
    delegate = del;
    
    if ([self stop])
    {
        needsDelay = TRUE;
    }
    
    
    //I don't know why but without this block here, background sound doesn't work.... perhaps, timing issue?
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    player = [[AVAudioPlayer alloc] initWithContentsOfURL: songURL error: nil];
    player.delegate = self;
    player.numberOfLoops = loopNumber;
    [player setVolume: volume];
    [[MPMusicPlayerController applicationMusicPlayer] setVolume: volume];
    
    if (previewFlag == YES)
    {
        NSTimeInterval soundDuration = [player duration];
        if (soundDuration > PREVIEW_TIMEOUT_TIME)
        {
            NSInvocation *inv = [NSInvocation invocationWithMethodSignature: [self methodSignatureForSelector:@selector(_onTick:)]];
            [inv setTarget: self];
            [inv setSelector:@selector(_onTick:)];
            
            [self _terminateTimer];
            previewTimerEngine = [NSTimer scheduledTimerWithTimeInterval: PREVIEW_TIMEOUT_TIME invocation:inv repeats: YES];
        }
    }
    
    //play with a small delay - that will allow the previous item to finish. Otherwise, the currently played item can be finished with the previous one
    if (needsDelay)
        [self performSelector:@selector(_playAVAudioPlayer) withObject: nil afterDelay: 0.5];
    else
        [self _playAVAudioPlayer];
}
#pragma GCC diagnostic pop
- (void) _playAVAudioPlayer
{
    if (player != nil)
    {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
        [player play];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (delegate != nil)
    {
        [delegate FinishedPlayingSound];
    }
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    if (delegate != nil)
    {
        [delegate ErrorPlayingSound];
    }
}

- (BOOL) inProgress
{
    if (player != nil && player.isPlaying == TRUE)
        return TRUE;
    else
        return FALSE;
    
    return FALSE;
}

- (BOOL) stop
{
    BOOL stopPerformed = FALSE;
    
    if ([self inProgress])
    {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        [[AVAudioSession sharedInstance] setActive: NO error: nil];
        
        stopPerformed = TRUE;
        [player stop];
        [self _terminateTimer];
    }
    
    player = nil;
    
    return stopPerformed;
}

-(void)_onTick:(NSTimer *)timer
{
    [self _volumeFadeout];
}

-(void) _terminateTimer
{
    if (previewTimerEngine)
    {
        [previewTimerEngine invalidate];
        previewTimerEngine = nil;
    }
}

-(void) _volumeFadeout
{
    [self _terminateTimer];
    
    if (player != nil && player.volume > 0.1)
    {
        player.volume = player.volume - 0.1;
        [self performSelector:@selector(_volumeFadeout) withObject:nil afterDelay: 0.1];
    }
    else
    {
        [self stop];
    }
}

@end
