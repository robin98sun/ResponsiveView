//
//  SLResponsiveNavigationController.m
//  MesgRain
//
//  Created by 孙麟 on 13-10-31.
//  Copyright (c) 2013年 Lin Sun. All rights reserved.
//

#import "SLResponsiveNavigationController.h"

@interface SLResponsiveNavigationController ()

@end

@implementation SLResponsiveNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - rotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    // for iOS 5
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation)||UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}
-(NSUInteger)supportedInterfaceOrientations{
    // for iOS 6 / iOS 7
    return UIInterfaceOrientationMaskAll;
}
-(BOOL)shouldAutorotate{
	return YES;
}

@end
