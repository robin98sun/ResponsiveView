//
//  SLResponsiveView.m
//  Introspection
//
//  Created by 孙 麟 on 13-6-26.
//  Copyright (c) 2013年 Lin Sun. All rights reserved.
//

#import "SLResponsiveView.h"
#import "SLGeneralDiagnose.h"
#import "SLResponsiveViewController.h"
#pragma mark - Class SLGemeralViewConstraint
@implementation SLResponsiveViewConstraint
@synthesize name, category, tag;
+(id)constraintWithType:(SLResponsiveViewConstraintType)aType andValue:(CGFloat)aValue forObject:(UIView *)obj isContained:(BOOL)isContained byReferencingObject:(UIView *)refObj  forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt{
    SLResponsiveViewConstraint *constraint=[[SLResponsiveViewConstraint alloc] init];
    if(constraint){
        constraint.type=aType;
        constraint.value=aValue;
        constraint.object=obj;
        constraint.referencingObject=refObj;
        constraint.isContained=isContained;
        constraint.orientation=orien;
        constraint.keyboardStatus=ks;
        constraint.deviceType=dt;
    }
    return constraint;
}
-(BOOL)compatibleWithOrientation:(SLResponsiveViewOrientation)orien{
    BOOL result=NO;
    if(self.orientation==kSLRVOrientationAll||orien==kSLRVOrientationAll
       ||((orien==kSLRVOrientationPortraitDown||orien==kSLRVOrientationPortraitUp)&&self.orientation==kSLRVOrientationPortrait)
       ||((orien==kSLRVOrientationLandscapeLeft||orien==kSLRVOrientationLandscapeRight)&&self.orientation==kSLRVOrientationLandscape)
       ||((self.orientation==kSLRVOrientationPortraitDown||self.orientation==kSLRVOrientationPortraitUp)&&orien==kSLRVOrientationPortrait)
       ||((self.orientation==kSLRVOrientationLandscapeLeft||self.orientation==kSLRVOrientationLandscapeRight)&&orien==kSLRVOrientationLandscape)
       ||orien==self.orientation){
        result=YES;
    }
    return result;
}
-(NSString *)description{
    NSMutableString *desc=[[NSMutableString alloc]init];
    [desc appendFormat:@"class=%@",[self class]];
    [desc appendString:@", "];
    [desc appendString:[[self class]namfOfConstraintType:self.type]];
    [desc appendFormat:@"=%ld, %@",(long)self.value, self.object];
    [desc appendString:(self.isContained)?@" contained in ":@" besides "];
    [desc appendFormat:@"%@",self.referencingObject];
    
    return desc;
}
+(NSString *)namfOfConstraintType:(SLResponsiveViewConstraintType)type{
    NSString *result=nil;
    switch (type) {
        case kSLRVConstraintMarginLeft:
            result=@"MarginLeft";
            break;
        case kSLRVConstraintMarginBottom:
            result=@"MargenBottom";
            break;
        case kSLRVConstraintCenterY:
            result=@"CenterHorizontal";
            break;
        case kSLRVConstraintCenterX:
            result=@"CenterVertical";
            break;
        case kSLRVConstraintHeight:
            result=@"Height";
            break;
        case kSLRVConstraintMarginRight:
            result=@"MarginRight";
            break;
        case kSLRVConstraintMarginTop:
            result=@"MarginTop";
            break;
        case kSLRVConstraintWidth:
            result=@"Width";
            break;
        default:
            result=@"Unknown";
            break;
    }
    return result;
}
@end
#pragma mark - Class SLResponsiveView
@implementation SLResponsiveView{
    // Variables for status
    BOOL isViewDidAppear;
	NSMutableArray *arrayOfGlobalInstances;
    NSMutableArray *arrayOfUnRotatableSubviewsDontAlignToTop;
    NSMutableArray *arrayOfUnRotatableSubviewsAlignToTop;
    NSMutableArray *arrayOfStaticContentSubviews;
	NSMutableArray *arrayOfOverrideStatusBarSubviews;
    NSMutableDictionary *dict_Subviews_OriginalFrame;
    NSMutableDictionary *constraintsOfSubviews;
    NSMutableDictionary *constraintsOfReferencedSubviews;
    NSMutableArray *subviewsWithConstraints;
    NSMutableArray *subviewsReferencedByConstraints;
    NSMutableDictionary *dict_SubviewsReferencing;
    NSMutableDictionary *dict_SubviewsReferencedBy;
    BOOL isSupportPortraitUpsideDown;
    NSMutableArray *fullScreenSubviews;
    double rotatedAngle;
    UIToolbar *toolbar;
	BOOL isRotationBegan;
	BOOL isRotationDone;
	int countOfSizeChangesWhenRotating;
	BOOL isGlobalInstanceAddedBack;
}
@synthesize orientation, keyboardHeight, keyboardWidth, viewController, originalViewFrame;
- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self somethingWhenInitWithFrame:frame];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder{
	self = [super initWithCoder:aDecoder];
	if(self){
		[self somethingWhenInitWithFrame:CGRectZero];
	}
	return self;
}
-(void)somethingWhenInitWithFrame:(CGRect)frame{
	// Initialization code
	isGlobalInstanceAddedBack = NO;
	isRotationBegan = NO;
	isRotationDone = YES;
	countOfSizeChangesWhenRotating=0;
	// Register StatusBar Change Notification
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStatusBarFrameDidChange) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
	
	// initialize local variables
	rotatedAngle=0;
	keyboardHeight=0;
	isViewDidAppear=NO;
	originalViewFrame=frame;
	self.backgroundColor=[UIColor clearColor];
	isSupportPortraitUpsideDown=NO;
	
	orientation = kSLRVOrientationUnknown;
	
