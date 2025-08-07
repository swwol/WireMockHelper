import Foundation

extension WireMock {
  public func stopRecording() async -> Result<Void, Error> {
    let url = localServerURL.appendingPathComponent("__admin/recordings/stop")
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      
      guard let httpResponse = response as? HTTPURLResponse else {
        return .failure(WireMockError.invalidResponse)
      }
      
      if httpResponse.statusCode == 200 {
        print("✅ WireMock recording stopped")
        return .success(())
      } else {
        print("❌ Failed to stop recording. Status code: \(httpResponse.statusCode)")
        return .failure(WireMockError.httpError(httpResponse.statusCode))
      }
      
    } catch {
      print("❌ Error stopping recording: \(error)")
      return .failure(error)
    }
  }
}
