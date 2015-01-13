ResponsiveView
==============

ResponsiveView is responsive UI framework on iOS, providing relative component positioning, 
responsible to events such as rotating, keyboard calling and dismissing etc. 

The framework including view, view controller and navigation controller, 
view hierarchy and component lifecycle are managed automatically. 

Support from iOS4 to iOS7

***

`Website`   http://mrsunlin.github.io/ResponsiveView 

`wiki`      https://github.com/mrsunlin/ResponsiveView/wiki

`author`    https://www.facebook.com/mrsunlin

# How to use

## Step 1: Define classes and initialize root viewController

### Define View & ViewController classes
Create `YourCustomViewController` & `YourCustomView` classes in project. The `YourCustomViewController` inherit from SLResponsiveViewController, `YourCustomView` inherit from SLResponsiveView

In `YourCustomViewController` implementation code (usually `.m` file), override the method `-(void)loadView` to assemble the view & viewController:

    -(void)loadView{
        self.view = [[YourCustomView alloc]initWithFrame:self.frame];
    }

### Customize initialization code
The customized initialization code of view & viewController should be in method `-(id)initWithFrame:`, don't forget the line at the beginning of the method `self = [super initWithFrame:frame];`:

    - (id)initWithFrame:(CGRect)frame{
        self = [super initWithFrame:frame];
        if (self) {
            // Initialization code
        }
        return self;
    }

### Create Instances
All instances, including views & viewControllers, must be initialized by method `-(id)initWithFrame:`. For root instances, the frame parameter must be a known value; for other instances, the frame could be zero (CGRectZero) when they have responsive constraints.

For root view, it is instanced by the viewController

    YourCustomViewController *vc = [[YourCustomViewController alloc] initWithFrame: frame];

For custom view component, it can be instanced directly

    YourCustomView *view = [[YourCustomView alloc] initWithFrame: frame];

### Instance the root viewController
In `YourAppDelegate.m` file, override the method `-(BOOL)application:didFinishLaunchingWithOptions:`

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
        // create window object to contain viewController
        if([SLResponsiveView OSMainVersionNumber]>=7){
            self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        }else{
            CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
            self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, appFrame.size.width, appFrame.size.height)];
        }
        [self.window makeKeyAndVisible];
        // create the root viewController
        YourCustomViewController *vc = [[YourCustomViewController alloc] initWithFrame: 
                                        [SLResponsiveView applicationFrameWithStatusBarShowing:YES]];
        // If need navigation support, create a SLResponsiveNavigationController object 
        SLResponsiveNavigationController *nc = [[SLResponsiveNavigationController alloc] initWithRootViewController: vc];
        self.window.rootViewController = nc;
        // If do not need navigation support, use the viewController object directly and comment above two lines
        // self.window.rootViewController = vc; 
    }

***

## Step 2: Define responsive constraints for components
Taking the process of creating a bottom stick components in `YourCustomView` as example, follow the 3 basic steps:

### Create the component object: 

    YourComponentView *yourCompView = [[YourComponentView alloc] initWithFrame: CGRectZero];

### Add to the view hierarchy

    [self addSubView: yourCompView];

### Set the responsive constraints 
Set the responsive constraints using method `-(SLResponsiveViewConstraint *) addSLConstraint:andValue: ...`. You can define all kinds of constraints as many as you want.

    [self addSLConstraint:kSLRVConstraintMarginBottom // set the constraint type, 
                                                      //   comparing corresponding value between yourCompView with the referencing object
                                                      //     kSLRVConstraintMarginLeft,  
                                                      //     kSLRVConstraintMarginTop,
                                                      //     kSLRVConstraintMarginRight,
                                                      //     kSLRVConstraintMarginBottom,
                                                      //     kSLRVConstraintCenterY,
                                                      //     kSLRVConstraintCenterX,
                                                      //     kSLRVConstraintWidth,
                                                      //     kSLRVConstraintHeight
                 andValue: 0.0f                       // set the constraint value
                forObject: yourCompView               // set yourCompView object created above
              isContained: NO                         // set the relationship between yourCompView with 
                                                      //     the referencing object.
                                                      //     if is referencing the container view (self)
                                                      //     the value should be "YES"
      byReferencingObject: anOtherComponent           // set the object to be referenced when positioning
                                                      //     if is referencing the container view (self)
                                                      //     the value should be "self"
           forOrientation: kSLRVOrientationAll        // set enabled according to the device orientation with values kSLRVOrientationAll, 
                                                      //     kSLRVOrientationPortraitUp, 
                                                      //     kSLRVOrientationPortraitDown, 
                                                      //     kSLRVOrientationLandscapeLeft, 
                                                      //     kSLRVOrientationLandscapeRight, 
                                                      //     kSLRVOrientationPortrait, 
                                                      //     kSLRVOrientationLandscape, 
                                                      //     kSLRVOrientationUnknown. 
        forKeyboardStatus:kSLRVKeyboardStatusUnused   // set enabled according to the keyboard status with values kSLRVKeyboardShowing, 
                                                      //     kSLRVKeyboardHidden, 
                                                      //     kSLRVKeyboardStatusAll, 
                                                      //     kSLRVKeyboardStatusUnused. the 
                                                      //     'Unused' set the constraint ignoring keyboard status
            forDeviceType:kSLRVDeviceTypeiPad         // set enabled on iPad or iPhone/iPod according to the value
                                                      //     kSLRVDeviceTypeiPad (iPad) or kSLRVDeviceTypeiPhone (iPhone/iPod)
    ];

