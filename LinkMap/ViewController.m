//
//  ViewController.m
//  LinkMap
//
//  Created by Suteki(67111677@qq.com) on 4/8/16.
//  Copyright © 2016 Apple. All rights reserved.
//

#import "ViewController.h"
#import "SymbolModel.h"
#import "SpecificModuleParser.h"

@interface ViewController()

@property (weak) IBOutlet NSTextField *filePathField;//显示选择的文件路径
@property (weak) IBOutlet NSProgressIndicator *indicator;//指示器
@property (weak) IBOutlet NSTextField *searchField;

@property (weak) IBOutlet NSScrollView *contentView;//分析的内容
@property (unsafe_unretained) IBOutlet NSTextView *contentTextView;
@property (weak) IBOutlet NSButton *groupButton;


@property (strong) NSURL *linkMapFileURL;
@property (strong) NSString *linkMapContent;

@property (strong) NSMutableString *result;//分析的结果

@property (nonatomic,strong) NSMutableArray* modulePathArr;
@property (nonatomic,strong) NSMutableArray* moduleParserArr1;
@property (nonatomic,strong) NSMutableArray* moduleParserArr2;
@property (nonatomic,assign) NSUInteger dataOffset;
@property (nonatomic,strong) NSDictionary* config;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.indicator.hidden = YES;
    
    _contentTextView.editable = NO;
    
    _contentTextView.string = @"使用方式：\n\
    1.在XCode中开启编译选项Write Link Map File \n\
    XCode -> Project -> Build Settings -> 把Write Link Map File选项设为yes，并指定好linkMap的存储位置 \n\
    2.工程编译完成后，在编译目录里找到Link Map文件（txt类型） \n\
    默认的文件地址：~/Library/Developer/Xcode/DerivedData/XXX-xxxxxxxxxxxxx/Build/Intermediates/XXX.build/Debug-iphoneos/XXX.build/ \n\
    3.回到本应用，点击“选择文件”，打开Link Map文件  \n\
    4.点击“开始”，解析Link Map文件 \n\
    5.点击“输出文件”，得到解析后的Link Map文件 \n\
    6. * 输入目标文件的关键字(例如：libIM)，然后点击“开始”。实现搜索功能 \n\
    7. * 勾选“分组解析”，然后点击“开始”。实现对不同库的目标文件进行分组";
    
