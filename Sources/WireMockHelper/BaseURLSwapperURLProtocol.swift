import Foundation

public class BaseURLSwapperURLProtocol: URLProtocol {

  // MARK: - Configuration
  static var isEnabled = false
  static var endpointMappings: [String: Int] = [:]

  // Property to prevent infinite loops
  private static let handledKey = "BaseURLSwapperURLProtocolHandled"

  // MARK: - Configuration Methods
  static public func enable() {
    guard let json = ProcessInfo.processInfo.environment["MOCK_URL_PORT_MAP"],
          let data = json.data(using: .utf8),
          let map = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else { return }
    endpointMappings = map
    isEnabled = true
    URLProtocol.registerClass(BaseURLSwapperURLProtocol.self)
  }

  static public func disable() {
    isEnabled = false
    endpointMappings.removeAll()
    URLProtocol.unregisterClass(BaseURLSwapperURLProtocol.self)
  }

  // MARK: - URLProtocol Implementation

  override public class func canInit(with request: URLRequest) -> Bool {
    // Only handle if enabled and not already handled
    guard isEnabled,
          URLProtocol.property(forKey: handledKey, in: request) == nil,
          let url = request.url else {
      return false
    }

    // Check if this URL needs swapping
    return shouldSwapURL(url)
  }

  override public class func canonicalRequest(for request: URLRequest) -> URLRequest {
    guard let originalURL = request.url,
          let swappedURL = swapURL(originalURL) else {
      return request
    }

    // Create new request with swapped URL
    let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
    mutableRequest.url = swappedURL

    // Mark as handled to prevent infinite loops
    URLProtocol.setProperty(true, forKey: handledKey, in: mutableRequest)

    if let testName = ProcessInfo.processInfo.environment["WIREMOCK_TEST_NAME"] {
      mutableRequest.setValue(testName, forHTTPHeaderField: "X-Test-Scenario")
    }
    let newRequest = mutableRequest as URLRequest
    print("making call to \(newRequest.url?.absoluteString)")
    return newRequest
  }

  override public func startLoading() {
    // Forward the request with swapped URL to the default session
    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
      guard let self = self else { return }

      if let error = error {
        self.client?.urlProtocol(self, didFailWithError: error)
        return
      }

      if let response = response {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      }

      if let data = data {
        self.client?.urlProtocol(self, didLoad: data)
      }

      self.client?.urlProtocolDidFinishLoading(self)
    }

    task.resume()
  }

  override public func stopLoading() {}

  // MARK: - URL Swapping Logic

  private class func shouldSwapURL(_ url: URL) -> Bool {
    guard let host = url.host else { return false }

    // Check if any mapping matches this host
    return endpointMappings.keys.contains(host)
  }

  private class func swapURL(_ originalURL: URL) -> URL? {
    guard let originalHost = originalURL.host,
          let wireMockPort = endpointMappings[originalHost] else { return nil }

    return buildSwappedURL(from: originalURL, wireMockPort: wireMockPort)
  }

  private class func buildSwappedURL(from originalURL: URL, wireMockPort: Int) -> URL? {
    var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
    components?.scheme = "http"
    components?.host = "localhost"
    components?.port = wireMockPort
    components?.path = originalURL.path
    return components?.url
  }
}
