import XCTest

public enum Mode {
  case record
  case playback
}

open class WireMockXCTestCase: XCTestCase {
  public var app: XCUIApplication!
  public var wireMocks: [WireMock] = []
  public var mode: Mode = .playback

  public func setUp(mode: Mode = .playback) {
    super.setUp()
    guard let url = Bundle(for: type(of: self)).url(forResource: "wiremock_config", withExtension: "json") else {
      XCTFail("Could not find wiremock_config.json in test bundle")
      return
    }
    do {
      let data = try Data(contentsOf: url)
      self.wireMocks = try JSONDecoder().decode([WireMock].self, from: data)
    } catch {
      XCTFail("Failed to decode mock config: \(error)")
      return
    }
    self.app = XCUIApplication()

    let mappings: [String: Int] = wireMocks.reduce(into: [:]) { result, mock in
      result[mock.host] = mock.port
    }
    let jsonData = try! JSONSerialization.data(withJSONObject: mappings)
    let jsonString = String(data: jsonData, encoding: .utf8)!

    app.launchEnvironment["MOCK_URL_PORT_MAP"] = jsonString
    app.launchEnvironment["WIREMOCK_TEST_NAME"] = name

    self.mode = mode

    if mode == .record {

      addTeardownBlock {
        let allSucceeded = await withTaskGroup(of: Bool.self) { group in
          for mock in self.wireMocks {
            group.addTask {
              let result = await mock.stopRecording()
              switch result {
              case .success:
                print("✅ \(mock.name) recording stopped")
                return true
              case .failure(let error):
                print("❌ \(mock.name) failed to stop: \(error)")
                return false
              }
            }
          }

          var success = true
          for await result in group {
            if !result {
              success = false
            }
          }
          return success
        }
      }


      Task {
        await startRecordingAndLaunchApp()
      }
    } else {
      self.app.launch()
    }
    continueAfterFailure = false
  }

  private func startRecordingAndLaunchApp() async {
    guard !wireMocks.isEmpty else { return }
    let allSucceeded = await withTaskGroup(of: Bool.self) { group in
      for mock in wireMocks {
        group.addTask {
          let result = await mock.startRecording()
          switch result {
          case .success:
            print("✅ \(mock.name) recording started")
            return true
          case .failure(let error):
            print("❌ \(mock.name) failed to start: \(error)")
            return false
          }
        }
      }

      var success = true
      for await result in group {
        if !result {
          success = false
        }
      }
      return success
    }

    if allSucceeded {
      print("🎬 All WireMock Servers recording. Launching app.")
      await app.launch()
    } else {
      print("🚫 Some WireMock servers failed to start recording..")
      XCTFail()
    }
  }
}

