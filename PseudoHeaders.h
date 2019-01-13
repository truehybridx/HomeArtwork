@interface SBWallpaperView : UIImageView
- (void)resetCurrentImageToWallpaper;
- (void)replaceWallpaperWithImage:(UIImage *)image;
@end

@interface SBApplication : NSObject
- (NSString *)displayIdentifier;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL)isPlaying;
- (NSDictionary *)_nowPlayingInfo;
- (SBApplication *)nowPlayingApplication;

// New in iOS 7
- (id)artwork;
@end

@interface SBFolderSlidingView : UIView {
	SBWallpaperView *_wallpaperView;
	UIView* _wallpaperContainerView;
}
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (SBWallpaperView *)wallpaperView;

// Added by us.
- (void)homeartwork_SBUIController_updateHomescreenWallpaper;
- (void)homeartwork_timerFired:(NSTimer*)timer;
@end

@interface SBIconController : NSObject {
	SBFolderSlidingView *_upperSlidingView;
	SBFolderSlidingView *_lowerSlidingView;
}
+ (id)sharedInstance;
// Added by us.
- (void)homeartwork_updateFolderSlides;

@end



// New in iOS 7
@interface SBFWallpaperView : UIView {
	UIView *_contentView;
	// Is actually an ImageView, contentMode is 0
}
@end

@interface SBFStaticWallpaperView : SBFWallpaperView {

}
@end

@interface SBWallpaperController : NSObject {
	UIView *_wallpaperContainerView;
	//SBFStaticWallpaperView appears to be at subviews index 0
}
+ (id)sharedInstance;
@end

@interface SBLockStateAggregator : NSObject
{
    
}
+ (id)sharedInstance;
- (unsigned int)lockState; // state 0 appears to be unlocked
@end