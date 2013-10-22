//
//  HelloWorldLayer.mm
//  TinySeal
//
//  Created by Chao Xu on 13-10-7.
//  Copyright Chao Xu 2013年. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"
#import "Terrain.h"
#pragma mark - HelloWorldLayer

@interface HelloWorldLayer(){
    CCSprite *_background;
    Terrain *_terrain;
}
@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}
-(CCSprite *)spriteWithColor:(ccColor4F)bgColor textureWidth:(float)textureWidth textureHeight:(float)textureHeight{
    //1Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureWidth height:textureHeight];
    //2Call ccrendertexture:begin
    [rt beginWithClear:bgColor.r g:bgColor.g b:bgColor.b a:bgColor.a];//beginWithClear:g:b:a: that clears the texture with a particular color before drawing
    
    
    //Adding a gradient to the Texture
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
    
    CC_NODE_DRAW_SETUP();
    //3:Draw into the texture
    //Applying Noise to Texture
    float gradientAlpha = 0.7f;
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    vertices[nVertices] = CGPointMake(0, 0);//top left
    colors[nVertices++] = (ccColor4F){0,0,0,0};
    vertices[nVertices] = CGPointMake(textureWidth, 0);//top right
    colors[nVertices++] = (ccColor4F){0,0,0,0};
    vertices[nVertices] = CGPointMake(0, textureHeight);//bottom left
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureWidth, textureHeight);//bottom right
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color);
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_FALSE, 0, colors);
    glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR,GL_ZERO}];//the first constant passed in (GL_DST_COLOR) specifies how to multiply the incoming/source color (which is the noise texture), and the second constant passed in (GL_ZERO) specifies how to multiply the existing/destination color (which is the colored texture).The existing color is multiplied by GL_ZERO, which means the existing color is cleared out.
    
    //The noise texture colors are multiplied by GL_DST_COLOR. GL_DST_COLOR means the existing colors, so the noise texture colors are multiplied by the existing color. So the more “white” in the noise, the more of the existing color appears, but the more “black” in the noise the darker the existing color is.

    noise.position = ccp(textureWidth/2, textureHeight/2);
    [noise visit];
    //4 call ccrendertexture:end
    [rt end];
    //5 create a new sprite from the texture
    return  [CCSprite spriteWithTexture:rt.sprite.texture];
}

-(ccColor4F)randomBrightColor{
    //randomBrightColor is a helper method to create a random color. Note it uses ccc4B (so you can specify the R/G/B/A values in the 0-255 range), and makes sure at least one of them is > 192 so you don’t get dark colors
    while (true) {
        float requiredBrightness = 192;
        ccColor4B randomColor = ccc4(arc4random()%255, arc4random()%255, arc4random()%255, 255);
        if (randomColor.r > requiredBrightness || randomColor.g > requiredBrightness ||randomColor.b > requiredBrightness) {
            //converts to a ccc4F
            return  ccc4FFromccc4B(randomColor);
        }
    }
}
-(void)genBackground {
    //Then genBackground method calls the spriteWithColor:textureWidth:textureHeight: method you just wrote, and adds it to the center of the screen.
    
    [_background removeFromParentAndCleanup:YES];
    ccColor4F bgColor = [self randomBrightColor];
   // ccColor4F color2 = [self randomBrightColor];
  //  int nStripes = ((arc4random()%4)+1)*2;
    _background = [self spriteWithColor:bgColor textureWidth:IS_IPHONE_5 ? 1024:512 textureHeight:512];
  //  _background = [self stripedSpriteWithColor1:bgColor color2:color2 textureWidth:IS_IPHONE_5?1024:512 textureHeight:512 stripes:nStripes];
   // self.scale = 0.5;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(winSize.width/2, winSize.height/2);
    ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [_background.texture setTexParameters:&tp];
    
    [self addChild:_background];
    
    ccColor4F color3 = [self randomBrightColor];
    ccColor4F color4 = [self randomBrightColor];
    CCSprite *stripes = [self stripedSpriteWithColor1:color3 color2:color4
                                         textureWidth:IS_IPHONE_5 ? 1024:512    textureHeight:512 stripes:4];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    _terrain.stripes = stripes;
}

-(void)onEnter{
    
    [super onEnter];
    
    _terrain = [Terrain node];
    [self addChild:_terrain z:1];
    
    [self genBackground];
    [self setTouchEnabled:YES];
    [self scheduleUpdate];
}
-(void)update:(ccTime)dt{
    float PIXELS_PER_SECOND = 100;
    static float offset = 0;
    offset += PIXELS_PER_SECOND;
    [_terrain setOffsetX:offset];
}
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self genBackground];
}

-(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureWidth:(float)textureWidth
                       textureHeight:(float)textureHeight stripes:(int)nStripes {
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureWidth height:textureHeight];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
    
    // 3: Draw into the texture
    
    // Layer 1: Stripes
    CGPoint vertices[nStripes*6];
    ccColor4F colors[nStripes*6];
    
    int nVertices = 0;
    float x1 = -textureHeight;
    float x2;
    float y1 = textureHeight;
    float y2 = 0;
    float dx = textureWidth / nStripes * 2;
    float stripeWidth = dx/2;
    for (int i=0; i<nStripes; i++) {
        x2 = x1 + textureHeight;
        
        vertices[nVertices] = CGPointMake(x1, y1);
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        
        vertices[nVertices] = CGPointMake(x1+stripeWidth, y1);
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        
        vertices[nVertices] = CGPointMake(x2, y2);
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        
        vertices[nVertices] = vertices[nVertices-2];
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        
        vertices[nVertices] = vertices[nVertices-2];
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        
        vertices[nVertices] = CGPointMake(x2+stripeWidth, y2);
        colors[nVertices++] = (ccColor4F){c2.r, c2.g, c2.b, c2.a};
        x1 += dx;
    }
    self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];
    //layer 2:noise
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR,GL_ZERO}];
    noise.position = ccp(textureWidth/2, textureHeight/2);
    [noise visit];
    //layer 3:stripes
    CC_NODE_DRAW_SETUP();
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_TRUE, 0, colors);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
    float gradientAlpha = 0.7;
    
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    vertices[nVertices] = CGPointMake(textureWidth, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    vertices[nVertices] = CGPointMake(0, textureHeight);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    vertices[nVertices] = CGPointMake(textureWidth, textureHeight);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_TRUE, 0, colors);
    glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    // layer 3: top highlight
    float borderHeight = textureHeight/16;
    float borderAlpha = 0.3f;
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){100, 10, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(textureWidth, 0);
    colors[nVertices++] = (ccColor4F){111, 11, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(0, borderHeight);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    vertices[nVertices] = CGPointMake(textureWidth, borderHeight);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_FLOAT, GL_TRUE, 0, colors);
    glBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    //4: Call ccrendertexture:end
    [rt end];
    //5 create a new sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
    
}



-(id) init
{
	if( (self=[super init])) {
		self.scale = 1.0;
		
	}
	return self;
}
@end




























