//
//  FeedUIComposer.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import Foundation
import SafariServices
import MarketCore
import MarketPresentation

public final class FeedUIComposer {
    
    private init() {}
    
    public static func makeFeedViewController(
        baseURL: URL = URL(string: "https://finnhub.io/api/v1")!,
        token: String = "---YOUR TOKEN---"
    ) -> MarketFeedViewController {
        
        let httpClient = URLSessionHTTPClient()
        let remoteLoader = RemoteMarketFeedLoader(baseURL: baseURL, token: token, client: httpClient)
        let viewModel = MarketFeedViewModel(loader: remoteLoader)
        let viewController = MarketFeedViewController(viewModel: viewModel)
        
        viewController.onSelectQuote = { [weak viewController] symbol in
            let detailVC = StockDetailUIComposer.makeStockDetailViewController(
                symbol: symbol,
                baseURL: baseURL,
                token: token
            )
            viewController?.navigationController?.pushViewController(detailVC, animated: true)
        }
        
        viewController.onSelectNews = { [weak viewController] url in
            let safariVC = SFSafariViewController(url: url)
            viewController?.present(safariVC, animated: true)
        }
        
        return viewController
    }
}
