//
//  HTTPClient.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public protocol HTTPClient {
    typealias Result = (Data, HTTPURLResponse)
    
    func get(from url: URL) async throws -> Result
}
