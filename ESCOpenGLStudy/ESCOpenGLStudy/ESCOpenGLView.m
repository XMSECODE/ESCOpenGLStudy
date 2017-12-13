//
//  ESCOpenGLView.m
//  ESCOpenGLStudy
//
//  Created by g on 2017/12/13.
//  Copyright © 2017年 xiang. All rights reserved.
//

#import "ESCOpenGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ESCOpenGLView ()

@property(nonatomic,strong)CAEAGLLayer* caeaglLayer;

@property(nonatomic,strong)EAGLContext* context;

@property(nonatomic,assign)GLuint colorRenderBuffer;

@end

@implementation ESCOpenGLView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        //设置layer为不透明
        [self setupLayer];
        //创建OpenGL上下文
        [self setupContext];
        //创建render buffer （渲染缓冲区）
        [self setupRenderBuffer];
        //创建一个 frame buffer （帧缓冲区）
        [self setupFrameBuffer];
        //清理屏幕
        [self render];
    }
    return self;
}


//设置layoutclass为CAEAGLLayer类型
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

//设置layer为不透明
- (void)setupLayer {
    self.caeaglLayer = (CAEAGLLayer *)self.layer;
    self.caeaglLayer.opaque = YES;
}

//创建OpenGL上下文
- (BOOL)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    self.context = [[EAGLContext alloc] initWithAPI:api];
    if(self.context == nil) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        return NO;
    }
    BOOL setContextIsSuccess = [EAGLContext setCurrentContext:self.context];
    if(setContextIsSuccess == YES) {
        return YES;
    }else {
        NSLog(@"Failed to set current OpenGL context");
        return NO;
    }
}

//创建render buffer （渲染缓冲区）
- (void)setupRenderBuffer {
    //创建新的render buffer object，返回一个integer来标记render buffer
    glGenRenderbuffers(1, &_colorRenderBuffer);
    //调用glBindRenderbuffer ，告诉这个OpenGL：我在后面引用GL_RENDERBUFFER的地方，其实是想用_colorRenderBuffer。其实就是告诉OpenGL，我们定义的buffer对象是属于哪一种OpenGL对象
    glBindRenderbuffer(GL_RENDERBUFFER, self.colorRenderBuffer);
    //最后，为render buffer分配空间。renderbufferStorage
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.caeaglLayer];
}

//创建一个 frame buffer （帧缓冲区）
- (void)setupFrameBuffer {
    //类似上面的colorbuffer
    GLuint frameBuffer;
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);
    //把前面创建的buffer render依附在frame buffer的GL_COLOR_ATTACHMENT0位置上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderBuffer);
}

//清理屏幕
- (void)render {
    //设置一个RGB颜色和透明度，接下来会用这个颜色涂满全屏
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    //填充颜色
    glClear(GL_COLOR_BUFFER_BIT);
    //呈现到view上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
