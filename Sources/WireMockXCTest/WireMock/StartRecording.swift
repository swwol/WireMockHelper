import Foundation

extension WireMock {
  public func startRecording(
    persist: Bool = true,
    captureHeaders: [String] = [
      "Accept",
      "Content-Type",
      "Authorization",
      "X-Correlation-ID",
      "X-Idempotency-Key",
      "If-None-Match",
      "If-Modified-Since",
      "Location",]
  ) async -> Result<Void, Error> {
    
    let url = localServerURL.appendingPathComponent("__admin/recordings/start")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let captureHeadersDict = Dictionary(uniqueKeysWithValues: captureHeaders.map { ($0, EmptyObject()) })
    let requestBody = RecordingStartRequest(
      targetBaseUrl: baseURL,
      persist: persist,
      extractBodyCriteria: ExtractBodyCriteria(
        textSizeThreshold: 2048,
        binarySizeThreshold: 10240
      ),
      captureHeaders: captureHeadersDict,
      requestBodyPattern: RequestBodyPattern(matcher: "auto"),
      repeatsAsScenarios: true,
      transformers: [],
      transformerParameters: EmptyObject()
    )
    
    do {
      request.httpBody = try JSONEncoder().encode(requestBody)
      let (_, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(WireMockError.invalidResponse)
      }
      
      if httpResponse.statusCode == 200 {
        print("✅ WireMock recording started for: \(baseURL)")
        return .success(())
      } else {
        print("❌ Failed to start recording. Status code: \(httpResponse.statusCode)")
        return .failure(WireMockError.httpError(httpResponse.statusCode))
      }
    } catch {
      print("❌ Error starting recording: \(error)")
      return .failure(error)
    }
  }
}

struct RecordingStartRequest: Codable {
  let targetBaseUrl: String
  let persist: Bool
  let extractBodyCriteria: ExtractBodyCriteria
  let captureHeaders: [String: EmptyObject]
  let requestBodyPattern: RequestBodyPattern
  let repeatsAsScenarios: Bool
  let transformers: [String]
  let transformerParameters: EmptyObject
 // let filters: RecordingFilters?
}

struct ExtractBodyCriteria: Codable {
  let textSizeThreshold: Int
  let binarySizeThreshold: Int
}

struct RequestBodyPattern: Codable {
  let matcher: String
}

struct EmptyObject: Codable {
  // Empty struct that encodes to {}
}

struct RecordingFilters: Codable {
    let headers: [String: String]?
    let method: String?
    let url: String?
    let urlPattern: String?
    let queryParameters: [String: String]?

  init(headers: [String : String]?,
       method: String? = nil,
       url: String? = nil,
       urlPattern: String? = nil,
       queryParameters: [String : String]? = nil
  ) {
    self.headers = headers
    self.method = method
    self.url = url
    self.urlPattern = urlPattern
    self.queryParameters = queryParameters
  }

  static func filterForTestName(_ name: String) -> Self {
    RecordingFilters(headers: ["X-Test-Scenario": name])
  }
}



struct QueryParameterFilter: Codable {
    let equalTo: String?
    let contains: String?
    let matches: String?
}
