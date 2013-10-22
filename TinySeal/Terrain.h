//
//  Terrain.h
//  TinySeal
//
//  Created by Chao Xu on 13-10-9.
//  Copyright (c) 2013年 Chao Xu. All rights reserved.
//

#import "CCNode.h"
@class HelloWorldLayer;

@interface Terrain : CCNode

@property (retain) CCSprite * stripes;
- (void) setOffsetX:(float)newOffsetX;

@end