//    _modulePathArr = [NSMutableArray new];
//    _moduleParserArr1 = [NSMutableArray new];
//    _moduleParserArr2 = [NSMutableArray new];
//    NSString* path1 = @"ipatest_6.5";
//    NSString* path2 = @"maint_6.6";
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___AppNameCore___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___Ui___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___Model___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___MakeFriends___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___OnePiece___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___RNComponents___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___TinyVideoV2___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___Werwolf___"];
//    [_modulePathArr addObject:@"/Users/fangyang/srcfolder/ios/%@/AppName/___YYPK___"];
//    for( NSString* path in _modulePathArr )
//    {
//        NSString* p1 = [NSString stringWithFormat:path,path1];
//        NSString* p2 = [NSString stringWithFormat:path,path2];
//        SpecificModuleParser* parser1 = [SpecificModuleParser new];
//        parser1.path = p1;
//        parser1.name = [p1 lastPathComponent];
//        parser1.assignCount = 0;
//        [parser1 loadModuleItems];
//        SpecificModuleParser* parser2 = [SpecificModuleParser new];
//        parser2.path = p2;
//        parser2.name = [p2 lastPathComponent];
//        parser2.assignCount = 0;
//        [parser2 loadModuleItems];
//        [_moduleParserArr1 addObject:parser1];
//        [_moduleParserArr2 addObject:parser2];
//    }
    self.config  = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"config" ofType:@"plist"]];
    NSString* path1 = [self.config objectForKey:@"linkmap1"];
    NSString* path2 = [self.config objectForKey:@"linkmap2"];
    NSString* content1 = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path1 isDirectory:NO] encoding:NSMacOSRomanStringEncoding error:nil];
    NSString* content2 = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path2 isDirectory:NO] encoding:NSMacOSRomanStringEncoding error:nil];
    NSMutableDictionary* dic1 = [self symbolMapFromContent:content1 extramodule:self.moduleParserArr1];
    NSMutableDictionary* dic2 = [self symbolMapFromContent:content2 extramodule:self.moduleParserArr2];
    NSArray *sortedSymbols1 = [self sortSymbols:[dic1 allValues]];
    NSArray *sortedSymbols2 = [self sortSymbols:[dic2 allValues]];
    NSMutableDictionary* groupedSymbols1 = nil,*groupedSymbols2 = nil;
    NSMutableString* result = [self buildCombinationResultWithSymbols:sortedSymbols1 groupedDic:&groupedSymbols1];
    NSMutableString* result2 =[self buildCombinationResultWithSymbols:sortedSymbols2 groupedDic:&groupedSymbols2];
    [result2 appendString:result];
    NSMutableArray* increase = [NSMutableArray new],*decrease = [NSMutableArray new],*gone = [NSMutableArray new],*new= [NSMutableArray new];
    NSInteger incsize = 0,decsize = 0,gonesize = 0,newsize = 0;
    NSInteger inccodesize = 0,deccodesize=0,gonecodesize = 0,newcodesize=0;
    for( NSString* key in [groupedSymbols1 allKeys] )
    {
        SymbolModel* oldModel = groupedSymbols1[key];
        SymbolModel* newmodel = groupedSymbols2[key];
        SymbolModel* model = [SymbolModel new];
        if( newmodel )
        {
            model.size = newmodel.size - oldModel.size;
            model.codeSize = newmodel.codeSize - oldModel.codeSize;
            model.file = key;
            if( model.size < 0 )
            {
                if( labs(model.size) > 1024 )
                {
                    [decrease addObject:model];
                }
                decsize -= model.size;
                deccodesize -= model.codeSize;
            }
            else if( model.size > 0 )
            {
                if( labs(model.size) > 1024 )
                {
                    [increase addObject:model];
                }
                incsize += model.size;
                inccodesize += model.codeSize;
            }
            [groupedSymbols2 removeObjectForKey:key];
        }
        else
        {
            [gone addObject:oldModel];
            gonesize += oldModel.size;
            gonecodesize += oldModel.codeSize;
        }
    }
    for( SymbolModel* model in [groupedSymbols2 allValues] )
    {
        [new addObject:model];
        newsize+= model.size;
        newcodesize += model.codeSize;
    }
    
    [increase sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        SymbolModel* m1 = obj1,*m2 = obj2;
        if( m1.size > m2.size )
        {
            return NSOrderedAscending;
        }
        else if( m1.size == m2.size )
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    [decrease sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        SymbolModel* m1 = obj1,*m2 = obj2;
        if( m1.size < m2.size )
        {
            return NSOrderedAscending;
        }
        else if( m1.size == m2.size )
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    [gone sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        SymbolModel* m1 = obj1,*m2 = obj2;
        if( m1.size > m2.size )
        {
            return NSOrderedAscending;
        }
        else if( m1.size == m2.size )
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    [new sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        SymbolModel* m1 = obj1,*m2 = obj2;
        if( m1.size > m2.size )
        {
            return NSOrderedAscending;
        }
        else if( m1.size == m2.size )
        {
            return NSOrderedSame;
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    [result2 appendString:[NSString stringWithFormat:@"\n\n 新增部分:%.2fM, 代码:%.2fM\n\n",newsize*1.0/1024/1024,newcodesize/1024.0/1024]];
    for( SymbolModel* model in new )
    {
        [self appendResultWithSymbol:model result:result2];
    }
    [result2 appendString:[NSString stringWithFormat:@"\n\n 删除部分:%.2fM, 代码:%.2fM\n\n",gonesize*1.0/1024/1024,gonecodesize/1024.0/1024.0]];
    for( SymbolModel* model in gone )
    {
        [self appendResultWithSymbol:model result:result2];
    }
    [result2 appendString:[NSString stringWithFormat:@"\n\n 增加部分:%.2fM, 代码:%.2fM\n\n",incsize*1.0/1024/1024,inccodesize/1024.0/1024.0]];
    for( SymbolModel* model in increase )
    {
        [self appendResultWithSymbol:model result:result2];
    }
    [result2 appendString:[NSString stringWithFormat:@"\n\n 减少部分:%.2fM, 代码:%.2fM\n\n",decsize*1.0/1024/1024,deccodesize/1024.0/1024.0]];
    for( SymbolModel* model in decrease )
    {
        [self appendResultWithSymbol:model result:result2];
    }
    
    NSString* retPath = [self.config objectForKey:@"resultdirectory"];
    
    NSString* output = [NSString stringWithFormat:@"%@/result.txt",retPath];
    [result2 writeToFile:output atomically:YES encoding:NSUTF8StringEncoding error:nil];
//    NSURL * outputurl = [NSURL fileURLWithPath:output];
    NSString* openpath = [[NSBundle mainBundle] pathForResource:@"openResult" ofType:@"sh"];
    [NSTask launchedTaskWithLaunchPath:openpath arguments:[NSArray arrayWithObjects:output, nil]];
    
    exit(0);
}

- (IBAction)chooseFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    panel.resolvesAliases = NO;
    panel.canChooseFiles = YES;
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *document = [[panel URLs] objectAtIndex:0];
            _filePathField.stringValue = document.path;
            self.linkMapFileURL = document;
        }
    }];
}

