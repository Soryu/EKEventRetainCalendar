//
//  ViewController.m
//  EKEventRetainCalendar
//
//  Created by Stanley Rost on 05.08.15.
//  Copyright (c) 2015 soryu2. All rights reserved.
//

#import "MainViewController.h"

@import EventKit;

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UISwitch *mySwitch;
@property (weak, nonatomic) IBOutlet UITextView *resultTextView;

// if we were to hold on to the store object it would also work
// @property (nonatomic) EKEventStore *eventStore;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.resultTextView.contentInset = UIEdgeInsetsZero;
    self.resultTextView.textContainerInset = UIEdgeInsetsZero;
    self.resultTextView.attributedText = [[NSAttributedString alloc] initWithString:@"🚀 Press Go!"
                                                                         attributes:@{ NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                                                                       NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]}];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.goButton.enabled = NO;
    
    switch ([EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent]) {
        case EKAuthorizationStatusNotDetermined:
            [self askForAccess];
            break;

        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
            [self showAccessDenied];
            break;
            
        case EKAuthorizationStatusAuthorized:
            self.goButton.enabled = YES;
            break;
    }
}

#pragma mark Segues

- (void)askForAccess
{
    [self performSegueWithIdentifier:@"askForCalendarAccess" sender:self];
}

- (void)showAccessDenied
{
    [self performSegueWithIdentifier:@"showAccessDenied" sender:self];
}

#pragma mark Actions

- (IBAction)goButtonPressed:(id)sender
{
    BOOL shouldAccessCalendarProperty = self.mySwitch.on;
    
    EKEvent *event = [self readAnyEventAndAccessCalendarProperty:shouldAccessCalendarProperty];
    
    if (event) {
        // Wait a bit... otherwise this bug does not show
        // in my real app I pass the calendar event to another view controller and use it later
        // this simulates that
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self printEvent:event];
        });
        
    } else {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"No calendar events found."
                                                         message:@"Please create at least one calendar event between the year 2000 and now."
                                                        delegate:nil
                                               cancelButtonTitle:@"Dismiss"
                                               otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark Calendar

- (EKEvent *)readAnyEventAndAccessCalendarProperty:(BOOL)shouldAccessCalendarProperty
{
    EKEventStore *store = [EKEventStore new];
    
    // predicate does not like [NSDate distantPast] and [NSDate distantFuture] as parameters!
    NSPredicate *predicate = [store predicateForEventsWithStartDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0]
                                                            endDate:[NSDate dateWithTimeIntervalSinceNow:0]
                                                          calendars:nil];
    NSArray *allEvents = [store eventsMatchingPredicate:predicate];
    EKEvent *anyEvent = allEvents.firstObject;
    NSLog(@"Our random event is called: %@", anyEvent.title);
    
    if (shouldAccessCalendarProperty) {
        NSLog(@"Accessing calendar property! Hold your horses!");
        
        [anyEvent calendar];
        
        // Calling debugDescription (e.g. by printing the event in the debugger will also result in the calendar being accessed.
        // Side effects when calling debugDescription!
        // This means it is literraly a Heisenbug, changing its behaviour when observed!
    }
    
    // self.eventStore = store;
    
    return anyEvent;
}

- (void)printEvent:(EKEvent *)event
{
    if (!event.calendar) {
        NSLog(@"Unexpected error: event has no associated calendar!");
    }
    
    NSMutableAttributedString *attributedText = [NSMutableAttributedString new];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"Event “"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:event.title]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"”\n\n"]];
    
    UIColor *color = [UIColor blackColor];
    
    if (event.calendar) {
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"😎 YAY! This event came from the calendar: “"]];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:event.calendar.title]];
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"”"]];
        color = [UIColor greenColor];
    } else {
        [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"😨 OH NOES! This event says it’s calendar is <nil>."]];
        color = [UIColor redColor];
    }
    
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: color,
                                  NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody]};
    [attributedText addAttributes:attributes range:NSMakeRange(0, attributedText.length)];

    self.resultTextView.attributedText = attributedText;
}

@end
