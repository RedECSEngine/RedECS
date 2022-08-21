import JavaScriptKit

public protocol WebGLProgram {
    var vertexShader: String { get }
    var fragmentShader: String { get }
    
    func execute(with webRenderer: WebRenderer) throws
}

extension WebGLProgram {
    func createProgram(with webRenderer: WebRenderer) throws -> JSValue {
        let gl = webRenderer.glContext
        let shaders = try setUpShaders(with: webRenderer)
        return try createProgram(gl: gl, vertexShader: shaders.vertex, fragmentShader: shaders.fragment)
    }
    
    private func setUpShaders(
        with webRenderer: WebRenderer
    ) throws -> (vertex: JSValue, fragment: JSValue) {
        let gl = webRenderer.glContext
        let vertexShader = try createShader(gl: gl, type: gl.VERTEX_SHADER, source: vertexShader)
        let fragmentShader = try createShader(gl: gl, type: gl.FRAGMENT_SHADER, source: fragmentShader)
        return (vertexShader, fragmentShader)
    }
    
    private func createProgram(
        gl: JSValue,
        vertexShader: JSValue,
        fragmentShader: JSValue
    ) throws -> JSValue {
        let program = gl.createProgram()
        _ = gl.attachShader(program, vertexShader)
        _ = gl.attachShader(program, fragmentShader)
        _ = gl.linkProgram(program)
        
        let success = gl.getProgramParameter(program, gl.LINK_STATUS)
        if success.boolean == true {
          return program
        }
        
        _ = gl.deleteProgram(program)
        
        throw WebGLError.couldNotCreateShader(gl.getProgramInfoLog(program).string)
    }

    private func createShader(gl: JSValue, type: JSValue, source: String) throws -> JSValue {
        let shader = gl.createShader(type)
        _ = gl.shaderSource(shader, source)
        _ = gl.compileShader(shader)
        
        let success = gl.getShaderParameter(shader, gl.COMPILE_STATUS)
        if success.boolean == true {
          return shader
        }
       
        _ = gl.deleteShader(shader)
        
        throw WebGLError.couldNotCreateShader(gl.getShaderInfoLog(shader).string)
    }
}

enum WebGLError: Error {
    case couldNotCreateShader(String?)
    case couldNotCreateProgram(String?)
    case couldNotCreateArray
}
