//
//  RemoteStockSearchLoaderTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteStockSearchLoader {
    
    enum Error: Swift.Error, LocalizedError, Equatable {
        case connectivity
        case invalidData
    }
    
    private let client: HTTPClient
    private let url: URL
    private let token: String
    
    init(url: URL, token: String, client: HTTPClient) {
        self.url = url
        self.token = token
        self.client = client
    }
    
    func search(query: String) async throws -> [SearchResultModel] {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
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
        
        guard response.statusCode == 200, let _ = try? JSONDecoder().decode(RootDTO.self, from: data) else { throw Error.invalidData }
        
        return []
    }
    
    private struct RootDTO: Decodable {}
}

final class RemoteStockSearchLoaderTests: XCTestCase {
    
    func test_init_doesNotPerformNetworkRequest() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_search_requestsDataFromURL() async {
        let query = "AAPL"
        let url = anyURL()
        let token = anyToken()
        let expectedURL = url.appendingQueryItems([
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
    
    
    //MARK: - HELPERS
    private func makeSUT(
        url: URL = anyURL(),
        token: String = anyToken(),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: RemoteStockSearchLoader, client: HTTPClientSpy){
        let client = HTTPClientSpy()
        let sut = RemoteStockSearchLoader(url: url, token: token, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
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
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        private var stub: Result<HTTPClient.Result, Error>?
        
        func stub(with result: Result<HTTPClient.Result, Error>) {
            stub = result
        }
        
        func stub(statusCode: Int, data: Data) {
            let response = HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            stub = .success((data, response))
        }
        
        func get(from url: URL) async throws -> HTTPClient.Result {
            requestedURLs.append(url)
            
            let response = HTTPURLResponse(
                url: anyURL(),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return try stub?.get() ?? (anyData(), response)
        }
    }
}
