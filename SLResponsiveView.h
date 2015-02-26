//
//  SLResponsiveView.h
//  Introspection
//
//  Created by 孙 麟 on 13-6-26.
//  Copyright (c) 2013年 Lin Sun. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum SLResponsiveViewOrientation{
    kSLRVOrientationAll,
    kSLRVOrientationPortraitUp,
    kSLRVOrientationPortraitDown,
    kSLRVOrientationLandscapeLeft,
    kSLRVOrientationLandscapeRight,
    kSLRVOrientationPortrait,
    kSLRVOrientationLandscape,
    kSLRVOrientationUnknown
}SLResponsiveViewOrientation;

typedef enum SLResponsiveViewKeyboardStatus{
    kSLRVKeyboardShowing,
    kSLRVKeyboardHidden,
    kSLRVKeyboardStatusAll,
    kSLRVKeyboardStatusUnused
}SLResponsiveViewKeyboardStatus;

typedef enum SLResponsiveViewDeviceType{
    kSLRVDeviceTypeiPad,
    kSLRVDeviceTypeiPhone,
    kSLRVDeviceTypeAll
}SLResponsiveViewDeviceType;

typedef enum  SLResponsiveViewConstraintType {
    kSLRVConstraintMarginLeft,
    kSLRVConstraintMarginTop,
    kSLRVConstraintMarginRight,
    kSLRVConstraintMarginBottom,
    kSLRVConstraintCenterY,
    kSLRVConstraintCenterX,
    kSLRVConstraintWidth,
    kSLRVConstraintHeight
}SLResponsiveViewConstraintType;

@protocol SLResponsiveViewConstraintConditionDelegate <NSObject>
-(BOOL)shouldApplyConditionalConstraint:(id)constraint;
@end

@protocol SLResponsiveViewConstraintKeyboardDelegate <NSObject>
-(CGFloat)keyboardHeight;
@end


@interface SLResponsiveViewConstraint : NSObject
@property SLResponsiveViewConstraintType type;
@property (unsafe_unretained,nonatomic) UIView *object;
@property (unsafe_unretained,nonatomic) UIView *referencingObject;
@property (nonatomic) NSInteger value;
@property (nonatomic) BOOL isContained;
@property (unsafe_unretained,nonatomic) id<SLResponsiveViewConstraintConditionDelegate> conditionDelegate;
@property (unsafe_unretained,nonatomic) id<SLResponsiveViewConstraintKeyboardDelegate> keyboardDelegate;
@property (nonatomic) SLResponsiveViewOrientation orientation;
@property (nonatomic) SLResponsiveViewKeyboardStatus keyboardStatus;
@property (nonatomic) SLResponsiveViewDeviceType deviceType;
@property (retain, nonatomic) NSString *name;
@property (retain, nonatomic) NSString *category;
@property (nonatomic) NSInteger tag;
+(id)constraintWithType:(SLResponsiveViewConstraintType)aType andValue:(CGFloat)aValue forObject:(UIView *)obj isContained:(BOOL)isContained byReferencingObject:(UIView *)refObj forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt;
//-(CGRect)applyConstraintInParentView:(UIView *)parentView;
+(NSString *)namfOfConstraintType:(SLResponsiveViewConstraintType)type;
-(BOOL)compatibleWithOrientation:(SLResponsiveViewOrientation)orien;
@end

#pragma mark - Class SLResponsiveView
@interface SLResponsiveView : UIView <SLResponsiveViewConstraintKeyboardDelegate>
@property (readonly,nonatomic) CGFloat adjustY;
@property (readonly,nonatomic) SLResponsiveViewOrientation orientation;
@property (readonly,nonatomic) CGFloat keyboardHeight;
@property (readonly,nonatomic) CGFloat keyboardWidth;
@property (nonatomic,unsafe_unretained) UIViewController *viewController;
@property (nonatomic) CGRect originalViewFrame;
-(CGFloat)rotatedAngle;
-(void)setSupportPortraitUpsideDown:(BOOL)support;
-(void)viewWillAppear;
-(void)viewDidAppear;
-(void)viewWillDisappear;
-(void)viewDidDisappear;
-(void)viewWillBeDestroyed;
-(BOOL)isViewAppearing;
-(void)keyboardHeightChangedTo:(CGFloat)height widthChangedTo:(CGFloat)width;
-(void)deviceShaked;
-(void)deviceIsRotating:(double)angle;
-(void)deviceRotated:(double)angle;
-(void)deviceRotatedToPortrait;
-(void)deviceRotatedToLandscapeLeft;
-(void)deviceRotatedToLandscapeRight;
-(void)deviceRotatedToPortraitUpsideDown;
-(void)deviceRotatedToFaceUp;
-(void)deviceRotatedToFaceDown;
-(void)addUnRotatableSubview:(id)unRotatableView alignTop:(BOOL)alignTop staticContent:(BOOL)staticContent overrideStatusBar:(BOOL)overrideStatusBar;
-(void)removeUnRotatableSubview:(id)unRotatableView;
-(void)addStaticContentSubview:(UIView *)subview;
-(void)removeStaticContentSubview:(UIView *)subview;
-(CGRect)convertDesignedFrame:(CGRect)frame;
-(CGRect)makeCGRectByX:(CGFloat) x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height;
-(void)superViewRotatedToAngle:(double)angle;
-(void)viewControllerWillRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration;
-(void)viewControllerDidRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
-(void)viewControllerDidLayoutSubviews;

