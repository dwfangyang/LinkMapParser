//
//  SpecificModuleParser.m
//  LinkMap
//
//  Created by 方阳 on 2017/7/26.
//  Copyright © 2017年 ND. All rights reserved.
//

#import "SpecificModuleParser.h"

@implementation SpecificModuleParser

- (void)loadModuleItems
{
    NSURL* url = [NSURL fileURLWithPath:self.path isDirectory:NO];
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSMacOSRomanStringEncoding error:nil];
    NSArray<NSString*>* lines = [content componentsSeparatedByString:@"\n"];
    if( !self.items )
    {
        self.items = [NSMutableDictionary new];
    }
    for( NSString* item in lines )
    {
        if( item.length )
        {
            [self.items setObject:@0 forKey:item];
        }
    }
    NSLog(@"%@ items for %@",@(lines.count),self.path);
}

@end
