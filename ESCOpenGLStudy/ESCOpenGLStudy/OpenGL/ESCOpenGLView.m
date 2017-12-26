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

@property(nonatomic,assign)GLuint frameBuffer;

@property(nonatomic,assign)GLuint vertexBuffer;

@property(nonatomic,assign)    GLuint indexBuffer;

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

    self.context = [EAGLContext currentContext];
    if (self.context != nil) {
        return YES;
    }


    NSLog(@"create context");
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

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    //把前面创建的buffer render依附在frame buffer的GL_COLOR_ATTACHMENT0位置上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.colorRenderBuffer);
}

//清理屏幕
- (void)render {
    //设置一个RGB颜色和透明度，接下来会用这个颜色涂满全屏
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    //填充颜色
    glClear(GL_COLOR_BUFFER_BIT);

    // 调用glViewport 设置UIView中用于渲染的部分。这个例子中指定了整个屏幕
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    /*
     调用glVertexAttribPointer来为vertex shader的两个输入参数配置两个合适的值。
     第二段这里，是一个很重要的方法，让我们来认真地看看它是如何工作的：
     ·第一个参数，声明这个属性的名称，之前我们称之为glGetAttribLocation
     ·第二个参数，定义这个属性由多少个值组成。譬如说position是由3个float（x,y,z）组成，而颜色是4个float（r,g,b,a）
     ·第三个，声明每一个值是什么类型。（这例子中无论是位置还是颜色，我们都用了GL_FLOAT）
     ·第四个，嗯……它总是false就好了。
     ·第五个，指 stride 的大小。这是一个种描述每个 vertex数据大小的方式。所以我们可以简单地传入 sizeof（Vertex），让编译器计算出来就好。
     ·最好一个，是这个数据结构的偏移量。表示在这个结构中，从哪里开始获取我们的值。Position的值在前面，所以传0进去就可以了。而颜色是紧接着位置的数据，而position的大小是3个float的大小，所以是从 3 * sizeof(float) 开始的。
     */
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (GLvoid *)(sizeof(float) * 3));

    /*
     调用glDrawElements ，它最后会在每个vertex上调用我们的vertex shader，以及每个像素调用fragment shader，最终画出我们的矩形
     第一个参数，声明用哪种特性来渲染图形。有GL_LINE_STRIP 和 GL_TRIANGLE_FAN。然而GL_TRIANGLE是最常用的，特别是与VBO 关联的时候。
     ·第二个，告诉渲染器有多少个图形要渲染。我们用到C的代码来计算出有多少个。这里是通过个 array的byte大小除以一个Indice类型的大小得到的。
     ·第三个，指每个indices中的index类型
     ·最后一个，在官方文档中说，它是一个指向index的指针。但在这里，我们用的是VBO，所以通过index的array就可以访问到了（在GL_ELEMENT_ARRAY_BUFFER传过了），所以这里不需要.
     */
    glDrawElements(GL_TRIANGLES, sizeof(Indices) / sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);

    //呈现到view上
    [_context presentRenderbuffer:GL_RENDERBUFFER];

    glDeleteBuffers(1, &_colorRenderBuffer);
    glDeleteFramebuffers(1, &_frameBuffer);
    glDeleteBuffers(sizeof(Vertices), &_vertexBuffer);
    glDeleteBuffers(sizeof(Indices), &_indexBuffer);

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
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);

    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);

}

@end