- (IBAction)analyze:(id)sender {
    if (!_linkMapFileURL || ![[NSFileManager defaultManager] fileExistsAtPath:[_linkMapFileURL path] isDirectory:nil]) {
        [self showAlertWithText:@"请选择正确的Link Map文件路径"];
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *content = [NSString stringWithContentsOfURL:_linkMapFileURL encoding:NSMacOSRomanStringEncoding error:nil];
        
        if (![self checkContent:content]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAlertWithText:@"Link Map文件格式有误"];
            });
            return ;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.indicator.hidden = NO;
            [self.indicator startAnimation:self];
            
        });
        
        NSDictionary *symbolMap = [self symbolMapFromContent:content extramodule:nil];
        
        NSArray <SymbolModel *>*symbols = [symbolMap allValues];
        
        NSArray *sortedSymbols = [self sortSymbols:symbols];
        
        if (_groupButton.state == 1) {
            self.result = [self buildCombinationResultWithSymbols:sortedSymbols groupedDic:nil];
        } else {
            [self buildResultWithSymbols:sortedSymbols];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentTextView.string = _result;
            self.indicator.hidden = YES;
            [self.indicator stopAnimation:self];
            
        });
    });
}

- (NSMutableDictionary *)symbolMapFromContent:(NSString *)content extramodule:(NSArray*)modules
{
    NSMutableDictionary <NSString *,SymbolModel *>*symbolMap = [NSMutableDictionary new];
    // 符号文件列表
    NSArray *lines = [content componentsSeparatedByString:@"\n"];
    
    BOOL reachFiles = NO;
    BOOL reachSymbols = NO;
    BOOL reachSections = NO;
    self.dataOffset = 0;
    NSUInteger size = 0;
    for(NSString *line in lines) {
        if([line hasPrefix:@"#"]) {
            if([line hasPrefix:@"# Object files:"])
                reachFiles = YES;
            else if ([line hasPrefix:@"# Sections:"])
                reachSections = YES;
            else if ([line hasPrefix:@"# Symbols:"])
                reachSymbols = YES;
        } else {
            if(reachFiles == YES && reachSections == NO && reachSymbols == NO) {
                NSRange range = [line rangeOfString:@"]"];
                if(range.location != NSNotFound) {
                    SymbolModel *symbol = [SymbolModel new];
                    symbol.file = [line substringFromIndex:range.location+1];
                    NSString *key = [line substringToIndex:range.location+1];
                    symbolMap[key] = symbol;
                }
            }
            else if( reachFiles == YES && reachSections == YES && reachSymbols == NO )
            {
                NSArray <NSString *>*sectionArray = [line componentsSeparatedByString:@"\t"];
                if ( !self.dataOffset && sectionArray.count == 4  && [sectionArray[2] isEqualToString:@"__DATA"] ) {
                    self.dataOffset = strtoul([sectionArray[0] UTF8String], nil, 16);
                }
            }
            else if (reachFiles == YES && reachSections == YES && reachSymbols == YES) {
                NSArray <NSString *>*symbolsArray = [line componentsSeparatedByString:@"\t"];
                if(symbolsArray.count == 3) {
                    if( [symbolsArray[0] containsString:@"<<dead>>"] )
                    {
                        size++;
                        continue;
                    }
                    NSString *fileKeyAndName = symbolsArray[2];
                    NSUInteger size = strtoul([symbolsArray[1] UTF8String], nil, 16);
                    NSUInteger offset = strtoul([symbolsArray[0] UTF8String], nil, 16);
                    
                    NSRange range = [fileKeyAndName rangeOfString:@"]"];
                    if(range.location != NSNotFound) {
                        NSString *key = [fileKeyAndName substringToIndex:range.location+1];
                        SymbolModel *symbol = symbolMap[key];
                        if(symbol) {
                            symbol.size += size;
                            if( offset < self.dataOffset )
                            {
                                symbol.codeSize += size;
                            }
                        }
                    }
                }
            }
        }
    }
    NSMutableDictionary <NSString *,SymbolModel *>*combinedSymbolMap = [NSMutableDictionary new];
    for ( NSString* key in symbolMap ) {
        SymbolModel* checkingModel = [symbolMap objectForKey:key];
        if( [checkingModel.file hasSuffix:@")"] )
        {
            [combinedSymbolMap setObject:checkingModel forKey:key];
            continue;
        }
        BOOL matched = NO;
        for( SpecificModuleParser* parser in modules )
        {
            for( NSString* item in parser.items.allKeys )
            {
                NSString* filestr = [checkingModel.file lastPathComponent];
                if( [filestr isEqualToString:[NSString stringWithFormat:@"%@.o",item]] )
                {
                    SymbolModel* model = [combinedSymbolMap objectForKey:parser.name];
                    if( !model )
                    {
                        model = [SymbolModel new];
                        model.file = parser.name;
                        model.size = 0;
                        [combinedSymbolMap setObject:model forKey:parser.name];
                    }
                    model.size += checkingModel.size;
                    model.codeSize += checkingModel.codeSize;
                    NSNumber* num = [parser.items objectForKey:item];
                    [parser.items setObject:@(num.unsignedIntegerValue+1) forKey:item];
                    parser.assignCount += 1;
                    matched = YES;
                }
            }
        }
        if( !matched )
        {
            [combinedSymbolMap setObject:checkingModel forKey:key];
        }
    }
    return combinedSymbolMap;
}

