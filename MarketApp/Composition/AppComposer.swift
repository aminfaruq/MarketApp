//
//  AppComposer.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import Foundation

public final class AppComposer {
    
    private init() {}
    
    public static func makeRootViewController(
        baseURL: URL = URL(string: "https://finnhub.io/api/v1")!,
        token: String = "---YOUR TOKEN---"
    ) -> UITabBarController {
        
        let feedVC = FeedUIComposer.makeFeedViewController(baseURL: baseURL, token: token)
        let feedNav = UINavigationController(rootViewController: feedVC)
        feedNav.navigationBar.prefersLargeTitles = true
        feedNav.tabBarItem = UITabBarItem(
            title: "Market",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis")
        )
        
        let searchVC = StockSearchUIComposer.makeStockSearchViewController(baseURL: baseURL, token: token)
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.navigationBar.prefersLargeTitles = true
        searchNav.tabBarItem = UITabBarItem(
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        
        let tabBarController = MainTabBarController(viewControllers: [feedNav, searchNav])
        return tabBarController
    }
}
