import RedECS

public enum ResourceLoadingAction: Equatable, Codable {
    case load(groupName: String, resources: [LoadableResource])
    case loadComplete(groupName: String)
    case loadingError(groupName: String, error: String)
}