- (NSArray *)sortSymbols:(NSArray *)symbols {
    NSArray *sortedSymbols = [symbols sortedArrayUsingComparator:^NSComparisonResult(SymbolModel *  _Nonnull obj1, SymbolModel *  _Nonnull obj2) {
        if(obj1.size > obj2.size) {
            return NSOrderedAscending;
        } else if (obj1.size < obj2.size) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    return sortedSymbols;
}

- (void)buildResultWithSymbols:(NSArray *)symbols {
    self.result = [@"文件大小\t文件名称\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    
    NSString *searchKey = _searchField.stringValue;
    
    for(SymbolModel *symbol in symbols) {
        if (searchKey.length > 0) {
            if ([symbol.file containsString:searchKey]) {
                [self appendResultWithSymbol:symbol result:self.result];
                totalSize += symbol.size;
            }
        } else {
            [self appendResultWithSymbol:symbol result:self.result];
            totalSize += symbol.size;
        }
    }
    
    [_result appendFormat:@"\r\n总大小: %.2fM\r\n",(totalSize/1024.0/1024.0)];
}


- (NSMutableString*)buildCombinationResultWithSymbols:(NSArray *)symbols groupedDic:(NSMutableDictionary* __strong *)dic{
    NSMutableString* str = [@"库大小\t\t库名称\t\t\t代码段大小\r\n\r\n" mutableCopy];
    NSUInteger totalSize = 0;
    
    NSMutableDictionary *combinationMap = [[NSMutableDictionary alloc] init];
    
    for(SymbolModel *symbol in symbols) {
        NSString *name = [[symbol.file componentsSeparatedByString:@"/"] lastObject];
        if ([name hasSuffix:@")"] &&
            [name containsString:@"("]) {
            NSRange range = [name rangeOfString:@"("];
            NSString *component = [name substringToIndex:range.location];
            
            SymbolModel *combinationSymbol = [combinationMap objectForKey:component];
            if (!combinationSymbol) {
                combinationSymbol = [[SymbolModel alloc] init];
                [combinationMap setObject:combinationSymbol forKey:component];
            }
            
            combinationSymbol.size += symbol.size;
            combinationSymbol.codeSize += symbol.codeSize;
            combinationSymbol.file = component;
        } else {
            // symbol可能来自app本身的目标文件或者系统的动态库，在最后的结果中一起显示
            [combinationMap setObject:symbol forKey:name];
        }
    }
    
    NSArray <SymbolModel *>*combinationSymbols = [combinationMap allValues];
    
    NSArray *sortedSymbols = [self sortSymbols:combinationSymbols];
    if( dic )
    {
        *dic = combinationMap;
    }
    
    NSString *searchKey = _searchField.stringValue;
    NSUInteger codesize = 0;
    for(SymbolModel *symbol in sortedSymbols) {
        if (searchKey.length > 0) {
            if ([symbol.file containsString:searchKey]) {
                [self appendResultWithSymbol:symbol result:str];
                totalSize += symbol.size;
            }
        } else {
            [self appendResultWithSymbol:symbol result:str];
            totalSize += symbol.size;
            codesize += symbol.codeSize;
        }
    }
    
    [str appendFormat:@"\r\n总大小: %.2fM, 代码:%.2fM\r\n",(totalSize/1024.0/1024.0),(codesize/1024.0/1024)];
    return str;
}

- (IBAction)ouputFile:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:NO];
    [panel setCanChooseDirectories:YES];
    [panel setResolvesAliases:NO];
    [panel setCanChooseFiles:NO];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
            NSMutableString *content =[[NSMutableString alloc]initWithCapacity:0];
            [content appendString:[theDoc path]];
            [content appendString:@"/linkMap.txt"];
            [_result writeToFile:content atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }];
}

