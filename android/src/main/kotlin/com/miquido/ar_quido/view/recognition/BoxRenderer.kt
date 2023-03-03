package com.miquido.ar_quido.view.recognition

import android.opengl.GLES30

import java.nio.FloatBuffer
import java.nio.ShortBuffer

import javax.microedition.khronos.egl.EGL10
import javax.microedition.khronos.egl.EGLContext

import cn.easyar.Vec2F
import cn.easyar.Matrix44F

// all methods of this class can only be called on one thread with the same OpenGLES context
class BoxRenderer {
    private var currentContext: EGLContext? = null
    private val programBox: Int
    private val posCoordBox: Int
    private val posColorBox: Int
    private val posTransBox: Int
    private val posProjBox: Int
    private val vboCoordBox: Int
    private val vboFacesBox: Int

    private val box_vert = ("uniform mat4 trans;\n"
        + "uniform mat4 proj;\n"
        + "attribute vec4 coord;\n"
        + "\n"
        + "void main(void) {\n"
        + "    gl_Position = proj*trans*coord;\n"
        + "}\n"
        + "\n")

    private val box_frag = ("#ifdef GL_ES\n"
        + "precision highp float;\n"
        + "#endif\n"
        + "uniform vec4 vcolor;\n"
        + "\n"
        + "void main(void) {\n"
        + "    gl_FragColor = vcolor;\n"
        + "}\n"
        + "\n")

    init {
        val boxColor = floatArrayOf(0.8f, 0.8f, 1f, 0.4f)
        currentContext = (EGLContext.getEGL() as EGL10).eglGetCurrentContext()
        programBox = GLES30.glCreateProgram()
        val vertShader = GLES30.glCreateShader(GLES30.GL_VERTEX_SHADER).also {
            GLES30.glShaderSource(it, box_vert)
            GLES30.glCompileShader(it)
        }
        val fragShader = GLES30.glCreateShader(GLES30.GL_FRAGMENT_SHADER).also {
            GLES30.glShaderSource(it, box_frag)
            GLES30.glCompileShader(it)
        }
        GLES30.glAttachShader(programBox, vertShader)
        GLES30.glAttachShader(programBox, fragShader)
        GLES30.glLinkProgram(programBox)
        GLES30.glUseProgram(programBox)
        GLES30.glDeleteShader(vertShader)
        GLES30.glDeleteShader(fragShader)
        posCoordBox = GLES30.glGetAttribLocation(programBox, "coord")
        posColorBox = GLES30.glGetUniformLocation(programBox, "vcolor").also { GLES30.glUniform4fv(it, 1, boxColor, 0) }
        posTransBox = GLES30.glGetUniformLocation(programBox, "trans")
        posProjBox = GLES30.glGetUniformLocation(programBox, "proj")

        vboCoordBox = generateOneBuffer()
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vboCoordBox)

