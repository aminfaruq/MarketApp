//
//  URLSessionWebSocketClientTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class URLSessionWebSocketClient {
    
    public enum Error: Swift.Error, Equatable {
        case notConnected
    }
    
    private let session: WebSocketSession
    private var task: WebSocketTask?
    private var receiveTask: Task<Void, Never>?
    
    private let eventContinuation: AsyncStream<WebSocketEvent>.Continuation
    public let events: AsyncStream<WebSocketEvent>
    
    public init(session: WebSocketSession = URLSession.shared) {
        self.session = session
        
        var continuation: AsyncStream<WebSocketEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
    }
    
    func connect(to url: URL) {
        let task = session.makeWebSocketTask(with: url)
        self.task = task
        task.resume()
        eventContinuation.yield(.connected)
        
        startReceiving(from: task)
    }
    
    private func startReceiving(from task: WebSocketTask) {
        receiveTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    guard let self = self else { break }
                    
                    switch message {
                        case .string(let text):
                            self.eventContinuation.yield(.message(text))
                        case .data(let data):
                            if let text = String(data: data, encoding: .utf8) {
                                self.eventContinuation.yield(.message(text))
                            }
                        @unknown default:
                            break
                    }
                } catch {
                    guard let self = self else { break }
                    if !Task.isCancelled {
                        self.eventContinuation.yield(.error(error.localizedDescription))
                    }
                    break
                }
            }
        }
    }
    
    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        eventContinuation.yield(.disconnected)
    }
    
    func send(text: String) async throws {
        guard let task = task else {
            throw Error.notConnected
        }
        try await task.send(.string(text))
    }
    
    deinit {
        disconnect()
        eventContinuation.finish()
    }
}

final class URLSessionWebSocketClientTests: XCTestCase {
    
    func test_init_doesNotCreateTaskOrEmitEvents() {
        let (_, session) = makeSUT()
        
        XCTAssertNil(session.requestedURL)
        XCTAssertNil(session.createdTask)
    }
    
    func test_connect_createsAndResumesTaskAndEmitsConnected() async {
        let (sut, session) = makeSUT()
        let url = anyURL()
        var iterator = sut.events.makeAsyncIterator()
        
        sut.connect(to: url)
        
        XCTAssertEqual(session.requestedURL, url)
        XCTAssertEqual(session.createdTask?.resumeCount, 1)
        
        let event = await iterator.next()
        XCTAssertEqual(event, .connected)
    }
    
    func test_disconnect_cancelsTaskAndEmitsDisconnected() async {
        let (sut, _) = makeSUT()
        var iterator = sut.events.makeAsyncIterator()
        
        sut.connect(to: anyURL())
        _ = await iterator.next()
        
        sut.disconnect()
        
        let event = await iterator.next()
        XCTAssertEqual(event, .disconnected)
    }
    
    func test_send_failsWhenNotConnected() async {
        let (sut, _) = makeSUT()
        
        do {
            try await sut.send(text: "any text")
            XCTFail("Expected error but succeeded")
        } catch let error as URLSessionWebSocketClient.Error {
            XCTAssertEqual(error, .notConnected)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func test_send_deliversMessageToTask() async throws {
        let (sut, session) = makeSUT()
        sut.connect(to: anyURL())
        
        try await sut.send(text: "test message")
        
        XCTAssertEqual(session.createdTask?.sentMessages, [.string("test message")])
    }
    
    func test_receiveStringMessage_yieldsMessageEvent() async {
        let (sut, session) = makeSUT()
        var iterator = sut.events.makeAsyncIterator()
        
        sut.connect(to: anyURL())
        _ = await iterator.next() // consume .connected
        
        session.createdTask?.simulateReceive(.success(.string("hello")))
        
        let event = await iterator.next()
        XCTAssertEqual(event, .message("hello"))
    }
    
    func test_receiveDataMessage_yieldsMessageEvent() async {
        let (sut, session) = makeSUT()
        var iterator = sut.events.makeAsyncIterator()
        
        sut.connect(to: anyURL())
        _ = await iterator.next() // consume .connected
        
        let data = "hello data".data(using: .utf8)!
        session.createdTask?.simulateReceive(.success(.data(data)))
        
        let event = await iterator.next()
        XCTAssertEqual(event, .message("hello data"))
    }
    
    func test_receiveError_yieldsErrorEvent() async {
        let (sut, session) = makeSUT()
        var iterator = sut.events.makeAsyncIterator()
        
        sut.connect(to: anyURL())
        _ = await iterator.next() // consume .connected
        
        session.createdTask?.simulateReceive(.failure(anyNSError()))
        
        let event = await iterator.next()
        XCTAssertEqual(event, .error(anyNSError().localizedDescription))
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: URLSessionWebSocketClient, spy: WebSocketSessionSpy) {
        let session = WebSocketSessionSpy()
        let sut = URLSessionWebSocketClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(session, file: file, line: line)
        return (sut, session)
    }
    
    private final class WebSocketSessionSpy: WebSocketSession, @unchecked Sendable {
        var requestedURL: URL?
        var createdTask: WebSocketTaskSpy?
        
        func makeWebSocketTask(with url: URL) -> WebSocketTask {
            self.requestedURL = url
            let task = WebSocketTaskSpy()
            self.createdTask = task
            return task
        }
    }
    
    private final class WebSocketTaskSpy: WebSocketTask, @unchecked Sendable {
        enum SentMessage: Equatable {
            case string(String)
            case data(Data)
        }
        
        var resumeCount = 0
        var isCancelled = false
        var sentMessages = [SentMessage]()
        
        private let incomingContinuation: AsyncStream<Result<URLSessionWebSocketTask.Message, Swift.Error>>.Continuation
        private var incomingIterator: AsyncStream<Result<URLSessionWebSocketTask.Message, Swift.Error>>.AsyncIterator
        
        init() {
            var cont: AsyncStream<Result<URLSessionWebSocketTask.Message, Swift.Error>>.Continuation!
            let stream = AsyncStream<Result<URLSessionWebSocketTask.Message, Swift.Error>> { cont = $0 }
            self.incomingContinuation = cont
            self.incomingIterator = stream.makeAsyncIterator()
        }
        
        func resume() {
            resumeCount += 1
        }
        
        func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            isCancelled = true
            incomingContinuation.finish()
        }
        
        func send(_ message: URLSessionWebSocketTask.Message) async throws {
            switch message {
                case .string(let text):
                    sentMessages.append(.string(text))
                case .data(let data):
                    sentMessages.append(.data(data))
                @unknown default:
                    break
            }
        }
        
        func receive() async throws -> URLSessionWebSocketTask.Message {
            if isCancelled {
                throw CancellationError()
            }
            
            guard let result = await incomingIterator.next() else {
                throw CancellationError()
            }
            
            return try result.get()
        }
        
        func simulateReceive(_ result: Result<URLSessionWebSocketTask.Message, Swift.Error>) {
            incomingContinuation.yield(result)
        }
    }
}

