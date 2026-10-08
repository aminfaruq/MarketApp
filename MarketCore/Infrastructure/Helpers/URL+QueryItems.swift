//
//  URL+QueryItems.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

extension URL {
    public func appendingQueryItems(_ items: [URLQueryItem]) -> URL {
        guard !items.isEmpty, var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return self
        }
        components.queryItems = (components.queryItems ?? []) + items
        return components.url ?? self
    }
}
