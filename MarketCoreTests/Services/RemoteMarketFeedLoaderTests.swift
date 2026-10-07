//
//  RemoteMarketFeedLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//


import XCTest
import MarketCore

final class RemoteMarketFeedLoader {
    
    enum Error: Swift.Error, LocalizedError, Equatable {
        case connectivity
        case invalidData
    }
    
    private let baseURL: URL
    private let client: HTTPClient
    private let token: String
    
    init (baseURL: URL, token: String, client: HTTPClient) {
        self.baseURL = baseURL
        self.token = token
        self.client = client
    }
    
    func loadMarketNews() async throws -> [MarketNewsModel] {
        let url = baseURL
            .appendingPathComponent("news")
            .appending(queryItems: [
                URLQueryItem(name: "category", value: "general"),
                URLQueryItem(name: "token", value: token),
            ])
        
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: url)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200, let root = try? JSONDecoder().decode([RemoteMarketFeedDTO].self, from: data) else { throw Error.invalidData }
        
        return root.map({ $0.toModel() })
    }
    
    func loadQuotes(symbols: [String]) async throws -> [StockQuoteModel] {
        guard !symbols.isEmpty else { return [] }
        
        return try await withThrowingTaskGroup(of: StockQuoteModel.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.loadSingleQuote(symbol: symbol)
                }
            }
            
            var quotes = [StockQuoteModel]()
            for try await quote in group {
                quotes.append(quote)
            }
            
            let symbolOrder = Dictionary(uniqueKeysWithValues: symbols.enumerated().map { ($1 , $0) })
            return quotes.sorted {
                (symbolOrder[$0.symbol] ?? 0) < (symbolOrder[$1.symbol] ?? 0)
            }
        }
        
    }
    
    private func loadSingleQuote(symbol: String) async throws -> StockQuoteModel {
        let queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "token", value: token)
        ]
        let requestURL = baseURL
            .appendingPathComponent("quote")
            .appendingQueryItems(queryItems)
        
        let response: HTTPURLResponse
        let data: Data
        
        do {
            (data, response) = try await client.get(from: requestURL)
        } catch {
            throw Error.connectivity
        }
        
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(RemoteStockQuoteDTO.self, from: data) else {
            throw Error.invalidData
        }
        
        return root.toModel(symbol: symbol)
    }
    
    private struct RemoteMarketFeedDTO: Decodable {
        let datetime: Double
        let headline: String
        let id: Int
        let image: String
        let source: String
        let summary: String
        let url: String
        
        func toModel() -> MarketNewsModel {
            .init(
                id: id,
                headline: headline,
                summary: summary,
                source: source,
                imageURL: URL(string: image),
                newsURL: URL(string: url),
                publishedAt: Date(timeIntervalSince1970: datetime)
            )
        }
    }
    
    private struct RemoteStockQuoteDTO: Decodable {
        let c: Double
        let d: Double
        let dp: Double
        let h: Double
        let l: Double
        let o: Double
        let pc: Double
        let t: Double
        
        func toModel(symbol: String) -> StockQuoteModel {
            .init(
                symbol: symbol,
                currentPrice: c,
                change: d,
                percentChange: dp,
                highPrice: h,
                lowPrice: l,
                openPrice: o,
                previousClose: pc,
                timestamp: Date(timeIntervalSince1970: t)
            )
        }
    }
    
}

