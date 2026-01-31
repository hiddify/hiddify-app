public struct SBItem: Codable {
    let tag: String
    let type: String
    let urlTestDelay: Int
    
    enum CodingKeys: String, CodingKey {
        case tag
        case type
        case urlTestDelay = "url-test-delay"
    }
}

public struct SBGroup: Codable {
    let tag: String
    let type: String
    let selected: String
    let items: [SBItem]
}
