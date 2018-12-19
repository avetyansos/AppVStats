//
//  UIViewController+Events.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "UIViewController+Events.h"
#import <objc/runtime.h>
#import "Videolytics.h"
#import "VLSession.h"

static BOOL installed;

void EventsInstall() {
    
    if (!installed) {
        
        installed = YES;
        
        Class _class = [UIViewController class];
        
        Method orig = class_getInstanceMethod(_class, sel_registerName("viewWillAppear:"));
        Method my = class_getInstanceMethod(_class, sel_registerName("v_viewWillAppear:"));
        method_exchangeImplementations(orig, my);
    }
}

void EventsUninstall() {
    
    if (installed) {
        
        installed = NO;
        
        Class _class = [UIViewController class];
        
        Method orig = class_getInstanceMethod(_class, sel_registerName("viewWillAppear:"));
        Method my = class_getInstanceMethod(_class, sel_registerName("v_viewWillAppear:"));
        method_exchangeImplementations(orig, my);
    }
}

@interface UIViewController (Events)

@end

@implementation UIViewController (Events)

- (void)v_viewWillAppear:(BOOL)animated {
    
    Videolytics *videlytics = [Videolytics sharedInstance];
    VLSession *session = videlytics.session;
    NSMutableArray *events = [NSMutableArray arrayWithArray:session.events];
    
    NSString *viewControllerName = NSStringFromClass([self class]);
    NSTimeInterval current = [[NSDate new] timeIntervalSince1970];
    NSUInteger timestamp = [[NSDate dateWithTimeIntervalSince1970:current] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:session.sessionCreateTimestamp]]*1000;
    NSDictionary *event = @{@"name": viewControllerName, @"timestamp": @(timestamp), @"type": @"view"};
    [events addObject:event];

    session.events = events;
    
    [self v_viewWillAppear:animated];
}

@end
