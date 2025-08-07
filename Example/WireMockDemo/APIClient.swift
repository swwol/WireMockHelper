import Foundation

/// An API client that fetches fruit and cat facts. It has no knowledge of Decoy and provides
/// methods to fetch using closure and async syntaxes to prove that these both work.
struct APIClient {

  private var catBaseURL: String = "https://catfact.ninja"
  private var fruitBaseURL: String = "https://fruityvice.com"

  private let session = URLSession.shared
  private let fruitEndpoint = "/api/fruit/"
  private let catEndpoint = "/fact"



  func fetchApple(completion: @escaping (Fruit?) -> Void) {
    fetchFruit("apple", completion: completion)
  }

  func fetchApple() async throws -> Fruit? {
    try await fetchFruit("apple")
  }

  func fetchBanana(completion: @escaping (Fruit?) -> Void) {
    fetchFruit("banana", completion: completion)
  }

  func fetchBanana() async throws -> Fruit? {
    try await fetchFruit("banana")
  }

  func fetchCatFact(completion: @escaping (String?) -> Void) {
    guard let url = URL(string: catBaseURL + catEndpoint) else { return completion(nil) }
    session.dataTask(with: URLRequest(url: url)) { data, response, error in
      guard let data = data else { return completion(nil) }
      let decoder = JSONDecoder()
      let fact = try? decoder.decode(CatFact.self, from: data)
      completion(fact?.fact)
    }.resume()
  }

  func fetchFruit(_ string: String, completion: @escaping (Fruit?) -> Void) {
    guard let url = URL(string: fruitBaseURL + fruitEndpoint + string) else { return completion(nil) }
    session.dataTask(with: URLRequest(url: url)) { data, response, error in
      guard let data = data else { return completion(nil) }
      let decoder = JSONDecoder()
      let fruit = try? decoder.decode(Fruit.self, from: data)
      completion(fruit)
    }.resume()
  }

  func fetchFruit(_ string: String) async throws -> Fruit? {
    guard let url = URL(string: fruitBaseURL + fruitEndpoint + string) else { return nil }
    let decoder = JSONDecoder()
    let (data, _) = try await session.data(from: url)
    return try decoder.decode(Fruit.self, from: data)
  }

  func fetchCatFact() async throws -> String? {
    guard let url = URL(string: catBaseURL + catEndpoint) else { return nil }
    let (data, _) = try await session.data(from: url)
    let fact = try JSONDecoder().decode(CatFact.self, from: data)
    return fact.fact
  }
}

struct Fruit: Decodable {
  let name: String
}

struct CatFact: Decodable {
  let fact: String
}