final class RemoteMarketFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertTrue(spy.requestedURLs.isEmpty)
    }
    
    // MARK: - Market news
    func test_loadMarketNews_requestsDataFromURL() async {
        let token = anyToken()
        let url = anyURL()
        let expectedURL = url
            .appendingPathComponent("news")
            .appendingQueryItems([
                URLQueryItem(name: "category", value: "general"),
                URLQueryItem(name: "token", value: token)
            ])
        let (sut, client) = makeSUT(url: url, token: token)
        
        _ = try? await sut.loadMarketNews()
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "category=general&token=\(token)")
    }
    
    func test_loadMarketNews_deliversErrorConnectivity() async {
        let (sut, spy) = makeSUT()
        spy.stub(with: .failure(anyNSError()))
        
        await assertThat({
            _ = try await sut.loadMarketNews()
        }, throws: .connectivity)
    }
    
    func test_loadMarketNews_deliversErrorInvalidDataOnNon200StatusCode() async {
        let samples = [199, 201, 300, 400, 500]
        let (sut, spy) = makeSUT()
        
        for code in samples {
            spy.stub(statusCode: code, data: anyData())
            
            await assertThat({
                _ = try await sut.loadMarketNews()
            }, throws: .invalidData)
        }
    }
    
    func test_loadMarketNews_deliversErrorInvalidDataOn200StatusCodeWithInvalidJSON() async {
        let (sut, spy) = makeSUT()
        spy.stub(statusCode: 200, data: Data("invalid-data".utf8))
        
        await assertThat({
            _ = try await sut.loadMarketNews()
        }, throws: .invalidData)
    }
    
    func test_loadMarketNews_deliversEmptyWith200StatusCode() async throws {
        let (sut, spy) = makeSUT()
        let empty = try! JSONSerialization.data(withJSONObject: [[String: Any]]())
        spy.stub(statusCode: 200, data: empty)
        
        let receivedResult = try await sut.loadMarketNews()
        
        XCTAssertEqual(receivedResult, [])
    }
    
    func test_loadMarketNews_deliversDataOn200StatusCode() async throws {
        let (sut, spy) = makeSUT()
        let market = makeMarket()
        let data = try! JSONSerialization.data(withJSONObject: [market.json])
        spy.stub(statusCode: 200, data: data)
        
        let receivedResult = try await sut.loadMarketNews()
        
        XCTAssertEqual(receivedResult, [market.model])
    }
    
    // MARK: - Quotes
    func test_loadQuotes_withEmptySymbols_doesNotRequestNetwork() async throws {
        let (sut, spy) = makeSUT()
        
        let result = try await sut.loadQuotes(symbols: [])
        
        XCTAssertTrue(spy.requestedURLs.isEmpty)
        XCTAssertEqual(result, [])
    }
    
    func test_loadQuotes_requestsDataFromURLForEachSymbol() async {
        let symbols = ["AAPL", "GOOG"]
        let token = anyToken()
        let url = anyURL()
        let (sut, spy) = makeSUT(url: url, token: token)
        
        let expectedURLs = symbols.map { symbol in
            url.appendingPathComponent("quote")
                .appendingQueryItems([
                    URLQueryItem(name: "symbol", value: symbol),
                    URLQueryItem(name: "token", value: token)
                ])
        }
        
        _ = try? await sut.loadQuotes(symbols: symbols)
        
        XCTAssertEqual(Set(spy.requestedURLs), Set(expectedURLs))
    }
    
    func test_loadQuotes_deliversErrorConnectivity() async {
        let (sut, spy) = makeSUT()
        spy.stub(with: .failure(anyNSError()))
        
        await assertThat({
            _ = try await sut.loadQuotes(symbols: ["AAPL"])
        }, throws: .connectivity)
    }
    
    func test_loadQuotes_deliversErrorInvalidDataOnNon200StatusCode() async {
        let samples = [199, 201, 300, 400, 500]
        let (sut, spy) = makeSUT()
        
        for code in samples {
            spy.stub(statusCode: code, data: anyData())
            
            await assertThat({
                _ = try await sut.loadQuotes(symbols: ["AAPL"])
            }, throws: .invalidData)
        }
    }
    
    func test_loadQuotes_deliversQuotesOn200StatusCode() async throws {
        let (sut, spy) = makeSUT()
        let quote = makeQuote(symbol: "AAPL")
        let data = try! JSONSerialization.data(withJSONObject: quote.json)
        spy.stub(statusCode: 200, data: data)
        
        let receivedQuotes = try await sut.loadQuotes(symbols: ["AAPL"])
        
        XCTAssertEqual(receivedQuotes, [quote.model])
    }
    
    // MARK: - Helpers
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RemoteMarketFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteMarketFeedLoader(baseURL: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func makeMarket(
        id: Int = 0,
        headline: String = "a string",
        summary: String = "a string",
        source: String = "a string",
        imageURL: URL = anyURL(),
        newsURL: URL = anyURL(),
        publishedAt: Double = 1596589501
    ) -> (model: MarketNewsModel, json: [String : Any]) {
        let model = MarketNewsModel(
            id: id,
            headline: headline,
            summary: summary,
            source: source,
            imageURL: imageURL,
            newsURL: newsURL,
            publishedAt: Date(timeIntervalSince1970: publishedAt)
        )
        let json: [String: Any] = [
            "datetime": publishedAt,
            "headline": headline,
            "id": id,
            "image": imageURL.absoluteString,
            "source": source,
            "summary": summary,
            "url": newsURL.absoluteString
        ]
        
        return (model, json)
    }
    
    private func makeQuote(
        symbol: String = "AAPL",
        currentPrice: Double = 150.0,
        change: Double = 2.5,
        percentChange: Double = 1.2,
        highPrice: Double = 155.0,
        lowPrice: Double = 148.0,
        openPrice: Double = 149.0,
        previousClose: Double = 147.5,
        timestamp: Double = 1696417200
    ) -> (model: StockQuoteModel, json: [String: Any]) {
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
        return (model, json)
    }
    
    private func assertThat(
        _ action: () async throws -> Any,
        throws expectedError: RemoteMarketFeedLoader.Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await action()
            XCTFail("Expected \(expectedError), got success", file: file, line: line)
        } catch let error as RemoteMarketFeedLoader.Error {
            XCTAssertEqual(error, expectedError, file: file, line: line)
            XCTAssertNotNil(error.localizedDescription, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError), got failure \(error)", file: file, line: line)
        }
    }
}
