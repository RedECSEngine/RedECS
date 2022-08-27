import JavaScriptKit
import Geometry
import RedECS
import GeometryAlgorithms

final class DrawTextureProgram {
    var triangles: [RenderTriangle]
    var textureSize: Size
    var image: JSValue
    
    var projectionMatrix: Matrix3
    var modelMatrix: Matrix3
    
    var program: JSValue?
    
    init(
        triangles: [RenderTriangle],
        textureSize: Size,
        image: JSValue,
        projectionMatrix: Matrix3,
        modelMatrix: Matrix3
    ) {
        self.triangles = triangles
        self.textureSize = textureSize
        self.image = image
        self.projectionMatrix = projectionMatrix
        self.modelMatrix = modelMatrix
    }
    
    func update(
        triangles: [RenderTriangle],
        textureSize: Size,
        image: JSValue,
        projectionMatrix: Matrix3,
        modelMatrix: Matrix3
    ) {
        self.triangles = triangles
        self.textureSize = textureSize
        self.image = image
        self.projectionMatrix = projectionMatrix
        self.modelMatrix = modelMatrix
    }
}

extension DrawTextureProgram: WebGLProgram {
    public func execute(with webRenderer: WebRenderer) throws {
        let gl = webRenderer.glContext
        let program: JSValue
        if let p = self.program {
            program = p
        } else {
            print("texture program create")
            let p = try createProgram(with: webRenderer)
            program = p
            self.program = p
        }
        
        let positionLocation = gl.getAttribLocation(program, "a_position")
        let texcoordLocation = gl.getAttribLocation(program, "a_texCoord")
        
        let projectionMatrixUniformLocation = gl.getUniformLocation(program, "u_projectionMatrix")
        let modelMatrixUniformLocation = gl.getUniformLocation(program, "u_modelMatrix")
        let textureSizeLocation = gl.getUniformLocation(program, "u_textureSize")
    
        // MARK: - Attributes
        
        let allTriangles = triangles.flatMap { renderTriangle in
            [
                renderTriangle.triangle.a.x, renderTriangle.triangle.a.y,
                renderTriangle.triangle.b.x, renderTriangle.triangle.b.y,
                renderTriangle.triangle.c.x, renderTriangle.triangle.c.y
            ]
        }
        
        guard let trianglesArrayData = JSObject.global.Float32Array.function?.new(allTriangles) else {
            throw WebGLError.couldNotCreateArray
        }
        
        // Bind the position buffer.
        let positionBuffer = gl.createBuffer()
        // Bind it to ARRAY_BUFFER (think of it as ARRAY_BUFFER = positionBuffer)
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
        _ = gl.bufferData(gl.ARRAY_BUFFER, trianglesArrayData, gl.STATIC_DRAW)
        
        let allTextureTriangles = triangles.flatMap { renderTriangle -> [Double] in
            guard let textureTriangle = renderTriangle.textureTriangle else { return [] }
            return [
                textureTriangle.a.x, textureTriangle.a.y,
                textureTriangle.b.x, textureTriangle.b.y,
                textureTriangle.c.x, textureTriangle.c.y
            ]
        }
        
        guard let textureTrianglesArrayData = JSObject.global.Float32Array.function?.new(allTextureTriangles) else {
            throw WebGLError.couldNotCreateArray
        }
        
        let texcoordBuffer = gl.createBuffer()
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer)
        _ = gl.bufferData(gl.ARRAY_BUFFER, textureTrianglesArrayData, gl.STATIC_DRAW);
        
        // Create a texture.
        let texture = gl.createTexture()
        _ = gl.bindTexture(gl.TEXTURE_2D, texture)
        
        // Set the parameters so we can render any size image.
        _ = gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true); // flip Y
        
        // alpha transparency support
        _ = gl.enable(gl.BLEND);
        _ = gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        
        // other texture parameters, nearest neighbour
        _ = gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        _ = gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        _ = gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
        _ = gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
        
        // Upload the image into the texture.
        _ = gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, self.image)
        
        // Tell WebGL how to convert from clip space to pixels
        _ = gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

        // Tell it to use our program (pair of shaders)
        _ = gl.useProgram(program)

        // Turn on the position attribute
        _ = gl.enableVertexAttribArray(positionLocation)
        // Bind the position buffer.
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
        
        // Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
        let size = 2          // 2 components per iteration
        let type: JSValue = gl.FLOAT   // the data is 32bit floats
        let normalize = false // don't normalize the data
        let stride = 0        // 0 = move forward size * sizeof(type) each iteration to get the next position
        let offset = 0        // start at the beginning of the buffer
        _ = gl.vertexAttribPointer(positionLocation, size, type, normalize, stride, offset)
        
        // Turn on the texcoord attribute
        _ = gl.enableVertexAttribArray(texcoordLocation);
        // bind the texcoord buffer.
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, texcoordBuffer);
        // Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
        let sizeT = 2          // 2 components per iteration
        let typeT: JSValue = gl.FLOAT   // the data is 32bit floats
        let normalizeT = false // don't normalize the data
        let strideT = 0        // 0 = move forward size * sizeof(type) each iteration to get the next position
        let offsetT = 0        // start at the beginning of the buffer
        _ = gl.vertexAttribPointer(texcoordLocation, sizeT, typeT, normalizeT, strideT, offsetT)
        
        // MARK: - Uniforms
        
        guard let projectionMatrixDataArray = JSObject.global.Float32Array.function?.new(projectionMatrix.values) else {
            throw WebGLError.couldNotCreateArray
        }
        _ = gl.uniformMatrix3fv(projectionMatrixUniformLocation, false, projectionMatrixDataArray);
        
        guard let modelMatrixDataArray = JSObject.global.Float32Array.function?.new(modelMatrix.values) else {
            throw WebGLError.couldNotCreateArray
        }
        _ = gl.uniformMatrix3fv(modelMatrixUniformLocation, false, modelMatrixDataArray);
        
        // set the textureSize
        _ = gl.uniform2f(textureSizeLocation, textureSize.width, textureSize.height);
        
        // MARK: - Draw

        // Draw the rectangle.
        _ = gl.drawArrays(gl.TRIANGLES, 0, triangles.count * 3);
    }
    
    var vertexShader: String {
    """
    attribute vec2 a_position;
    attribute vec2 a_texCoord;
    
    uniform mat3 u_projectionMatrix;
    uniform mat3 u_modelMatrix;
    uniform vec2 u_textureSize;
    
    varying vec2 v_texCoord;
    
    void main() {
        vec3 position = vec3(a_position, 1.0);
        gl_Position = vec4((u_projectionMatrix * u_modelMatrix * position).xy, 0.0, 1.0);
    
        vec2 zeroToOneTexture = a_texCoord / u_textureSize;
        v_texCoord = zeroToOneTexture;
    }
    """
    }
    
    var fragmentShader: String {
    """
    precision mediump float;
    
    // our texture
    uniform sampler2D u_image;
    
    // the texCoords passed in from the vertex shader.
    varying vec2 v_texCoord;
    
    void main() {
        vec4 color = texture2D(u_image, v_texCoord);
        if(color.w == 0.0) {
            gl_FragColor = color;
        } else {
            gl_FragColor = vec4(color.xyz, 1); //todo: read alpha from buffer
        }
    }
    """
    }
    
}

