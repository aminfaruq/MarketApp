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
        
        guard response.statusCode == 200, let _ = try? JSONDecoder().decode(RemoteMarketFeedDTO.self, from: data) else { throw Error.invalidData }
        
        return []
    }
    
    private struct RemoteMarketFeedDTO: Decodable {}
}

final class RemoteMarketFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestFromURL() {
        let (_, spy) = makeSUT()
        
        XCTAssertTrue(spy.requestedURLs.isEmpty)
    }
    
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
