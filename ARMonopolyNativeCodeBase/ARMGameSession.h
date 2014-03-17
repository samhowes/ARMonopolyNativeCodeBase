//
//  ARMGameSession.h
//  ARMonopolyNativeCodeBase
//
//  Created by Sam Howes on 3/14/14.
//  Copyright (c) 2014 Sam Howes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ARMGameSession : NSObject

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *ID;
@property (strong, nonatomic) NSMutableArray *players;

- (id)initWithName:(NSString *)sessionName withID:(NSString *)sessionID;

@end
