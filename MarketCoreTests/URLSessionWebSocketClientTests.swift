//
//  URLSessionWebSocketClientTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class URLSessionWebSocketClient {
    
    private let session: WebSocketSession
    private var task: WebSocketTask?
    
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
    
    private func startReceiving(from task: WebSocketTask) {}
    
    deinit {
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
        var resumeCount = 0
        var isCancelled = false
        var sentMessages = [URLSessionWebSocketTask.Message]()
        
        private var receiveContinuation: CheckedContinuation<URLSessionWebSocketTask.Message, Swift.Error>?
        
        func resume() {
            resumeCount += 1
        }
        
        func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            isCancelled = true
            receiveContinuation?.resume(throwing: CancellationError())
            receiveContinuation = nil
        }
        
        func send(_ message: URLSessionWebSocketTask.Message) async throws {
            sentMessages.append(message)
        }
        
        func receive() async throws -> URLSessionWebSocketTask.Message {
            return try await withCheckedThrowingContinuation { continuation in
                self.receiveContinuation = continuation
            }
        }
        
        func simulateReceive(_ result: Result<URLSessionWebSocketTask.Message, Swift.Error>) {
            switch result {
                case .success(let message):
                    receiveContinuation?.resume(returning: message)
                case .failure(let failure):
                    receiveContinuation?.resume(throwing: failure)
            }
            receiveContinuation = nil
        }
    }
}
