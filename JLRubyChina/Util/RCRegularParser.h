//
//  SMRegularParser.h
//  SinaMBlog
//
//  Created by jimneylee on 13-2-18.
//  Copyright (c) 2013年 jimneylee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCRegularParser : NSObject

// 返回所有at某人的range数组
+ (NSArray *)keywordRangesOfAtPersonInString:(NSString *)string;

// 返回所有#楼的range数组
+ (NSArray *)keywordRangesOfSharpFloorInString:(NSString *)string;

// 返回表情的range数组，和去掉表情字符的trimed字符串
+ (NSArray *)keywordRangesOfEmotionInString:(NSString *)string trimedString:(NSString **)trimedString;

// 返回图片的string数组，和去掉图片链接的trimed字符串
+ (NSArray *)imageUrlsInString:(NSString *)string trimedString:(NSString **)trimedString;

@end
