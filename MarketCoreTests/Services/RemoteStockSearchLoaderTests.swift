//
//  RemoteStockSearchLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockSearchLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformNetworkRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_search_requestsDataFromURL() async {
        let query = "AAPL"
        let url = anyURL()
        let token = anyToken()
        let expectedURL = url
            .appendingPathComponent("search")
            .appendingQueryItems([
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "token", value: token)
            ])
        let (sut, client) = makeSUT(url: url)
        
        _ = try? await sut.search(query: query)
        
        XCTAssertEqual(client.requestedURLs, [expectedURL])
        XCTAssertEqual(client.requestedURLs.first?.query, "q=\(query)&token=\(token)")
    }
    
    func test_search_deliversErrorConnectivity() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(with: .failure(anyNSError()))
        
        await assertThat(sut, throws: .connectivity)
    }
    
    func test_search_deliversInvalidDataOnNon200StatusCode() async {
        let samples = [199, 201, 300, 400, 500]
        
        for code in samples {
            let (sut, client) = makeSUT(url: anyURL())
            client.stub(statusCode: code, data: anyData())
            
            await assertThat(sut, throws: .invalidData)
        }
    }
    
    func test_search_deliversInvalidData200StatusCodeWithInvalidJSON() async {
        let (sut, client) = makeSUT(url: anyURL())
        client.stub(statusCode: 200, data: Data("invalid json".utf8))
        
        await assertThat(sut, throws: .invalidData)
    }
    
    func test_search_deliversEmptyJSONWith200StatusCode() async {
        let (sut, client) = makeSUT(url: anyURL())
        let emptyJSON = makeStocks([])
        client.stub(statusCode: 200, data: emptyJSON)
        
        let receivedResult = try? await sut.search(query: anyString())
        
        XCTAssertEqual(receivedResult, [])
    }
    
    func test_search_deliversStocksWith200StatusCode() async {
        let (sut, client) = makeSUT(url: anyURL())
        let stock1 = makeStock(symbol: "AAPL", description: "APPLE INC", displaySymbol: "AAPL", type: "Common Stock")
        let stock2 = makeStock(symbol: "AAPL.SW", description: "APPLE INC", displaySymbol: "AAPL.SW", type: "Common Stock")
        let expectedResult = [stock1.model, stock2.model]
        let json = makeStocks([stock1.json, stock2.json])
        client.stub(statusCode: 200, data: json)
        
        let receivedResult = try? await sut.search(query: anyString())
        
        XCTAssertEqual(receivedResult, expectedResult)
    }
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockSearchLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockSearchLoader(baseURL: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private func makeStocks(_ result: [[String: Any]]) -> Data {
        let json: [String: Any] = [
            "result": result
        ]
        
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeStock(
        symbol: String,
        description: String,
        displaySymbol: String,
        type: String
    ) -> (model: SearchResultModel, json: [String: Any]) {
        let json : [String: Any] = [
            "description": description,
            "displaySymbol": displaySymbol,
            "symbol": symbol,
            "type": type
        ]
        
        let model = SearchResultModel(
            symbol: symbol,
            description: description,
            displaySymbol: displaySymbol,
            type: type)
        
        return (model, json)
    }
    
    private func assertThat(
        _ sut: RemoteStockSearchLoader,
        throws expectedError: RemoteStockSearchLoader.Error,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await sut.search(query: anyString())
            XCTFail("Expected \(expectedError), got success", file: file, line: line)
        } catch let error as RemoteStockSearchLoader.Error {
            XCTAssertEqual(error, expectedError, file: file, line: line)
            XCTAssertNotNil(error.localizedDescription, file: file, line: line)
        } catch {
            XCTFail("Expected \(expectedError), got failure \(error)", file: file, line: line)
        }
    }
}
