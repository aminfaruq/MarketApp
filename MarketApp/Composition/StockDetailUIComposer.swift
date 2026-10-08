//
//  StockDetailUIComposer.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import Foundation
import MarketCore
import MarketPresentation

public final class StockDetailUIComposer {
    private init() {}
    
    public static func makeStockDetailViewController(
        symbol: String,
        baseURL: URL = URL(string: "https://finnhub.io/api/v1")!,
        wsURL: URL? = nil,
        token: String = "---YOUR TOKEN---"
    ) -> StockDetailViewController {
        let httpClient = URLSessionHTTPClient()
        let detailLoader = RemoteStockDetailLoader(baseURL: baseURL, token: token, client: httpClient)
        let detailViewModel = StockDetailViewModel(symbol: symbol, loader: detailLoader)
        
        let webSocketURL = wsURL ?? URL(string: "wss://ws.finnhub.io?token=\(token)")!
        let wsClient = URLSessionWebSocketClient()
        let streamService = RemoteLiveMarketStreamService(url: webSocketURL, client: wsClient)
        let streamViewModel = LiveMarketStreamViewModel(service: streamService, symbol: symbol)
        
        return StockDetailViewController(
            symbol: symbol,
            detailViewModel: detailViewModel,
            streamViewModel: streamViewModel
        )
    }
}
