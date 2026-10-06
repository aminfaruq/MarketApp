//
//  RemoteLiveMarketStreamServiceTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteLiveMarketStreamServiceTests: XCTestCase {
    
    func test_init_doesNotConnectOrSendMessage() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.sentMessages.isEmpty)
        XCTAssertNil(client.connectedURL)
    }
    
    func test_connect_connectsToCorrectURL() {
        let url = URL(string: "wss://ws.finnhub.io?token=test_token")!
        let (sut, client) = makeSUT(url: url)
        
        sut.connect()
        
        XCTAssertEqual(client.connectedURL, url)
    }
    
    func test_disconnect_disconnectsClient() {
        let (sut, client) = makeSUT()
        
        sut.disconnect()
        
        XCTAssertTrue(client.didDisconnect)
    }
    
    func test_subscribe_sendsCorrectFinnhubJSONPayLoad() async throws {
        let (sut, client) = makeSUT()
        
        try await sut.subscribe(to: "AAPL")
        
        XCTAssertEqual(client.sentMessages, [
            #"{"symbol":"AAPL","type":"subscribe"}"#
        ])
    }
    
    func test_unsubscribe_sendsCorrectFinnHubJSONPayLoad() async throws {
        let (sut, client) = makeSUT()
        
        try await sut.unsubscribe(from: "AAPL")
        
        XCTAssertEqual(client.sentMessages, [
            #"{"symbol":"AAPL","type":"unsubscribe"}"#
        ])
    }
    
    func test_tradeStream_deliversDecodedLiveTrades() async {
        let (sut, client) = makeSUT()
        
        let validJSON = """
        {
            "type": "trade",
            "data": [
                {
                    "s": "AAPL",
                    "p": 178.5,
                    "t": 1696417200000,
                    "v": 100
                }
            ]
        }
        """
        
        var iterator = sut.tradeStream.makeAsyncIterator()
        
        client.simulateMessage(validJSON)
        
        let trade = await iterator.next()
        
        XCTAssertEqual(trade?.symbol, "AAPL")
        XCTAssertEqual(trade?.price, 178.5)
        XCTAssertEqual(trade?.timestamp, Date(timeIntervalSince1970: 1696417200))
    }
    
    private func makeSUT(
        url: URL = URL(string: "wss://any-url.com")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RemoteLiveMarketStreamService, WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = RemoteLiveMarketStreamService(url: url, client: client)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(client, file: file, line: line)
        return (sut, client)
    }
    
    private final class WebSocketClientSpy: WebSocketClient, @unchecked Sendable {
        var connectedURL: URL?
        var didDisconnect = false
        var sentMessages = [String]()
        
        private let continuation: AsyncStream<WebSocketEvent>.Continuation
        let events: AsyncStream<WebSocketEvent>
        
        init() {
            var cont: AsyncStream<WebSocketEvent>.Continuation!
            self.events = AsyncStream { cont = $0 }
            self.continuation = cont
        }
        
        func connect(to url: URL) {
            connectedURL = url
            continuation.yield(.connected)
        }
        
        func disconnect() {
            didDisconnect = true
            continuation.yield(.disconnected)
        }
        
        func send(text: String) async throws {
            sentMessages.append(text)
        }
        
        func simulateMessage(_ message: String) {
            continuation.yield(.message(message))
        }
    }
    
}
