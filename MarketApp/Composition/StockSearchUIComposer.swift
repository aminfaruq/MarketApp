//
//  StockSearchUIComposer.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import Foundation
import MarketCore
import MarketPresentation

public final class StockSearchUIComposer {
    
    private init() {}
    
    public static func makeStockSearchViewController(
        baseURL: URL = URL(string: "https://finnhub.io/api/v1")!,
        token: String = "---YOUR TOKEN---"
    ) -> StockSearchViewController {
        let httpClient = URLSessionHTTPClient()
        let searchLoader = RemoteStockSearchLoader(baseURL: baseURL, token: token, client: httpClient)
        let viewModel = StockSearchViewModel(loader: searchLoader)
        let viewController = StockSearchViewController(viewModel: viewModel)
        
        viewController.onSelectStock = { [weak viewController] symbol in
            let detailVC = StockDetailUIComposer.makeStockDetailViewController(
                symbol: symbol,
                baseURL: baseURL,
                token: token
            )
            viewController?.navigationController?.pushViewController(detailVC, animated: true)
        }
        
        return viewController
    }
}
