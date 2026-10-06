//
//  MarketNewsModel.swift
//  MarketApp
//
//  Created by Amin faruq on 06/10/26.
//

import Foundation

public struct MarketNewsModel: Equatable, Identifiable {
    public let id: Int
    public let headline: String
    public let summary: String
    public let source: String
    public let imageURL: URL?
    public let newsURL: URL?
    public let publishedAt: Date
    
    public init(id: Int, headline: String, summary: String, source: String, imageURL: URL?, newsURL: URL?, publishedAt: Date) {
        self.id = id
        self.headline = headline
        self.summary = summary
        self.source = source
        self.imageURL = imageURL
        self.newsURL = newsURL
        self.publishedAt = publishedAt
    }
}
