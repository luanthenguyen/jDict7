//
//  Google_TranslateViewController.h
//  Google Translate
//
//  Created by Shao Ping Lee on 10/13/11.
//  Copyright 2011 University of Illinois at Urbana-Champaign. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Google_TranslateViewController : UIViewController {
    IBOutlet UITextView *textView;
    IBOutlet UITextField *textField;
    IBOutlet UIButton *button;
    NSMutableData *responseData;
    NSMutableArray *translations;
//    NSString *_lastText;
}
@property (nonatomic, copy) NSString *lastText;

-(IBAction)doTranslation;
-(void)performTranslation;
//test test test

@end
