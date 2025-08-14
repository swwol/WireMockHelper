import XCTest

public enum Mode {
  case record
  case playback
}

open class WireMockXCTestCase: XCTestCase {

  enum Error: Swift.Error {
    case noHostWireMock
  }

  public var app: XCUIApplication!
  public var wireMocks: [WireMock] = []
  public var mode: Mode = .playback
  public var hostMock: WireMock!

  public func setUp(mode: Mode = .playback, configURL: String) {
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
    guard let hostMock = wireMocks.first(where: { configURL.contains("http://localhost:\($0.port)")}) else {
      XCTFail("No WireMock defined hosting config")
      return
    }
    self.hostMock = hostMock
    self.app = XCUIApplication()
    app.launchEnvironment["UITEST_CONFIG_URL"] = configURL
    self.mode = mode

    if mode == .record {
      addTeardownBlock {
        let _ = await withTaskGroup(of: Bool.self) { group in
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
      Task {
        let _ = await stubConfigURL(wireMock: hostMock)
        await self.app.launch()
      }
    }
    continueAfterFailure = false
  }

  private func stubConfigURL(wireMock: WireMock) async -> Result<Void, Swift.Error> {
    guard let url = Bundle(for: type(of: self)).url(forResource: "config", withExtension: "json") else { return .failure(Error.noHostWireMock)}
    do {
      let jsonString = try String(contentsOf: url, encoding: .utf8)
      print(jsonString)
      return await wireMock.stubbedResponse(request: .init(method: "GET", url: "/ios-retail-appstore/msconfig-v2.json"), response: .init(body: jsonString))
    } catch {
      XCTFail("failed to read config file")
      return .failure(error)
    }
  }

  private func startRecordingAndLaunchApp() async {
    guard !wireMocks.isEmpty else { return }
    let allSucceeded = await withTaskGroup(of: Bool.self) { group in
      group.addTask {
        let result = await self.stubConfigURL(wireMock: self.hostMock)
        switch result {
        case .success:
          print("✅ stubbing config")
          return true
        case .failure(let error):
          print("❌  failed to stuub config: \(error)")
          return false
        }
      }
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

