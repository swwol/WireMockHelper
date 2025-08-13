import XCTest

public enum Mode {
  case record
  case playback
}

open class WireMockXCTestCase: XCTestCase {
  public var app: XCUIApplication!
  public var wireMocks: [WireMock] = []
  public var mode: Mode = .playback

  public func setUp(mode: Mode = .playback, mappingConfigFromHost: String? = nil) {
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
      if let mappingConfigFromHost,
         let url = Bundle(for: type(of: self)).url(forResource: "config", withExtension: "json"),
         let hostMock = wireMocks.first(where: { $0.host == mappingConfigFromHost }){
        do {
          let data = try Data(contentsOf: url)
          let transformed = try swapBaseURLs(in: data, with: mappings)
          let transformedJsonString = String(data: transformed, encoding: .utf8)!
          print(transformedJsonString)
          Task {
            await hostMock.stubbedResponse(request: .init(method: "GET", url: "/ios-retail-appstore/msconfig-v2.json"), response: .init(body: transformedJsonString))
            await self.app.launch()
          }
        } catch {
          XCTFail("Failed to decode mock config: \(error)")
          return
        }
      } else {
        app.launch()
      }
    }
    continueAfterFailure = false
  }

  private func jsonToDictionary(_ json: Data) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: json, options: [])
    guard let dictionary = object as? [String: Any] else {
      throw NSError(domain: "InvalidJSON", code: 0, userInfo: [NSLocalizedDescriptionKey: "Root is not a dictionary"])
    }
    return dictionary
  }

  private func swapBaseURLs(in data: Data, with mappings: [String: Int]) throws -> Data {
    var dictionary = try jsonToDictionary(data)
    for (key, value) in dictionary {
      if let stringValue = value as? String {
        dictionary[key] = swapBaseURL(for: stringValue, with: mappings) as Any
      }
      if var stringsValue = value as? [String] {
        stringsValue = stringsValue.map { swapBaseURL(for: $0, with: mappings)}
        dictionary[key] = stringsValue as Any
      }
    }

    return try JSONSerialization.data(withJSONObject: dictionary, options: [])
  }

  private func swapBaseURL(for string: String, with mappings: [String: Int]) -> String {
    guard let url = URL(string: string) else {
      return string
    }
    return swapBaseURL(for: url, with: mappings).absoluteString
  }

  private func swapBaseURL(for url: URL, with mappings: [String: Int]) -> URL {
    guard let host = url.host,
    let port = mappings[host]
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

