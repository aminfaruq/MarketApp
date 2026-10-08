//
//  StockSearchViewController.swift
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

public final class StockSearchViewController: ASDKViewController<ASCollectionNode>, ListAdapterDataSource {
    public var onSelectStock: ((String) -> Void)?
    
    private let viewModel: StockSearchViewModel
    private let disposeBag = DisposeBag()
    
    private var items: [ListDiffable] = []
    private var currentQuery: String = ""
    
    private lazy var adapter: ListAdapter = {
        let updater = ListAdapterUpdater()
        updater.allowsReloadingOnTooManyUpdates = false
        return ListAdapter(updater: updater, viewController: self)
    }()
    
    private let searchController = UISearchController(searchResultsController: nil)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    public init(viewModel: StockSearchViewModel) {
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
        
        showInitialPrompt()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Automatically focus the search bar for convenience
        if searchController.searchBar.text?.isEmpty ?? true {
            searchController.searchBar.becomeFirstResponder()
        }
    }
    
    private func setupUI() {
        title = "Search"
        navigationItem.largeTitleDisplayMode = .always
        node.backgroundColor = .systemBackground
        node.view.alwaysBounceVertical = true
        node.view.keyboardDismissMode = .onDrag
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search stocks, ETFs (e.g. AAPL)"
        searchController.searchBar.autocapitalizationType = .allCharacters
        searchController.searchBar.autocorrectionType = .no
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        activityIndicator.hidesWhenStopped = true
        let loadingBarButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = loadingBarButton
    }
    
    private func setupAdapter() {
        adapter.setASDKCollectionNode(node)
        adapter.dataSource = self
    }
    
    private func showInitialPrompt() {
        items = [SearchStateDiffableModel(state: .prompt("Type a company name or ticker symbol to explore the market."))]
        adapter.performUpdates(animated: false)
    }
    
    private func bindViewModel() {
        let searchTrigger = searchController.searchBar.rx.text.orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .do(onNext: { [weak self] query in
                self?.currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            })
            .asObservable()
        
        let input = StockSearchViewModel.Input(searchTrigger: searchTrigger)
        let output = viewModel.transform(input: input)
        
        output.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        output.items
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] results in
                guard let self = self else { return }
                
                if results.isEmpty {
                    if self.currentQuery.isEmpty {
                        self.items = [SearchStateDiffableModel(state: .prompt("Type a company name or ticker symbol to explore the market."))]
                    } else {
                        self.items = [SearchStateDiffableModel(state: .empty("No symbols found matching \"\(self.currentQuery)\""))]
                    }
                } else {
                    self.items = results.map { SearchResultDiffableModel(viewModel: $0) }
                }
                
                self.adapter.performUpdates(animated: false)
            })
            .disposed(by: disposeBag)
        
        output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self = self else { return }
                self.items = [SearchStateDiffableModel(state: .error(message))]
                self.adapter.performUpdates(animated: false)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - ListAdapterDataSource
    
    public func objects(for listAdapter: ListAdapter) -> [any ListDiffable] {
        return items
    }
    
    public func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        if object is SearchResultDiffableModel {
            let sectionController = SearchResultSectionController()
            sectionController.onSelect = { [weak self] symbol in
                self?.onSelectStock?(symbol)
            }
            return sectionController
        } else if object is SearchStateDiffableModel {
            return SearchStateSectionController()
        }
        return ListSectionController()
    }
    
    public func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}
