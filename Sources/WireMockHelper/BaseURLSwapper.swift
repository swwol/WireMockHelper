import Foundation

public enum BaseURLSwapper {

public static func swapBaseURL(for url: URL) -> URL {
  guard let json = ProcessInfo.processInfo.environment["MOCK_URL_PORT_MAP"],
        let data = json.data(using: .utf8),
        let map = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
        let host = url.host,
        let port = map[host]
  else {
    return url
  }

  var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
  components?.scheme = "http"
  components?.host = "localhost"
  components?.port = port
  components?.path = url.path
  return components?.url ?? url
  }
}