//	switch ([[UIApplication sharedApplication]statusBarOrientation]) {
//		case UIInterfaceOrientationLandscapeLeft:
//			orientation=kSLRVOrientationLandscapeRight;
//			rotatedAngle=M_PI*3/2;
//			break;
//		case UIInterfaceOrientationLandscapeRight:
//			orientation=kSLRVOrientationLandscapeLeft;
//			rotatedAngle=M_PI/2;
//			break;
//		case UIInterfaceOrientationPortrait:
//			orientation=kSLRVOrientationPortraitUp;
//			rotatedAngle=0;
//			break;
//		case UIInterfaceOrientationPortraitUpsideDown:
//			orientation=kSLRVOrientationPortraitDown;
//			rotatedAngle=(isSupportPortraitUpsideDown)?M_PI:0;
//		default:
//			orientation=kSLRVOrientationPortraitUp;
//			break;
//	}
	//
}
//
#pragma mark - 初始化/调整外观
-(void)addObserverForRotationAndKeyboard{
	// register orientation events
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
	// Register Keyboard Notification
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification object:nil];
}
-(void)removeObserverForRotationAndKeyboard{
	// register orientation events
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	// Register Keyboard Notification
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}
-(void)setViewController:(UIViewController *)aViewController{
	viewController = aViewController;
	if(viewController){
		[self addObserverForRotationAndKeyboard];
	}else{
		[self removeObserverForRotationAndKeyboard];
	}
}
-(void)viewWillBeDestroyed{
	[self removeObserverForRotationAndKeyboard];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	for(id o in self.subviews){
		if([o isKindOfClass:SLResponsiveView.class]){
			SLResponsiveView *gv=o;
			[gv viewWillBeDestroyed];
		}
		if([o respondsToSelector:@selector(setDelegate:)]){
			[o setDelegate:nil];
		}
	}
	[self viewWillDisappear];
	[self viewDidDisappear];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	// Release all subviews
	if(arrayOfUnRotatableSubviewsDontAlignToTop){
		[arrayOfUnRotatableSubviewsDontAlignToTop removeAllObjects];
		arrayOfUnRotatableSubviewsDontAlignToTop=nil;
	}
	if(arrayOfUnRotatableSubviewsAlignToTop){
		[arrayOfUnRotatableSubviewsAlignToTop removeAllObjects];
		arrayOfUnRotatableSubviewsAlignToTop=nil;
	}
	if(arrayOfStaticContentSubviews){
		[arrayOfStaticContentSubviews removeAllObjects];
		arrayOfStaticContentSubviews=nil;
	}
	if(arrayOfOverrideStatusBarSubviews){
		[arrayOfOverrideStatusBarSubviews removeAllObjects];
		arrayOfOverrideStatusBarSubviews=nil;
	}
	if(dict_Subviews_OriginalFrame){
		[dict_Subviews_OriginalFrame removeAllObjects];
		dict_Subviews_OriginalFrame=nil;
	}
	if(constraintsOfSubviews){
		[constraintsOfSubviews removeAllObjects];
		constraintsOfSubviews=nil;
	}
	if(constraintsOfReferencedSubviews){
		[constraintsOfReferencedSubviews removeAllObjects];
		constraintsOfReferencedSubviews=nil;
	}
	if(subviewsWithConstraints){
		[subviewsWithConstraints removeAllObjects];
		subviewsWithConstraints=nil;
	}
	if(subviewsReferencedByConstraints){
		[subviewsReferencedByConstraints removeAllObjects];
		subviewsReferencedByConstraints=nil;
	}
	if(dict_SubviewsReferencing){
		[dict_SubviewsReferencing removeAllObjects];
		dict_SubviewsReferencing=nil;
	}
	if(dict_SubviewsReferencedBy){
		[dict_SubviewsReferencedBy removeAllObjects];
		dict_SubviewsReferencedBy=nil;
	}
	if(fullScreenSubviews){
		[fullScreenSubviews removeAllObjects];
		fullScreenSubviews=nil;
	}
	if(arrayOfGlobalInstances){
		[arrayOfGlobalInstances removeAllObjects];
		arrayOfGlobalInstances=nil;
	}
	toolbar=nil;
}
-(void)viewWillAppear{
	// Add back the global instance
	if(arrayOfGlobalInstances && arrayOfGlobalInstances.count>0){
		for(id instance in arrayOfGlobalInstances){
			if([instance isKindOfClass:[UIView class]] && ![self.subviews containsObject:instance]){
				[self addGlobalInstance:instance];
				isGlobalInstanceAddedBack = YES;
			}
		}
	}
	
    //在iOS7之前，必须变成firstResponder才能响应shakeMotion
    [self becomeFirstResponder];
    // Set inner variable
	
	UIInterfaceOrientation orien=[[UIApplication sharedApplication]statusBarOrientation];
	switch (orien) {
		case UIInterfaceOrientationLandscapeLeft:
			[self superViewRotatedToAngle:M_PI*3/2];
			break;
		case UIInterfaceOrientationLandscapeRight:
			[self superViewRotatedToAngle:M_PI/2];
			break;
		case UIInterfaceOrientationPortrait:
			[self superViewRotatedToAngle:0];
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			if(isSupportPortraitUpsideDown)
				[self superViewRotatedToAngle:M_PI];
			else [self superViewRotatedToAngle:0];
			break;
		default:
			break;
	}
	// 在引入navigationController之后，如果在显示pop回来之前界面变动过，则无法调整
	[self performSelectorOnMainThread:@selector(layoutSubviews) withObject:nil waitUntilDone:YES];
    isViewDidAppear=YES;
	
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[SLResponsiveView class]]){
			[((SLResponsiveView *)v) viewWillAppear];
		}
	}
}
-(void)viewWillDisappear{
	/*
	[UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
		self.alpha=0;
	} completion:^(BOOL finished){
		
	}];
	 */
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[SLResponsiveView class]]){
			[((SLResponsiveView *)v) viewWillDisappear];
		}
	}
}
-(void)viewDidAppear{
	if(isGlobalInstanceAddedBack){
		//[self rotateUnRotatableSubviewsBack];
		[self layoutSubviews];
		isGlobalInstanceAddedBack=NO;
	}
    // 为了消除当view被压在view stack底部又重新恢复显示的时候可能有的adjustY方面的错误，牺牲一部分计算性能
	// 虽然其作用，但是很难看，当着用户的面调整界面；可能还是和[self adjustY]有关，但是尝试之后还是没有关系
	// 引入了viewController变量，解决了如何判断一个view是mainView的问题
	
	isViewDidAppear = YES;
	
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[SLResponsiveView class]]){
			[((SLResponsiveView *)v) viewDidAppear];
		}
	}
}
-(void)viewDidDisappear{
    // Un-Register keyboard Notification
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    // Set Inner variable
    isViewDidAppear=NO;
	
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[SLResponsiveView class]]){
			[((SLResponsiveView *)v) viewDidDisappear];
		}
	}
}
-(BOOL)isViewAppearing{
    return isViewDidAppear;
}
-(BOOL)isMainView{
	//if([self.superview isKindOfClass:[UIWindow class]]||!self.superview){
	if(self.viewController){
		return YES;
	}else return NO;
}
-(void)setSupportPortraitUpsideDown:(BOOL)support{
    isSupportPortraitUpsideDown=support;
}
-(id)superViewController{
	id result=self;
	while (result) {
		if([result isKindOfClass:[SLResponsiveView class]] && ((SLResponsiveView *)result).viewController){
			return ((SLResponsiveView *)result).viewController;
		}
		result=((UIView *)result).superview;
	}
	return result;
}
#pragma mark - StatusBar
-(void)onStatusBarFrameDidChange{
	//NSLog(@"statusBar frame changed, height: %f, width: %f",[self.class statusBarHeight], [UIApplication sharedApplication].statusBarFrame.size.width);
	//[self layoutSubviews];
}
-(CGFloat)adjustY{
    CGFloat result=0;
    CGFloat tmpValue=[[self class]adjustY];
    if(tmpValue>0 && [self isMainView]){
        result=tmpValue ;
	}
    return result;
}
+(CGFloat)adjustY{
    CGFloat result=0;
    if([[self class] OSMainVersionNumber]>=7){
        // iOS 7以前的版本,他们的view的hight会比iOS 7版本的少20，也就是statusBar。
        // 比如在iPhone 4S上，iOS 7的view的height=480，而iOS 6上的height=460，x/y都是0
        // 而在iOS 7上，statusBar是会占用view的最上端20部分，也就是以view为背景的statusBar
        // 因此要对iOS 7之前的版本调整其中各元素的y值，对y值减去statusBar.height，对于iOS 7，y值要加上statusBar.height
        //result=[[UIApplication sharedApplication]statusBarFrame].size.height;
        result=[[self class]statusBarHeight];
    }
    
    return result;
}
+(CGFloat)statusBarHeight{
	CGRect statusBarFrame = [[UIApplication sharedApplication]statusBarFrame];
	if(statusBarFrame.size.width == 0 || statusBarFrame.size.height == 0) return 0;
	else
		return 20;
		//return (statusBarFrame.size.width>statusBarFrame.size.height)?statusBarFrame.size.height:statusBarFrame.size.width;
}
#pragma mark - Handle Shake events
-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    if([super respondsToSelector:@selector(motionEnded:withEvent:)]){
        [super motionEnded:motion withEvent:event];
    }
    if(event.subtype==UIEventSubtypeMotionShake && [self isViewAppearing]){
        [self deviceShaked];
    }
}
-(void)deviceShaked{
}
-(BOOL)canBecomeFirstResponder{
    // 在iOS7之前，必须有这个函数才能把View变为firstResponder，变成firstResponder之后才能响应shakeMotion
    return YES;
}
#pragma mark - Handle Orientation Changed
-(SLResponsiveViewOrientation)orientation{
	return orientation;
}
-(CGFloat)rotatedAngle{
	return rotatedAngle;
}
-(void)superViewRotatedToAngle:(double)angle{
	rotatedAngle=angle;
	if(angle==0){
		[self deviceRotatedToOrientation:kSLRVOrientationPortraitUp];
		[self deviceRotatedToPortrait];
	}else if(angle-M_PI==0){
		[self deviceRotatedToOrientation:kSLRVOrientationPortraitDown];
		[self deviceRotatedToPortraitUpsideDown];
	}else if(angle - M_PI/2 == 0){
		[self deviceRotatedToOrientation:kSLRVOrientationLandscapeLeft];
		[self deviceRotatedToLandscapeLeft];
	}else if(angle - M_PI*3/2 == 0){
		[self deviceRotatedToOrientation:kSLRVOrientationLandscapeRight];
		[self deviceRotatedToLandscapeRight];
	}
	
	// 2014-9-6
	// 在有些情况下，layout会在rotation message到达之前执行，导致rotation message到达之后不能调整页面排版
	// 比如 PlantID 项目中，第一页的rotation message在layout之前到达，当第一页被压入下层，第二页的rotation message就在layout之后才到达
	// 因此
	[self layoutSubviews];
	
	[self deviceIsRotating:angle];
	[self deviceRotated:angle];
	//
	for(UIView *v in self.subviews){
		// 2014-9-7 这个消息必须传递给 staticContentSubview ，否则比如UniversalBar被固定的时候，它的buttons将无法被rotate回来
		//if(arrayOfStaticContentSubviews && [arrayOfStaticContentSubviews containsObject:v]){
		//	continue;
		//}else{
			if([v isKindOfClass:[SLResponsiveView class]] && [v respondsToSelector:@selector(superViewRotatedToAngle:)]){
				SLResponsiveView *gv  = (SLResponsiveView *)v;
				[gv superViewRotatedToAngle:angle];
			}
		//}
	}
	
}
-(UIInterfaceOrientation)interfaceOrientationForAngle:(double)angle{
	if(angle==0){
		return UIInterfaceOrientationPortrait;
	}else if(angle-M_PI==0){
		return UIInterfaceOrientationPortraitUpsideDown;
	}else if(angle - M_PI*3/2 == 0){
		return UIInterfaceOrientationLandscapeLeft;
	}else if(angle - M_PI/2 == 0){
		return UIInterfaceOrientationLandscapeRight;
	}
	return UIInterfaceOrientationPortrait;
}
-(void)didRotate:(NSNotification *)notification{
    //if(![self isViewAppearing]) return;
    // 在ios7之前，self.frame 也会随着屏幕的变化而变化，所以还得不断的重新还原到最开始的大小
    // 把不需要旋转的部分旋转回去
    // Something need to be re-arranged when rotated
	isRotationBegan = YES;
	isRotationDone = NO;
	countOfSizeChangesWhenRotating = 0;
    UIDeviceOrientation currentOrientation=[[UIDevice currentDevice]orientation];
	//
    double angle=0;
    if(currentOrientation==UIDeviceOrientationPortrait || currentOrientation==UIDeviceOrientationUnknown){
        // 正常方向 旋转角度为 0
        if(angle!=rotatedAngle){
			[self superViewRotatedToAngle:angle];
        }
    }else if (currentOrientation==UIDeviceOrientationPortraitUpsideDown){
        // 上下颠倒 旋转角度为 M_PI
        angle=(isSupportPortraitUpsideDown)?M_PI:0;
        if(angle!=rotatedAngle){
           [self superViewRotatedToAngle:angle];
        }
    }else if (currentOrientation == UIDeviceOrientationLandscapeLeft){
        // 向左横向 旋转角度为 M_PI/2
        angle=M_PI/2;
        if(angle!=rotatedAngle){
            [self superViewRotatedToAngle:angle];
        }
    }else if (currentOrientation==UIDeviceOrientationLandscapeRight){
        // 向右横向 旋转角度为 M_PI*3/2
        angle=M_PI*3/2;
        if(angle!=rotatedAngle){
            [self superViewRotatedToAngle:angle];
        }
    }else if(currentOrientation ==UIDeviceOrientationFaceDown){
		//[self superViewRotatedToAngle:rotatedAngle];
        // 正面朝下
        [self deviceRotatedToFaceDown];
    }else if(currentOrientation == UIDeviceOrientationFaceUp){
        // 正面朝上
		//[self superViewRotatedToAngle:rotatedAngle];
        [self deviceRotatedToFaceUp];
    }
}
-(void)deviceRotatedToOrientation:(SLResponsiveViewOrientation)orien{
    if(orien != orientation){
		
        //if([self isMainView]) {
        //    self.frame=originalViewFrame;
        //}
		
        orientation=orien;
        [self rotateUnRotatableSubviewsBack];
		
		if(self.viewController && [self.viewController isKindOfClass:[SLResponsiveViewController class]]){
			((SLResponsiveViewController *)self.viewController).orientation = orien;
			[((SLResponsiveViewController *)self.viewController) deviceRotatedToOrientation:orien];
		}
		/*
        // 必须传递给子视图，否则子视图接受不到rotation notification
        for(id v in self.subviews){
            if([v isKindOfClass:[SLResponsiveView class]]){
                SLResponsiveView *tmpV=v;
                [tmpV deviceRotatedToOrientation:orien];
                //[tmpV rotateUnRotatableSubviewsBack];
            }
        }
		 */
    }
}
-(void)deviceIsRotating:(double)angle{
}
-(void)deviceRotated:(double)angle{
}
-(void)deviceRotatedToPortrait{
    //NSLog(@"current orientation= Portrait");
}
-(void)deviceRotatedToLandscapeLeft{
    //NSLog(@"current orientation= LandscapeLeft");
}
-(void)deviceRotatedToLandscapeRight{
    //NSLog(@"current orientation= LandscapeRight");
}
-(void)deviceRotatedToPortraitUpsideDown{
    //NSLog(@"current orientation= PortraitUpsideDown");
}
-(void)deviceRotatedToFaceUp{
    //NSLog(@"current orientation= Face Up");
}
-(void)deviceRotatedToFaceDown{
    //NSLog(@"current orientation= Face Down");
}
-(void)rotateUnRotatableSubviewsBack{
    NSMutableArray *theArray=[[NSMutableArray alloc]init];
    if(arrayOfUnRotatableSubviewsAlignToTop) [theArray addObject:arrayOfUnRotatableSubviewsAlignToTop];
    if(arrayOfUnRotatableSubviewsDontAlignToTop)[theArray addObject:arrayOfUnRotatableSubviewsDontAlignToTop];
    NSMutableArray *rotatedSubviews=[[NSMutableArray alloc]initWithCapacity:theArray.count];
	UIDeviceOrientation currentOrientation=UIDeviceOrientationPortrait;
	switch (orientation) {
		case kSLRVOrientationPortraitDown:
			currentOrientation=UIDeviceOrientationPortraitUpsideDown;
			break;
		case kSLRVOrientationLandscapeLeft:
			currentOrientation=UIDeviceOrientationLandscapeLeft;
			break;
		case kSLRVOrientationLandscapeRight:
			currentOrientation=UIDeviceOrientationLandscapeRight;
			break;
		default:
			break;
	}
    for(NSArray *tmpArray in theArray){
        BOOL alignedTop=(tmpArray==arrayOfUnRotatableSubviewsAlignToTop)?YES:NO;
        for(UIView *view in tmpArray){
			UIView *rotatedView=[[self class] rotateShapeBack:view
												originalFrame:[self getOriginalFrameForSubview:view]
										  includingUpsideDown:isSupportPortraitUpsideDown
											 includingContent:(arrayOfStaticContentSubviews && [arrayOfStaticContentSubviews containsObject:view])?YES:NO
											 showingStatusBar:(arrayOfOverrideStatusBarSubviews && [arrayOfOverrideStatusBarSubviews containsObject:view])?NO:YES
												 isAlignedTop:alignedTop
											  verticalReverse:YES
									 currentDeviceOrientation:currentOrientation];
			if(rotatedView){
				[rotatedSubviews addObject:rotatedView];
			}
        }
    }
    // Apply constraints for the rotated subviews
    for(UIView *v in subviewsWithConstraints){
        if([rotatedSubviews containsObject:v]){
            [self applyConstraintsForSubview:v];
        }
    }
}
-(void)addUnRotatableSubview:(id)unRotatableView alignTop:(BOOL)alignTop staticContent:(BOOL)staticContent overrideStatusBar:(BOOL)overrideStatusBar{
    if(unRotatableView == nil || ![unRotatableView isKindOfClass:[UIView class]])return;
    if(alignTop){
        if(!arrayOfUnRotatableSubviewsAlignToTop){
            arrayOfUnRotatableSubviewsAlignToTop=[[NSMutableArray alloc]init];
        }
        [arrayOfUnRotatableSubviewsAlignToTop addObject:unRotatableView];
    }else{
        if(!arrayOfUnRotatableSubviewsDontAlignToTop){
            arrayOfUnRotatableSubviewsDontAlignToTop=[[NSMutableArray alloc]init];
        }
        [arrayOfUnRotatableSubviewsDontAlignToTop addObject:unRotatableView];
    }
    if(![self.subviews containsObject:unRotatableView]){
        [self addSubview:unRotatableView];
    }
    if([unRotatableView respondsToSelector:@selector(frame)]){
        [self storeOriginalFrame:[unRotatableView frame] forSubview:unRotatableView];
    }
	if(staticContent)[self addStaticContentSubview:unRotatableView];
	if(overrideStatusBar)[self addOverrideStatusBarSubview:unRotatableView];
}
-(void)removeUnRotatableSubview:(id)unRotatableView{
	if(!unRotatableView)return;
    NSMutableArray *tmpArray=[[NSMutableArray alloc]init];
	if(arrayOfStaticContentSubviews)[tmpArray addObject:arrayOfStaticContentSubviews];
	if(arrayOfUnRotatableSubviewsAlignToTop)[tmpArray addObject:arrayOfUnRotatableSubviewsAlignToTop];
	if(arrayOfUnRotatableSubviewsDontAlignToTop)[tmpArray addObject:arrayOfUnRotatableSubviewsDontAlignToTop];
	if(arrayOfOverrideStatusBarSubviews)[tmpArray addObject:arrayOfOverrideStatusBarSubviews];
	for(NSMutableArray *array in tmpArray){
    	if([array containsObject:unRotatableView]){
        	[array removeObject:unRotatableView];
	    }
	}
	if([self.subviews containsObject:unRotatableView]){
		[unRotatableView removeFromSuperview];
    	[self removeOriginalFrameOfSubview:unRotatableView];
	}
}
-(void)addStaticContentSubview:(UIView *)subview{
	if(!subview)return;
    if(arrayOfStaticContentSubviews==nil)arrayOfStaticContentSubviews=[[NSMutableArray alloc]init];
    [arrayOfStaticContentSubviews addObject:subview];
}
-(void)addOverrideStatusBarSubview:(UIView *)subview{
	if(!subview)return;
    if(arrayOfOverrideStatusBarSubviews==nil)arrayOfOverrideStatusBarSubviews=[[NSMutableArray alloc]init];
    [arrayOfOverrideStatusBarSubviews addObject:subview];
}
-(void)removeStaticContentSubview:(UIView *)subview{
    if(arrayOfStaticContentSubviews.count>0 && [arrayOfStaticContentSubviews containsObject:subview])
        [arrayOfStaticContentSubviews removeObject:subview];
}
-(CGRect)getOriginalFrameForSubview:(id)Subview{
    CGRect frame=CGRectMake(0, 0, 0, 0);
    if(dict_Subviews_OriginalFrame && Subview){
        NSString *frameString=[dict_Subviews_OriginalFrame objectForKey:[NSString stringWithFormat:@"%p",Subview]];
        if(frameString.length>0){
            NSArray *rectComp=[frameString componentsSeparatedByString:@","];
            if(rectComp.count==4){
                frame.origin.x=[rectComp[0] floatValue];
                frame.origin.y=[rectComp[1] floatValue];
                frame.size.width=[rectComp[2] floatValue];
                frame.size.height=[rectComp[3] floatValue];
            }
        }
    }
    return frame;
}
-(void)storeOriginalFrame:(CGRect)frame forSubview:(id)Subview{
    NSString *frameString=[NSString stringWithFormat:@"%f,%f,%f,%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height];
    NSString *SubviewAddr=[NSString stringWithFormat:@"%p",Subview];
    if(dict_Subviews_OriginalFrame==nil){
        dict_Subviews_OriginalFrame=[[NSMutableDictionary alloc]init];
    }
    [dict_Subviews_OriginalFrame setObject:frameString forKey:SubviewAddr];
}
-(void)removeOriginalFrameOfSubview:(id)Subview{
    if(Subview==nil)return;
    NSString *SubviewAddr=[NSString stringWithFormat:@"%p",Subview];
    if(dict_Subviews_OriginalFrame && [dict_Subviews_OriginalFrame.allKeys containsObject:SubviewAddr]){
        [dict_Subviews_OriginalFrame removeObjectForKey:SubviewAddr];
    }
}
-(CGRect)convertDesignedFrame:(CGRect)frame{
    CGRect result=frame;
    result.origin.y+=self.adjustY;
    return result;
}
-(CGRect)makeCGRectByX:(CGFloat) x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height{
    CGRect rect=CGRectMake(x, y, width, height);
    return [self convertDesignedFrame:rect];
}
-(void)viewControllerDidRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[self class]]){
			[(SLResponsiveView *)v viewControllerDidRotateFromInterfaceOrientation:fromInterfaceOrientation];
		}
	}
}
-(void)viewControllerWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	for(UIView *v in self.subviews){
		if([v isKindOfClass:[self class]]){
			[(SLResponsiveView *)v viewControllerWillRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
		}
	}
}
-(void)viewControllerDidLayoutSubviews{
	for(id v in self.subviews){
		if([v isKindOfClass:[self class]]){
			[(SLResponsiveView *)v viewControllerDidLayoutSubviews];
		}
	}
}
#pragma mark - Class Methods
+(id)rotateShapeBack:(id)obj originalFrame:(CGRect)originRect includingUpsideDown:(BOOL)includingUpsideDown includingContent:(BOOL)includingContent  showingStatusBar:(BOOL)showingStatusBar isAlignedTop:(BOOL)isAlignedTop verticalReverse:(BOOL)verticalReverse currentDeviceOrientation:(UIDeviceOrientation)currentOrientation{
    if(![obj isKindOfClass:[UIView class]])return nil;
    CGRect currentAppFrame=[[self class]currentApplicationBoundsWithStatusBarShowing:showingStatusBar currentDeviceOrientation:currentOrientation];
    UIView *view=obj;
    //UIDeviceOrientation currentOrientation=[[UIDevice currentDevice]orientation];
	
    CGRect targetFrame=originRect;
    double deviceAngle=0;
    double targetAngle=0;
    CGFloat adjustX=(isAlignedTop && showingStatusBar)?[[self class]adjustY]:0;
    adjustX-=(isAlignedTop && showingStatusBar)?0:[[self class] statusBarHeight]-[[self class]adjustY];
	CGFloat adjustY=(showingStatusBar)?[[self class]adjustY]:0;
	if(view.tag == 987654321){
		NSLog(@"CATCH YOU");
	}
    switch (currentOrientation) {
        case UIDeviceOrientationLandscapeLeft:
            deviceAngle=M_PI/2;
            targetFrame.size.height=originRect.size.width;
            targetFrame.size.width=originRect.size.height;
            targetFrame.origin.x=originRect.origin.y-adjustX;
            targetFrame.origin.y=currentAppFrame.size.height-originRect.size.width-originRect.origin.x+adjustY;
			//targetFrame.origin.y=adjustY-originRect.origin.x;
            targetAngle=M_PI*2-deviceAngle;
            break;
        case UIDeviceOrientationLandscapeRight:
            deviceAngle=M_PI*3/2;
            targetFrame.size.height=originRect.size.width;
            targetFrame.size.width=originRect.size.height;
            targetFrame.origin.x=currentAppFrame.size.width-originRect.origin.y+adjustX-originRect.size.height;
            targetFrame.origin.y=originRect.origin.x+adjustY;
            targetAngle=M_PI*2-deviceAngle;
            break;
        case UIDeviceOrientationPortrait:
            //deviceAngle=0;
            targetAngle=0;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //deviceAngle=M_PI;
            if(includingUpsideDown){
                targetFrame.origin.x=originRect.origin.x;
                targetFrame.origin.y=currentAppFrame.size.height-originRect.origin.y+adjustY-originRect.size.height;
                if(includingContent)targetFrame.origin.y-=-originRect.size.height;
                targetAngle=M_PI;
            }else{
                targetAngle=0;
            }
            break;
        default:
            break;
    }
    if(includingContent){
        [view setTransform:CGAffineTransformMakeRotation(targetAngle)];
    }
    view.frame=targetFrame;
    return view;
}
+(NSInteger)OSMainVersionNumber{
	return [[[[[UIDevice currentDevice]systemVersion] componentsSeparatedByString:@"."]objectAtIndex:0] integerValue];
}
+(void)storeScreenBounds{
	CGRect bounds = [[UIScreen mainScreen]bounds];
	[SLGeneralDiagnose printRect:bounds comment:@"Screen Bounds"];
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication]statusBarOrientation];
	NSString *value = [NSString stringWithFormat:@"%f,%f,%f,%f,%ld", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, orientation];
	[[NSUserDefaults standardUserDefaults]setObject:value forKey:@"SLResponsiveView_InitialScreenBoundsAndOrientation"];
	[[NSUserDefaults standardUserDefaults]synchronize];
}
+(UIDeviceOrientation)deviceOrientationForSLResponsiveViewOrientation:(SLResponsiveViewOrientation)orientation{
	switch (orientation) {
		case kSLRVOrientationPortrait:
			return UIDeviceOrientationPortrait;
			break;
		case kSLRVOrientationPortraitDown:
			return UIDeviceOrientationPortraitUpsideDown;
			break;
		case kSLRVOrientationLandscapeLeft:
			return UIDeviceOrientationLandscapeLeft;
			break;
		case kSLRVOrientationLandscapeRight:
			return UIDeviceOrientationLandscapeRight;
		default:
			return UIDeviceOrientationPortrait;
			break;
	}
}
+(CGRect)currentApplicationBoundsWithStatusBarShowing:(BOOL)showingStatusBar currentDeviceOrientation:(UIDeviceOrientation)currentOrientation{
	BOOL useStoredValue = NO;
	if([[self class]OSMainVersionNumber]>=8){
		NSString *value = [[NSUserDefaults standardUserDefaults]stringForKey:@"SLResponsiveView_InitialScreenBoundsAndOrientation"];
		if(value){
			NSArray *components = [value componentsSeparatedByString:@","];
			if(components.count==5){
				useStoredValue = YES;
				CGRect screenBounds = CGRectMake(((NSString *)components[0]).floatValue,
												 ((NSString *)components[1]).floatValue,
												 ((NSString *)components[2]).floatValue,
												 ((NSString *)components[3]).floatValue);
				UIInterfaceOrientation orientation = ((NSString *)components[4]).intValue;
				
				if(currentOrientation == UIDeviceOrientationFaceUp || currentOrientation == UIDeviceOrientationFaceDown ||
				   ((orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
				   &&(currentOrientation == UIDeviceOrientationLandscapeLeft || currentOrientation == UIDeviceOrientationLandscapeRight))
				||((orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
				   &&(currentOrientation == UIDeviceOrientationPortrait || currentOrientation == UIDeviceOrientationPortraitUpsideDown))
				   ){
					return screenBounds;
				}else{
					CGFloat v = screenBounds.size.height;
					screenBounds.size.height = screenBounds.size.width;
					screenBounds.size.width = v;
					return screenBounds;
				}
			}
		}
	}
	
	CGRect screenBounds=[[UIScreen mainScreen]bounds];
	CGFloat adjustStatusBarHeight=[[self class]statusBarHeight]-[[self class]adjustY];
	CGRect currentAppFrame=screenBounds;
	switch (currentOrientation) {
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			currentAppFrame.size.height=(showingStatusBar)?screenBounds.size.width-adjustStatusBarHeight:screenBounds.size.width;
			currentAppFrame.size.width=screenBounds.size.height;
			break;
		default:
			currentAppFrame.size.height=(showingStatusBar)?screenBounds.size.height-adjustStatusBarHeight:screenBounds.size.height;
			currentAppFrame.size.width=screenBounds.size.width;
			break;
	}
	return currentAppFrame;
}
+(CGRect)applicationFrameWithStatusBarShowing:(BOOL)showingStatusBar{
    CGRect viewControllerFrame=[[UIScreen mainScreen]applicationFrame];
    if([[self class] adjustY]>0||!showingStatusBar){
        viewControllerFrame=[[UIScreen mainScreen]bounds];
    }
    return viewControllerFrame;
}
+(NSString *)nameOfOrientation:(SLResponsiveViewOrientation)orientation{
    NSString *name=nil;
    switch (orientation) {
        case kSLRVOrientationLandscape:
            name=@"Landscape";
            break;
        case kSLRVOrientationLandscapeLeft:
            name=@"LandscapeLeft";
            break;
        case kSLRVOrientationLandscapeRight:
            name=@"LandscapeRight";
            break;
        case kSLRVOrientationPortrait:
            name=@"Portrait";
            break;
        case kSLRVOrientationPortraitDown:
            name=@"PortraitDown";
            break;
        case kSLRVOrientationPortraitUp:
            name=@"PortraitUp";
            break;
        case kSLRVOrientationAll:
            name=@"All";
            break;
        default:
            name=@"Undefined";
            break;
    }
    return name;
}
+(CGFloat)fontSizeForWidth:(CGFloat)width{
    CGFloat suggestedSize=0;
    NSString *testString=@"国";
    if(suggestedSize==0)
        for (CGFloat i=suggestedSize; i<30; i+=0.1) {
            CGSize tmpStringSize=[testString sizeWithFont:[UIFont systemFontOfSize:i]];
            if(tmpStringSize.width*4>width){
                suggestedSize=i-0.1;
                break;
            }
        }
    return suggestedSize;
}
+(BOOL)rect:(CGRect)rect1 isEqualWithRect:(CGRect)rect2{
    if(rect1.origin.x==rect2.origin.x && rect1.origin.y==rect2.origin.y && rect1.size.height==rect2.size.height && rect1.size.width==rect2.size.width)
        return YES;
    else return NO;
}
+(BOOL)isRunningOniPad{
    if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad) return YES;
    else return NO;
}
+(BOOL)isRunningOnIPhone{
	return ![[self class]isRunningOniPad];
    //if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)return YES;
    //else return NO;
}
+(BOOL)isRunningOnIPhone4SOrEarlier{
	if(UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone){
		CGRect screenBounds=[[UIScreen mainScreen]bounds];
		CGFloat longestSide=(screenBounds.size.height>screenBounds.size.width)?screenBounds.size.height:screenBounds.size.width;
		if(longestSide<=480)
			return YES;
		else return NO;
	}
    else return NO;
}
+(UIImage *) convertToGreyscale:(UIImage *)i {
    CGSize size = [i size];
    int width = size.width*i.scale;
    int height = size.height*i.scale;
    typedef enum {
        ALPHA = 0,
        BLUE = 1,
        GREEN = 2,
        RED = 3
    } PIXELS;
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [i CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}
+(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
+(UIImage*)imageWithImage:(UIImage*)image resizeCanvusWithFactor:(float)factor {
	if(factor==1)return image;
	else if(factor>1){
		CGSize newSize=CGSizeMake(image.size.width*factor, image.size.height*factor);
		UIGraphicsBeginImageContext( newSize );
		CGRect rect=CGRectMake((newSize.width-image.size.width)/2,(newSize.height-image.size.height)/2,image.size.width,image.size.height);
		[image drawInRect:rect];
		UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		return newImage;
	}else if(factor>0 && factor<1){
		CGSize newSize=CGSizeMake(image.size.width*factor, image.size.height*factor);
		CGRect rect=CGRectMake((image.size.width-newSize.width)/2, (image.size.height-newSize.height)/2, newSize.width, newSize.height);
		CGImageRef cgImage=CGImageCreateWithImageInRect(image.CGImage, rect);
		UIImage* newImage =[UIImage imageWithCGImage:cgImage];
		CGImageRelease(cgImage);
		return newImage;
	}else{
		return nil;
	}
}
+(void)shakeObject:(id)obj withSwing:(CGFloat)swing inHorizontalDirection:(BOOL)hori{
    if(obj && [obj isKindOfClass:UIView.class]){
        UIView *v=obj;
        CGFloat t = swing;
        if(t<=0)t=2.0f;
        CGFloat times=2.0f;
        CGAffineTransform translate2  =(hori)?CGAffineTransformTranslate(CGAffineTransformIdentity, t, 0.0):CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, t);
        CGAffineTransform translate1 = (hori)?CGAffineTransformTranslate(CGAffineTransformIdentity, -t, 0.0):CGAffineTransformTranslate(CGAffineTransformIdentity, 0.0, -t);
        v.transform = translate2;
        [UIView animateWithDuration:0.07
                              delay:0.0
                            options:UIViewAnimationOptionAutoreverse|UIViewAnimationOptionRepeat
                         animations:^{
                             [UIView setAnimationRepeatCount:times];
                             v.transform = translate1;
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 [UIView animateWithDuration:0.05
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseInOut
                                                  animations:^{
                                                      v.transform = CGAffineTransformIdentity;
                                                  }
                                                  completion:NULL];
                             }
                         }
         ];
    }
}
+(UIImage *)iconAtLine:(NSInteger)line column:(NSInteger)column{
    if(line<1 || line>15 || column<1 || column>14)return nil;
    UIImage *targetImage=nil;
    UIImage *motherImage=[UIImage imageNamed:@"SLResponsiveView_iconSet.png"];
    CGRect targetRect=CGRectZero;
    CGFloat marginTop=0;
    CGFloat marginLeft=0;
    CGFloat marginVertical=30;
    CGFloat marginHorizontal=45;
    CGSize targetSize=CGSizeMake(32, 32);
    targetRect.origin.x=marginLeft+(column-1)*(targetSize.width+marginHorizontal);
    targetRect.origin.y=marginTop+(line-1)*(targetSize.height+marginVertical);
    targetRect.size=targetSize;
    CGImageRef drawImage=CGImageCreateWithImageInRect(motherImage.CGImage, targetRect);
    targetImage=[UIImage imageWithCGImage:drawImage];
	CGImageRelease(drawImage);
    return targetImage;
}
+(UIImage *)image:(UIImage *)img withColor:(UIColor *)color {
	if(!color)return img;
	CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
	UIGraphicsBeginImageContext(img.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Add the following 2 lines to prevent the image be flipped upside down
	CGContextTranslateCTM(context, 0, img.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextClipToMask(context, rect, img.CGImage);
	CGContextSetFillColorWithColor(context, [color CGColor]);
	CGContextFillRect(context, rect);
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	// if just change the orientation, it will be ignored at some place
	// such as when image is set as button background, the system generated highlighted image will be upside down
	//UIImage *flippedImage = [UIImage imageWithCGImage:image.CGImage scale:1.0 orientation: UIImageOrientationDownMirrored];
	return image;
}
+(UIImage *)image:(UIImage *)image withMarkImage:(UIImage *)markImage atCornerUp:(BOOL)up left:(BOOL)left markScale:(CGFloat)scale{
	if(!markImage)return image;
	UIImage *newImage=nil;
	CGSize markSize=CGSizeMake(scale*image.size.height/markImage.size.height*markImage.size.width, scale*image.size.height);
	CGPoint markPoint=CGPointMake((left)?0:image.size.width-markSize.width, (up)?0:image.size.height-markSize.height);
	UIImage *newMarkImage=[[self class]imageWithImage:markImage scaledToSize:markSize];
	if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(image.size, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(image.size);
    }
	[image drawAtPoint: CGPointZero];
    [newMarkImage drawAtPoint:markPoint];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
+(UIImage *)imageByCombiningImage:(UIImage*)aFirstImage withImage:(UIImage*)aSecondImage horizontally:(BOOL)horizontally margin:(CGFloat)margin resizeToSmallerSize:(BOOL) resizeToSmallerSize{
	UIImage *firstImage=aFirstImage;
	UIImage *secondImage=aSecondImage;
	if(firstImage==nil)return secondImage;
	if(secondImage==nil)return  firstImage;
    UIImage *image = nil;
	if(resizeToSmallerSize){
		if(horizontally){
			if(firstImage.size.height>secondImage.size.height){
				CGSize smallerSize=CGSizeMake(firstImage.size.width*(secondImage.size.height/firstImage.size.height), secondImage.size.height);
				firstImage=[self.class imageWithImage:firstImage scaledToSize:smallerSize];
			}else if(secondImage.size.height>firstImage.size.height){
				CGSize smallerSize=CGSizeMake(secondImage.size.width*(firstImage.size.height/secondImage.size.height), firstImage.size.height);
				secondImage=[self.class imageWithImage:secondImage scaledToSize:smallerSize];
			}
		}else{
			if(firstImage.size.width>secondImage.size.width){
				CGSize smallerSize=CGSizeMake(secondImage.size.width, firstImage.size.height*(secondImage.size.width/firstImage.size.width));
				firstImage=[self.class imageWithImage:firstImage scaledToSize:smallerSize];
			}else if(secondImage.size.width>firstImage.size.width){
				CGSize smallerSize=CGSizeMake(firstImage.size.width, secondImage.size.height*(firstImage.size.width/secondImage.size.width));
				secondImage=[self.class imageWithImage:secondImage scaledToSize:smallerSize];
			}
		}
	}
    //CGSize newImageSize = CGSizeMake(MAX(firstImage.size.width, secondImage.size.width), MAX(firstImage.size.height, secondImage.size.height));
	CGSize newImageSize = (horizontally)? CGSizeMake(firstImage.size.width + secondImage.size.width, MAX(firstImage.size.height, secondImage.size.height)) : CGSizeMake(MAX(firstImage.size.width, secondImage.size.width), firstImage.size.height+ margin+secondImage.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(newImageSize);
    }
	CGPoint firstPoint=(horizontally)?CGPointMake(0,roundf((newImageSize.height-firstImage.size.height)/2)):
								  	  CGPointMake(roundf((newImageSize.width-firstImage.size.width)/2),0);
	CGPoint secondPoint=(horizontally)?CGPointMake(firstImage.size.width+margin,roundf((newImageSize.height-secondImage.size.height)/2)):
									   CGPointMake(firstImage.size.height+margin,roundf((newImageSize.width-secondImage.size.width)/2));
    [firstImage drawAtPoint: firstPoint];
    [secondImage drawAtPoint:secondPoint];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
+(UIImage *)image:(UIImage *)image withRoundBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor fillColor:(UIColor *)fillColor{
	if(!image) return nil;
	UIGraphicsBeginImageContext(image.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, borderWidth);
	CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
	CGContextSetFillColorWithColor(context, fillColor.CGColor);
	CGRect rect = CGRectMake(borderWidth/2, borderWidth/2, image.size.width-borderWidth, image.size.height-borderWidth);
	CGContextFillEllipseInRect(context, rect);
	CGContextAddEllipseInRect(context, rect);
    CGContextStrokePath(context);
	[image drawAtPoint:CGPointZero];
	UIImage *borderImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return borderImage;
}
+(UIImage *)image:(UIImage *)image rotatedAngle:(CGFloat)angle{
	if(!image)return nil;
    // calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(angle);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
	
    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
	
    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
	
    //   // Rotate the image context
    CGContextRotateCTM(bitmap, angle);
	
    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
	
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
	
}
+(NSAttributedString *)setUnderlineStyleForString:(NSString *)text color:(UIColor *)color{
	NSMutableAttributedString *attrText=[[NSMutableAttributedString alloc]initWithString:text];
	NSRange range={.location=0, .length=text.length};
	[attrText addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
	if(color)
		[attrText addAttribute:NSForegroundColorAttributeName value:color range:range];
	return attrText;
}
+(UIButton *)setUnderlineStyleForButton:(UIButton *)button withTitleText:(NSString *)text{
    if([button respondsToSelector:@selector(setAttributedTitle:forState:)]){
        NSMutableAttributedString *attrText=[[NSMutableAttributedString alloc]initWithString:text];
        NSRange range={.location=0, .length=text.length};
        [attrText addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
        [attrText addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:range];
        [button setAttributedTitle:attrText forState:UIControlStateNormal];
        attrText=[[NSMutableAttributedString alloc]initWithString:text];
        [attrText addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
        [attrText addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
        [button setAttributedTitle:attrText forState:UIControlStateHighlighted];
    }else{
        [button setTitle:text forState:UIControlStateNormal];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    }
    button.titleLabel.adjustsFontSizeToFitWidth=YES;
    return button;
}
+(UIButton *)setUnderlineStyleForButton:(UIButton *)button withTitleText:(NSString *)text color:(UIColor *)color forState:(UIControlState)state{
    if(text!=nil && [button respondsToSelector:@selector(setAttributedTitle:forState:)]){
        NSMutableAttributedString *attrText=[[NSMutableAttributedString alloc]initWithString:text];
        NSRange range={.location=0, .length=text.length};
        [attrText addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
        [attrText addAttribute:NSForegroundColorAttributeName value:color range:range];
        [button setAttributedTitle:attrText forState:state];
    }else{
        [button setTitle:text forState:state];
        [button setTitleColor:color forState:state];
    }
    button.titleLabel.adjustsFontSizeToFitWidth=YES;
    return button;
}
+(CGSize)sizeOfText:(NSString *)text font:(UIFont *)font constrainedToSize:(CGSize)size{
    if ([[self class]OSMainVersionNumber]>=7)
    {
        CGRect frame = [text boundingRectWithSize:size
                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                       attributes:@{NSFontAttributeName:font}
                                          context:nil];
        return CGSizeMake(roundf(frame.size.width),roundf(frame.size.height));
    }
    else
    {
		CGSize size=CGSizeZero;
		size=[text sizeWithFont:font constrainedToSize:size];
        return CGSizeMake(ceilf(size.width),ceilf(size.height));
    }
}
+(CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font{
	if(!text)return CGSizeZero;
	UIFont *textFont=font;
	if(!font)textFont=[UIFont systemFontOfSize:[UIFont systemFontSize]];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:textFont, NSFontAttributeName, nil];
	CGSize strSize=([[[UIDevice currentDevice]systemVersion]integerValue]<7)?[text sizeWithFont:textFont]:[text sizeWithAttributes:attributes];
	return strSize;
}
+(UIViewAnimationOptions)randomTransitionOption{
	NSInteger random=(int)(arc4random()%7);
	UIViewAnimationOptions option=UIViewAnimationOptionTransitionFlipFromBottom;
	switch (random) {
		case 0:
			option=UIViewAnimationOptionTransitionCrossDissolve;
			break;
		case 1:
			option=UIViewAnimationOptionTransitionCurlDown;
			break;
		case 2:
			option=UIViewAnimationOptionTransitionCurlUp;
			break;
		case 3:
			option=UIViewAnimationOptionTransitionFlipFromTop;
			break;
		case 4:
			option=UIViewAnimationOptionTransitionFlipFromBottom;
			break;
		case 5:
			option=UIViewAnimationOptionTransitionFlipFromLeft;
			break;
		case 6:
			option=UIViewAnimationOptionTransitionFlipFromRight;
			break;
		default:
			option=UIViewAnimationOptionShowHideTransitionViews;
			break;
	}
	return option;
}
+(CGRect) imagePositionInImageView:(UIImageView*)anImageView{
    float x = 0.0f;
    float y = 0.0f;
    float w = 0.0f;
    float h = 0.0f;
    CGFloat ratio = 0.0f;
    CGFloat horizontalRatio = anImageView.frame.size.width / anImageView.image.size.width;
    CGFloat verticalRatio = anImageView.frame.size.height / anImageView.image.size.height;

    switch (anImageView.contentMode) {
        case UIViewContentModeScaleToFill:
            w = anImageView.frame.size.width;
            h = anImageView.frame.size.height;
            break;
        case UIViewContentModeScaleAspectFit:
            // contents scaled to fit with fixed aspect. remainder is transparent
            ratio = MIN(horizontalRatio, verticalRatio);
            w = anImageView.image.size.width*ratio;
            h = anImageView.image.size.height*ratio;
            x = (horizontalRatio == ratio ? 0 : ((anImageView.frame.size.width - w)/2));
            y = (verticalRatio == ratio ? 0 : ((anImageView.frame.size.height - h)/2));
            break;
        case UIViewContentModeScaleAspectFill:
            // contents scaled to fill with fixed aspect. some portion of content may be clipped.
            ratio = MAX(horizontalRatio, verticalRatio);
            w = anImageView.image.size.width*ratio;
            h = anImageView.image.size.height*ratio;
            x = (horizontalRatio == ratio ? 0 : ((anImageView.frame.size.width - w)/2));
            y = (verticalRatio == ratio ? 0 : ((anImageView.frame.size.height - h)/2));
            break;
        case UIViewContentModeCenter:
            // contents remain same size. positioned adjusted.
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            x = (anImageView.frame.size.width - w)/2;
            y = (anImageView.frame.size.height - h)/2;
            break;
        case UIViewContentModeTop:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            x = (anImageView.frame.size.width - w)/2;
            break;
        case UIViewContentModeBottom:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            y = (anImageView.frame.size.height - h);
            x = (anImageView.frame.size.width - w)/2;
            break;
        case UIViewContentModeLeft:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            y = (anImageView.frame.size.height - h)/2;
            break;
        case UIViewContentModeRight:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            y = (anImageView.frame.size.height - h)/2;
            x = (anImageView.frame.size.width - w);
            break;
        case UIViewContentModeTopLeft:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            break;
        case UIViewContentModeTopRight:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            x = (anImageView.frame.size.width - w);
            break;
        case UIViewContentModeBottomLeft:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            y = (anImageView.frame.size.height - h);
            break;
        case UIViewContentModeBottomRight:
            w = anImageView.image.size.width;
            h = anImageView.image.size.height;
            y = (anImageView.frame.size.height - h);
            x = (anImageView.frame.size.width - w);
        default:
            break;
    }
    return CGRectMake(x, y, w, h);
}
+(UIImage*)captureView:(UIView *)view rectOnScreen:(CGRect)rect {
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
+(UIImage *)image:(UIImage *)image subRegion:(CGRect)rect{
	if(!image)return nil;
	CGRect fromRect = rect; // or whatever rectangle
	CGImageRef drawImage = CGImageCreateWithImageInRect(image.CGImage, fromRect);
	UIImage *newImage = [UIImage imageWithCGImage:drawImage];
	CGImageRelease(drawImage);
	return newImage;
}
+(UIImage *)image:(UIImage *)image rotateAngle:(CGFloat)angle{
	if(!image) return nil;
	CGSize imgSize = image.size;
	// calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,imgSize.width, imgSize.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(angle);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;

    // Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();

    // Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

    //   // Rotate the image context
    CGContextRotateCTM(bitmap, angle);

    // Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-imgSize.width / 2, -imgSize.height / 2, imgSize.width, imgSize.height), [image CGImage]);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
#pragma mark - Constraint
-(SLResponsiveViewConstraint *)addSLConstraint:(SLResponsiveViewConstraintType)type andValue:(CGFloat)value forObject:(UIView *)Subview isContained:(BOOL)isContained byReferencingObject:(UIView *)refView forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt{
    if(!Subview)return nil;
    SLResponsiveViewConstraint *constraint=[SLResponsiveViewConstraint constraintWithType:type andValue:value forObject:Subview isContained:isContained byReferencingObject:refView forOrientation:orien forKeyboardStatus:ks forDeviceType:dt];
    if(ks!=kSLRVKeyboardStatusUnused) constraint.keyboardDelegate=self;
    [self addSLConstraint:constraint];
    return constraint;
}
-(NSArray *)addInnerMarginSLConstraintForSubview:(UIView *)subview margin:(UIEdgeInsets)margin inFullScreenMode:(BOOL)fullScreenMode forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt{
	SLResponsiveViewConstraint *constraintBottom=nil;
	if([[self class]OSMainVersionNumber] < 8){
		constraintBottom=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginBottom andValue:(fullScreenMode)?margin.bottom:margin.bottom+[self.class adjustY] forObject:subview isContained:YES byReferencingObject:self forOrientation:orien forKeyboardStatus:ks forDeviceType:dt];
		[self addSLConstraint:constraintBottom];
	}else{
		NSArray *orienLandscape = @[[NSNumber numberWithInt: kSLRVOrientationLandscapeLeft]
									,[NSNumber numberWithInt: kSLRVOrientationLandscapeRight]
									,[NSNumber numberWithInt: kSLRVOrientationLandscape]];
		NSArray *orienPorait = @[[NSNumber numberWithInt: kSLRVOrientationPortraitUp]
								 ,[NSNumber numberWithInt: kSLRVOrientationPortraitDown]
								 ,[NSNumber numberWithInt: kSLRVOrientationPortrait]];
		
		NSMutableArray *orienSet = [NSMutableArray new];
		if(orien == kSLRVOrientationAll){
			[orienSet addObjectsFromArray:orienLandscape];
			[orienSet addObjectsFromArray:orienPorait];
		}else if(orien==kSLRVOrientationPortrait){
			[orienSet addObjectsFromArray:orienPorait];
		}else if(orien==kSLRVOrientationLandscape){
			[orienSet addObjectsFromArray:orienLandscape];
		}else{
			[orienSet addObject:[NSNumber numberWithInt:orien]];
		}
		for(NSNumber *obj in orienSet){
			SLResponsiveViewOrientation o = obj.intValue;
			if(o == kSLRVOrientationLandscape || o == kSLRVOrientationLandscapeLeft || o == kSLRVOrientationLandscapeRight){
				constraintBottom=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginBottom andValue:margin.bottom forObject:subview isContained:YES byReferencingObject:self forOrientation:o forKeyboardStatus:ks forDeviceType:dt];
			}else if(o == kSLRVOrientationPortrait || o == kSLRVOrientationPortraitUp || o == kSLRVOrientationUnknown){
				constraintBottom=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginBottom andValue:(fullScreenMode)?margin.bottom:margin.bottom+[self.class adjustY] forObject:subview isContained:YES byReferencingObject:self forOrientation:o forKeyboardStatus:ks forDeviceType:dt];
			}
			[self addSLConstraint:constraintBottom];
		}
	}
    SLResponsiveViewConstraint *constraintTop=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginTop andValue:margin.top forObject:subview isContained:YES byReferencingObject:self forOrientation:orien forKeyboardStatus:ks forDeviceType:dt];
    [self addSLConstraint:constraintTop];
    SLResponsiveViewConstraint *constraintLeft=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginLeft andValue:margin.left forObject:subview isContained:YES byReferencingObject:self forOrientation:orien forKeyboardStatus:ks forDeviceType:dt];
    [self addSLConstraint:constraintLeft];
    SLResponsiveViewConstraint *constraintRight=[SLResponsiveViewConstraint constraintWithType:kSLRVConstraintMarginRight andValue:margin.right forObject:subview isContained:YES byReferencingObject:self forOrientation:orien forKeyboardStatus:ks forDeviceType:dt];
    [self addSLConstraint:constraintRight];
    if(fullScreenMode){
        if(fullScreenSubviews==nil)fullScreenSubviews=[[NSMutableArray alloc]init];
        [fullScreenSubviews addObject:subview];
    }
    return @[constraintTop, constraintBottom, constraintLeft, constraintRight];
}
-(void)addSLConstraint:(SLResponsiveViewConstraint *)constraint{
    if(constraint && constraint.object
       &&(constraint.deviceType==kSLRVDeviceTypeAll||(constraint.deviceType==kSLRVDeviceTypeiPhone && [[self class]isRunningOnIPhone])
          ||(constraint.deviceType==kSLRVDeviceTypeiPad && [[self class]isRunningOniPad]))){
           if(constraintsOfSubviews==nil)constraintsOfSubviews=[[NSMutableDictionary alloc]init];
           NSValue *SubviewValue=[NSValue valueWithNonretainedObject:constraint.object];
           NSMutableArray *constraintStack=[constraintsOfSubviews objectForKey:SubviewValue];
           if(constraintStack==nil){
               constraintStack=[[NSMutableArray alloc]init];
               [constraintsOfSubviews setObject:constraintStack forKey:SubviewValue];
           }
           [constraintStack addObject:constraint];
           if(!subviewsWithConstraints) subviewsWithConstraints=[[NSMutableArray alloc]init];
           if(![subviewsWithConstraints containsObject:constraint.object]) [subviewsWithConstraints addObject:constraint.object];
           if(constraint.referencingObject && constraint.referencingObject!=self){
               if(subviewsReferencedByConstraints==nil)subviewsReferencedByConstraints=[[NSMutableArray alloc]init];
               if(![subviewsReferencedByConstraints containsObject:constraint.referencingObject])
                   [subviewsReferencedByConstraints addObject:constraint.referencingObject];
               
               NSMutableArray *tmpArray=nil;
               if(constraintsOfReferencedSubviews==nil)constraintsOfReferencedSubviews=[[NSMutableDictionary alloc]init];
               NSValue *referencedSubviewValue=[NSValue valueWithNonretainedObject:constraint.referencingObject];
               tmpArray=[constraintsOfReferencedSubviews objectForKey:referencedSubviewValue];
               if(tmpArray==nil){
                   tmpArray=[[NSMutableArray alloc]init];
                   [constraintsOfReferencedSubviews setObject:tmpArray forKey:referencedSubviewValue];
               }
               [tmpArray addObject:constraint];
               
               if(dict_SubviewsReferencing==nil)dict_SubviewsReferencing=[[NSMutableDictionary alloc]init];
               tmpArray=nil;
               tmpArray=[dict_SubviewsReferencing objectForKey:SubviewValue];
               if(tmpArray==nil){
                   tmpArray=[[NSMutableArray alloc]init];
                   [dict_SubviewsReferencing setObject:tmpArray forKey:SubviewValue];
               }
               if(![tmpArray containsObject:constraint.referencingObject])
                   [tmpArray addObject:constraint.referencingObject];
               
               if(dict_SubviewsReferencedBy==nil)dict_SubviewsReferencedBy=[[NSMutableDictionary alloc]init];
               NSValue *referencingSubviewValue=[NSValue valueWithNonretainedObject:constraint.referencingObject];
               tmpArray=nil;
               tmpArray=[dict_SubviewsReferencedBy objectForKey:referencingSubviewValue];
               if(tmpArray==nil){
                   tmpArray=[[NSMutableArray alloc]init];
                   [dict_SubviewsReferencedBy setObject:tmpArray forKey:SubviewValue];
               }
               if(![tmpArray containsObject:constraint.object])
                   [tmpArray addObject:constraint.object];
           }
           [self sortSubviewsWithConstraints];
       }
}
-(void)removeSLConstraint:(SLResponsiveViewConstraint *)constraint{
    if(constraint && constraintsOfSubviews.count>0){
        NSValue *subviewValue=[NSValue valueWithNonretainedObject:constraint.object];
        NSMutableArray *constraintStack=[constraintsOfSubviews objectForKey:subviewValue];
        if(constraintStack && [constraintStack containsObject:constraint]){
            [constraintStack removeObject:constraint];
            if(constraint.referencingObject && constraintsOfReferencedSubviews){
                NSValue *referencedSubviewValue=[NSValue valueWithNonretainedObject:constraint.referencingObject];
                NSMutableArray *tmpConstraintStack=[constraintsOfReferencedSubviews objectForKey:referencedSubviewValue];
                if(tmpConstraintStack && [tmpConstraintStack containsObject:constraint]){
                    [tmpConstraintStack removeObject:constraint];
                }
                if(tmpConstraintStack.count==0) [constraintsOfReferencedSubviews removeObjectForKey:referencedSubviewValue];
                
                BOOL exist=NO;
                for(SLResponsiveViewConstraint *cst in constraintStack){
                    if(cst.referencingObject==constraint.referencingObject){
                        exist=YES;
                        break;
                    }
                }
                if(!exist){
                    NSMutableArray *tmpArray=[dict_SubviewsReferencing objectForKey:subviewValue];
                    if([tmpArray containsObject:constraint.referencingObject]){
                        [tmpArray removeObject:constraint.referencingObject];
                    }
                    if(tmpArray.count==0)[dict_SubviewsReferencing removeObjectForKey:subviewValue];
                    
                    tmpArray=[dict_SubviewsReferencedBy objectForKey:referencedSubviewValue];
                    if([tmpArray containsObject:constraint.object]){
                        [tmpArray removeObject:constraint.object];
                    }
                    if(tmpArray.count==0){
                        [dict_SubviewsReferencedBy removeObjectForKey:referencedSubviewValue];
                        if( [subviewsReferencedByConstraints containsObject:constraint.referencingObject]){
                            [subviewsReferencedByConstraints removeObject:constraint.referencingObject];
                        }
                    }
                }
            }
        }
        if(constraintStack.count==0){
            [constraintsOfSubviews removeObjectForKey:subviewValue];
            if(subviewsWithConstraints && [subviewsWithConstraints containsObject:constraint.object])
                [subviewsWithConstraints removeObject:constraint.object];
        }
        
        
    }
}
-(void)removeSLConstraintForObject:(UIView *)subview{
    if(!subview)return;
    NSValue *SubviewValue=[NSValue valueWithNonretainedObject:subview];
    if(constraintsOfSubviews){
        NSMutableArray *constraints=[[constraintsOfSubviews objectForKey:SubviewValue] mutableCopy];
        for(SLResponsiveViewConstraint *cst in constraints) [self removeSLConstraint:cst];
        constraints=[[constraintsOfReferencedSubviews objectForKey:SubviewValue]mutableCopy];
        for(SLResponsiveViewConstraint *cst in constraints) [self removeSLConstraint:cst];
    }
    if([fullScreenSubviews containsObject:subview])[fullScreenSubviews removeObject:subview];
}
-(void)sortSubviewsWithConstraints{
    // 1. Find out subviews referenced by others
    NSMutableArray *referencedSubviewsWithConstraints=[[NSMutableArray alloc]init];
    NSMutableArray *onlyReferencingOrSoloSubviewsWithChonstraints=[subviewsWithConstraints mutableCopy];
    for(UIView *v in subviewsReferencedByConstraints){
        if([subviewsWithConstraints containsObject:v]) [referencedSubviewsWithConstraints addObject:v];
    }
    [onlyReferencingOrSoloSubviewsWithChonstraints removeObjectsInArray:referencedSubviewsWithConstraints];
    // 2. Find out objects not referencing others excepts those already picked out from the referencedSubviewsWithConstraints
    NSMutableArray *sortedSubviewsWithConstraints=[[NSMutableArray alloc]initWithCapacity:subviewsWithConstraints.count];
    if(referencedSubviewsWithConstraints.count>0){
        while (referencedSubviewsWithConstraints.count>0){
            UIView *clearView=nil;
            for(UIView *v in referencedSubviewsWithConstraints){
                BOOL isReferencingOthers=NO;
                NSMutableArray *tmpArray=[[dict_SubviewsReferencing objectForKey:[NSValue valueWithNonretainedObject:v]]mutableCopy];
                if(tmpArray.count>0){
                    [tmpArray removeObjectsInArray:sortedSubviewsWithConstraints];
                    if(tmpArray.count>0) isReferencingOthers=YES;
                }
                if(!isReferencingOthers){
                    clearView=v;
                    break;
                }
            }
            if(clearView!=nil){
                [sortedSubviewsWithConstraints addObject:clearView];
                [referencedSubviewsWithConstraints removeObject:clearView];
            }else {
                [sortedSubviewsWithConstraints addObjectsFromArray:referencedSubviewsWithConstraints];
                break;
            }
        }
    }
    [sortedSubviewsWithConstraints addObjectsFromArray:onlyReferencingOrSoloSubviewsWithChonstraints];
    subviewsWithConstraints=sortedSubviewsWithConstraints;
}
-(BOOL)shouldAnimateConstraints{
	return NO;
}
-(void)applyConstraints{
	for(UIView *subview in subviewsWithConstraints){
		[self applyConstraintsForSubview:subview];
	}
}
-(BOOL)shouldApplyConstraint:(SLResponsiveViewConstraint *)cst verbose:(BOOL)verbose{
    if(cst.object==nil || ![self.subviews containsObject:cst.object])return NO;
	if(cst.referencingObject && cst.referencingObject!=self && ![self.subviews containsObject:cst.referencingObject]) return NO;
    BOOL deviceCompatible=(
                           cst.deviceType==kSLRVDeviceTypeAll
                           || (cst.deviceType==kSLRVDeviceTypeiPad && [[self class]isRunningOniPad])
                           ||(cst.deviceType==kSLRVDeviceTypeiPhone && [[self class]isRunningOnIPhone])
                           );
    BOOL orientationCompatible=[cst compatibleWithOrientation:orientation];
    BOOL conditionCompatible=(
                              cst.conditionDelegate==nil
                              || (cst.conditionDelegate && [cst.conditionDelegate shouldApplyConditionalConstraint:cst])
                              );
    BOOL keyboardStatusCompatible=(
                                   cst.keyboardStatus==kSLRVKeyboardStatusUnused || cst.keyboardDelegate==nil ||cst.keyboardStatus==kSLRVKeyboardStatusAll
                                   ||(cst.keyboardStatus==kSLRVKeyboardShowing && cst.keyboardDelegate && [cst.keyboardDelegate keyboardHeight]>0)
                                   ||(cst.keyboardStatus==kSLRVKeyboardHidden && cst.keyboardDelegate && [cst.keyboardDelegate keyboardHeight]==0)
                                   );
    if(verbose)
        NSLog(@"device=%d, orientation=%d, condition=%d, keyboard=%d", deviceCompatible, orientationCompatible, conditionCompatible, keyboardStatusCompatible);
    if(deviceCompatible
       && orientationCompatible
       && conditionCompatible
       && keyboardStatusCompatible
       ) return YES;
    else return NO;
}
-(void)applyConstraintsForSubview:(UIView *)subview{
	// For iOS 6, need to check whether the view is in mainThread
	if([[SLResponsiveView class]OSMainVersionNumber] < 7 && ![NSThread isMainThread])return;
	//
    NSMutableArray *constraintsOfSubview=[constraintsOfSubviews objectForKey:[NSValue valueWithNonretainedObject:subview]];
	NSMutableArray *constraints=[[NSMutableArray alloc]init];
   // NSMutableArray *deleteCSTs=[[NSMutableArray alloc]init];
    for(SLResponsiveViewConstraint *cst in constraintsOfSubview){
         if([cst.name isEqualToString:@"ABC"]){
            // NSLog(@"cst condition=%d, shouldApply=%d",[cst.conditionDelegate shouldApplyConditionalConstraint:cst], [self shouldApplyConstraint:cst verbose:YES]);
			 if([self shouldApplyConstraint:cst verbose:NO]){
				 NSLog(@"should apply constraint ABC");
			 }
         }
        if(![self shouldApplyConstraint:cst verbose:NO]){
            //[deleteCSTs addObject:cst];
        }else{
			if(cst.type!=kSLRVConstraintWidth && cst.type!=kSLRVConstraintHeight)
				[constraints addObject:cst];
			else
				[constraints insertObject:cst atIndex:0];
		}
    }
    //if(constraints.count>0 && deleteCSTs.count>0){
    //    [constraints removeObjectsInArray:deleteCSTs];
    //}
    if(constraints.count>0){
        NSMutableArray *tmpConstraints=[constraints mutableCopy];
        // Apply solo constraints first
        for(SLResponsiveViewConstraint *cst in constraints){
            if(cst.referencingObject==nil && [self shouldApplyConstraint:cst verbose:NO ]){
                [self applyConstraint:cst];
                [tmpConstraints removeObject:cst];
            }
        }
        // Check for constraints co-operate on the same object with related attributes
        NSMutableArray *tmpArray=[tmpConstraints mutableCopy];
        NSMutableArray *processedConstraints=[[NSMutableArray alloc]init];
        while (tmpArray.count>0) {
            SLResponsiveViewConstraint *cst=[tmpArray lastObject];
            [tmpArray removeLastObject];
			for(SLResponsiveViewConstraint *tmpCST in tmpArray){
				if((tmpCST.type==kSLRVConstraintMarginBottom&& cst.type==kSLRVConstraintMarginTop)
				   ||(tmpCST.type==kSLRVConstraintMarginTop&&cst.type==kSLRVConstraintMarginBottom)){
					CGRect rect=cst.object.frame;
					if(cst.isContained && tmpCST.isContained && cst.referencingObject==tmpCST.referencingObject)
						rect.size.height=cst.referencingObject.bounds.size.height-cst.value-tmpCST.value;
					else if(cst.isContained && !tmpCST.isContained){
						if(tmpCST.type==kSLRVConstraintMarginBottom&& cst.type==kSLRVConstraintMarginTop){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.y+tmpCST.referencingObject.frame.size.height:tmpCST.referencingObject.frame.origin.y;
							rect.size.height=tmpCstBorder-tmpCST.value-cst.value;
						}else if(tmpCST.type==kSLRVConstraintMarginTop&&cst.type==kSLRVConstraintMarginBottom){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.y:tmpCST.referencingObject.frame.origin.y+tmpCST.referencingObject.frame.size.height;
							rect.size.height=cst.referencingObject.bounds.size.height-cst.value-tmpCstBorder-tmpCST.value;
						}
					}else if(tmpCST.isContained && !cst.isContained){
						if(tmpCST.type==kSLRVConstraintMarginBottom&& cst.type==kSLRVConstraintMarginTop){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.y:cst.referencingObject.frame.origin.y+cst.referencingObject.frame.size.height;
							rect.size.height=tmpCST.referencingObject.bounds.size.height-tmpCST.value-(cstBorder+cst.value);
						}else if(tmpCST.type==kSLRVConstraintMarginTop&&cst.type==kSLRVConstraintMarginBottom){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.y+cst.referencingObject.frame.size.height:cst.referencingObject.frame.origin.y;
							rect.size.height=cstBorder-cst.value-tmpCST.value;
						}
					}else if(!tmpCST.isContained && !cst.isContained){
						if(tmpCST.type==kSLRVConstraintMarginBottom&& cst.type==kSLRVConstraintMarginTop){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.y:cst.referencingObject.frame.origin.y+cst.referencingObject.frame.size.height;
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.y+tmpCST.referencingObject.frame.size.height:tmpCST.referencingObject.frame.origin.y;
							rect.size.height=tmpCstBorder-tmpCST.value-cstBorder-cst.value;
						}else if(tmpCST.type==kSLRVConstraintMarginTop&&cst.type==kSLRVConstraintMarginBottom){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.y+cst.referencingObject.frame.size.height:cst.referencingObject.frame.origin.y;
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.y:tmpCST.referencingObject.frame.origin.y+tmpCST.referencingObject.frame.size.height;
							rect.size.height=cstBorder-cst.value-(tmpCstBorder+tmpCST.value);
						}
					}
					if(cst.keyboardStatus==kSLRVKeyboardStatusAll||cst.keyboardStatus==kSLRVKeyboardShowing||cst.keyboardStatus==kSLRVKeyboardHidden){
						CGFloat adjustY=[self adjustY];
						if([fullScreenSubviews containsObject:subview]){
							adjustY=0;
						}
						rect.size.height-=self.keyboardHeight+adjustY;
					}
					if(rect.size.height<0)rect.size.height = 0;
					cst.object.frame=rect;
					[processedConstraints addObject:tmpCST];
				}else if((tmpCST.type==kSLRVConstraintMarginRight&&cst.type==kSLRVConstraintMarginLeft)
						 ||(tmpCST.type==kSLRVConstraintMarginLeft&&cst.type==kSLRVConstraintMarginRight)){
					CGRect rect=cst.object.frame;
					if(cst.isContained && tmpCST.isContained && cst.referencingObject==tmpCST.referencingObject)
						rect.size.width=cst.referencingObject.bounds.size.width-cst.value-tmpCST.value;
					else if(cst.isContained && !tmpCST.isContained){
						if(tmpCST.type==kSLRVConstraintMarginRight&&cst.type==kSLRVConstraintMarginLeft){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.size.width+tmpCST.referencingObject.frame.origin.x:tmpCST.referencingObject.frame.origin.x;
							rect.size.width=tmpCstBorder-tmpCST.value-cst.value;
						}else if(tmpCST.type==kSLRVConstraintMarginLeft&&cst.type==kSLRVConstraintMarginRight){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.x:tmpCST.referencingObject.frame.size.width+tmpCST.referencingObject.frame.origin.x;
							rect.size.width=cst.referencingObject.bounds.size.width-cst.value-tmpCstBorder-tmpCST.value;
						}
					}else if(tmpCST.isContained && !cst.isContained){
						if(tmpCST.type==kSLRVConstraintMarginRight && cst.type==kSLRVConstraintMarginLeft){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.x:cst.referencingObject.frame.size.width+cst.referencingObject.frame.origin.x;
							rect.size.width=tmpCST.referencingObject.bounds.size.width-tmpCST.value-cstBorder-cst.value;
						}else if(tmpCST.type==kSLRVConstraintMarginLeft && cst.type==kSLRVConstraintMarginRight){
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.size.width+cst.referencingObject.frame.origin.x:cst.referencingObject.frame.origin.x;
							rect.size.width=cstBorder-cst.value-tmpCST.value;
						}
					}else if(!tmpCST.isContained && !cst.isContained) {
						if(tmpCST.type==kSLRVConstraintMarginRight&&cst.type==kSLRVConstraintMarginLeft){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.size.width+tmpCST.referencingObject.frame.origin.x:tmpCST.referencingObject.frame.origin.x;
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.origin.x:cst.referencingObject.frame.size.width+cst.referencingObject.frame.origin.x;
							rect.size.width=tmpCstBorder-tmpCST.value-cstBorder-cst.value;
						}else if(tmpCST.type==kSLRVConstraintMarginLeft&&cst.type==kSLRVConstraintMarginRight){
							CGFloat tmpCstBorder=(tmpCST.referencingObject.hidden)?tmpCST.referencingObject.frame.origin.x:tmpCST.referencingObject.frame.size.width+tmpCST.referencingObject.frame.origin.x;
							CGFloat cstBorder=(cst.referencingObject.hidden)?cst.referencingObject.frame.size.width+cst.referencingObject.frame.origin.x:cst.referencingObject.frame.origin.x;
							rect.size.width=cstBorder-tmpCST.value-tmpCstBorder-cst.value;
						}
					}
					if(rect.size.width <0)rect.size.width = 0;
					cst.object.frame=rect;
					[processedConstraints addObject:tmpCST];
				}
			}
			if(processedConstraints.count>0){
				[tmpArray removeObjectsInArray:processedConstraints];
				[processedConstraints removeAllObjects];
			}
        }
        // Implement the constraints
        for(SLResponsiveViewConstraint *cst in tmpConstraints){
            [self applyConstraint:cst];
        }
    }
}
-(CGRect)applyConstraint:(SLResponsiveViewConstraint *)cst{
    if(cst.object==nil)return CGRectZero;
    CGFloat adjustY=([fullScreenSubviews containsObject:cst.object])?0:[self adjustY];
    CGRect originFrame=cst.object.frame;
    CGPoint originCenter=cst.object.center;
    CGRect referencingFrame=(cst.isContained)?cst.referencingObject.bounds:cst.referencingObject.frame;
	UIView *referencingObj=cst.referencingObject;
	BOOL isReferencingObjHidden=(referencingObj && !referencingObj.hidden)?NO:YES;
    if(cst.isContained && cst.keyboardDelegate){
        CGFloat tmpKeyboardHeight=[cst.keyboardDelegate keyboardHeight];
        referencingFrame.size.height-=tmpKeyboardHeight;
    }
    CGPoint referencingCenter=(cst.isContained)?CGPointMake(referencingFrame.size.width/2, referencingFrame.size.height/2):cst.referencingObject.center;
    CGRect targetFrame=originFrame;
    CGPoint targetCenter=originCenter;
    switch (cst.type) {
        case kSLRVConstraintCenterY:
            targetCenter.y=(cst.isContained)?referencingCenter.y+cst.value+adjustY/2:referencingCenter.y+cst.value;
            targetFrame.origin.y+=targetCenter.y-originCenter.y;
            break;
        case kSLRVConstraintCenterX:
            targetCenter.x=referencingCenter.x+cst.value;
            targetFrame.origin.x+=targetCenter.x-originCenter.x;
            break;
        case kSLRVConstraintHeight:
            targetFrame.size.height=cst.value;
            break;
        case kSLRVConstraintWidth:
            targetFrame.size.width=cst.value;
            break;
        case kSLRVConstraintMarginLeft:
            targetFrame.origin.x=(cst.isContained)?cst.value:(isReferencingObjHidden)?referencingFrame.origin.x+cst.value:referencingFrame.origin.x+referencingFrame.size.width+cst.value;
            break;
        case kSLRVConstraintMarginRight:
            targetFrame.origin.x=(cst.isContained)?referencingFrame.size.width:(isReferencingObjHidden)?referencingFrame.origin.x+referencingFrame.size.width:referencingFrame.origin.x;
            targetFrame.origin.x-=cst.value+targetFrame.size.width;
            break;
        case kSLRVConstraintMarginTop:
            targetFrame.origin.y=(cst.isContained)?cst.value+adjustY:(isReferencingObjHidden)?referencingFrame.origin.y+cst.value:referencingFrame.origin.y+referencingFrame.size.height+cst.value;
            break;
        case kSLRVConstraintMarginBottom:
            targetFrame.origin.y=(cst.isContained)?referencingFrame.size.height:(isReferencingObjHidden)?referencingFrame.origin.y+referencingFrame.size.height:referencingFrame.origin.y;
            targetFrame.origin.y-=cst.value+targetFrame.size.height;
            break;
        default:
            break;
    }
    cst.object.frame=targetFrame;
    return targetFrame;
}
#pragma mark - Keyboard Appear/Disappear
-(void)setKeyboardHeight:(CGFloat)h{
    keyboardHeight=h;
}
-(void)setKeyboardWidth:(CGFloat)w{
	keyboardWidth=w;
}
-(void)keyboardHeightChangedTo:(CGFloat)height widthChangedTo:(CGFloat)width{
	[self setKeyboardHeight:height];
	[self setKeyboardWidth:width];
    [self performSelectorOnMainThread:@selector(layoutSubviews) withObject:Nil waitUntilDone:NO];
}
-(void)keyboardWillShow:(NSNotification *)notification{
    NSDictionary *userInfo = [notification userInfo];
    //[self animationByKeyboard:userInfo forAction:YES];
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self convertRect:keyboardRect fromView:nil];
    keyboardHeight=keyboardRect.size.height;
	keyboardWidth=keyboardRect.size.width;
    // Get the duration of the animation.
    /*
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    */
    //[self applyConstraints];
    //[self performSelectorInBackground:@selector(layoutSubviews) withObject:nil];
    [self keyboardHeightChangedTo:keyboardHeight widthChangedTo:keyboardWidth];
	[self passThroughKeyboardHeight];
}
-(void)keyboardWillHide:(NSNotification *)notification{
    keyboardHeight=0;
    /*
    NSDictionary *userInfo = [notification userInfo];
    // Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    // Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self convertRect:keyboardRect fromView:nil];
    // Get the duration of the animation.
     */
    /*
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    */
    //[self applyConstraints];
    //[self performSelectorInBackground:@selector(layoutSubviews) withObject:nil];
	[self keyboardHeightChangedTo:keyboardHeight widthChangedTo:keyboardWidth];
    //[self passThroughKeyboardHeight];
}
#pragma mark - UIView interfaces
-(void)passThroughKeyboardHeight{
	for(id o in self.subviews){
        if([o isKindOfClass:[SLResponsiveView class]]){
            SLResponsiveView *v=o;
			CGFloat vHeight=keyboardHeight-(self.bounds.size.height-v.frame.origin.y-v.bounds.size.height);
			if(vHeight<0)vHeight=0;
            [v keyboardHeightChangedTo:vHeight widthChangedTo:keyboardWidth];
        }
    }
}
-(void)constraintsApplied{
	
}
-(void)arrangeContent{
	if(self.shouldAnimateConstraints){
		[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[self applyConstraints];
		} completion:^(BOOL finished) {
			
		}];
	}else [self applyConstraints];
    if(toolbar)[toolbar setFrame:self.bounds];
	[self constraintsApplied];
}
-(void)layoutSubviews{
    [super layoutSubviews];
	[self arrangeContent];
	[self passThroughKeyboardHeight];
}
#pragma mark - Blur like iOS7 effect
-(BOOL)canSetBlurTintColor{
	UIToolbar *tmpToolbar=toolbar;
    if(!toolbar){
        tmpToolbar=[[UIToolbar alloc]initWithFrame:self.bounds];
    }
    if(![tmpToolbar respondsToSelector:@selector(setBarTintColor:)]){
        return NO;
    }else {
		return YES;
	}
}
-(void)setBlurTintColor:(UIColor *)color{
    if( color && [self canSetBlurTintColor] ){
		if(!toolbar){
			toolbar=[[UIToolbar alloc]initWithFrame:self.bounds];
			[self.layer insertSublayer:toolbar.layer atIndex:0];
		}
		toolbar.barTintColor=color;
	}else if(color==nil && toolbar){
		[toolbar.layer removeFromSuperlayer];
		toolbar=nil;
	}
}
#pragma  mark - Global Instance
-(void)addGlobalInstance:(id)instance{
	if(instance){
		if(!arrayOfGlobalInstances){
			arrayOfGlobalInstances=[[NSMutableArray alloc]init];
		}
		if(![arrayOfGlobalInstances containsObject:instance]){
			[arrayOfGlobalInstances addObject:instance];
		}
		if([instance isKindOfClass:UIView.class] ){
			if(((UIView *)instance).superview != self){
				[((UIView *)instance)removeFromSuperview];
			}
			if( ![self.subviews containsObject:instance]){
				[self addSubview:instance];
			}
		}
	}
}
-(void)removeGlobalInstance:(id)instance{
	if(instance && arrayOfGlobalInstances && [arrayOfGlobalInstances containsObject:instance]){
		//[self removeObject:instance];
		if([instance respondsToSelector:@selector(setDelegate:)]){
			[instance setDelegate:nil];
		}
		if([instance isKindOfClass:UIView.class] && [self.subviews containsObject:instance]){
			[((UIView *)instance)removeFromSuperview];
		}
	}
}
-(NSArray *)globalInstances{
	return arrayOfGlobalInstances;
}
#pragma mark - Remove subview
-(void)removeObject:(id)obj{
	//	  NSMutableArray *arrayOfGlobalInstances;
	if(obj && arrayOfGlobalInstances && [arrayOfGlobalInstances containsObject:obj]){
		[arrayOfGlobalInstances removeObject:obj];
	}
	
	//    NSMutableArray *arrayOfUnRotatableSubviewsDontAlignToTop;
	if(obj && arrayOfUnRotatableSubviewsDontAlignToTop && [arrayOfUnRotatableSubviewsDontAlignToTop containsObject:obj]){
		[arrayOfUnRotatableSubviewsDontAlignToTop removeObject:obj];
	}
	
	//    NSMutableArray *arrayOfUnRotatableSubviewsAlignToTop;
	if(obj && arrayOfUnRotatableSubviewsAlignToTop && [arrayOfUnRotatableSubviewsAlignToTop containsObject:obj]){
		[arrayOfUnRotatableSubviewsAlignToTop removeObject:obj];
	}
	
	//    NSMutableArray *arrayOfStaticContentSubviews;
	if(obj && arrayOfStaticContentSubviews && [arrayOfStaticContentSubviews containsObject:obj]){
		[arrayOfStaticContentSubviews removeObject: obj];
	}
	
	//	  NSMutableArray *arrayOfOverrideStatusBarSubviews;
	if(obj && arrayOfOverrideStatusBarSubviews && [arrayOfOverrideStatusBarSubviews containsObject:obj]){
		[arrayOfOverrideStatusBarSubviews removeObject:obj];
	}
	
	//    NSMutableDictionary *dict_Subviews_OriginalFrame;
	[self removeOriginalFrameOfSubview:obj];
	
	//    NSMutableDictionary *constraintsOfSubviews;
	//    NSMutableDictionary *constraintsOfReferencedSubviews;
	//    NSMutableArray *subviewsWithConstraints;
	//    NSMutableArray *subviewsReferencedByConstraints;
	//    NSMutableDictionary *dict_SubviewsReferencing;
	//    NSMutableDictionary *dict_SubviewsReferencedBy;
	//    NSMutableArray *fullScreenSubviews;
	[self removeSLConstraintForObject:obj];
	
	if([obj respondsToSelector:@selector(setDelegate:)]){
		[obj setDelegate:nil];
	}
	
	if([obj isKindOfClass:UIView.class] && [self.subviews containsObject:obj]){
		[((UIView *)obj)removeFromSuperview];
	}
}
-(void)removeSubview:(UIView *)subview{
	if(subview && [self.subviews containsObject:subview]){
		[self removeObject:subview];
	}
}
#pragma mark - Add subview
-(void)addSubview:(UIView *)view{
	[super addSubview:view];
	// 2014-9-15 为了解决初始orientation的bug而采取的临时办法
	//if([view isKindOfClass:[SLResponsiveView class]]){
	//	[((SLResponsiveView *)view)viewWillAppear];
	//}
}
@end
