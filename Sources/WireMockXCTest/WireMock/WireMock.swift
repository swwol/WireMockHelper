import Foundation

public struct ConfigOverride: Codable {
  let method: String
  let endpoint: String
}

extension ConfigOverride {
  private enum CodingKeys: String, CodingKey {
    case method
    case endpoint
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let method = try container.decodeIfPresent(String.self, forKey: .method) ?? "GET"
    let endpoint = try container.decode(String.self, forKey: .endpoint)
    self.init(method: method, endpoint: endpoint)
  }
}

public struct WireMock: Codable {

  public init(
    name: String,
    port: Int,
    scheme: String,
    host: String,
    configOverride: ConfigOverride?
  ) {
    self.name = name
    self.port = port
    self.scheme = scheme
    self.host = host
    self.configOverride = configOverride
  }
  
  public let name: String
  let port: Int
  let scheme: String
  public let host: String
  let configOverride: ConfigOverride?

  var localServerURL: URL {
    URL(string: "http://localhost:\(port)")!
  }

  var baseURL: String {
    scheme + "://" + host
  }
}

enum WireMockError: Error, LocalizedError {
  case invalidResponse
  case httpError(Int)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from WireMock"
    case .httpError(let code):
      return "HTTP error with status code: \(code)"
    }
  }
}

