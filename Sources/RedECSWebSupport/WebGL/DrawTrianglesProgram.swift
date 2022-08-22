import JavaScriptKit
import RedECS
import Geometry
import GeometryAlgorithms

struct DrawTrianglesProgram {
    var triangles: [RenderTriangle]
    var color: Color
    
    var projectionMatrix: Matrix3
    var modelMatrix: Matrix3
    
    init(
        triangles: [RenderTriangle],
        color: Color,
        projectionMatrix: Matrix3,
        modelMatrix: Matrix3
    ) {
        self.triangles = triangles
        self.color = color
        self.projectionMatrix = projectionMatrix
        self.modelMatrix = modelMatrix
    }
}

extension DrawTrianglesProgram: WebGLProgram {
    func execute(with webRenderer: WebRenderer) throws {
        let gl = webRenderer.glContext
        let program = try self.createProgram(with: webRenderer)

        // look up where data locations
        let positionAttributeLocation = gl.getAttribLocation(program, "a_position")
        let colorLocation = gl.getAttribLocation(program, "a_color");
        let projectionMatrixUniformLocation = gl.getUniformLocation(program, "u_projectionMatrix")
        let modelMatrixUniformLocation = gl.getUniformLocation(program, "u_modelMatrix")
        
        let positionBuffer = gl.createBuffer()
        let colorBuffer = gl.createBuffer()
        
        // Tell WebGL how to convert from clip space to pixels
        _ = gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

        // Tell it to use our program (pair of shaders)
        _ = gl.useProgram(program)

        // Turn on the attributes
        _ = gl.enableVertexAttribArray(positionAttributeLocation)
        _ = gl.enableVertexAttribArray(colorLocation);

        guard let projectionMatrixDataArray = JSObject.global.Float32Array.function?.new(projectionMatrix.values) else {
            throw WebGLError.couldNotCreateArray
        }
        _ = gl.uniformMatrix3fv(projectionMatrixUniformLocation, false, projectionMatrixDataArray);
        
        guard let modelMatrixDataArray = JSObject.global.Float32Array.function?.new(modelMatrix.values) else {
            throw WebGLError.couldNotCreateArray
        }
        _ = gl.uniformMatrix3fv(modelMatrixUniformLocation, false, modelMatrixDataArray);
        
        // MARK: Position
        
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
        // Tell the attribute how to get data out of positionBuffer (ARRAY_BUFFER)
        let size = 2          // 2 components per iteration
        let type: JSValue = gl.FLOAT   // the data is 32bit floats
        let normalize = false // don't normalize the data
        let stride = 0        // 0 = move forward size * sizeof(type) each iteration to get the next position
        let offset = 0        // start at the beginning of the buffer
        _ = gl.vertexAttribPointer(positionAttributeLocation, size, type, normalize, stride, offset)
        
        // MARK: Color
        
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer)
        // Tell the color attribute how to get data out of colorBuffer (ARRAY_BUFFER)
        let sizeC = 4          // 4 components per iteration
        let typeC: JSValue = gl.FLOAT   // the data is 32bit floats
        let normalizeC = false // don't normalize the data
        let strideC = 0        // 0 = move forward size * sizeof(type) each iteration to get the next position
        let offsetC = 0        // start at the beginning of the buffer
        _ = gl.vertexAttribPointer(colorLocation, sizeC, typeC, normalizeC, strideC, offsetC)
        
        let allTriangles = triangles.flatMap { renderTriangle in
            [
                renderTriangle.triangle.a.x, renderTriangle.triangle.a.y,
                renderTriangle.triangle.b.x, renderTriangle.triangle.b.y,
                renderTriangle.triangle.c.x, renderTriangle.triangle.c.y
            ]
        }
        
        let allColors = triangles.flatMap { triangle -> [Double] in
            return [
                color.red, color.green, color.blue, color.alpha,
                color.red, color.green, color.blue, color.alpha,
                color.red, color.green, color.blue, color.alpha
            ]
        }

        guard let trianglesArrayData = JSObject.global.Float32Array.function?.new(allTriangles) else {
            throw WebGLError.couldNotCreateArray
        }
        
        guard let colorsArrayData = JSObject.global.Float32Array.function?.new(allColors) else {
            throw WebGLError.couldNotCreateArray
        }

        // Bind the position buffer.
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
        _ = gl.bufferData(gl.ARRAY_BUFFER, trianglesArrayData, gl.STATIC_DRAW)
        
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
        _ = gl.bufferData(gl.ARRAY_BUFFER, colorsArrayData, gl.STATIC_DRAW)
        
        _ = gl.drawArrays(gl.TRIANGLES, 0, triangles.count * 3);
    }
    
    var vertexShader: String {
    """
    attribute vec2 a_position;
    attribute vec4 a_color;
    
    uniform mat3 u_projectionMatrix;
    uniform mat3 u_modelMatrix;
    
    varying vec4 v_color;
    
    void main() {
        vec3 position = vec3(a_position, 1.0);
        gl_Position = vec4((u_projectionMatrix * u_modelMatrix * position).xy, 0.0, 1.0);
        v_color = a_color;
    }
    """
    }
    
    var fragmentShader: String {
    """
    // fragment shaders don't have a default precision so we need
    // to pick one. mediump is a good default
    precision mediump float;

    varying vec4 v_color;
    
    void main() {
        gl_FragColor = v_color;
    }
    """
    }
}
