//
//  HTTPClientSpy.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation
import MarketCore

class HTTPClientSpy: HTTPClient {
    private let lock = NSLock()
    private var _requestedURLs = [URL]()
    
    var requestedURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return _requestedURLs
    }
    
    private var stub: Result<HTTPClient.Result, Error>?
    
    func stub(with result: Result<HTTPClient.Result, Error>) {
        lock.lock()
        defer { lock.unlock() }
        stub = result
    }
    
    func stub(statusCode: Int, data: Data) {
        let response = HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        stub(with: .success((data, response)))
    }
    
    func get(from url: URL) async throws -> HTTPClient.Result {
        let currentStub = lock.withLock {
            _requestedURLs.append(url)
            return stub
        }
        
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        return try currentStub?.get() ?? (anyData(), response)
    }
}