- (void)appendResultWithSymbol:(SymbolModel *)model result:(NSMutableString*)result{
    NSString *size = nil;
    NSString* codesize = nil;
    NSNumber* limit = [self.config objectForKey:@"outputsizelimit"];
    if( labs(model.size) < limit.integerValue )
    {
        return;
    }
    if (model.size / 1024.0 / 1024.0 > 1) {
        size = [NSString stringWithFormat:@"%.2fM", model.size / 1024.0 / 1024.0];
    } else {
        size = [NSString stringWithFormat:@"%.2fK", model.size / 1024.0];
    }
    if( model.codeSize / 1024.0/1024.0 > 1 )
    {
        codesize = [NSString stringWithFormat:@"%.2fM", model.codeSize / 1024.0 / 1024.0];
    }else {
        codesize = [NSString stringWithFormat:@"%.2fK", model.codeSize / 1024.0];
    }
    [result appendFormat:@"%-10s%-40s%-10s\r\n",[size UTF8String], [[[model.file componentsSeparatedByString:@"/"] lastObject] UTF8String],[codesize UTF8String]];
}

- (BOOL)checkContent:(NSString *)content {
    NSRange objsFileTagRange = [content rangeOfString:@"# Object files:"];
    if (objsFileTagRange.length == 0) {
        return NO;
    }
    NSString *subObjsFileSymbolStr = [content substringFromIndex:objsFileTagRange.location + objsFileTagRange.length];
    NSRange symbolsRange = [subObjsFileSymbolStr rangeOfString:@"# Symbols:"];
    if ([content rangeOfString:@"# Path:"].length <= 0||objsFileTagRange.location == NSNotFound||symbolsRange.location == NSNotFound) {
        return NO;
    }
    return YES;
}

- (void)showAlertWithText:(NSString *)text {
    NSAlert *alert = [[NSAlert alloc]init];
    alert.messageText = text;
    [alert addButtonWithTitle:@"确定"];
    [alert beginSheetModalForWindow:[NSApplication sharedApplication].windows[0] completionHandler:^(NSModalResponse returnCode) {
    }];
}

@end
