//

#import "TouchPointerWindow.h"
#import <objc/runtime.h>
#import "Videolytics.h"
#import "VLSession.h"

static BOOL installed;

void TouchPointerWindowInstall() {
    
	if (!installed) {
        
		installed = YES;
		
		Class _class = [UIWindow class];
		
		Method orig = class_getInstanceMethod(_class, sel_registerName("sendEvent:"));
		Method my = class_getInstanceMethod(_class, sel_registerName("v_sendEvent:"));
		method_exchangeImplementations(orig, my);
	}
}

void TouchPointerWindowUninstall() {
    
	if (installed) {
        
		installed = NO;
		
		Class _class = [UIWindow class];
		
		Method orig = class_getInstanceMethod(_class, sel_registerName("sendEvent:"));
		Method my = class_getInstanceMethod(_class, sel_registerName("v_sendEvent:"));
		method_exchangeImplementations(orig, my);
	}
}

@interface UIWindow (TouchPointerWindow)

@end

@implementation UIWindow (TouchPointerWindow)

- (void)v_sendEvent:(UIEvent *)event {
    
    Videolytics *videolytics = [Videolytics sharedInstance];
    VLSession *session = videolytics.session;
    
    NSMutableSet *touches = [NSMutableSet setWithSet:session.currentTouches];
    
    for (UITouch *touch in [event allTouches]) {
        
        switch ([touch phase]) {
                case UITouchPhaseBegan:
            {
                [touches addObject:touch];
                NSLog(@"Touch Began");
            }
                break;
                case UITouchPhaseMoved:
            {
                [touches addObject:touch];
                NSLog(@"Touch Move");
            }
                break;
                case UITouchPhaseEnded:
            {
                [touches removeObject:touch];
                NSLog(@"Touch End");
            }
                break;
                case UITouchPhaseCancelled:
            {
                [touches removeObject:touch];
                NSLog(@"Touch Cancelled");
            }
                break;
            default:
                break;
        }
    }
    
    session.currentTouches = touches;
    
	[self v_sendEvent:event];
}

@end
