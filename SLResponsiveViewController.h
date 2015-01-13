//
//  SLResponsiveViewController.h
//  mesgrain
//
//  Created by 孙 麟 on 13-9-9.
//  Copyright (c) 2013年 Lin Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLResponsiveView.h"
#import "GAITrackedViewController.h"

@interface SLResponsiveViewController : GAITrackedViewController

@property (weak,nonatomic) SLResponsiveView *mainView;
-(id)initWithFrame:(CGRect)frame;
-(UIViewController *)rootViewController;
-(UIViewController *)popToRootViewControllerAnimated:(BOOL)animated;
-(void)dismissOthersAndPresentNewController:(UIViewController *)vc animated:(BOOL)animated;
-(void)dismissOthersAndPushNewController:(UIViewController *)vc animated:(BOOL)animated;
-(void)destroyPresentingViewControllersUntil:(UIViewController *)rootVC;
-(void)destroyPresentedViewControllers;
-(void)popToPreviousViewControllerAnimated:(BOOL)animated;
-(void)viewControllerWillBeDestroied;
@property (nonatomic) CGRect frame;
@property (nonatomic) BOOL enableDefaultAnimationDuringRotation;
@end
