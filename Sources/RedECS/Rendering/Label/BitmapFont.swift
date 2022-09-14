public struct BitmapFont: Codable {
    public var info: Info
    public var common: Common
    public var page: Page
    public var characters: [Character]
    public var characterMap: [String: Character] = [:]
    
    /*
     info face="Arial Black" size=64 bold=1 italic=0 charset="" unicode=0 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=2,2
     common lineHeight=90 base=70 scaleW=490 scaleH=547 pages=1 packed=0
     page id=0 file="myFont.png"
     chars count=95
     char id=32     x=486   y=459   width=0     height=0     xoffset=0     yoffset=74    xadvance=21    page=0  chnl=0  letter="space"
     char id=33     x=166   y=358   width=22    height=54    xoffset=3     yoffset=20    xadvance=21    page=0  chnl=0  letter="!"
     kernings count=241
     kerning first=89 second=112 amount=-3
     */
    
    public init(fromString textData: String) throws {
        var info: Info?
        var common: Common?
        var page: Page?
        var characters: [Character] = []
        
        let lines = textData.split(separator: "\n")
        for line in lines {
            let properties = line.split(separator: " ")
            let type = properties[0]
            
            let props: [(Substring, Substring)] = properties.dropFirst().map { property in
                let parts = property.split(separator: "=")
                return (parts[0], parts[1])
            }
            switch type {
            case "info":
                info = Info(props)
            case "common":
                common = Common(props)
            case "page":
                page = Page(props)
            case "char":
                characters.append(Character(props))
            default: break
            }
        }
        
        guard let info = info, let page = page, let common = common else {
            throw BitmapFontError.missingInfoOrPropsData
        }
        
        self.info = info
        self.common = common
        self.page = page
        self.characters = characters
        self.characterMap = characters.reduce(into: [:]) { partialResult, char in
            partialResult[char.letter] = char
        }
    }
}

extension BitmapFont {
    public enum BitmapFontError: String, Error {
        case missingInfoOrPropsData
    }
    
    public struct Common: Codable {
        public var lineHeight: Double = 0
        public var base: Double = 0
        public var scaleW: Double = 0
        public var scaleH: Double = 0
        
        public init(_ properties: [(key: Substring, value: Substring)]) {
            for property in properties {
                switch property.key {
                case CodingKeys.lineHeight.stringValue:
                    lineHeight = Double(property.value) ?? 0
                case CodingKeys.base.stringValue:
                    base = Double(property.value) ?? 0
                case CodingKeys.scaleW.stringValue:
                    scaleW = Double(property.value) ?? 0
                case CodingKeys.scaleH.stringValue:
                    scaleH = Double(property.value) ?? 0
                default: break
                }
            }
        }
    }
    
    public struct Info: Codable {
        public var face: String = ""
        public var size: Double = 0
        public var bold: Bool = false
        public var italic: Bool = false
        
        public init(_ properties: [(key: Substring, value: Substring)]) {
            for property in properties {
                switch property.key {
                case CodingKeys.face.stringValue:
                    face = property.value.replacingOccurrences(of: "\"", with: "")
                case CodingKeys.size.stringValue:
                    size = Double(property.value) ?? 0
                case CodingKeys.bold.stringValue:
                    bold = (property.value == "1")
                case CodingKeys.italic.stringValue:
                    italic = (property.value == "1")
                default: break
                }
            }
        }
    }
    
    public struct Page: Codable {
        public var id: String = ""
        public var file: String = ""
        
        public init(_ properties: [(key: Substring, value: Substring)]) {
            for property in properties {
                switch property.key {
                case CodingKeys.id.stringValue:
                    id = String(property.value)
                case CodingKeys.file.stringValue:
                    file = property.value.replacingOccurrences(of: "\"", with: "")
                default: break
                }
            }
        }
    }
    
    public struct Character: Codable {
        public var id: String = ""
        public var x: Double = 0
        public var y: Double = 0
        public var width: Double = 0
        public var height: Double = 0
        public var xoffset: Double = 0
        public var yoffset: Double = 0
        public var xadvance: Double = 0
        public var letter: String = ""
        
        public init(_ properties: [(key: Substring, value: Substring)]) {
            for property in properties {
                switch property.key {
                case CodingKeys.id.stringValue:
                    id = String(property.value)
                case CodingKeys.x.stringValue:
                    x = Double(property.value) ?? 0
                case CodingKeys.y.stringValue:
                    y = Double(property.value) ?? 0
                case CodingKeys.width.stringValue:
                    width = Double(property.value) ?? 0
                case CodingKeys.height.stringValue:
                    height = Double(property.value) ?? 0
                case CodingKeys.xoffset.stringValue:
                    xoffset = Double(property.value) ?? 0
                case CodingKeys.yoffset.stringValue:
                    yoffset = Double(property.value) ?? 0
                case CodingKeys.xadvance.stringValue:
                    xadvance = Double(property.value) ?? 0
                case CodingKeys.letter.stringValue:
                    letter = property.value.replacingOccurrences(of: "\"", with: "")
                default: break
                }
            }
        }
    }
}
