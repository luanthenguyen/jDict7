//
//  centerViewController.m
//  DictWithBar
//
//  Created by luan nguyen the on 10/25/13.
//  Copyright (c) 2013 uit. All rights reserved.
//

#import "centerViewController.h"
#import "MySidePanelController.h"
#import "UIViewController+JASidePanel.h"
#import <sqlite3.h>
#import "detailViewController.h"
#import "DictWithBarAppDelegate.h"
int inHistory = 0;
NSUInteger count = 0;
NSMutableArray *historyArray;
NSMutableArray *favoriteArray;

NSArray* kanjiSorted;
@interface centerViewController ()

@end

@implementation centerViewController
@synthesize tableData,wordArray,selectedWord,settingArray,sections,btnHistory,btnSetting;
@synthesize searchBar,dictSQL,dictString,dictFileType,dictType,dictLang;
@synthesize db=_db,lastWord;



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
UIGestureRecognizer *tapper;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [bannerView_ setDelegate:self];
    //admob
    bannerView_ = [[GADBannerView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height-GAD_SIZE_320x50.height, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height)];
    bannerView_.adUnitID = @"a1528c9684bacf6";
    bannerView_.rootViewController = self;
    [self.view addSubview:bannerView_];
    [bannerView_ loadRequest:[GADRequest request]];
    //admob define end
    sections = [[NSMutableDictionary alloc] init];
    [searchBar setDelegate: self];//delegate
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ChangeDictNot:) name:@"ChangeDictionaryType" object:nil];
    UIApplication *myApp = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ChangeDictLang:) name:@"ChangeDictionaryLang" object:nil];
