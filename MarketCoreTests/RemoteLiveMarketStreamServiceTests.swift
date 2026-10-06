//
//  RemoteLiveMarketStreamServiceTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class RemoteLiveMarketStreamService {
    
    private let url: URL
    private let client: WebSocketClient
    
    init(url: URL, client: WebSocketClient) {
        self.url = url
        self.client = client
    }
    
    func connect() {
        client.connect(to: url)
    }
    
    func disconnect() {
        client.disconnect()
    }
    
    func subscribe(to symbol: String) async throws {
        let payload = #"{"symbol":"\#(symbol)","type":"subscribe"}"#

        try await client.send(text: payload)
    }
}

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
        
        private var continuation: AsyncStream<WebSocketEvent>.Continuation?
        
        lazy var events: AsyncStream<WebSocketEvent> = {
            AsyncStream { continuation in
                self.continuation = continuation
            }
        }()
        
        func connect(to url: URL) {
            connectedURL = url
            continuation?.yield(.connected)
        }
        
        func disconnect() {
            didDisconnect = true
            continuation?.yield(.disconnected)
        }
        
        func send(text: String) async throws {
            sentMessages.append(text)
        }
        
        func simulateMessage(_ message: String) {
            continuation?.yield(.message(message))
        }
    }
    
}
