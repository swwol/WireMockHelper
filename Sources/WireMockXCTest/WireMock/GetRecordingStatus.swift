import Foundation

extension WireMock {
  
  /// Checks the current recording status
  /// - Returns: Result with recording status or error
  public func getRecordingStatus() async -> Result<RecordingStatus, Error> {
    let url = localServerURL.appendingPathComponent("__admin/recordings/status")
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    if #available(iOS 15.0, *) {
      do {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          return .failure(WireMockError.invalidResponse)
        }
        
        if httpResponse.statusCode == 200 {
          let status = try JSONDecoder().decode(RecordingStatus.self, from: data)
          return .success(status)
        } else {
          return .failure(WireMockError.httpError(httpResponse.statusCode))
        }
        
      } catch {
        return .failure(error)
      }
    }
  }
}

public struct RecordingStatus: Codable {
  let status: String
  let targetBaseUrl: String?
}
