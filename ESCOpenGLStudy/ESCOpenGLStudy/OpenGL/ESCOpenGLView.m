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
#import "ESCOpenGLHeader.h"

@interface ESCOpenGLView ()

@property(nonatomic,strong)CAEAGLLayer* caeaglLayer;

@property(nonatomic,strong)EAGLContext* context;

@property(nonatomic,assign)GLuint colorRenderBuffer;

@property(nonatomic,assign)    GLuint positionSlot;

@property(nonatomic,assign)GLuint colorSlot;

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
        //编译OpenGL
        [self compileShaders];

        [self setupVBOs];
        
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

    glViewport(0, 0, self.frame.size.width, self.frame.size.height);

    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));

    glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

    //呈现到view上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)compileShaders {
    //编译文件
    GLuint vertexShader = [self compileShader:@"SimpleVertex" type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment" type:GL_FRAGMENT_SHADER];

    //链接文件
    GLuint programeHandle = glCreateProgram();
    glAttachShader(programeHandle, vertexShader);
    glAttachShader(programeHandle, fragmentShader);
    glLinkProgram(programeHandle);


    //检查错误
    GLint linkSuccess;
    glGetProgramiv(programeHandle, GL_LINK_STATUS, &linkSuccess);
    if(linkSuccess == GL_FALSE) {
        GLchar messages[2560];
        glGetProgramInfoLog(programeHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error == %@",messageString);
        return;
    }

    //执行程序
    glUseProgram(programeHandle);

    //最后，调用 glGetAttribLocation 来获取指向 vertex shader传入变量的指针。以后就可以通过这写指针来使用了。还有调用 glEnableVertexAttribArray来启用这些数据。
    self.positionSlot = glGetAttribLocation(programeHandle, "Position");
    self.colorSlot = glGetAttribLocation(programeHandle, "SourceColor");
    glEnableVertexAttribArray(self.positionSlot);
    glEnableVertexAttribArray(self.colorSlot);
}

//编译OpenGL的shader文件
- (GLuint)compileShader:(NSString *)shaderName type:(GLenum)shadeType {
    //查找要编译文件的路径
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    //读取文件内容
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if(shaderString == nil) {
        NSLog(@"error == %@",error);
        return -1;
    }

    //调用glCreateShader来创建一个代表shader 的OpenGL对象，这时你必须告诉OpenGL，你想创建 fragment shader还是vertex shader。所以便有了这个参数：shaderType
    GLuint shaderHandle = glCreateShader(shadeType);

    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    //让OpenGL回去这个shader的源代码
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);

    //编译shader
    glCompileShader(shaderHandle);


    GLint compileSuccess;
    //判断编译是否成功
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if(compileSuccess == GL_FALSE) {
        GLchar messages[2560];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"error ===%@ ===%@",shaderName,messageString);
        return -1;
    }
    return shaderHandle;
}

- (void)setupVBOs {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);

    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

}

@end
