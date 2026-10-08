//
//  MarketFeedViewController.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//
import UIKit
import RxSwift
import RxCocoa
import IGListKit
import AsyncDisplayKit
import MarketPresentation

public final class MarketFeedViewController: ASDKViewController<ASCollectionNode>, ListAdapterDataSource {
    private let viewModel: MarketFeedViewModel
    private let disposeBag = DisposeBag()
    
    private var items: [ListDiffable] = []
    
    private lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        // IGListKit falls back to `reloadData` when a diff has > 100 changes.
        // ASCollectionView ignores `reloadData` after its first load, so the node
        // would stay empty while the adapter believes it has the new sections,
        // and the next update asserts on the section-count mismatch.
        updater.allowsReloadingOnTooManyUpdates = false
        return ListAdapter(updater: updater, viewController: self)
    }()
    
    private let refreshControl = UIRefreshControl()
    
    private let loadTrigger = PublishSubject<Void>()
    private let refreshTrigger = PublishSubject<Void>()
    
    public init(viewModel: MarketFeedViewModel) {
        self.viewModel = viewModel
        
        let layout = UICollectionViewFlowLayout()
        super.init(node: ASCollectionNode(collectionViewLayout: layout))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupAdapter()
        setupUI()
        bindViewModel()
        
        loadTrigger.onNext(())
    }
    
    private func setupUI() {
        title = "Market Watch"
        navigationController?.navigationBar.prefersLargeTitles = true
        node.backgroundColor = .systemBackground
        
        node.view.alwaysBounceVertical = true
        node.view.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    }
    
    @objc private func didPullToRefresh() {
        refreshTrigger.onNext(())
    }
    
    private func setupAdapter() {
        adapter.setASDKCollectionNode(node)
        adapter.dataSource = self
    }
    
    private func bindViewModel() {
        let input = MarketFeedViewModel.Input(
            loadTrigger: loadTrigger.asObservable(),
            refreshTrigger: refreshTrigger.asObservable()
        )
        
        let output = viewModel.transform(input: input)
        
        output.feed
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] quotes, news in
                guard let self = self else { return }
                
                let quoteModels = quotes.map { StockQuoteDiffableModel(viewModel: $0) }
                let newsModels = news.map { MarketNewsDiffableModel(viewModel: $0) }
                
                self.items = quoteModels + newsModels
                self.adapter.performUpdates(animated: false) 
            })
            .disposed(by: disposeBag)
        
        output.isRefreshing
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isRefreshing in
                if !isRefreshing {
                    self?.refreshControl.endRefreshing()
                }
            })
            .disposed(by: disposeBag)
        
        output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self = self, self.isViewLoaded, self.view.window != nil, self.presentedViewController == nil else { return }
                let alert = UIAlertController(title: "Attention", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    public func objects(for listAdapter: ListAdapter) -> [any ListDiffable] {
        return items
    }
    
    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if object is StockQuoteDiffableModel {
            return StockQuoteSectionController()
        } else {
            return MarketNewsSectionController()
        }
    }
    
    public func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
    
}
