//
//  RCReplyCell.m
//  JLOSChina
//
//  Created by Lee jimney on 12/10/13.
//  Copyright (c) 2013 jimneylee. All rights reserved.
//

#import "OSCReplyCell.h"
#import <QuartzCore/QuartzCore.h>
#import "NIAttributedLabel.h"
#import "NIWebController.h"
#import "UIView+findViewController.h"
#import "UIImage+nimbusImageNamed.h"
//#import "RCUserHomepageC.h"
//#import "RCContentPhotoBrowerC.h"
#import "OSCCommonRepliesListC.h"
#import "OSCReplyEntity.h"
#import "RCKeywordEntity.h"

#define NAME_FONT_SIZE [UIFont systemFontOfSize:15.f]
#define DATE_FONT_SIZE [UIFont systemFontOfSize:12.f]
#define CONTENT_FONT_SIZE [UIFont fontWithName:@"STHeitiSC-Light" size:18.f]
#define BUTTON_FONT_SIZE [UIFont boldSystemFontOfSize:13.f]

#define CONTENT_LINE_HEIGHT 24.f
#define HEAD_IAMGE_HEIGHT 34
#define BUTTON_SIZE CGSizeMake(40.f, 22.f)
#define CONTENT_IMAGE_HEIGHT 160

@interface OSCReplyCell()<NIAttributedLabelDelegate>
@property (nonatomic, strong) NIAttributedLabel* contentLabel;
@property (nonatomic, strong) UILabel* floorLabel;
@property (nonatomic, strong) NINetworkImageView* headView;
@property (nonatomic, strong) UIButton* replyBtn;
@property (nonatomic, strong) UIImageView* moreImageView;
@property (nonatomic, strong) OSCReplyEntity* replyEntity;
@end
@implementation OSCReplyCell

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)addAllLinksInContentLabel:(NIAttributedLabel*)contentLabel
                       withStatus:(OSCReplyEntity*)o
                     fromLocation:(NSInteger)location
{
    RCKeywordEntity* keyworkEntity = nil;
    NSString* url = nil;
    if (o.atPersonRanges.count) {
        for (int i = 0; i < o.atPersonRanges.count; i++) {
            keyworkEntity = (RCKeywordEntity*)o.atPersonRanges[i];
            url =[NSString stringWithFormat:@"%@%@", PROTOCOL_AT_SOMEONE, [keyworkEntity.keyword urlEncoded]];
            [contentLabel addLink:[NSURL URLWithString:url]
                            range:NSMakeRange(keyworkEntity.range.location + location, keyworkEntity.range.length)];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)insertAllEmotionsInContentLabel:(NIAttributedLabel*)contentLabel
                             withStatus:(OSCReplyEntity*)o
{
    RCKeywordEntity* keyworkEntity = nil;
    if (o.emotionRanges.count) {
        NSString* emotionImageName = nil;
        // replace emotion from nail to head, so range's location is right. it's very important, good idea!
        for (int i = 0; i < o.emotionRanges.count; i++) {
            keyworkEntity = (RCKeywordEntity*)o.emotionRanges[i];
            if (i < o.emotionImageNames.count) {
                emotionImageName = o.emotionImageNames[i];
                if (emotionImageName.length) {
                    [contentLabel insertImage:[UIImage nimbusImageNamed:emotionImageName]
                                      atIndex:keyworkEntity.range.location];
                }
            }
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)attributeHeightForEntity:(OSCReplyEntity*)o withWidth:(CGFloat)width
{
    // only alloc one time,reuse it, optimize best
    static NIAttributedLabel* contentLabel = nil;
    
    if (!contentLabel) {
        contentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
        contentLabel.numberOfLines = 0;
        contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        contentLabel.font = CONTENT_FONT_SIZE;
        contentLabel.lineHeight = CONTENT_LINE_HEIGHT;
        contentLabel.width = width;
    }
    else {
        // reuse contentLabel and reset frame, it's great idea from my mind
        contentLabel.frame = CGRectZero;
        contentLabel.width = width;
    }
    
    contentLabel.text = o.body;
    [OSCReplyCell insertAllEmotionsInContentLabel:contentLabel withStatus:o];
    //[contentLabel sizeToFit];
    CGSize contentSize = [contentLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    if (contentSize.height < CONTENT_LINE_HEIGHT) {
        contentSize.height = CONTENT_LINE_HEIGHT;
    }
    return contentSize.height;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)heightForObject:(id)object atIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    if ([object isKindOfClass:[OSCReplyEntity class]]) {
        CGFloat cellMargin = CELL_PADDING_4;
        CGFloat contentViewMarin = CELL_PADDING_6;
        CGFloat sideMargin = cellMargin + contentViewMarin;
        
        CGFloat height = sideMargin;
        
        // head image
        height = height + HEAD_IAMGE_HEIGHT;
        height = height + CELL_PADDING_4;
        
        // body
        OSCReplyEntity* o = (OSCReplyEntity*)object;
        CGFloat kContentLength = tableView.width - sideMargin * 2;
        
#if 0// sizeWithFont
        CGSize contentSize = [o.body sizeWithFont:CONTENT_FONT_SIZE constrainedToSize:CGSizeMake(kContentLength, FLT_MAX)];
        height = height + contentSize.height;
#else// sizeToFit
        height = height + [self attributeHeightForEntity:o withWidth:kContentLength];
#endif
        height = height + sideMargin;
        
        return height;
    }
    
    return 0.0f;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - LifeCycle

///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // head
        self.headView = [[NINetworkImageView alloc] initWithFrame:CGRectMake(0, 0, HEAD_IAMGE_HEIGHT,
                                                                                    HEAD_IAMGE_HEIGHT)];
        self.headView.initialImage = [UIImage nimbusImageNamed:@"head_s.png"];
        [self.contentView addSubview:self.headView];
        UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                              action:@selector(visitUserHomepage)];
        self.headView.userInteractionEnabled = YES;
        [self.headView addGestureRecognizer:tap];
        
        // name
        self.textLabel.font = NAME_FONT_SIZE;
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.highlightedTextColor = self.textLabel.textColor;
        
        // date
        self.detailTextLabel.font = DATE_FONT_SIZE;
        self.detailTextLabel.textColor = [UIColor grayColor];
        self.detailTextLabel.highlightedTextColor = self.detailTextLabel.textColor;
        
        // lou
        self.floorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.floorLabel.numberOfLines = 0;
        self.floorLabel.font = DATE_FONT_SIZE;
        self.floorLabel.textColor = [UIColor blackColor];
        self.floorLabel.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self.floorLabel];
        
        self.replyBtn = [[UIButton alloc] initWithFrame:CGRectMake(0.f, 0.f, BUTTON_SIZE.width, BUTTON_SIZE.height)];
        [self.replyBtn.titleLabel setFont:BUTTON_FONT_SIZE];
        [self.replyBtn setTitle:@"回复" forState:UIControlStateNormal];
        [self.replyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.replyBtn setBackgroundColor:RGBCOLOR(27, 128, 219)];
        [self.replyBtn addTarget:self action:@selector(replyAction) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.replyBtn];
        self.replyBtn.layer.borderColor = CELL_CONTENT_VIEW_BORDER_COLOR.CGColor;
        self.replyBtn.layer.borderWidth = 1.0f;
        
        // content
        self.contentLabel = [[NIAttributedLabel alloc] initWithFrame:CGRectZero];
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.font = CONTENT_FONT_SIZE;
        self.contentLabel.lineHeight = CONTENT_LINE_HEIGHT;
        self.contentLabel.textColor = [UIColor blackColor];
        self.contentLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.contentLabel.autoDetectLinks = YES;
        self.contentLabel.delegate = self;
        self.contentLabel.attributesForLinks =@{(NSString *)kCTForegroundColorAttributeName:(id)RGBCOLOR(6, 89, 155).CGColor};
        self.contentLabel.highlightedLinkBackgroundColor = RGBCOLOR(26, 162, 233);
        [self.contentView addSubview:self.contentLabel];
        
        // content view border
        self.contentView.layer.borderColor = CELL_CONTENT_VIEW_BORDER_COLOR.CGColor;
        self.contentView.layer.borderWidth = 1.0f;
        
        // background color
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = CELL_CONTENT_VIEW_BG_COLOR;
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.floorLabel.backgroundColor = [UIColor clearColor];
        self.contentLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)prepareForReuse
{
    [super prepareForReuse];
    if (self.headView.image) {
        self.headView.image = nil;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (IOS_IS_AT_LEAST_7) {
    }
    else {
        // set here compatible with ios6.x
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
    
    CGFloat cellMargin = CELL_PADDING_4;
    CGFloat contentViewMarin = CELL_PADDING_6;
    //CGFloat sideMargin = cellMargin + contentViewMarin;
    
    self.contentView.frame = CGRectMake(cellMargin, cellMargin,
                                        self.width - cellMargin * 2,
                                        self.height - cellMargin * 2);
    
    self.headView.left = contentViewMarin;
    self.headView.top = contentViewMarin;
    
    // name
    CGFloat topWidth = self.contentView.width - contentViewMarin * 2 - (self.headView.right + CELL_PADDING_10);
    self.textLabel.frame = CGRectMake(self.headView.right + CELL_PADDING_10, self.headView.top,
                                      topWidth / 2,
                                      self.textLabel.font.lineHeight);
    
    // floor
    self.floorLabel.frame = CGRectMake(self.textLabel.right, CELL_PADDING_2,
                                     self.textLabel.width, self.textLabel.height);
    
    // reply btn
    self.replyBtn.right = self.contentView.width - contentViewMarin;
    self.replyBtn.top = self.floorLabel.bottom;
    
    // date
    self.detailTextLabel.frame = CGRectMake(self.textLabel.left, self.textLabel.bottom,
                                            topWidth, self.detailTextLabel.font.lineHeight);

    
    // content
    CGFloat kContentLength = self.contentView.width - contentViewMarin * 2;
    self.contentLabel.frame = CGRectMake(self.headView.left, self.headView.bottom + CELL_PADDING_4,
                                         kContentLength, 0.f);
    [self.contentLabel sizeToFit];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)shouldUpdateCellWithObject:(id)object
{
    [super shouldUpdateCellWithObject:object];
    if ([object isKindOfClass:[OSCReplyEntity class]]) {
        OSCReplyEntity* o = (OSCReplyEntity*)object;
        self.replyEntity = o;
        if (o.user.avatarUrl.length) {
            [self.headView setPathToNetworkImage:o.user.avatarUrl];
        }
        else {
            [self.headView setPathToNetworkImage:nil];
        }
        self.textLabel.text = o.user.authorName;
        self.detailTextLabel.text = [o.createdAtDate formatRelativeTime];
        self.floorLabel.text = o.floorNumberString;
        self.contentLabel.text = o.body;
        [OSCReplyCell addAllLinksInContentLabel:self.contentLabel withStatus:o fromLocation:0];
        [OSCReplyCell insertAllEmotionsInContentLabel:self.contentLabel withStatus:o];
    }
    return YES;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)replyAction
{
    UIViewController* superviewC = self.viewController;
    // 弹出回复框
    if ([superviewC isKindOfClass:[OSCCommonRepliesListC class]]) {
        OSCCommonRepliesListC* repliesListC = (OSCCommonRepliesListC*)superviewC;
        [repliesListC replyTopicWithFloorAtSomeone:[NSString stringWithFormat:@"回复 @%@ : ",
                                                    self.replyEntity.user.authorName]];
        // 移动当前cell至顶部
        NSIndexPath *indexPath = [repliesListC.tableView indexPathForCell: self];
        if (indexPath) {
            [repliesListC.tableView scrollToRowAtIndexPath:indexPath
                                          atScrollPosition:UITableViewScrollPositionTop
                                                  animated:YES];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)visitUserHomepage
{
    UIViewController* superviewC = self.viewController;
    [OSCGlobalConfig HUDShowMessage:self.replyEntity.user.authorName
                       addedToView:[UIApplication sharedApplication].keyWindow];
//    if (superviewC) {
//        RCUserHomepageC* c = [[RCUserHomepageC alloc] initWithUserLoginId:self.replyEntity.user.loginId];
//        [superviewC.navigationController pushViewController:c animated:YES];
//    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)showMoreImages
{
    UIViewController* superviewC = self.viewController;
//    if (superviewC) {
//        RCContentPhotoBrowerC* c = [[RCContentPhotoBrowerC alloc] initWithPhotoUrls:self.replyEntity.imageUrlsArray];
//        [superviewC.navigationController pushViewController:c animated:YES];
//    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NIAttributedLabelDelegate

///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)attributedLabel:(NIAttributedLabel*)attributedLabel
didSelectTextCheckingResult:(NSTextCheckingResult *)result
                atPoint:(CGPoint)point {
    NSURL* url = nil;
    if (NSTextCheckingTypePhoneNumber == result.resultType) {
        url = [NSURL URLWithString:[@"tel://" stringByAppendingString:result.phoneNumber]];
        
    } else if (NSTextCheckingTypeLink == result.resultType) {
        url = result.URL;
    }
    
    if (nil != url) {
        UIViewController* superviewC = self.viewController;
        if ([url.absoluteString hasPrefix:PROTOCOL_AT_SOMEONE]) {
            NSString* someone = [url.absoluteString substringFromIndex:PROTOCOL_AT_SOMEONE.length];
            someone = [someone stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [OSCGlobalConfig HUDShowMessage:someone
                               addedToView:[UIApplication sharedApplication].keyWindow];
        }
        else if ([url.absoluteString hasPrefix:PROTOCOL_SHARP_FLOOR]) {
            NSString* somefloor = [url.absoluteString substringFromIndex:PROTOCOL_SHARP_FLOOR.length];
            somefloor = [somefloor stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [OSCGlobalConfig HUDShowMessage:[NSString stringWithFormat:@"Jump to #%@", somefloor]
                               addedToView:[UIApplication sharedApplication].keyWindow];
            
            if ([superviewC isKindOfClass:[UITableViewController class]]) {
                UITableViewController* t = (UITableViewController*)superviewC;
                NSUInteger floor = [somefloor integerValue] - 1;
                if (floor < [t.tableView numberOfRowsInSection:0]) {
                    [t.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:floor inSection:0]
                                       atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
            }
        }
        else {
            if (superviewC) {
                NIWebController* webC = [[NIWebController alloc] initWithURL:url];
                [superviewC.navigationController pushViewController:webC animated:YES];
            }
        }
    }
    else {
        [OSCGlobalConfig HUDShowMessage:@"无效的链接" addedToView:self.viewController.view];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)attributedLabel:(NIAttributedLabel *)attributedLabel
shouldPresentActionSheet:(UIActionSheet *)actionSheet
 withTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point
{
    return NO;
}

@end
