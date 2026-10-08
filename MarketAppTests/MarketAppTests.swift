//
//  MarketAppTests.swift
//  MarketAppTests
//
//  Created by Amin faruq on 06/10/26.
//

import XCTest
import IGListKit
import MarketCore
import MarketPresentation
@testable import MarketApp
internal import AsyncDisplayKit

final class MarketAppTests: XCTestCase {

    func test_feedUIComposer_createsComposedMarketFeedViewController() {
        let sut = FeedUIComposer.makeFeedViewController()
        
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.onSelectQuote)
        XCTAssertNotNil(sut.onSelectNews)
    }

    func test_stockDetailUIComposer_createsComposedStockDetailViewController() {
        let sut = StockDetailUIComposer.makeStockDetailViewController(symbol: "AAPL")
        
        XCTAssertNotNil(sut)
        _ = sut.node.view
        XCTAssertEqual(sut.title, "AAPL")
    }

    func test_stockQuoteSectionController_callsOnSelectWhenItemIsSelected() {
        let sut = StockQuoteSectionController()
        let quote = StockQuoteModel(
            symbol: "AAPL",
            currentPrice: 150.0,
            change: 2.5,
            percentChange: 1.69,
            highPrice: 155.0,
            lowPrice: 145.0,
            openPrice: 148.0,
            previousClose: 147.5,
            timestamp: Date()
        )
        let diffable = StockQuoteDiffableModel(viewModel: StockQuoteItemViewModel(model: quote))
        sut.didUpdate(to: diffable)
        
        var selectedSymbol: String?
        sut.onSelect = { symbol in
            selectedSymbol = symbol
        }
        
        sut.didSelectItem(at: 0)
        
        XCTAssertEqual(selectedSymbol, "AAPL")
    }

    func test_marketNewsSectionController_callsOnSelectWhenItemIsSelected() {
        let sut = MarketNewsSectionController()
        let newsURL = URL(string: "https://news.com/apple")!
        let news = MarketNewsModel(
            id: 1,
            headline: "Apple updates line",
            summary: "New Macs released",
            source: "TechNews",
            imageURL: nil,
            newsURL: newsURL,
            publishedAt: Date()
        )
        let diffable = MarketNewsDiffableModel(viewModel: MarketNewsItemViewModel(model: news))
        sut.didUpdate(to: diffable)
        
        var selectedURL: URL?
        sut.onSelect = { url in
            selectedURL = url
        }
        
        sut.didSelectItem(at: 0)
        
        XCTAssertEqual(selectedURL, newsURL)
    }
}
