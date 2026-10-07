//
//  RemoteStockDetailLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

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
        let expectedURL = url
            .appendingPathComponent("stock/profile2")
            .appendingQueryItems([
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
        
        let validJSONData = makeResultData(profile.json)
        spy.stub(statusCode: 200, data: validJSONData)
        
        let receivedProfile = try await sut.loadProfile(symbol: query)
        
        XCTAssertEqual(receivedProfile, profile.model)
    }
    
    // MARK: - QUOTE
    func test_loadQuote_requestsDataFromURL() async {
        let query = "AAPL"
        let token = anyToken()
        let url = anyURL()
        let expectedURL = url
            .appendingPathComponent("quote")
            .appendingQueryItems([
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
    
    func test_loadQuote_deliversQuoteOn200StatusCodeWithValidJSON() async throws {
        let (sut, spy) = makeSUT()
        let query = "AAPL"
        let quote = makeQuote(symbol: query)
        
        let validJSONData = makeResultData(quote.json)
        spy.stub(statusCode: 200, data: validJSONData)
        
        let receivedQuote = try await sut.loadQuote(symbol: query)
        
        XCTAssertEqual(receivedQuote, quote.model)
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
    
    private func makeResultData(_ json: [String: Any]) -> Data {
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
    
    private func makeQuote(
        symbol: String = anyString(),
        currentPrice: Double = 178.5,
        change: Double = 2.5,
        percentChange: Double = 1.42,
        highPrice: Double = 180.0,
        lowPrice: Double = 176.5,
        openPrice: Double = 177.0,
        previousClose: Double = 176.0,
        timestamp: Double = 1696417200
    ) -> (model: StockQuoteModel, json: [String: Any]) {
        let json: [String: Any] = [
            "c": currentPrice,
            "d": change,
            "dp": percentChange,
            "h": highPrice,
            "l": lowPrice,
            "o": openPrice,
            "pc": previousClose,
            "t": timestamp
        ]
        let model = StockQuoteModel(
            symbol: symbol,
            currentPrice: currentPrice,
            change: change,
            percentChange: percentChange,
            highPrice: highPrice,
            lowPrice: lowPrice,
            openPrice: openPrice,
            previousClose: previousClose,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
        return (model, json)
    }
}