#pragma mark - Blur
-(BOOL)canSetBlurTintColor;
-(void)setBlurTintColor:(UIColor *)color;
#pragma mark - GlobalInstance;
-(void)addGlobalInstance:(id)instance;
-(void)removeGlobalInstance:(id)instance;
-(NSArray *)globalInstances;
-(id)superViewController;
#pragma mark - Class Methods
+(id)rotateShapeBack:(id)obj originalFrame:(CGRect)originRect includingUpsideDown:(BOOL)includingUpsideDown includingContent:(BOOL)includingContent  showingStatusBar:(BOOL)showingStatusBar isAlignedTop:(BOOL)isAlignedTop verticalReverse:(BOOL)verticalReverse currentDeviceOrientation:(UIDeviceOrientation)currentOrientation;
+(CGFloat)adjustY;
+(void)storeScreenBounds;
+(CGFloat)statusBarHeight;
+(NSInteger)OSMainVersionNumber;
+(UIDeviceOrientation)deviceOrientationForSLResponsiveViewOrientation:(SLResponsiveViewOrientation)orientation;
+(CGRect)currentApplicationBoundsWithStatusBarShowing:(BOOL)showingStatusBar currentDeviceOrientation:(UIDeviceOrientation)currentOrientation;
+(CGRect)applicationFrameWithStatusBarShowing:(BOOL)showingStatusBar;
+(NSString *)nameOfOrientation:(SLResponsiveViewOrientation)orientation;
+(CGFloat)fontSizeForWidth:(CGFloat)width;
+(BOOL)rect:(CGRect)rect1 isEqualWithRect:(CGRect)rect2;
+(BOOL)isRunningOniPad;
+(BOOL)isRunningOnIPhone;
+(BOOL)isRunningOnIPhone4SOrEarlier;
+(UIImage *) convertToGreyscale:(UIImage *)i ;
+(UIImage *) imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+(UIImage *) imageWithImage:(UIImage *)image resizeCanvusWithFactor:(float)factor;
+(UIImage *)imageByCombiningImage:(UIImage*)aFirstImage withImage:(UIImage*)aSecondImage horizontally:(BOOL)horizontally margin:(CGFloat)margin resizeToSmallerSize:(BOOL) resizeToSmallerSize;
+(void)shakeObject:(id)obj withSwing:(CGFloat)swing inHorizontalDirection:(BOOL)hori;
+(UIImage *)iconAtLine:(NSInteger)line column:(NSInteger)column;
+(UIImage *)image:(UIImage *)img withColor:(UIColor *)color;
+(UIImage *)image:(UIImage *)image withMarkImage:(UIImage *)markImage atCornerUp:(BOOL)up left:(BOOL)left markScale:(CGFloat)scale;
+(UIImage *)image:(UIImage *)image withRoundBorderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor fillColor:(UIColor *)fillColor;
+(UIImage *)image:(UIImage *)image rotatedAngle:(CGFloat)angle;
+(NSAttributedString *)setUnderlineStyleForString:(NSString *)text color:(UIColor *)color;
+(UIButton *)setUnderlineStyleForButton:(UIButton *)button withTitleText:(NSString *)text;
+(UIButton *)setUnderlineStyleForButton:(UIButton *)button withTitleText:(NSString *)text color:(UIColor *)color forState:(UIControlState)state;
+(CGSize)sizeOfText:(NSString *)text font:(UIFont *)font constrainedToSize:(CGSize)size;
+(CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font;
+(UIViewAnimationOptions)randomTransitionOption;
+(CGRect) imagePositionInImageView:(UIImageView*)anImageView;
+(UIImage*)captureView:(UIView *)view rectOnScreen:(CGRect)rect;
+(UIImage *)image:(UIImage *)image subRegion:(CGRect)rect;
+(UIImage *)image:(UIImage *)image rotateAngle:(CGFloat)angle;
#pragma mark - Constraint
-(SLResponsiveViewConstraint *)addSLConstraint:(SLResponsiveViewConstraintType)type andValue:(CGFloat)value forObject:(UIView *)Subview isContained:(BOOL)isContained byReferencingObject:(UIView *)refView forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt;
-(NSArray *)addInnerMarginSLConstraintForSubview:(UIView *)subview margin:(UIEdgeInsets)margin inFullScreenMode:(BOOL)fullScreenMode forOrientation:(SLResponsiveViewOrientation)orien forKeyboardStatus:(SLResponsiveViewKeyboardStatus)ks forDeviceType:(SLResponsiveViewDeviceType)dt;
-(void)addSLConstraint:(SLResponsiveViewConstraint *)constraint;
-(void)removeSLConstraintForObject:(UIView *)Subview;
-(void)removeSLConstraint:(SLResponsiveViewConstraint *)constraint;
-(void)removeSubview:(UIView *)subview;
-(void)constraintsApplied;
-(BOOL)shouldAnimateConstraints;
@end
