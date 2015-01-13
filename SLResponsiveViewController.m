//
//  SLResponsiveViewController.m
//  mesgrain
//
//  Created by 孙 麟 on 13-9-9.
//  Copyright (c) 2013年 Lin Sun. All rights reserved.
//

#import "SLResponsiveViewController.h"
#import "SLResponsiveNavigationController.h"
@interface SLResponsiveViewController ()

@end

@implementation SLResponsiveViewController{
}
@synthesize mainView, enableDefaultAnimationDuringRotation, frame;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		enableDefaultAnimationDuringRotation=YES;
    }
    return self;
}

-(id)initWithFrame:(CGRect)aFrame{
    self=[super init];
    if(self){
        enableDefaultAnimationDuringRotation=YES;
		frame = aFrame;
    }
    return self;
}

- (void)loadView
{
    self.view=[[SLResponsiveView alloc]initWithFrame:self.frame];
}
- (void)viewDidLoad{
	[super viewDidLoad];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameWillChange:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameDidChange:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
}
#pragma mark - StatusBar appearance and event
-(CGFloat)currentStatusBarHeight{
	CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
	CGFloat statusBarHeight = (statusBarFrame.size.width>statusBarFrame.size.height)?statusBarFrame.size.height:statusBarFrame.size.width;
	return statusBarHeight;
}
-(void)statusBarFrameWillChange:(NSNotification *)note{
	//NSValue *newFrameValue = [note userInfo][UIApplicationStatusBarFrameUserInfoKey];
	//CGRect newFrame = newFrameValue.CGRectValue;
	//[SLGeneralDiagnose printRect:newFrame comment:@"Will change to"];
	//originalStatusBarHeight = [self currentStatusBarHeight];
}
-(void)statusBarFrameDidChange:(NSNotification *)note{
	//CGFloat delta = currentStatusBarHeight - [SLResponsiveView statusBarHeight];
	//[SLGeneralDiagnose [[UIScreen mainScreen]applicationFrame] comment:@"AppFrame"];
	//[SLGeneralDiagnose printRect:self.view.frame comment:@"ViewFrame"];
	//[SLGeneralDiagnose printRect:[[UIApplication sharedApplication]keyWindow].frame comment:@"WindowFrame"];
	//[self adjustViewFrameAccordingToCurrentStatusBarState];
	//[SLGeneralDiagnose printRect:self.view.frame comment:@"NewViewFrame"];
}
-(void)adjustViewFrameAccordingToCurrentStatusBarState{
	BOOL isInCall = NO;
	CGFloat currentStatusBarHeight = [self currentStatusBarHeight];
	if(currentStatusBarHeight>[SLResponsiveView statusBarHeight]){
		isInCall = YES;
	}
	CGRect appFrame = [[UIScreen mainScreen]applicationFrame];
	CGRect screenBounds = [[UIScreen mainScreen]bounds];
	CGRect viewFrame = self.view.frame;
	UIInterfaceOrientation orien = [[UIApplication sharedApplication]statusBarOrientation];
	if(orien == UIInterfaceOrientationPortrait){
		if(isInCall){
			viewFrame = appFrame;
			viewFrame.origin.y = 20;
			viewFrame.size.height-=10;
		}else{
			viewFrame = screenBounds;
		}
	}else if (orien == UIInterfaceOrientationPortraitUpsideDown){
		if(isInCall){
			viewFrame = appFrame;
			if(appFrame.origin.y == 0){
				viewFrame.origin.y = currentStatusBarHeight;
			}else{
				viewFrame.origin.y =0;
			}
		}else{
			viewFrame = screenBounds;
		}
	}else if(orien == UIInterfaceOrientationLandscapeLeft || orien == UIInterfaceOrientationLandscapeRight){
		viewFrame.origin = CGPointZero;
		viewFrame.size.width=screenBounds.size.height;
		viewFrame.size.height = screenBounds.size.width;
	}
	self.view.frame = viewFrame;
	[self.view layoutSubviews];
}
#pragma mark - View controller lifecycle
-(void)viewControllerWillBeDestroied{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(mainView)[mainView viewDidAppear];
	//[self adjustViewFrameAccordingToCurrentStatusBarState];

}
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	if(mainView){
		if(mainView.originalViewFrame.size.width==0 && mainView.originalViewFrame.size.height==0){
			mainView.originalViewFrame=self.view.frame;
		}
		[mainView viewWillAppear];
	}
}
-(void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	if(mainView)[mainView viewWillDisappear];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    if(mainView)[mainView viewDidDisappear];
}
-(void)setView:(UIView *)aView{
    [super setView:aView];
    if([aView isKindOfClass:[SLResponsiveView class]]){
        mainView=(SLResponsiveView *)aView;
		mainView.viewController=self;
    }
}
- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - rotation
-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if(!enableDefaultAnimationDuringRotation)[UIView setAnimationsEnabled:NO];
	else [UIView setAnimationsEnabled:YES];
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	if(!enableDefaultAnimationDuringRotation)[UIView setAnimationsEnabled:NO];
	else [UIView setAnimationsEnabled:YES];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    // for iOS 5
	if(!enableDefaultAnimationDuringRotation)[UIView setAnimationsEnabled:NO];
	else [UIView setAnimationsEnabled:YES];
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation)||UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}
-(NSUInteger)supportedInterfaceOrientations{
    // for iOS 6 / iOS 7
    return UIInterfaceOrientationMaskAll;
}
-(BOOL)shouldAutorotate{
	return YES;
}
#pragma mark - View Lifecycle
-(UIViewController *)rootViewController{
	UIViewController *rootVC=self;
	if(!self.navigationController){
		while (rootVC.presentingViewController!=nil){
			UIViewController *vc=rootVC.presentingViewController;
			if([vc isKindOfClass:[UINavigationController class]]){
				UINavigationController *nc=(UINavigationController *)vc;
				rootVC=[nc.viewControllers objectAtIndex:0];
				break;
			}
			rootVC=vc;
		}
	}else{
		rootVC=[self.navigationController.viewControllers objectAtIndex:0];
	}
	return rootVC;
}
-(void)transferGlobalInstancesFromView:(SLResponsiveView *)v1 toView:(SLResponsiveView *)v2{
	if(!v1 || !v2)return;
	NSArray *globalInstances=v1.globalInstances;
	for(id instance in globalInstances){
		[v2 addGlobalInstance:instance];
		[v1 removeGlobalInstance:instance];
	}
}
-(void)destroyPresentingViewControllersUntil:(UIViewController *)rootVC{
	if(!rootVC)return;
	UIViewController *vc=self;
	SLResponsiveView *rootView=nil;
	NSInteger index=-1;
	NSInteger targetIndex=100000;
	if([rootVC isKindOfClass:SLResponsiveViewController.class]){
		rootView=((SLResponsiveViewController *)rootVC).mainView;
	}
	if(self.navigationController && [self.navigationController.viewControllers containsObject:rootVC]){
		targetIndex=[self.navigationController.viewControllers indexOfObject:rootVC];
	}
	if(self.navigationController && [self.navigationController.viewControllers containsObject:self]){
		index=[self.navigationController.viewControllers indexOfObject:self];
	}
	while (vc!=rootVC || (self.navigationController && index>targetIndex && vc!=rootVC)) {
		if([vc isKindOfClass:SLResponsiveViewController.class]){
			SLResponsiveViewController *gvc=(SLResponsiveViewController *)vc;
			[self transferGlobalInstancesFromView:gvc.mainView toView:rootView];
			if(gvc.mainView){
				[gvc.mainView viewWillBeDestroyed];
			}
			[gvc viewControllerWillBeDestroied];
		}
		
		if(self.navigationController){
			index--;
			vc=[self.navigationController.viewControllers objectAtIndex:index];
		}else{
			vc=vc.presentingViewController;
		}
		if([vc isKindOfClass:UINavigationController.class]){
			if([((UINavigationController *)vc).viewControllers containsObject:rootVC] && [rootVC isKindOfClass:[SLResponsiveViewController class]]){
				[((SLResponsiveViewController *)rootVC)destroyPresentedViewControllers];
			}
			break;
		}
	}
}
-(void)destroyPresentedViewControllers{
	UIViewController *vc=nil;
	NSInteger index=-1;
	if(self.navigationController && [self.navigationController.viewControllers containsObject:self]){
		index=[self.navigationController.viewControllers indexOfObject:self];
		if(index<self.navigationController.viewControllers.count-1){
			index++;
			vc=[self.navigationController.viewControllers objectAtIndex:index];
		}
	}else{
		vc=self.presentedViewController;
	}
	while (vc!=nil) {
		if([vc isKindOfClass:SLResponsiveViewController.class]){
			SLResponsiveViewController *gvc=(SLResponsiveViewController*)vc;
			[self transferGlobalInstancesFromView:gvc.mainView toView:self.mainView];
			if(gvc.mainView){
				[gvc.mainView viewWillBeDestroyed];
			}
			[gvc viewControllerWillBeDestroied];
		}
		if(self.navigationController){
			if(index<self.navigationController.viewControllers.count-1){
				index++;
				vc=[self.navigationController.viewControllers objectAtIndex:index];
			}else{
				vc=nil;
			}
		}else{
			vc=vc.presentedViewController;
		}
	}
}
-(void)popToPreviousViewControllerAnimated:(BOOL)animated{
	if(self.navigationController && [self.navigationController.viewControllers containsObject:self]){
		UIViewController *vc=nil;
		NSInteger index=[self.navigationController.viewControllers indexOfObject:self];
		if (index>0){
			vc=[self.navigationController.viewControllers objectAtIndex:index-1];
			if(vc){
				if([vc isKindOfClass:[SLResponsiveViewController class]]){
					[((SLResponsiveViewController *)vc)destroyPresentedViewControllers];
				}else{
					[self.mainView viewWillBeDestroyed];
				}
				[vc.navigationController popToViewController:vc animated:animated];
			}
		}
	}else{
		UIViewController *vc=self.presentingViewController;
		if(vc){
			if(vc && [vc isKindOfClass:[UINavigationController class]]){
				vc=[((UINavigationController *)vc).viewControllers lastObject];
			}
			if([vc isKindOfClass:[SLResponsiveViewController class]]){
				[self transferGlobalInstancesFromView:self.mainView toView:((SLResponsiveViewController *)vc).mainView];
			}
			[self.mainView viewWillBeDestroyed];
			[self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
		}
	}
}
-(UIViewController *)popToRootViewControllerAnimated:(BOOL)animated{
	UIViewController *rootVC=self.rootViewController;
	[self destroyPresentingViewControllersUntil:rootVC];
	if(self.navigationController){
		[self.navigationController popToViewController:rootVC animated:YES];
	}else{
		[rootVC dismissViewControllerAnimated:animated completion:nil];
	}
	return rootVC;
}
-(void)dismissOthersAndPresentNewController:(UIViewController *)vc animated:(BOOL)animated{
	[self destroyPresentedViewControllers];
	[self dismissViewControllerAnimated:animated completion:^{
		if(vc){
			[self presentViewController:vc animated:animated completion:nil];
		}
	}];
}
-(void)dismissOthersAndPushNewController:(UIViewController *)vc animated:(BOOL)animated{
	if(self.navigationController == nil) return;
	[self destroyPresentedViewControllers];
	[self.navigationController popToViewController:self animated:NO];
	[self.navigationController pushViewController:vc animated:animated];
}
@end
