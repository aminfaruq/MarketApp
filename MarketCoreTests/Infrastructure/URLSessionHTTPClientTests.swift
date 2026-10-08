//
//  URLSessionHTTPClientTests.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest
import MarketCore

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func tearDown() {
        URLProtocolStub.stub = nil
        super.tearDown()
    }
    
    func test_getFromURL_requestsDataFromURL() async {
        let url = anyURL()
        let exp = expectation(description: "Wait for GET request")
        
        URLProtocolStub.stub = { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
            return (Data(), self.makeURLResponse(statusCode: 200))
        }
        
        _ = try? await makeSUT().get(from: url)
        
        await fulfillment(of: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_deliversErrorOnRequestFailure() async {
        let expectedError = anyNSError()
        
        URLProtocolStub.stub = { _ in
            throw expectedError
        }
        
        do {
            _ = try await makeSUT().get(from: anyURL())
            XCTFail("Expected to fail but it succeeded")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, expectedError.domain)
            XCTAssertEqual(error.code, expectedError.code)
        }
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() async throws {
        let data = "any data".data(using: .utf8)!
        let response = makeURLResponse(statusCode: 200)
        
        URLProtocolStub.stub = { _ in
            return (data, response)
        }
        
        let (receivedData, receivedResponse) = try await makeSUT().get(from: anyURL())
        
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(receivedResponse.url, response.url)
        XCTAssertEqual(receivedResponse.statusCode, response.statusCode)
    }
    
    func test_getFromURL_failsOnNonHTTPURLResponse() async {
        let nonHTTPResponse = URLResponse(
            url: anyURL(),
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil)
        
        URLProtocolStub.stub = { _ in
            (Data(), nonHTTPResponse)
        }
        
        do {
            _ = try await makeSUT().get(from: anyURL())
            XCTFail("Expected to fail but it succeeded")
        } catch  {
            XCTAssertTrue(error is URLSessionHTTPClient.UnexpectedValueRepresentation)
        }
    }
    
    // MARK: Helpers
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeURLResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stub: ((URLRequest) throws -> (Data, URLResponse))?
        
        override class func canInit(with request: URLRequest) -> Bool {
            return URLProtocolStub.stub != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard let stub = URLProtocolStub.stub else { return }
            do {
                let (data, response) = try stub(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
        }
        
        override func stopLoading() {}
    }
}
