import JavaScriptKit
import Geometry
import RedECS

struct DrawTrianglesProgram {
    var triangles: [RenderTriangle]
    init(triangles: [RenderTriangle]) {
        self.triangles = triangles
    }
}

extension DrawTrianglesProgram: WebGLProgram {
    func execute(with webRenderer: WebRenderer) throws {
        let gl = webRenderer.glContext
        let program = try self.createProgram(with: webRenderer)

        // look up where data locations
        let positionAttributeLocation = gl.getAttribLocation(program, "a_position")
        let matrixLocation = gl.getAttribLocation(program, "a_matrix")
        let colorLocation = gl.getAttribLocation(program, "a_color");
        let resolutionUniformLocation = gl.getUniformLocation(program, "u_resolution")
        
        // Create a buffer for the colors.
        // Create a buffer and put three 2d clip space points in it
        let positionBuffer = gl.createBuffer()
        let colorBuffer = gl.createBuffer()
        let matrixBuffer = gl.createBuffer()
        
        //
        // code above this line is initialization code.
        // code below this line is rendering code.
        //

        // Tell WebGL how to convert from clip space to pixels
        _ = gl.viewport(0, 0, gl.canvas.width, gl.canvas.height)

        // Tell it to use our program (pair of shaders)
        _ = gl.useProgram(program)

        // Turn on the attributes
        _ = gl.enableVertexAttribArray(positionAttributeLocation)
        _ = gl.enableVertexAttribArray(colorLocation);

        // set the resolution
        _ = gl.uniform2f(resolutionUniformLocation, gl.canvas.width, gl.canvas.height);

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
        
        // MARK: Matrix
        for i in 0..<3 {
            _ = gl.enableVertexAttribArray(matrixLocation.number! + Double(i))
            _ = gl.bindBuffer(gl.ARRAY_BUFFER, matrixBuffer)
            _ = gl.vertexAttribPointer(matrixLocation.number! + Double(i), 3, gl.FLOAT, 0, 36, i * 12);
        }
        
        let allTriangles = triangles.flatMap { renderTriangle in
            [
                renderTriangle.triangle.a.x, renderTriangle.triangle.a.y,
                renderTriangle.triangle.b.x, renderTriangle.triangle.b.y,
                renderTriangle.triangle.c.x, renderTriangle.triangle.c.y
            ]
        }
        
        let allColors = triangles.flatMap { triangle -> [Double] in
            guard case let .color(color) = triangle.fragmentType else { return [] }
            return [
                color.red, color.green, color.blue, color.alpha,
                color.red, color.green, color.blue, color.alpha,
                color.red, color.green, color.blue, color.alpha
            ]
        }
        
        let allMatrixTransforms = triangles.flatMap {
            [$0.transformMatrix.values, $0.transformMatrix.values, $0.transformMatrix.values].flatMap { $0 }
        }

        guard let trianglesArrayData = JSObject.global.Float32Array.function?.new(allTriangles) else {
            throw WebGLError.couldNotCreateArray
        }
        
        guard let colorsArrayData = JSObject.global.Float32Array.function?.new(allColors) else {
            throw WebGLError.couldNotCreateArray
        }
        
        guard let matrixArrayData = JSObject.global.Float32Array.function?.new(allMatrixTransforms) else {
            throw WebGLError.couldNotCreateArray
        }
        
        // Bind the position buffer.
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer)
        _ = gl.bufferData(gl.ARRAY_BUFFER, trianglesArrayData, gl.STATIC_DRAW)
        
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
        _ = gl.bufferData(gl.ARRAY_BUFFER, colorsArrayData, gl.STATIC_DRAW)
        
        _ = gl.bindBuffer(gl.ARRAY_BUFFER, matrixBuffer)
        _ = gl.bufferData(gl.ARRAY_BUFFER, matrixArrayData, gl.STATIC_DRAW)
        
        _ = gl.drawArrays(gl.TRIANGLES, 0, triangles.count * 3);
    }
    
    var vertexShader: String {
    """
                    attribute vec2 a_position;
                    attribute mat3 a_matrix;
                    attribute vec4 a_color;
            
                    varying vec4 v_color;
                    
                    uniform vec2 u_resolution;
                    
                    void main() {
            //
            // POSITION
            //
    
            // Multiply the position by the matrix.
            vec2 position = (a_matrix * vec3(a_position, 1)).xy;
    
                        // convert the position from pixels to 0.0 to 1.0
                        vec2 zeroToOne = position / u_resolution;
                    
                        // convert from 0->1 to 0->2
                        vec2 zeroToTwo = zeroToOne * 2.0;
                    
                        // convert from 0->2 to -1->+1 (clip space)
                        vec2 clipSpace = zeroToTwo - 1.0;
                    
                        gl_Position = vec4(clipSpace, 0, 1);

                        // gl_Position = vec4(clipSpace * vec2(1, -1), 0, 1); // flipped Y
            //
            // COLOR
            //
            
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