        vboFacesBox = generateOneBuffer()
        GLES30.glBindBuffer(GLES30.GL_ELEMENT_ARRAY_BUFFER, vboFacesBox)
        val cubeFaces = arrayOf(
            /* +x */ shortArrayOf(0, 1, 5, 4),
            /* -x */ shortArrayOf(3, 7, 6, 2),
            /* +y */ shortArrayOf(0, 4, 7, 3),
            /* -y */ shortArrayOf(1, 2, 6, 5),
            /* +z */ shortArrayOf(0, 3, 2, 1),
            /* -z */ shortArrayOf(4, 5, 6, 7)
        )
        val cubeFacesBuffer = ShortBuffer.wrap(flatten(cubeFaces))
        GLES30.glBufferData(GLES30.GL_ELEMENT_ARRAY_BUFFER, cubeFacesBuffer.limit() * 2, cubeFacesBuffer, GLES30.GL_STATIC_DRAW)
    }

    fun render(projectionMatrix: Matrix44F, cameraView: Matrix44F, size: Vec2F) {
        val size0 = size.data[0]
        val size1 = size.data[1]

        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vboCoordBox)
        val height = size0 / 1000
        val cubeVertices = arrayOf(
            /* +z */
            floatArrayOf(size0 / 2, size1 / 2, height / 2),
            floatArrayOf(size0 / 2, -size1 / 2, height / 2),
            floatArrayOf(-size0 / 2, -size1 / 2, height / 2),
            floatArrayOf(-size0 / 2, size1 / 2, height / 2),
            /* -z */
            floatArrayOf(size0 / 2, size1 / 2, 0f),
            floatArrayOf(size0 / 2, -size1 / 2, 0f),
            floatArrayOf(-size0 / 2, -size1 / 2, 0f),
            floatArrayOf(-size0 / 2, size1 / 2, 0f)
        )
        val cubeVerticesBuffer = FloatBuffer.wrap(flatten(cubeVertices))
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, cubeVerticesBuffer.limit() * 4, cubeVerticesBuffer, GLES30.GL_DYNAMIC_DRAW)

        GLES30.glEnable(GLES30.GL_BLEND)
        GLES30.glBlendFunc(GLES30.GL_SRC_ALPHA, GLES30.GL_ONE_MINUS_SRC_ALPHA)
        GLES30.glEnable(GLES30.GL_DEPTH_TEST)
        GLES30.glUseProgram(programBox)
        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vboCoordBox)
        GLES30.glEnableVertexAttribArray(posCoordBox)
        GLES30.glVertexAttribPointer(posCoordBox, 3, GLES30.GL_FLOAT, false, 0, 0)
        GLES30.glEnableVertexAttribArray(posColorBox)
        GLES30.glVertexAttribPointer(posColorBox, 1, GLES30.GL_UNSIGNED_BYTE, true, 0, 0)
        GLES30.glUniformMatrix4fv(posTransBox, 1, false, getGLMatrix(cameraView), 0)
        GLES30.glUniformMatrix4fv(posProjBox, 1, false, getGLMatrix(projectionMatrix), 0)
        GLES30.glBindBuffer(GLES30.GL_ELEMENT_ARRAY_BUFFER, vboFacesBox)
        for (i in 0..5) {
            GLES30.glDrawElements(GLES30.GL_TRIANGLE_FAN, 4, GLES30.GL_UNSIGNED_SHORT, i * 4 * 2)
        }

        GLES30.glBindBuffer(GLES30.GL_ARRAY_BUFFER, vboCoordBox)
        val cubeVertices2 = arrayOf(
            /* +z */
            floatArrayOf(size0 / 2, size1 / 2, size0 / 2),
            floatArrayOf(size0 / 2, -size1 / 2, size0 / 2),
            floatArrayOf(-size0 / 2, -size1 / 2, size0 / 2),
            floatArrayOf(-size0 / 2, size1 / 2, size0 / 2),
            /* -z */
            floatArrayOf(size0 / 2, size1 / 2, 0f),
            floatArrayOf(size0 / 2, -size1 / 2, 0f),
            floatArrayOf(-size0 / 2, -size1 / 2, 0f),
            floatArrayOf(-size0 / 2, size1 / 2, 0f)
        )
        val cubeVertices2Buffer = FloatBuffer.wrap(flatten(cubeVertices2))
        GLES30.glBufferData(GLES30.GL_ARRAY_BUFFER, cubeVertices2Buffer.limit() * 4, cubeVertices2Buffer, GLES30.GL_DYNAMIC_DRAW)
        GLES30.glEnableVertexAttribArray(posCoordBox)
        GLES30.glVertexAttribPointer(posCoordBox, 3, GLES30.GL_FLOAT, false, 0, 0)
        GLES30.glEnableVertexAttribArray(posColorBox)
        GLES30.glVertexAttribPointer(posColorBox, 1, GLES30.GL_UNSIGNED_BYTE, true, 0, 0)
        for (i in 0..5) {
            GLES30.glDrawElements(GLES30.GL_TRIANGLE_FAN, 4, GLES30.GL_UNSIGNED_SHORT, i * 4 * 2)
        }
    }

    fun dispose() {
        if ((EGLContext.getEGL() as EGL10).eglGetCurrentContext() == currentContext) { //destroy resources unless the context has lost
            GLES30.glDeleteProgram(programBox)
            deleteOneBuffer(vboCoordBox)
            deleteOneBuffer(vboFacesBox)
        }
    }

    private fun flatten(a: Array<FloatArray>): FloatArray {
        var size = 0
        run {
            var k = 0
            while (k < a.size) {
                size += a[k].size
                k += 1
            }
        }
        val l = FloatArray(size)
        var offset = 0
        var k = 0
        while (k < a.size) {
            System.arraycopy(a[k], 0, l, offset, a[k].size)
            offset += a[k].size
            k += 1
        }
        return l
    }

    private fun flatten(a: Array<ShortArray>): ShortArray {
        var size = 0
        run {
            var k = 0
            while (k < a.size) {
                size += a[k].size
                k += 1
            }
        }
        val l = ShortArray(size)
        var offset = 0
        var k = 0
        while (k < a.size) {
            System.arraycopy(a[k], 0, l, offset, a[k].size)
            offset += a[k].size
            k += 1
        }
        return l
    }

    private fun generateOneBuffer(): Int {
        val buffer = intArrayOf(0)
        GLES30.glGenBuffers(1, buffer, 0)
        return buffer[0]
    }

    private fun deleteOneBuffer(id: Int) {
        val buffer = intArrayOf(id)
        GLES30.glDeleteBuffers(1, buffer, 0)
    }

    private fun getGLMatrix(m: Matrix44F): FloatArray {
        val d = m.data
        return floatArrayOf(d[0], d[4], d[8], d[12], d[1], d[5], d[9], d[13], d[2], d[6], d[10], d[14], d[3], d[7], d[11], d[15])
    }
}
