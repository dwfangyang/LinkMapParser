//
//  SpecificModuleParser.h
//  LinkMap
//
//  Created by 方阳 on 2017/7/26.
//  Copyright © 2017年 ND. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpecificModuleParser : NSObject

@property (nonatomic,strong) NSString* name;
@property (nonatomic,strong) NSString* path;
@property (nonatomic,strong) NSMutableDictionary* items;
@property (nonatomic,assign) NSUInteger assignCount;

- (void)loadModuleItems;

@end
