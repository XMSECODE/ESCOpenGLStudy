//
//  ESCOpenGLHeader.h
//  ESCOpenGLStudy
//
//  Created by g on 2017/12/13.
//  Copyright © 2017年 xiang. All rights reserved.
//

#ifndef ESCOpenGLHeader_h
#define ESCOpenGLHeader_h


/**
 一个用于跟踪所有顶点信息的结构Vertex （目前只包含位置和颜色。）
 */
typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

//定义了以上面这个Vertex结构为类型的array。
const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {0, 1, 0, 1}},
    {{-1, 1, 0}, {0, 0, 1, 1}},
    {{-1, -1, 0}, {0, 0, 0, 1}}
};

//个用于表示三角形顶点的数组
const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0
};

#endif /* ESCOpenGLHeader_h */
