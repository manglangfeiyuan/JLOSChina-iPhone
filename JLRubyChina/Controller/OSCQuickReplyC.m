//
//  RCQuickReplyC.m
//  JLOSChina
//
//  Created by Lee jimney on 12/12/13.
//  Copyright (c) 2013 jimneylee. All rights reserved.
//

#import "OSCQuickReplyC.h"
#import "OSCReplyModel.h"
#import "MTStatusBarOverlay.h"
#import "NSString+Emojize.h"

#define BTN_TITLE_REPLY @"回复"
#define BTN_TITLE_CANCEL @"取消"
#define BTN_TITLE_EMOJI @"表情"
#define BTN_TITLE_KEYBOARD @"键盘"

@interface OSCQuickReplyC ()<OSCEmotionDelegate>
@property (nonatomic, strong) UIView* containerView;
@property (nonatomic, strong) UIButton* emojiBtn;
@property (nonatomic, strong) UIButton* sendBtn;
@end

@implementation OSCQuickReplyC

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithTopicId:(unsigned long)topicId catalogType:(OSCCatalogType)catalogType
{
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.topicId = topicId;
        self.catalogType = catalogType;
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView* containerView = [[UIView alloc] initWithFrame:CGRectZero];
    containerView.backgroundColor = [UIColor grayColor];
    self.containerView = containerView;
    
    UIButton* emojiBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[emojiBtn setTitle:BTN_TITLE_EMOJI forState:UIControlStateNormal];
    [emojiBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [emojiBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [emojiBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[emojiBtn addTarget:self action:@selector(showEmojiViewAction) forControlEvents:UIControlEventTouchUpInside];
    self.emojiBtn = emojiBtn;
    
	HPGrowingTextView* textView = [[HPGrowingTextView alloc] initWithFrame:CGRectZero];
    textView.isScrollable = YES;
    textView.contentInset = UIEdgeInsetsMake(0, 5, 0, 5);
	textView.minNumberOfLines = 1;
	textView.returnKeyType = UIReturnKeyDefault;
	textView.font = [UIFont systemFontOfSize:20.0f];
	textView.delegate = self;
    textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(5, 0, 5, 0);
    textView.backgroundColor = [UIColor whiteColor];
    textView.placeholder = @"我也说几句...";
    self.textView = textView;
    
	UIButton* sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
	[sendBtn setTitle:BTN_TITLE_CANCEL forState:UIControlStateNormal];
    [sendBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
    [sendBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
    [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[sendBtn addTarget:self action:@selector(replyAction) forControlEvents:UIControlEventTouchUpInside];
    self.sendBtn = sendBtn;
    
    // view
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:emojiBtn];
    [self.containerView addSubview:self.textView];
	[self.containerView addSubview:sendBtn];
    
    // layout
    CGFloat kViewWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat kViewHeight = TTToolbarHeightForOrientation(self.interfaceOrientation);
    
    CGFloat kBtnWidth = 40.f;
    CGFloat KBtnHeight = 20.f;
    CGFloat kBtnSideMargin = CELL_PADDING_4;
    CGFloat kBtnTopMargin = (kViewHeight - KBtnHeight) / 2;
    
    CGFloat kTextViewWidth = kViewWidth - kBtnSideMargin * 4 - kBtnWidth * 2;
    CGFloat kTextViewMaxHeight = [UIScreen mainScreen].bounds.size.height
    - TTKeyboardHeightForOrientation(self.interfaceOrientation)
    - NIStatusBarHeight() - NIToolbarHeightForOrientation(self.interfaceOrientation) * 2;

    self.view.frame = CGRectMake(0, 0, kViewWidth, kViewHeight);
    self.containerView.frame = self.view.bounds;
	self.emojiBtn.frame = CGRectMake(kBtnSideMargin, kBtnTopMargin, kBtnWidth, KBtnHeight);
    self.textView.frame = CGRectMake(emojiBtn.right + kBtnSideMargin, 0.f, kTextViewWidth, kViewHeight);
    self.textView.maxHeight = kTextViewMaxHeight;
    self.sendBtn.frame = CGRectMake(self.textView.right + kBtnSideMargin, kBtnTopMargin, kBtnWidth, KBtnHeight);
    
    //self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.sendBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.emojiBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showEmojiViewAction
{
    if (!_emojiView) {
        _emojiView = [[OSCEmotionMainView alloc]
                      initWithFrame:CGRectMake(0, self.view.frame.size.height - TTKeyboardHeightForOrientation(self.interfaceOrientation),
                                               self.view.width, TTKeyboardHeightForOrientation(self.interfaceOrientation))];
        _emojiView.emotionDelegate = self;
    }
    if (!self.textView.internalTextView.inputView) {
        // show emoji view
        [self.emojiBtn setTitle:BTN_TITLE_KEYBOARD forState:UIControlStateNormal];
        [self.textView.internalTextView resignFirstResponder];
        self.textView.internalTextView.inputView = self.emojiView;
        [self.textView.internalTextView becomeFirstResponder];
        
        // by default, inputAccessoryView is in front of inputView,
        // when touch first row of emoji view, emoji's TSEmojiViewLayer is coverd by inputAccessoryView
        // after do hack, know that inputView's superview is the same to inputAccessoryView 's superview。
        // it is UIPeripheralHostView, so i can bring front inputView, make emoji's TSEmojiViewLayer show well!
#ifdef DEBUG
        UIView* s1 = self.textView.internalTextView.inputView.superview;
        NSLog(@"inputView.superview = %@", s1);
        UIView* s2 = self.textView.internalTextView.inputAccessoryView.superview;
        NSLog(@"inputAccessoryView.superview = %@", s2);
#endif
        if (self.textView.internalTextView.inputView.superview) {
            [self.textView.internalTextView.inputView.superview bringSubviewToFront:self.textView.internalTextView.inputView];
        }
    }
    else {
        // show keyboard
        [self.emojiBtn setTitle:BTN_TITLE_EMOJI forState:UIControlStateNormal];
        [self.textView.internalTextView resignFirstResponder];
        self.textView.internalTextView.inputView = nil;
        [self.textView.internalTextView becomeFirstResponder];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// TODO: will move this method it util
- (NSString*)stringByReplaceEmojiUnicodeWithTextCodeForSourceText:(NSString*)sourceText
{
//    NSLog(@"before source Text:%@", sourceText);
//    for (NSString* key in [OSCGlobalConfig emojiReverseAliases]) {
//        sourceText = [sourceText stringByReplacingOccurrencesOfString:key withString:[OSCGlobalConfig emojiReverseAliases][key]];
//    }
//    NSLog(@"after source Text:%@", sourceText);
    return sourceText;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
-(void)replyAction
{
    if (self.textView.text.length) {
        OSCReplyModel* replyModel = [[OSCReplyModel alloc] init];
        // replace emoji unicode to text code
        NSString* bodyText = [self.textView.text copy];
        NSString* pureBodyText = [self stringByReplaceEmojiUnicodeWithTextCodeForSourceText:bodyText];
        [[MTStatusBarOverlay sharedOverlay] postMessage:@"回复中..."];
        [replyModel replyContentId:self.topicId
                       catalogType:self.catalogType
                            body:pureBodyText //self.textView.text
                         success:^(OSCReplyEntity* replyEntity){
                             self.textView.text = @"";
                             [self.textView resignFirstResponder];
                             
                             if ([self.replyDelegate respondsToSelector:@selector(didReplySuccessWithMyReply:)]) {
                                 [self.replyDelegate didReplySuccessWithMyReply:replyEntity];
                                 [[MTStatusBarOverlay sharedOverlay] postImmediateFinishMessage:@"回复成功" duration:2.0f animated:YES];
                             }
                         } failure:^(OSCErrorEntity* errorEntity) {
                             [OSCGlobalConfig HUDShowMessage:@"回复失败!" addedToView:self.view];
                             if ([self.replyDelegate respondsToSelector:@selector(didReplyFailure)]) {
                                 [self.replyDelegate didReplyFailure];
                                 [[MTStatusBarOverlay sharedOverlay] postImmediateErrorMessage:@"回复失败，请重新发送" duration:2.0f animated:YES];
                             }
                         }];
    }
    else {
        [self.textView resignFirstResponder];
        if ([self.replyDelegate respondsToSelector:@selector(didReplyCancel)]) {
            [self.replyDelegate didReplyCancel];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)appendString:(NSString*)string
{
    if (self.textView.text.length) {
        self.textView.text = [NSString stringWithFormat:@"%@ %@", self.textView.text, string];
    }
    else {
        self.textView.text = string;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - ZDEmotionDelegate

//////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)emotionSelectedWithCode:(NSString*)code
{
    self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, code];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - HPGrowingTextViewDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    if (0 == growingTextView.text.length) {
        [self.sendBtn setTitle:BTN_TITLE_CANCEL forState:UIControlStateNormal];
    }
    else {
        [self.sendBtn setTitle:BTN_TITLE_REPLY forState:UIControlStateNormal];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    float diff = (growingTextView.frame.size.height - height);
    
	CGRect r = self.containerView.frame;
    r.size.height -= diff;
    r.origin.y += diff;
	self.containerView.frame = r;
}

@end
