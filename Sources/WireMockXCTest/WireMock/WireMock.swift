import Foundation

public struct WireMock: Codable {

  public init(
    name: String,
    port: Int,
    scheme: String,
    host: String,
    isConfigProvider: Bool = false
  ) {
    self.name = name
    self.port = port
    self.scheme = scheme
    self.host = host
    self.isConfigProvider = isConfigProvider
  }
  
  let name: String
  let port: Int
  let scheme: String
  let host: String
  let isConfigProvider: Bool

  var localServerURL: URL {
    URL(string: "http://localhost:\(port)")!
  }

  var baseURL: String {
    scheme + "://" + host
  }
}

extension WireMock {
  private enum CodingKeys: String, CodingKey {
    case name
    case port
    case scheme
    case host
    case isConfigProvider
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let name = try container.decode(String.self, forKey: .name)
    let port = try container.decode(Int.self, forKey: .port)
    let scheme = try container.decode(String.self, forKey: .scheme)
    let host = try container.decode(String.self, forKey: .host)
    let isConfigProvider = try container.decodeIfPresent(Bool.self, forKey: .isConfigProvider) ?? false

    self.init(
      name: name,
      port: port,
      scheme: scheme,
      host: host,
      isConfigProvider: isConfigProvider
    )
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

