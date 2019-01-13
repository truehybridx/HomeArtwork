#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#import "PseudoHeaders.h"
#import <substrate.h>
#import <QuartzCore/QuartzCore.h>

// Preference Constants
#define PreferencesFilePath [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Preferences/org.thebigboss.homeartwork.plist"]
#define PreferencesChangedNotification "org.thebigboss.homeartwork.prefs"




// Common

// Statics
static NSTimer *homeartworkTimer = nil;
static BOOL homeartworkFullscreen = NO;
static BOOL homeartworkAnimated = NO;

static inline void loadPrefValues() {
	NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];
	int behavior = [[prefs objectForKey:@"behavior_setting"] intValue] ?: 1;
	
	if (behavior == 1) {
		homeartworkFullscreen = NO;
		homeartworkAnimated = NO;
	} else if (behavior == 2) {
		homeartworkFullscreen = YES;
		homeartworkAnimated = NO;
	} else {
		homeartworkFullscreen = YES;
		homeartworkAnimated = YES;
	}
}

static void preferenceChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	loadPrefValues();
	[[NSNotificationCenter defaultCenter] postNotificationName:@"HomeArtworkPreferenceChangedNotification" object:nil];
	
}



%group iOS6_Only


static inline UIImage *GetNowPlayingArtwork6() {
	return ([UIImage imageWithData:[[[%c(SBMediaController) sharedInstance] _nowPlayingInfo] objectForKey:@"artworkData"]] ?: nil);
}


%hook SBUIController

- (id)init {
	self = %orig;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeartwork_updateHomescreenWallpaper) name:@"SBMediaNowPlayingChangedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeartwork_updateHomescreenWallpaper) name:@"HomeArtworkPreferenceChangedNotification" object:nil];
	}
	return self;
}

%new(v@:@@)
- (void)homeartwork_timerFired6:(NSTimer*)timer {		
	SBWallpaperView *wallpaper = [self wallpaperView];
	SBWallpaperView *upperWallpaper = nil;
	SBWallpaperView *lowerWallpaper = nil;
	
	// Grab junk from SBIconController
	SBIconController *iconCont = [%c(SBIconController) sharedInstance];
	SBFolderSlidingView *upper = MSHookIvar<SBFolderSlidingView *>(iconCont, "_upperSlidingView");
	SBFolderSlidingView *lower = MSHookIvar<SBFolderSlidingView *>(iconCont, "_lowerSlidingView");
	
	if (upper && lower) {
		upperWallpaper = MSHookIvar<SBWallpaperView *>(upper, "_wallpaperView");
		lowerWallpaper = MSHookIvar<SBWallpaperView *>(lower, "_wallpaperView");
	}
	
	if (homeartworkAnimated) {
	
		if (wallpaper.frame.origin.x >= 0) {
        	// To the left
        	[UIView animateWithDuration:6.0f animations:^{
            	wallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -80.0, 0.0);
            	
            	// FolderSlides Wallpaper
            	if (upperWallpaper && lowerWallpaper) {
            		upperWallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -80.0, 0.0);
            		lowerWallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -80.0, 0.0);
            	}
        	}];
    	} else {
    		 // To the right
			[UIView animateWithDuration:6.0f animations:^{
        	    wallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 80.0, 0.0);
        	    
        	    // FolderSlides Wallpaper
            	if (upperWallpaper && lowerWallpaper) {
            		upperWallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 80.0, 0.0);
            		lowerWallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 80.0, 0.0);
            	}
			}];
			
			
   		}
   	} else {
   		// Kill timer if running, Set view to normal position
		if (homeartworkTimer) {
			[homeartworkTimer invalidate];
			homeartworkTimer = nil;
			[wallpaper.layer removeAllAnimations];
			//[wallpaper setFrame:CGRectMake(0, 0, wallpaper.frame.size.width, wallpaper.frame.size.height)];
			wallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, 0.0);
		}
   	}

}

%new(v@:)
- (void)homeartwork_updateHomescreenWallpaper {
	UIImage *artwork = GetNowPlayingArtwork6();
	SBWallpaperView *wallpaper = [self wallpaperView];

	if (artwork && [[%c(SBMediaController) sharedInstance] isPlaying]) {
		// Change/Add Artwork
		[wallpaper setContentMode:((!homeartworkFullscreen) ? 1 : 2)];
		[wallpaper replaceWallpaperWithImage:artwork];
		
		// Setup Timer if not already running.
		if (!homeartworkTimer && homeartworkAnimated) {
			homeartworkTimer = [NSTimer scheduledTimerWithTimeInterval:7.0
                                             target:self
                                           selector:@selector(homeartwork_timerFired6:)
                                           userInfo:nil
                                            repeats:YES];
    		[homeartworkTimer fire];
		} else if (homeartworkTimer && !homeartworkAnimated) {
			[homeartworkTimer fire];
		}
		
	} else {
		// Remove artwork
		[wallpaper setContentMode:2];
		[wallpaper resetCurrentImageToWallpaper];
		
		// Kill timer if running
		if (homeartworkTimer) {
			[homeartworkTimer invalidate];
			homeartworkTimer = nil;
			[wallpaper.layer removeAllAnimations];
			//[wallpaper setFrame:CGRectMake(0, 0, wallpaper.frame.size.width, wallpaper.frame.size.height)];
			wallpaper.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, 0.0);
		}
	}
}

%end // End of SBUIController Hook


%hook SBIconController

