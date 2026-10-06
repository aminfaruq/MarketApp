//
//  XCTestHelpers.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks(
        _ instance: AnyObject,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Should have been deallocated. Potential Memory leak.", file: file, line: line)
        }
    }
}

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

func anyData() -> Data {
    Data()
}

func anyNSError() -> NSError {
    NSError(domain: "any-error-domain", code: 0)
}

func anyToken() -> String {
    "423535"
}
