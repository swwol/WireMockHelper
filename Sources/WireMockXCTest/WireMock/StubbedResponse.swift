import Foundation

extension WireMock {
  // MARK: -  Stub

  public func stubbedResponse(
    request stubRequest: StubRequest,
    response stubResponse: StubResponse,
    persistent: Bool = false
  ) async -> Result<Void, Error> {
    let url = localServerURL.appendingPathComponent("__admin/mappings")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let requestBody = MakeStub(request:  stubRequest,
                               response: stubResponse,
                               persistent: persistent)
    do {
      request.httpBody = try JSONEncoder().encode(requestBody)
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(WireMockError.invalidResponse)
      }

      if httpResponse.statusCode == 201 {
        print("✅ WireMock made stub for request")
        return .success(())
      } else {
        print("❌ Failed to make stub. Status code: \(httpResponse.statusCode)")
        return .failure(WireMockError.httpError(httpResponse.statusCode))
      }
    } catch {
      print("❌ Error making stub: \(error)")
      return .failure(error)
    }
  }
}

public struct StubRequest: Codable {
  public init(method: String, url: String) {
    self.method = method
    self.url = url
  }
  let method: String
  let url: String
}

public struct StubResponse: Codable {
  public init(body: String, headers: [String: String] = [:], status: Int = 200) {
    self.body = body
    self.headers = headers
    self.status = status
  }
  let body: String
  let headers: [String: String]
  let status: Int
}

struct MakeStub: Codable {
  let request: StubRequest
  let response: StubResponse
  let persistent: Bool
}