***

# Improve
## Global instance
In some case you may need global instances to improve overall performance, for example, the Ad banner should only be instanced once and used globally across entire view hierarchy. There are many methods to create global instances, for example, setting as the appDelegate's member. But the global instance is hard to manage in the view hierarchy lifecycle. 

With the help of SLResponsiveView framework, it becomes very easy. 

In `YourCustomView`'s initializing code, after getting the global instance `yourGlobalComp`, use `[self addGlobalInstance: yourGlobalComp];` to inform the framework to handle it's lifecycle in the view hierarchy. And it's safe to define constraints for the global instance whenever using it. Here is a sample code for this:

    adBanner=[SLAdvertiseBanner getInstance];
    adBanner.frame=CGRectMake(0, self.frame.size.height-adBannerHeight, self.frame.size.width, adBannerHeight);
    [self addGlobalInstance:adBanner];
    // it's safe to define constraints for the adBanner instance whenever using it
    
## Un-rotatable subview
If you want some components (`yourComp`) to be fixed in the screen, such as fixing near the home button or the handset no matter what the orientation is, use the method `-(void)addUnRotatableSubview:alignTop:staticContent:overrideStatusBar:`

    yourComp.frame = aCustomRect;      // set the object frame in portrait state.
    [self addUnRotatableSubview: yourComp
                       alignTop: YES   // whether stick with the status bar
                  staticContent: NO    // whether rotate its content when device orientation changed
              overrideStatusBar: NO    // whether override the status bar if they overlap
    ];

## Conditional constraint
In some case the constraints need to be more programmed, you can use the `SLResponsiveViewConstraintConditionDelegate` with two steps:

### Define the constraint's name & delegate
When defining the constraint, set a name for it and set it's delegate:

    SLResponsiveViewConstraint * cst =[self addConstraint: ...... ].name = "yourConditionConstraint";
    cst.delegate = self;

### Implement the delegate
Implement the delegate `-(BOOL)shouldApplyConditionalConstraint:`

    -(BOOL)shouldApplyConditionalConstraint:(id)constraint{
        if(constraint.name == @"yourConditionConstraint"){
            if( satisfy some condition ){
                return YES;
            }
        }
        return NO;
    }

***

# Interfaces
## View hierarchy & lifecycle control 
### `SLResponsiveViewController`

    -(UIViewController *)rootViewController;   // return the root view controller object
    -(UIViewController *)popToRootViewControllerAnimated:(BOOL)animated;
    -(void)dismissOthersAndPresentNewController:(UIViewController *)vc animated:(BOOL)animated;
    -(void)dismissOthersAndPushNewController:(UIViewController *)vc animated:(BOOL)animated;
    -(void)destroyPresentingViewControllersUntil:(UIViewController *) aViewController;
    -(void)destroyPresentedViewControllers;
    -(void)popToPreviousViewControllerAnimated:(BOOL)animated;

## Overridable events
### `SLResponsiveViewController`

    -(void)viewControllerWillBeDestroied;

### `SLResponsiveView`

    -(void)viewWillBeDestroyed;
    -(void)keyboardHeightChangedTo:(CGFloat)height widthChangedTo:(CGFloat)width;
    -(void)deviceShaked;
    -(void)deviceRotated:(double)angle;
    -(void)deviceRotatedToPortrait;
    -(void)deviceRotatedToLandscapeLeft;
    -(void)deviceRotatedToLandscapeRight;
    -(void)deviceRotatedToPortraitUpsideDown;
    -(void)deviceRotatedToFaceUp;
    -(void)deviceRotatedToFaceDown;

