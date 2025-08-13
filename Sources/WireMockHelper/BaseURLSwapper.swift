import Foundation

public enum BaseURLSwapper {

  private static func jsonToDictionary(_ json: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: json, options: [])
    guard let dictionary = object as? [String: Any] else {
      throw NSError(domain: "InvalidJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Root is not a dictionary"])
    }
    return dictionary
  }

  public static func swapBaseURLs(in data: Data) throws -> Data {
    var dictionary = try jsonToDictionary(data)
    for (key, value) in dictionary {
      if let stringValue = value as? String {
        dictionary[key] = swapBaseURL(for: stringValue) as Any
      }
      if var stringsValue = value as? [String] {
        stringsValue = stringsValue.map { swapBaseURL(for: $0)}
        dictionary[key] = stringsValue as Any
      }
    }

    return try JSONSerialization.data(withJSONObject: dictionary, options: [])
  }


  public static func swapBaseURL(for string: String) -> String {
    guard let url = URL(string: string) else {
      return string
    }
    return swapBaseURL(for: url).absoluteString
  }

  public static func swapBaseURL(for url: URL) -> URL {
    guard let json = ProcessInfo.processInfo.environment["MOCK_URL_PORT_MAP"],
          let data = json.data(using: .utf8),
          let map = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
          let host = url.host,
          let port = map[host]
    else {
      print("didn't find a match for \(url)")
      return url
    }
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.scheme = "http"
    components?.host = "localhost"
    components?.port = port
    components?.path = url.path
    print("Swapping base URL from \(url) to \(String(describing: components?.url))")
    return components?.url ?? url
  }
}

