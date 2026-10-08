//
//  StockDetailViewController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit
import RxSwift
import MarketPresentation

public final class StockDetailViewController: ASDKViewController<StockDetailScrollNode> {
    private let symbol: String
    private let detailViewModel: StockDetailViewModel
    private let streamViewModel: LiveMarketStreamViewModel
    private let disposeBag = DisposeBag()
    
    private let refreshControl = UIRefreshControl()
    private let loadTrigger = PublishSubject<Void>()
    private let refreshTrigger = PublishSubject<Void>()
    private let startStreaming = PublishSubject<Void>()
    private let stopStreaming = PublishSubject<Void>()
    
    public init(
        symbol: String,
        detailViewModel: StockDetailViewModel,
        streamViewModel: LiveMarketStreamViewModel
    ) {
        self.symbol = symbol
        self.detailViewModel = detailViewModel
        self.streamViewModel = streamViewModel
        
        let scrollNode = StockDetailScrollNode()
        super.init(node: scrollNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        
        loadTrigger.onNext(())
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startStreaming.onNext(())
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStreaming.onNext(())
    }
    
    private func setupUI() {
        title = symbol
        navigationItem.largeTitleDisplayMode = .never
        
        node.view.alwaysBounceVertical = true
        node.view.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        
        node.headerNode.configurePlaceholder(symbol: symbol)
    }
    
    @objc private func didPullToRefresh() {
        refreshTrigger.onNext(())
    }
    
    private func bindViewModel() {
        // 1. StockDetailViewModel bindings
        let detailInput = StockDetailViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            refreshTrigger: refreshTrigger.asObservable()
        )
        let detailOutput = detailViewModel.transform(input: detailInput)
        
        detailOutput.detail
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] item in
                guard let self = self else { return }
                self.node.headerNode.configure(with: item)
                self.node.priceNode.configure(with: item)
                self.node.metricsNode.configure(with: item)
            })
            .disposed(by: disposeBag)
        
        detailOutput.isRefreshing
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isRefreshing in
                if !isRefreshing {
                    self?.refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)
        
        detailOutput.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self = self, self.isViewLoaded, self.view.window != nil else { return }
                let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        // 2. LiveMarketStreamViewModel bindings
        let streamInput = LiveMarketStreamViewModel.Input(
            startStreaming: startStreaming.asObservable(),
            stopStreaming: stopStreaming.asObservable()
        )
        let streamOutput = streamViewModel.transform(input: streamInput)
        
        streamOutput.trade
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] trade in
                self?.node.priceNode.updateLiveTrade(trade)
            })
            .disposed(by: disposeBag)
        
        streamOutput.isConnected
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isConnected in
                self?.node.priceNode.updateConnectionStatus(isConnected: isConnected)
            })
            .disposed(by: disposeBag)
    }
}
