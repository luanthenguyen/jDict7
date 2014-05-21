//
//  Google_TranslateViewController.m
//  Google Translate
//
//  Created by Shao Ping Lee on 10/13/11.
//  Copyright 2011 University of Illinois at Urbana-Champaign. All rights reserved.
//

#import "Google_TranslateViewController.h"
#import "SBJson.h"

@implementation Google_TranslateViewController
@synthesize lastText = _lastText;

- (IBAction)doTranslation {
    [translations removeAllObjects];
    [textField resignFirstResponder];
    
    button.enabled = NO;
    self.lastText = textField.text;
    [translations addObject:_lastText];
    textView.text = _lastText;
    
    [self performTranslation];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [responseData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [responseData appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    textView.text = [[NSString alloc] initWithFormat:@"Connection failed: %@", [error description]];
    button.enabled = YES;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection release];
    
    NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    [responseData release];
    
    NSMutableDictionary *JSONval = [responseString JSONValue];
    [responseString release];
    
    if (JSONval != nil) {
        NSDecimalNumber *responseStatus = [JSONval objectForKey:@"responseStatus"];
        if (responseStatus.intValue != 200) {
            button.enabled = YES;
            return;
        }
        
        NSMutableDictionary *responseDataDict = [JSONval objectForKey:@"responseData"];
        if (responseDataDict!= nil) {
            NSString *translatedText = [responseDataDict objectForKey:@"translatedText"];
            [translations addObject:translatedText];
            self.lastText = translatedText;
            textView.text = [textView.text stringByAppendingFormat:@"\n%@", translatedText];
            button.enabled = YES;
        }
            
    }
}

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    translations = [[NSMutableArray alloc] init];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void) dealloc {
    [_lastText release];
    [translations release];
    [super dealloc];
}

- (void) performTranslation {
    responseData = [[NSMutableData data] retain];
    
    NSString *langString = @"en|ja";
    NSString *textEscaped = [_lastText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *langStringEscaped = [langString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *url = [NSString stringWithFormat:@"http://ajax.googleapis.com/ajax/services/language/translate?q=%@&v=1.0&langpair=%@",textEscaped, langStringEscaped];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [[NSURLConnection alloc] initWithRequest: request delegate: self];
}

@end