- (id)init {
	self = %orig;
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeartwork_updateFolderSlides) name:@"SBMediaNowPlayingChangedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeartwork_updateFolderSlides) name:@"HomeArtworkPreferenceChangedNotification" object:nil];
	}
	return self;
}

- (void)_insertFolderViewAndSlidingViewsForFolder:(id)folder {
	%orig;
	[self homeartwork_updateFolderSlides];
}

%new(v@:)
- (void)homeartwork_updateFolderSlides {
	SBFolderSlidingView *upper = MSHookIvar<SBFolderSlidingView *>(self, "_upperSlidingView");
	SBFolderSlidingView *lower = MSHookIvar<SBFolderSlidingView *>(self, "_lowerSlidingView");
	
	if (upper && lower) {
		SBWallpaperView *upperWallpaper = MSHookIvar<SBWallpaperView *>(upper, "_wallpaperView");
		SBWallpaperView *lowerWallpaper = MSHookIvar<SBWallpaperView *>(lower, "_wallpaperView");

		UIImage *artwork = GetNowPlayingArtwork6();

		if (artwork && [[%c(SBMediaController) sharedInstance] isPlaying]) {
			// Data is valid, use it.
			[upperWallpaper setContentMode:((!homeartworkFullscreen) ? 1 : 2)];
			[upperWallpaper replaceWallpaperWithImage:artwork];
			[lowerWallpaper setContentMode:((!homeartworkFullscreen) ? 1 : 2)];
			[lowerWallpaper replaceWallpaperWithImage:artwork];
		} else {
			[upperWallpaper setContentMode:2];
			[upperWallpaper resetCurrentImageToWallpaper];
			[lowerWallpaper setContentMode:2];
			[lowerWallpaper resetCurrentImageToWallpaper];
		}
	}
}

%end // End of SBIconController Hook



%end // End iOS6_Only Group


// Start of iOS 7 Only stuff
%group iOS7_Only

// Statics for iOS 7
static UIImage *TXOrigWallPaperImage = nil;
static UIImageView *TXWallPaperImageView = nil;

static inline UIImage *GetNowPlayingArtwork7() {
	return [[%c(SBMediaController) sharedInstance] artwork] ?: TXOrigWallPaperImage;
}

%hook SBUIController

- (id)init {
	self = %orig;
	
	if (self) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homealbumart7_nowPlayingChanged:) name:@"SBMediaNowPlayingChangedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homealbumart7_nowPlayingChanged:) name:@"HomeArtworkPreferenceChangedNotification" object:nil];
	}
	
	return self;
}


%new(v@:@@)
- (void)homeartwork_timerFired7:(NSTimer*)timer {

	if (homeartworkAnimated) {
	
		if (TXWallPaperImageView.frame.origin.x >= 0) {
        	// To the left
        	[UIView animateWithDuration:6.0f animations:^{
            	TXWallPaperImageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -80.0, 0.0);
            	
        	}];
    	} else {
    		 // To the right
			[UIView animateWithDuration:6.0f animations:^{
        	    TXWallPaperImageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 80.0, 0.0);
        	    
			}];
		}
	
	} else {
		
		// Kill timer if running
		if (homeartworkTimer) {
			[homeartworkTimer invalidate];
			homeartworkTimer = nil;
			[TXWallPaperImageView.layer removeAllAnimations];
			TXWallPaperImageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, 0.0);
		}
		
	}

}

%new(v@:@@)
- (void)homealbumart7_nowPlayingChanged:(NSNotification *)notification {
	
	
	if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
		// Music is playing, update wallpaper
		[TXWallPaperImageView setImage:GetNowPlayingArtwork7()];
		[TXWallPaperImageView setContentMode:((!homeartworkFullscreen) ? 1 : 2)];
		
		// Setup Timer if not already running.
		if (!homeartworkTimer && homeartworkAnimated) {
			homeartworkTimer = [NSTimer scheduledTimerWithTimeInterval:7.0
                                             target:self
                                           selector:@selector(homeartwork_timerFired7:)
                                           userInfo:nil
                                            repeats:YES];
    		[homeartworkTimer fire];
		} else if (homeartworkTimer && !homeartworkAnimated) {
			[homeartworkTimer fire];
		}
		
	} else {
		// Music is not playing, restore older wallpaper
		[TXWallPaperImageView setImage:TXOrigWallPaperImage];
		
		// Kill timer if running
		if (homeartworkTimer) {
			[homeartworkTimer invalidate];
			homeartworkTimer = nil;
			[TXWallPaperImageView.layer removeAllAnimations];
			TXWallPaperImageView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, 0.0);
		}
	}
	
}

%end // End of SBUIController


%hook SBFWallpaperView

- (void)layoutSubviews {
	
	if (!TXWallPaperImageView) {
		TXWallPaperImageView = MSHookIvar<UIImageView *>(self, "_contentView");
	}
	
	if (!TXOrigWallPaperImage) {
		TXOrigWallPaperImage = [[TXWallPaperImageView image] copy];
	}
	%orig();
}

%end


%end // End of iOS7_Only Group


%ctor {

	// Set initial values
	loadPrefValues();
	
	// Register for pref notifications
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferenceChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);

	// Version Based Setup
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
		NSLog(@"HOMEARTWORK7:iOS 7 LOCKED AND LOADED!!!");
		%init(iOS7_Only);
	} else {
		NSLog(@"HOMEARTWORK7:iOS 6 LOCKED AND LOADED!!!");
		%init(iOS6_Only);
	}

}