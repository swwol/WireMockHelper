import Foundation

public struct WireMock: Codable {

  public init(name: String, port: Int, scheme: String, host: String) {
    self.name = name
    self.port = port
    self.scheme = scheme
    self.host = host
  }
  
  let name: String
  let port: Int
  let scheme: String
  let host: String

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

