//
//  Terrain.m
//  TinySeal
//
//  Created by Chao Xu on 13-10-9.
//  Copyright (c) 2013年 Chao Xu. All rights reserved.
//

#import "Terrain.h"
#import "HelloWorldLayer.h"
#define  kMaxHillKeyPoints 1000
#define  kHillSegmentWidth 10
#define  kMaxHillVertices 4000
#define  kMaxBorderVertices 800
@interface Terrain(){
    int _offsetX;//an offset for how far the terrain is currently being scrolled
    
    CGPoint _hillKeyPoints[kMaxHillKeyPoints];
    //array called _hillKeyPoints where you’ll store all of the points representing the peak of each hill
    CCSprite *_stripes;
    int _fromKeyPointI;
    int _toKeyPointI;
    int _nHillVertices;
    CGPoint _hillVertices[kMaxHillVertices];
    CGPoint _hillTexCoords[kMaxHillVertices];
    int _nBorderVertices;
    CGPoint _borderVertices[kMaxBorderVertices];
}
@end

@implementation Terrain

-(void)generateHills{
    //generate the key points for some random hills
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    float minDX = 160;
    float minDY = 60;
    int rangeDX = 80;
    int rangeDY = 40;
    
    float x = -minDX;
    float y = winSize.height/2;
    
    float dy, ny;
    float sign = 1; // +1 - going up, -1 - going  down
    float paddingTop = 20;
    float paddingBottom = 20;
    for(int i=0;i<kMaxHillKeyPoints;i++){
        _hillKeyPoints[i] = CGPointMake(x, y);
        if (i == 0 ) {
            x = 0;
            y = winSize.height/2;
        }else{
            x += rand()%rangeDX+minDX;
            while (true) {
                dy = rand()%rangeDY+minDY;
                ny = y + dy*sign;
                if (ny < winSize.height - paddingTop && ny > paddingBottom) {
                    break;
                }
            }
            y = ny;
        }
        sign *= -1;
    }

}
-(void)resetHillVertices{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    static int prevFromKeyPointI = -1;
    static int prevTokeyPointI = -1;
    // key points interval for drawing
    while (_hillKeyPoints[_fromKeyPointI+1].x < _offsetX-winSize.width/8/self.scale) {
        _fromKeyPointI++;
    }
    while (_hillKeyPoints[_toKeyPointI].x < _offsetX+winSize.width*12/8/self.scale) {
        _toKeyPointI++;
    }
    //Drawing Hills
    float minY = 0;
    if (winSize.height > 480) {
        minY = (1136 - 1024)/4;
    }
    if (prevFromKeyPointI != _fromKeyPointI || prevTokeyPointI != _toKeyPointI) {
        
        // vertices for visible area
        _nHillVertices = 0;
        _nBorderVertices = 0;
        CGPoint p0, p1, pt0, pt1;
        p0 = _hillKeyPoints[_fromKeyPointI];
        for (int i=_fromKeyPointI+1; i<_toKeyPointI+1; i++) {
            p1 = _hillKeyPoints[i];
            
            // triangle strip between p0 and p1
            int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
            float dx = (p1.x - p0.x) / hSegments;
            float da = M_PI / hSegments;
            float ymid = (p0.y + p1.y) / 2;
            float ampl = (p0.y - p1.y) / 2;
            pt0 = p0;
            _borderVertices[_nBorderVertices++] = pt0;
            for (int j=1; j<hSegments+1; j++) {
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                _borderVertices[_nBorderVertices++] = pt1;
                
                _hillVertices[_nHillVertices] = CGPointMake(pt0.x, 0 + minY);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt0.x/512, 1.0f);
                _hillVertices[_nHillVertices] = CGPointMake(pt1.x, 0 + minY);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt1.x/512, 1.0f);
                
                _hillVertices[_nHillVertices] = CGPointMake(pt0.x, pt0.y);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt0.x/512, 0);
                _hillVertices[_nHillVertices] = CGPointMake(pt1.x, pt1.y);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt1.x/512, 0);
                
                pt0 = pt1;
            }
            
            p0 = p1;
        }
        
        prevFromKeyPointI = _fromKeyPointI;
        prevTokeyPointI = _toKeyPointI;        
    }
}
-(id)init{
    if ((self = [super init])) {
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
        [self generateHills];
        [self resetHillVertices];
    }
    return self;
}

-(void)draw{
    //draws lines between each of the points for debugging, so you can easily visualize them on the screen
    CC_NODE_DRAW_SETUP();
    ccGLBindTexture2D(_stripes.texture.name);
    ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords);
    ccDrawColor4F(1.0f, 1.0f, 1.0f, 1.0f);
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, _hillVertices);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, _hillTexCoords);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_nHillVertices);
    
    for (int i=MAX(_fromKeyPointI, 1); i < _toKeyPointI; ++i) {
        ccDrawColor4F(1.0, 0, 0, 1.0);//red color line
        ccDrawLine(_hillKeyPoints[i-1], _hillKeyPoints[i]);
        
        ccDrawColor4F(1.0, 1.0, 1.0, 1.0);
        
        CGPoint p0 = _hillKeyPoints[i-1];
        CGPoint p1 = _hillKeyPoints[i];
        int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
        float dx = (p1.x - p0.x) / hSegments;
        float da = M_PI / hSegments;
        float ymid = (p0.y + p1.y) / 2;
        float ampl = (p0.y - p1.y) / 2;
        
        CGPoint pt0, pt1;
        pt0 = p0;
        for (int j = 0; j < hSegments+1; ++j) {
            
            pt1.x = p0.x + j*dx;
            pt1.y = ymid + ampl * cosf(da*j);
            
            ccDrawLine(pt0, pt1);
            
            pt0 = pt1;
            
        }

    }
}

- (void) setOffsetX:(float)newOffsetX {
    _offsetX = newOffsetX;
    self.position = CGPointMake(-_offsetX*self.scale, 0);
    [self resetHillVertices];
}

- (void)dealloc {
    [_stripes release];
    _stripes = NULL;
    [super dealloc];
}


@end













































