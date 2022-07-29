import JavaScriptKit
import Geometry
import RedECS

struct DrawTextureProgram {
    var triangles: [RenderTriangle]
    var textureMap: TextureMap
    var image: JSValue
    init(
        triangles: [RenderTriangle],
        textureMap: TextureMap,
        image: JSValue
    ) {
        self.triangles = triangles
        self.textureMap = textureMap
        self.image = image
    }
}

extension DrawTextureProgram: WebGLProgram {
    public func execute(with webRenderer: WebRenderer) throws {
        let gl = webRenderer.glContext
        let program = try createProgram(with: webRenderer)
        
        let positionLocation = gl.getAttribLocation(program, "a_position")
        let texcoordLocation = gl.getAttribLocation(program, "a_texCoord")
        let resolutionLocation = gl.getUniformLocation(program, "u_resolution")
        let textureSizeLocation = gl.getUniformLocation(program, "u_textureSize")
        
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
            guard case let .texture(_ , triangle) = renderTriangle.fragmentType else { return [] }
            return [
                triangle.a.x, triangle.a.y,
                triangle.b.x, triangle.b.y,
                triangle.c.x, triangle.c.y
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
        _ = gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        _ = gl.enable(gl.BLEND);
        
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
        
        // set the resolution
        _ = gl.uniform2f(resolutionLocation, gl.canvas.width, gl.canvas.height);
        
        // set the textureSize
        _ = gl.uniform2f(textureSizeLocation, textureMap.meta.size.w, textureMap.meta.size.h);

        // Draw the rectangle.
        _ = gl.drawArrays(gl.TRIANGLES, 0, triangles.count * 3);
    }
    
    var vertexShader: String {
    """
    attribute vec2 a_position;
    attribute vec2 a_texCoord;
    
    uniform vec2 u_resolution;
    uniform vec2 u_textureSize;
    
    varying vec2 v_texCoord;
    
    void main() {
        // convert the rectangle from pixels to 0.0 to 1.0
        vec2 zeroToOnePosition = a_position / u_resolution;
        // convert from 0->1 to 0->2
        vec2 zeroToTwoPosition = zeroToOnePosition * 2.0;
        // convert from 0->2 to -1->+1 (clipspace)
        vec2 clipSpacePosition = zeroToTwoPosition - 1.0;
        gl_Position = vec4(clipSpacePosition, 0, 1);
    
        vec2 zeroToOneTexture = a_texCoord / u_textureSize;
        // pass the texCoord to the fragment shader
        // The GPU will interpolate this value between points.
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
       gl_FragColor = texture2D(u_image, v_texCoord);
    }
    """
    }
    
}

