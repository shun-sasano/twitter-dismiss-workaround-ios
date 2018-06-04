//
//  WorkaroundViewController.m
//  twitter-dismiss-fix
//
//  Created by Sander van den Brink on 04/06/2018.
//  Copyright © 2018 Sander van den Brink. All rights reserved.
//

#import <SafariServices/SafariServices.h>
#import <TwitterKit/TwitterKit.h>

#import "WorkaroundViewController.h"

@interface WorkaroundViewController () <SFSafariViewControllerDelegate>

@property (nonatomic, weak) id <SFSafariViewControllerDelegate> originalTwitterSafariDelegate;
@property (nonatomic, getter=isSafariDoneButtonPressed) BOOL    safariDoneButtonPressed;

@end

@implementation WorkaroundViewController

/**
 WORKAROUND
 */
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    
    // Do not dismiss view controller when user pressed the done button in the Safari Controller. This is to prevent a double dismiss caused by the Twitter SDK (see https://github.com/twitter/twitter-kit-ios/issues/16)
    if ([self isSafariViewControllerPresented:self.presentedViewController] && self.isSafariDoneButtonPressed) {
        NSLog(@"Twitter Safari controller dismissed with done button.");
        self.safariDoneButtonPressed = NO;
        return;
    }
    
    [super dismissViewControllerAnimated:flag completion:completion];
}

/**
 WORKAROUND
 */
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    
    // Use delay because have to wait for viewDidLoad to be done on TWTRWebAuthenticationViewController so Safari controller is set as child.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SFSafariViewController *safariController = [self safariControllerFromViewController:viewControllerToPresent];
        
        if (safariController) {
            NSLog(@"Override Twitter Safari controller delegate");
            self.originalTwitterSafariDelegate = safariController.delegate;
            safariController.delegate = self; // Override delegate to intercept Done button press.
        }
    });
    
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
}

- (IBAction)onTweet {
    
    TWTRComposer *composer = [[TWTRComposer alloc] init];
    [composer setURL:[NSURL URLWithString:@"https://twitter.com/"]];
    [composer setText:@"Check this out!"];
    [composer showFromViewController:self completion:^(TWTRComposerResult result) {
        NSString *message = @"done";
        
        if (result == TWTRComposerResultCancelled)
            message = @"cancelled";
        
        NSLog(@"%@", [NSString stringWithFormat:@"Tweet was %@!", message]);
    }];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Convenience methods

- (BOOL)isSafariViewControllerPresented:(UIViewController*)viewController {
    
    return [self safariControllerFromViewController:viewController] != nil;
}

- (SFSafariViewController*)safariControllerFromViewController:(UIViewController*)viewController {
    
    for (UIViewController *child in viewController.childViewControllers) {
        if (![child isKindOfClass:NSClassFromString(@"TWTRWebAuthenticationViewController")])
            continue;
        
        // TODO: Determine whether the done button of the SFSafariViewController was pressed.
        for (UIViewController *childOfChild in child.childViewControllers) {
            if ([childOfChild isKindOfClass:NSClassFromString(@"SFSafariViewController")])
                return (SFSafariViewController*)childOfChild;
        }
    }
    
    return nil;
}

@end