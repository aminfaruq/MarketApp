//
//  RemoteStockDetailLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockDetailLoader {
    
    public enum Error: Swift.Error, LocalizedError, Equatable {
        case connectivity
        case invalidData
        
        public var errorDescription: String? {
            switch self {
                case .connectivity:
                    return "Cannot connect to the server. Check your internet connection."
                case .invalidData:
                    return "The server returned an unexpected response."
            }
        }
    }
    
    private let url: URL
    private let client: HTTPClient
    private let token: String
    
    init (url: URL, token: String, client: HTTPClient) {
        self.url = url
        self.token = token
        self.client = client
    }
    
    func loadProfile(symbol: String) async throws -> CompanyProfileModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: token)
        ]
        
        let requestURL = url.appendingQueryItems(queryItems)
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200, let data = try? JSONDecoder().decode(RemoteProfileDTO.self, from: data) else { throw Error.invalidData }
        
        return data.toModel()
    }
    
    func loadQuote(symbol: String) async throws -> StockQuoteModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: token)
        ]
        
        let requestURL = url.appendingQueryItems(queryItems)
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200, let _ = try? JSONDecoder().decode(RemoteStockQuoteDTO.self, from: data) else { throw Error.invalidData }
        
        
        return .init(symbol: symbol, currentPrice: 0, change: 0, percentChange: 0, highPrice: 0, lowPrice: 0, openPrice: 0, previousClose: 0, timestamp: Date())
    }
    
    private struct RemoteProfileDTO: Decodable {
        let ticker: String
        let name: String
        let currency: String
        let exchange: String
        let logo: String
        let finnhubIndustry: String
        
        func toModel() -> CompanyProfileModel {
            .init(
                symbol: ticker,
                name: name,
                logoURL: URL(string: logo),
                industry: finnhubIndustry,
                currency: currency,
                exchange: exchange
            )
        }
    }
    
    private struct RemoteStockQuoteDTO: Decodable {
        
    }
}

final class RemoteStockDetailLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformNetworkRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - PROFILE
    func test_loadProfile_requestsDataFromURL() async {
        let query = "AAPL"
        let token = anyToken()
        let url = anyURL()
        let expectedURL = url.appendingQueryItems([
            URLQueryItem(name: "symbol", value: query),
            URLQueryItem(name: "token", value: token)
        ])
        let (sut, client) = makeSUT(url: url, token: token)
        
        _ = try? await sut.loadProfile(symbol: query)
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "symbol=\(query)&token=\(token)")
    }
    
    func test_loadProfile_deliversErrorConnectivity() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(with: .failure(anyNSError()))
        
        await assertThat({ try await sut.loadProfile(symbol: anyString()) }, throws: .connectivity)
    }
    
    func test_loadProfile_deliversInvalidDataOnNon200StatusCode() async {
        let samples = [199, 201, 300, 400, 500]
        
        for code in samples {
            let (sut, client) = makeSUT(url: anyURL())
            client.stub(statusCode: code, data: anyData())
            
            await assertThat({ try await sut.loadProfile(symbol: anyString()) }, throws: .invalidData)
        }
    }
    
    func test_loadProfile_deliversInvalidData200StatusCodeWithInvalidJSON() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(statusCode: 200, data: Data("invalid json".utf8))
        
        await assertThat({ try await sut.loadProfile(symbol: anyString()) }, throws: .invalidData)
    }
    
    func test_loadProfile_deliversProfileOn200StatusCodeWithValidJSON() async throws {
        let (sut, spy) = makeSUT()
        let query = "AAPL"
        let profile = makeProfile(symbol: "AAPL", name: "Apple Inc")
        
        let validJSONData = makeProfileData(profile.json)
        spy.stub(statusCode: 200, data: validJSONData)
        
        let receivedProfile = try await sut.loadProfile(symbol: query)
        
        XCTAssertEqual(receivedProfile, profile.model)
    }
    
    // MARK: - QUOTE
    func test_loadQuote_requestsDataFromURL() async {
        let query = "AAPL"
        let token = anyToken()
        let url = anyURL()
        let expectedURL = url.appendingQueryItems([
            URLQueryItem(name: "symbol", value: query),
            URLQueryItem(name: "token", value: token)
        ])
        let (sut, client) = makeSUT(url: url, token: token)
        
        _ = try? await sut.loadQuote(symbol: query)
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "symbol=\(query)&token=\(token)")
    }
    
    func test_loadQuote_deliversErrorConnectivity() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(with: .failure(anyNSError()))
                
        await assertThat({ try await sut.loadQuote(symbol: anyString()) }, throws: .connectivity)
    }
    
    func test_loadQuote_deliversInvalidDataOnNon200StatusCode() async {
        let samples = [199, 201, 300, 400, 500]
        
        for code in samples {
            let (sut, client) = makeSUT(url: anyURL())
            client.stub(statusCode: code, data: anyData())
            
            await assertThat({ try await sut.loadQuote(symbol: anyString()) }, throws: .invalidData)
        }
    }
    
    func test_loadQuote_deliversInvalidData200StatusCodeWithInvalidJSON() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(statusCode: 200, data: Data("invalid json".utf8))
        
        await assertThat({ try await sut.loadQuote(symbol: anyString()) }, throws: .invalidData)
    }
    
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockDetailLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockDetailLoader(url: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private func assertThat(
        _ action: () async throws -> Any,
        throws expectedError: RemoteStockDetailLoader.Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await action()
            XCTFail("Expected \(expectedError), got success", file: file, line: line)
        } catch let error as RemoteStockDetailLoader.Error {
            XCTAssertEqual(error, expectedError, file: file, line: line)
            XCTAssertNotNil(error.localizedDescription, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError), got failure \(error)", file: file, line: line)
        }
    }
    
    private func makeProfileData(_ json: [String: Any]) -> Data {
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeProfile(
        symbol: String = "AAPL",
        name: String = "Apple Inc",
        currency: String = "USD",
        exchange: String = "NASDAQ",
        logo: String = "https://example.com/logo.png",
        industry: String = "Technology",
    ) -> (model: CompanyProfileModel, json: [String: Any]) {
        
        let model = CompanyProfileModel(
            symbol: symbol,
            name: name,
            logoURL: URL(string: logo),
            industry: industry,
            currency: currency,
            exchange: exchange
        )
        
        let json: [String: Any] = [
            "ticker": symbol,
            "name": name,
            "currency": currency,
            "exchange": exchange,
            "logo": logo,
            "finnhubIndustry": industry,
        ]
        
        return (model, json)
    }
}
