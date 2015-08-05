//
//  AccessViewController.m
//  EKEventRetainCalendar
//
//  Created by Stanley Rost on 05.08.15.
//  Copyright (c) 2015 soryu2. All rights reserved.
//

#import "AccessViewController.h"

@import EventKit;

@interface AccessViewController ()

@end

@implementation AccessViewController

- (IBAction)grantAccessButtonPressed:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
    EKEventStore *store = [EKEventStore new];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            [self performSegueWithIdentifier:@"showAccessDenied" sender:self];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