//end notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:myApp];
    //touch dismiss keyboard
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = FALSE;
    [self.view addGestureRecognizer:tapper];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedLeftDidShowNotification:) name:JASidePanelLeftDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedRightDidShowNotification:) name:JASidePanelRightDidShowNotification object:nil];

    wordArray = [[NSMutableArray alloc]init];
    //init history
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *filePath = [basePath stringByAppendingPathComponent:@"history.plist"];
    NSString *historyPath =  [basePath stringByAppendingPathComponent:@"favorite.plist"];

    //NSLog(@"file path %@",filePath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if([fileManager fileExistsAtPath:filePath])
    {
        NSData *archiveData = [NSData dataWithContentsOfFile:filePath];
        historyArray = (NSMutableArray*)[NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
    }
    else
    {
        historyArray = [[NSMutableArray alloc]init];

    }
    
    if([fileManager fileExistsAtPath:historyPath])
    {
        NSData *archiveData = [NSData dataWithContentsOfFile:historyPath];
        favoriteArray = (NSMutableArray*)[NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
    }
    else
    {
        favoriteArray = [[NSMutableArray alloc]init];
        
    }
    NSString* settingFilePath = [basePath stringByAppendingPathComponent:@"setting.plist"];
    //NSLog(@"file path %@",filePath);
    if([fileManager fileExistsAtPath:settingFilePath])
    {
        settingArray = [NSMutableArray arrayWithContentsOfFile:settingFilePath];
        dictString = [settingArray objectAtIndex:0];
        dictFileType = [settingArray objectAtIndex:1];
        dictSQL = [settingArray objectAtIndex:2];
        dictType = [settingArray objectAtIndex:3];
    }
    else
    {
        settingArray  = [[NSMutableArray alloc]init];
        dictString = @"VN-JP";
        dictFileType = @"idx2";
        dictSQL = @"VN-JP.sqlite";
        dictType = @"Việt-Nhật";
    }
    self.db = [DBController sharedDatabaseController:dictSQL];
    if ([dictType isEqualToString:@"Hán Tự"]) {
        [self Query:[self.searchBar text]];
    }
    [self.tableData reloadData];
}

- (void) ChangeDictNot:(NSNotification *) notification{
    NSDictionary* userInfo = notification.userInfo;
    dictString = [userInfo objectForKey:@"dictString"];
    dictFileType = [userInfo objectForKey:@"dictType"];
    dictSQL = [userInfo objectForKey:@"dictSQL"];
    dictType = [userInfo objectForKey:@"typeOfDict"];
    NSLog(@"change Dict type %@",dictType);
    self.db = [DBController ReleaseDataBase];
    self.db = [DBController sharedDatabaseController:dictSQL];
    [wordArray removeAllObjects];
    //[self.searchBar setText:@""];
    if (![searchBar.text isEqual:@""] || [dictType isEqualToString:@"Hán Tự"]) {
        [self Query:[searchBar text]];
    }
    [self.tableData reloadData];
    [tableData scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];

}
- (void) ChangeDictLang:(NSNotification *) notification{
    NSDictionary* userInfo = notification.userInfo;
    dictLang = [userInfo objectForKey:@"dictLang"];
    if ([dictLang isEqualToString:@"Tiếng Việt"]) {
        btnHistory.title=@"Lịch Sử";
        btnSetting.title=@"Từ Điển";
    }
    else{
        btnSetting.title=@"辞書";
        btnHistory.title=@"履歴";
    }
}
- (void) Query:(NSString*)word{
    NSString* newword = [word stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    word=newword;

    if ([dictType isEqualToString:@"Hán Tự"]) {
        NSString *sql = [NSString stringWithFormat:@"SELECT * FROM ZMOJI WHERE HANVIET LIKE '%@' or HANKHONGDAU LIKE '%@' or READINGDATA LIKE '%%%@%%' ORDER BY ZGROUP",word,word,word];
        DataTable* table = [_db  ExecuteQuery:sql];
        NSMutableDictionary * theDictionary = [NSMutableDictionary dictionary];
        for (NSArray* row in table.rows)
        {   //NSString* PK = row[0];
            NSString* kanjiID = row[2]; //int
            NSString* numberOfLine = row[3]; //int
            NSString* kanjiWord = row[4];
            NSString* kanjiGroup = row[5];
            NSString* hanWord = row[6];
            //[self ConvertToVietnameseNotSignature:hanWord];
            //[self updateKhongDau:hanWord :[PK intValue]];
            NSString* example = row[7];
            NSString* onReading = row[8];
            NSString* kunReading = row[9];
            ////
            Word* aWord = [[Word alloc]init];
            aWord.word = hanWord;
            aWord.kanjiWord = kanjiWord;
            aWord.kanjiGroup=kanjiGroup;
            aWord.kanjiID = [kanjiID intValue];
            aWord.onReading=onReading;
            aWord.kunReading = kunReading;
            NSString* temp = [NSString stringWithFormat:@"%@",kanjiID];
            NSString *pathImg = [[NSBundle mainBundle] pathForResource:temp ofType:@"gif"];
           /* NSString* webViewContent = [NSString stringWithFormat:
                                        @"<html><body><img style='height: 125px; width: 125px; float: right;' src=\"file://%@\" /></body></html>", pathImg];
            */

            NSString* webViewContent = [NSString stringWithFormat:
                                        @"<html><body><img style='height: 150px; width: 150px; float: right;' src=\"file://%@\" /><h2><span style='font-size:48px;'>%@ &nbsp;</span></h2><ul><li><span style='color:#0099ff;'><span style='font-size:22px;'>画 :&nbsp;</span></span><strong>&nbsp;</strong><span style='font-size:24px;'>%@</span></li><li><span style='color:#0099ff;'><span style='font-size:22px;'>部 : &nbsp;</span></span>&nbsp;<span style='font-size:22px;'>%@</span></li><li><span style='color:#0099ff;'><span style='font-size:22px;'>音読み :</span></span><span style='font-size:22px;'>　%@</span><li><span style='font-size:22px;'>%@</span></li></ul><p><ul><li><span style='color:#0099ff;'><span style='font-size:22px;'>例 :&nbsp;</span></span> <span style='font-size:22px;'>%@</span></p></body></html>",pathImg, kanjiWord ,numberOfLine,[kanjiGroup substringToIndex:1],onReading,kunReading,example];
            aWord.content=webViewContent;
            [wordArray addObject:aWord];
            NSMutableArray * theMutableArray = [theDictionary objectForKey:aWord.kanjiGroup];
                if ( theMutableArray == nil ) {
                    theMutableArray = [NSMutableArray array];
                    [theDictionary setObject:theMutableArray forKey:aWord.kanjiGroup];
                }
                [theMutableArray addObject:aWord];
        }
        kanjiSorted = [[theDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        self.sections = theDictionary;
    }
    else {
        NSString *sql;
        NSString *secondsql;
        if ([dictType isEqualToString:@"Việt-Nhật"]) {
            sql = [NSString stringWithFormat:@"SELECT * FROM data WHERE word_str LIKE '%@%%' or wordkhongdau LIKE '%@%%'ORDER BY word_data_offset LIMIT 3",word,word];
            secondsql = [NSString stringWithFormat:@"SELECT * FROM data WHERE wordhantu LIKE '%%%@%%'  ORDER BY word_data_offset LIMIT 10",[word uppercaseString]];
            //sql = [NSString stringWithFormat:@"SELECT * FROM data WHERE word_str LIKE '%@%%' or wordkhongdau LIKE '%@%%' ORDER BY word_data_offset",word,word];
            //sql = [NSString stringWithFormat:@"SELECT * FROM data WHERE word_data_offset >'%@' " ,word];
            //fix ? symbol
            //sql = [NSString stringWithFormat:@"SELECT * FROM data WHERE wordkhongdau LIKE  '%%%?%%%'"];
        }
        else {
             sql = [NSString stringWithFormat:@"SELECT * FROM data WHERE word_str LIKE '%@%%' ORDER BY word_data_offset LIMIT 10",word];
        }
        //NSLog(@"sql:%@",sql);
        DataTable* table = [_db  ExecuteQuery:sql];
        //NSString* tempcontent ;
        //NSString* path = [[NSBundle mainBundle] pathForResource:@"VN-JP"
        //                                                 ofType:@"idx2"];

        for (NSArray* row in table.rows)
        //@autoreleasepool {
        {
        
            NSString* word = row[0]; // in column order 0 is first column in query above
            NSString* startoffset = row[1];
            NSNumber* dataleght = row[2]; // sqlite ints and floats arrive as NSNumbers
            //NSString* khongdau = row[3];
            NSString* hanViet= row[4];
            NSString* kanjiWord = row[5];
            Word* aWord = [[Word alloc]init];
            aWord.word = word;
            //khongdau = [self fixsymbol:khongdau];
            //NSLog(@"%@",khongdau);
            //[self updateKhongDau:khongdau :word];
            aWord.startoffset= [startoffset intValue];
            aWord.dataleght = [dataleght intValue];
            aWord.hanViet = hanViet;
            aWord.kunReading = kanjiWord;
            //tempcontent = [self readFile:path :aWord];
            //self UpdateHantu:tempcontent :word];
            //[self updateKanji:tempcontent :word];
            [wordArray addObject:aWord];
        }
        //}

        if ([dictType isEqualToString:@"Việt-Nhật"]) {

        DataTable* secondtable = [_db  ExecuteQuery:secondsql];
        for (NSArray* row in secondtable.rows)
            //@autoreleasepool {
        {
            NSString* word = row[0]; // in column order 0 is first column in query above
            NSString* startoffset = row[1];
            NSNumber* dataleght = row[2]; // sqlite ints and floats arrive as NSNumbers
            //NSString* khongdau = row[3];
            NSString* hanViet= row[4];
            NSString* kanjiWord = row[5];
            Word* aWord = [[Word alloc]init];
            aWord.word = word;
            //khongdau = [self fixsymbol:khongdau];
            //NSLog(@"%@",khongdau);
            //[self updateKhongDau:khongdau :word];
            aWord.startoffset= [startoffset intValue];
            aWord.dataleght = [dataleght intValue];
            aWord.hanViet = hanViet;
            aWord.kunReading = kanjiWord;
            //tempcontent = [self readFile:path :aWord];
            //self UpdateHantu:tempcontent :word];
            //[self updateKanji:tempcontent :word];
            [wordArray addObject:aWord];
            }
        }
    }

}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if ([dictType isEqualToString:@"Hán Tự"]) {
        return [kanjiSorted count];
    }
    return 1;
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    
    if ([dictType isEqualToString:@"Hán Tự"]) {
        return kanjiSorted;
    }
    return nil;

}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([dictType isEqualToString:@"Hán Tự"]) {
        return [kanjiSorted objectAtIndex:section];
    }
    return dictType;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([dictType isEqualToString:@"Hán Tự"]) {
        return [[self.sections objectForKey:[kanjiSorted objectAtIndex:section]] count];
    }
    return [wordArray count];
}
- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

- (IBAction)setting:(id)sender {
    //[self.sidePanelController showLeftPanelAnimated:YES];
    [self.sidePanelController toggleLeftPanel:nil];
    [self dismissKeyboard];
}
- (IBAction)history:(id)sender {
    [self.sidePanelController toggleRightPanel:nil];
    [self dismissKeyboard];
}
- (void) clearHistory{
    [historyArray removeAllObjects];
    NSLog(@"remove all history");
    }
- (void) dismissKeyboard
{
    [self.searchBar resignFirstResponder];
}
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    if ([searchText isEqualToString:@""]) {
        //[self Query: searchText];
    }
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [wordArray removeAllObjects];
    [self Query: self.searchBar.text];
    [self.tableData reloadData];
    [self dismissKeyboard];
}
- (void)searchBarTextDidBeginEditing:(UISearchBar *) bar
{
    UITextField *searchBarTextField = nil;
    NSArray *views = ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0f) ? bar.subviews : [[bar.subviews objectAtIndex:0] subviews];
    for (UIView *subview in views)
    {
        if ([subview isKindOfClass:[UITextField class]])
        {
            searchBarTextField = (UITextField *)subview;
            break;
        }
    }
    searchBarTextField.enablesReturnKeyAutomatically = NO;
}
/*
-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.searchBar setShowsCancelButton:NO animated:YES];
}*/

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [self setTableData:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    Word * aWord;
    if ([dictType isEqualToString:@"Hán Tự"]) {
        NSString * kanjiGroup = [kanjiSorted objectAtIndex:indexPath.section];
        NSMutableArray * objectsForGroup = [self.sections objectForKey:kanjiGroup];
         aWord = [objectsForGroup objectAtIndex:indexPath.row];
    }
    else{
    aWord = [self.wordArray objectAtIndex:[indexPath row]];
    }

    cell.textLabel.text = aWord.word;
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIImage *image = [self imageFromText:aWord.kanjiWord];
    cell.imageView.image = image;
    cell.detailTextLabel.text=nil;
    [cell.imageView setHidden:YES];
    UILabel *labelTwo = [[UILabel alloc]initWithFrame:
                         CGRectMake(230, 1, 100, 20)];
    UIFont *detailFont = [UIFont systemFontOfSize:11.0];
    
    labelTwo.font = detailFont;
    labelTwo.tag = 123;
    [[cell.contentView viewWithTag:123] removeFromSuperview];
    if ([dictType isEqualToString:@"Hán Tự"]) {
        [cell.imageView setHidden:NO];
        [cell.contentView addSubview:labelTwo];
        labelTwo.text = aWord.onReading;
        cell.detailTextLabel.text=aWord.kunReading;
    }
    if ([dictType isEqualToString:@"Việt-Nhật"]) {
        [cell.imageView setHidden:YES];
        [cell.contentView addSubview:labelTwo];
        labelTwo.text = aWord.hanViet;
        cell.detailTextLabel.text=aWord.kunReading;
    }
    return cell;
}
-(UIImage *)imageFromText:(NSString *)text
{
    // set the font type and size
    UIFont *font = [UIFont systemFontOfSize:25.0];
    CGSize size  = [text sizeWithFont:font];
    
    // check if UIGraphicsBeginImageContextWithOptions is available (iOS is 4.0+)
    if (UIGraphicsBeginImageContextWithOptions != NULL)
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
    else
        // iOS is < 4.0
        UIGraphicsBeginImageContext(size);
    
    // optional: add a shadow, to avoid clipping the shadow you should make the context size bigger
    //
    // CGContextRef ctx = UIGraphicsGetCurrentContext();
    // CGContextSetShadowWithColor(ctx, CGSizeMake(1.0, 1.0), 5.0, [[UIColor grayColor] CGColor]);
    
    // draw in context, you can use also drawInRect:withFont:
    [text drawAtPoint:CGPointMake(0.0, 0.0) withFont:font];
    
    // transfer image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
-(NSString*)readFile:(NSString*) myFile:(Word*)word{
    @autoreleasepool {
    NSFileHandle *file;
    NSData *databuffer;
    file = [NSFileHandle fileHandleForReadingAtPath: myFile];
    NSLog(@"going to open file");
    if (file == nil)
        NSLog(@"Failed to open file");
    
    [file seekToFileOffset: word.startoffset];
    
    databuffer = [file readDataOfLength: word.dataleght];
    NSString *aString  = [[NSString alloc] initWithData:databuffer encoding:NSUTF8StringEncoding];
    //NSLog(@"%@", [self ConvertToMark:aString]);
    return aString;
    [file closeFile];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *filePath = [basePath stringByAppendingPathComponent:@"history.plist"];
    NSString *favoritePath = [basePath stringByAppendingPathComponent:@"favorite.plist"];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:historyArray];
    NSData *favoriteData = [NSKeyedArchiver archivedDataWithRootObject:favoriteArray];
    if(data) {
        NSError  *error;
        [data writeToFile:filePath options:NSDataWritingAtomic error:&error];
    }// end init history
    NSLog(@"save History");

    if(favoriteData) {
        NSError  *error;
        [favoriteData writeToFile:favoritePath options:NSDataWritingAtomic error:&error];
    }// end init favorite
    NSLog(@"save favorite");

    NSString* settingFilePath = [basePath stringByAppendingPathComponent:@"setting.plist"];
    [settingArray insertObject:dictString atIndex:0];
    [settingArray insertObject:dictFileType atIndex:1];
    [settingArray insertObject:dictSQL atIndex:2];
    [settingArray insertObject:dictType atIndex:3];
    [settingArray writeToFile:settingFilePath atomically:YES];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"showDetail" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    detailViewController *detailViewController = [segue destinationViewController];
    NSString* path = [[NSBundle mainBundle] pathForResource:dictString
                                                     ofType:dictFileType];
    if ([dictType isEqualToString:@"Hán Tự"]) {
        NSString * kanjiGroup = [kanjiSorted objectAtIndex:[self.tableData indexPathForSelectedRow].section];
        NSMutableArray * objectsForGroup = [self.sections objectForKey:kanjiGroup];
        selectedWord = [objectsForGroup objectAtIndex:[self.tableData indexPathForSelectedRow].row];
    }
    else{
        selectedWord = [self.wordArray objectAtIndex:[self.tableData indexPathForSelectedRow].row];
    }
    count = 0;
    inHistory = 0;
    for (Word *word in historyArray) {
        //[word print];
        if ([word isEqualTo:selectedWord]) {
            NSLog(@"HISTORY EXIST");
            selectedWord = word;
            inHistory = 1;
            break;
        }
        count ++;
    }
    if (inHistory == 0 && ![dictType isEqualToString:@"Hán Tự"]) {
        NSLog(@"not found in history");
        selectedWord.content = [self readFile:path :selectedWord];
        //NSLog(selectedWord.content);
    }
    if (historyArray.count >= 51) {
        [historyArray removeObjectAtIndex:50];
    }
    //NSLog(@"add history");
    selectedWord.searchTimes++;
    selectedWord.atDictType = dictType;
    if (inHistory ==1 && historyArray.count >0) {
        [historyArray removeObjectAtIndex:count];
    }
    [historyArray insertObject:selectedWord atIndex:0];
    NSNotification *msg = [NSNotification notificationWithName:@"updateHistory" object:nil];
    [[NSNotificationCenter defaultCenter]postNotification:msg];
    NSLog(@"right view controll : history count %d",historyArray.count);
    detailViewController.word=selectedWord;
}
- (void)adViewDidReceiveAd:(GADBannerView *)bannerView {
    NSLog(@"banner delegate");
    [UIView beginAnimations:@"BannerSlide" context:nil];
    bannerView.frame = CGRectMake(0.0,
                                  self.view.frame.size.height -
                                  bannerView.frame.size.height,
                                  bannerView.frame.size.width,
                                  bannerView.frame.size.height);
    [UIView commitAnimations];
}
-(void)adView:(GADBannerView*)banner didFailToReceiveAdWithError:(GADRequestError*)error
{
    //Never gets called, should be called when both iAd and AdMob fails.
    NSLog(@"AdMobBanner failed.");
}

-(void)bannerView:(GADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
    //If iAd fails, due to no internet connection or whatever, then it calls this.
    NSLog(@"AdMobBanner failed.");


}
-(void)receivedLeftDidShowNotification:(NSNotification*)notification {
       NSLog(@"left did show notification");
    [self dismissKeyboard];
}
-(void)receivedRightDidShowNotification:(NSNotification*)notification {
    NSLog(@"left did show notification");
    [self dismissKeyboard];
}

-(NSString*) ConvertToMark:( NSString*)strJP
 {
     NSMutableString *result = [[NSMutableString alloc]init];
     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
     NSString *filePath = [basePath stringByAppendingPathComponent:@"hantu.txt"];
     //NSLog(@"file path %@",filePath);
     NSFileManager *fileManager = [NSFileManager defaultManager];
     NSString* fileContents ;
     if([fileManager fileExistsAtPath:filePath])
     {
         NSLog(@"hantu.txt read");
         fileContents =
         [NSString stringWithContentsOfFile:filePath
                                   encoding:NSUTF8StringEncoding error:nil];
         // NSLog(@"file %@",fileContents);
     }
     // first, separate by new line
     NSArray* allLinedStrings =
     [fileContents componentsSeparatedByCharactersInSet:
      [NSCharacterSet newlineCharacterSet]];
     //-----------------
     strJP = [strJP stringByReplacingOccurrencesOfString:@"」" withString:@"「"];
     NSArray *array = [strJP componentsSeparatedByString:@"「"];
     NSMutableArray *resultArray = [[NSMutableArray alloc]init];
     [resultArray removeAllObjects];
     for (int i = 0; i<array.count; i++) {
         @autoreleasepool{
         if (i%2 !=0) {
             NSString* hanViet = @"[";
             //NSLog(@"word %@",[array objectAtIndex:i]);
             NSString* KanjiinDict = [array objectAtIndex:i];
             for (int temp = 0; temp<[KanjiinDict length]; temp++) {
                 NSString *checkWord = [NSString stringWithFormat:@"%C",[KanjiinDict characterAtIndex:temp]];
                 //NSLog(@"%@",checkWord);
                 for (int j = 0; j<allLinedStrings.count; j++) {
                     if ((j+2)%2 == 0) {
                         NSArray *kanjiWord = [ [allLinedStrings objectAtIndex:j] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                         NSString *compareKanji = [kanjiWord objectAtIndex:1];
                         if ([compareKanji isEqualToString:checkWord]) {
                             hanViet = [NSString stringWithFormat:@"%@ %@",hanViet,[kanjiWord objectAtIndex:2]];
                             //NSLog(@"hanviet %@",hanViet);
                         }
                     }
                 }
             }
             hanViet = [NSString stringWithFormat:@"%@ ]",hanViet];
             [resultArray addObject:hanViet ];
             //NSLog(@"result %@",hanViet);
         }
     }
 }
     for (NSString* word in resultArray) {
         NSLog(@"word %@",word);
         [result appendString:word];
     }
     
     return result;
 }
-(NSString*) GetKanji:( NSString*)strJP{
    NSMutableString* result = [[NSMutableString alloc]init];;
    //NSLog(@"%@",strJP);
    strJP = [strJP stringByReplacingOccurrencesOfString:@"」" withString:@"「"];
    NSArray *array = [strJP componentsSeparatedByString:@"「"];
    NSMutableArray *resultArray = [[NSMutableArray alloc]init];
    [resultArray removeAllObjects];
    for (int i = 0; i<array.count; i++) {
        @autoreleasepool{
            if (i%2 !=0) {
                NSLog(@"%@",[array objectAtIndex:i]);
                NSString* hanViet = [NSString stringWithFormat:@"[%@]",[array objectAtIndex:i]];
                [resultArray addObject:hanViet];
            }
        }
        
    }
    for (NSString* word in resultArray) {
        NSLog(@"word %@",word);
        [result appendString:word];
    }
    NSLog(@"%@",result);
    return result;
}
-(void)UpdateHantu:(NSString*)content :(NSString*)PK{
     //[self readFile:path :selectedWord];
    //NSLog(@"content %@", content);
    NSString *sql = [NSString stringWithFormat:@"UPDATE data SET wordhantu='%@' WHERE word_str ='%@' ",[self ConvertToMark:content],PK];
    int table = [_db  ExecuteNonQuery:sql];
}

-(NSString*) ConvertToVietnameseNotSgnature:( NSString*)strVietnamese
{
    NSData *data = [strVietnamese dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"%@ co dau , %@ , khong dau",strVietnamese,dataString);
    NSRange range = [dataString rangeOfString:@"?"];
    
    if(range.location != NSNotFound) {
        NSLog(@" found");
        dataString = [dataString stringByReplacingCharactersInRange:range withString:@"d"];
    }
    NSLog(@"%@ co dau , %@ , khong dau",strVietnamese,dataString);

    return dataString;
}

-(NSString*) fixsymbol:( NSString*)strVietnamese{
    NSRange range = [strVietnamese rangeOfString:@"?"];
    if(range.location != NSNotFound) {
        NSLog(@" found");
        strVietnamese = [strVietnamese stringByReplacingCharactersInRange:range withString:@"d"];
    }
    return strVietnamese;
}

-(void)updateKhongDau:(NSString*)hanWord:(NSString*)PK{
    NSString *sql = [NSString stringWithFormat:@"UPDATE data SET wordkhongdau='%@' WHERE word_str ='%@' ",hanWord,PK];
    int table = [_db  ExecuteNonQuery:sql];
}
-(void)updateKanji:(NSString*)hanWord:(NSString*)PK{
    NSString *sql = [NSString stringWithFormat:@"UPDATE data SET wordkanji='%@' WHERE word_str ='%@' ",[self GetKanji:hanWord],PK];
    int table = [_db  ExecuteNonQuery:sql];
}
@end
