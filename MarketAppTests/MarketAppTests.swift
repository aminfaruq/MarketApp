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

    func test_feedUIComposer_hasOnOpenSearchConfigured() {
        let sut = FeedUIComposer.makeFeedViewController()
        
        XCTAssertNotNil(sut.onOpenSearch)
    }

    func test_stockSearchUIComposer_createsComposedStockSearchViewController() {
        let sut = StockSearchUIComposer.makeStockSearchViewController()
        
        XCTAssertNotNil(sut)
        _ = sut.node.view
        XCTAssertEqual(sut.title, "Search")
        XCTAssertNotNil(sut.onSelectStock)
    }

    func test_searchResultSectionController_callsOnSelectWhenItemIsSelected() {
        let sut = SearchResultSectionController()
        let vm = SearchResultItemViewModel(symbol: "TSLA", companyName: "Tesla, Inc.", type: "Common Stock")
        let diffable = SearchResultDiffableModel(viewModel: vm)
        sut.didUpdate(to: diffable)
        
        var selectedSymbol: String?
        sut.onSelect = { symbol in
            selectedSymbol = symbol
        }
        
        sut.didSelectItem(at: 0)
        
        XCTAssertEqual(selectedSymbol, "TSLA")
    }

    func test_searchResultDiffableModel_equalityAndDiffIdentifier() {
        let vm1 = SearchResultItemViewModel(symbol: "AAPL", companyName: "Apple Inc", type: "Common Stock")
        let vm2 = SearchResultItemViewModel(symbol: "AAPL", companyName: "Apple Inc", type: "Common Stock")
        let vm3 = SearchResultItemViewModel(symbol: "GOOGL", companyName: "Alphabet", type: "Common Stock")
        
        let diffable1 = SearchResultDiffableModel(viewModel: vm1)
        let diffable2 = SearchResultDiffableModel(viewModel: vm2)
        let diffable3 = SearchResultDiffableModel(viewModel: vm3)
        
        XCTAssertEqual(diffable1.diffIdentifier() as? String, "AAPL")
        XCTAssertTrue(diffable1.isEqual(toDiffableObject: diffable2))
        XCTAssertFalse(diffable1.isEqual(toDiffableObject: diffable3))
    }

    func test_appComposer_createsRootTabBarControllerWithConfiguredTabs() {
        let tabBar = AppComposer.makeRootViewController()
        
        XCTAssertEqual(tabBar.viewControllers?.count, 2)
        
        let nav1 = tabBar.viewControllers?[0] as? UINavigationController
        let nav2 = tabBar.viewControllers?[1] as? UINavigationController
        
        XCTAssertNotNil(nav1)
        XCTAssertNotNil(nav2)
        
        XCTAssertTrue(nav1?.topViewController is MarketFeedViewController)
        XCTAssertTrue(nav2?.topViewController is StockSearchViewController)
        
        XCTAssertEqual(nav1?.tabBarItem.title, "Market")
        XCTAssertEqual(nav2?.tabBarItem.title, "Search")
    }

    func test_feedUIComposer_onOpenSearch_switchesTabWhenInsideTabBarController() {
        let tabBar = AppComposer.makeRootViewController()
        let nav1 = tabBar.viewControllers?[0] as? UINavigationController
        let feedVC = nav1?.topViewController as? MarketFeedViewController
        
        XCTAssertEqual(tabBar.selectedIndex, 0)
        feedVC?.onOpenSearch?()
        XCTAssertEqual(tabBar.selectedIndex, 1)
    }
}
