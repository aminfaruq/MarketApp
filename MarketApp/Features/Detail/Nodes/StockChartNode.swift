//
//  StockChartNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit
import MarketPresentation

public final class StockChartNode: ASDisplayNode {
    public var onScrubPrice: ((Double?, Date?) -> Void)?
    
    private let changeNode = ASTextNode()
    private let dateNode = ASTextNode()
    private let canvasNode = StockChartCanvasNode()
    
    private var timeframeButtons: [StockChartTimeframe: ASButtonNode] = [:]
    private var selectedTimeframe: StockChartTimeframe = .day
    
    private var currentItem: StockDetailItemViewModel?
    private var currentPoints: [StockChartDataPoint] = []
    
    public override init() {
        super.init()
        
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground
        
        setupTimeframeButtons()
        setupScrubHandling()
    }
    
    private func setupTimeframeButtons() {
        for timeframe in StockChartTimeframe.allCases {
            let button = ASButtonNode()
            button.setTitle(timeframe.rawValue, with: UIFont.systemFont(ofSize: 12, weight: .semibold), with: .secondaryLabel, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
            button.cornerRadius = 14
            button.clipsToBounds = true
            
            button.addTarget(self, action: #selector(didTapTimeframe(_:)), forControlEvents: .touchUpInside)
            timeframeButtons[timeframe] = button
        }
        updateButtonStyles()
    }
    
    private func setupScrubHandling() {
        canvasNode.style.height = ASDimension(unit: .points, value: 200)
        canvasNode.onScrub = { [weak self] point in
            guard let self = self else { return }
            if let point = point {
                self.showScrubbedPoint(point)
                self.onScrubPrice?(point.price, point.date)
            } else {
                self.restoreHeader()
                self.onScrubPrice?(nil, nil)
            }
        }
    }
    
    @objc private func didTapTimeframe(_ sender: ASButtonNode) {
        for (timeframe, button) in timeframeButtons where button === sender {
            selectedTimeframe = timeframe
            updateButtonStyles()
            regeneratePoints()
            break
        }
    }
    
    private func updateButtonStyles() {
        for (timeframe, button) in timeframeButtons {
            let isSelected = (timeframe == selectedTimeframe)
            let textColor: UIColor = isSelected ? .systemBackground : .secondaryLabel
            let bgColor: UIColor = isSelected ? .label : .clear
            
            button.setTitle(timeframe.rawValue, with: UIFont.systemFont(ofSize: 12, weight: isSelected ? .bold : .medium), with: textColor, for: .normal)
            button.backgroundColor = bgColor
        }
    }
    
    public func configure(with item: StockDetailItemViewModel) {
        self.currentItem = item
        regeneratePoints()
    }
    
    public func updateLivePrice(_ newPrice: Double) {
        guard var item = currentItem, selectedTimeframe == .day, !currentPoints.isEmpty else { return }
        
        // Update last data point with live streamed price
        let lastIndex = currentPoints.count - 1
        currentPoints[lastIndex] = StockChartDataPoint(date: Date(), price: newPrice)
        
        // Calculate updated isPositive relative to previous close or first point
        let baseline = item.previousClose > 0 ? item.previousClose : currentPoints[0].price
        let isPositive = newPrice >= baseline
        
        canvasNode.configure(
            points: currentPoints,
            isPositive: isPositive,
            baselinePrice: item.previousClose > 0 ? item.previousClose : nil
        )
        
        restoreHeader()
    }
    
    private func regeneratePoints() {
        guard let item = currentItem else { return }
        
        currentPoints = StockChartHistoryGenerator.generatePoints(
            symbol: item.symbol,
            currentPrice: item.currentPrice,
            openPrice: item.openPrice,
            highPrice: item.highPrice,
            lowPrice: item.lowPrice,
            previousClose: item.previousClose,
            timeframe: selectedTimeframe
        )
        
        guard let first = currentPoints.first, let last = currentPoints.last else { return }
        let baseline = selectedTimeframe == .day && item.previousClose > 0 ? item.previousClose : first.price
        let isPositive = last.price >= baseline
        
        canvasNode.configure(
            points: currentPoints,
            isPositive: isPositive,
            baselinePrice: selectedTimeframe == .day && item.previousClose > 0 ? item.previousClose : nil
        )
        
        restoreHeader()
    }
    
    private func restoreHeader() {
        guard let item = currentItem, let first = currentPoints.first, let last = currentPoints.last else { return }
        
        let baseline = selectedTimeframe == .day && item.previousClose > 0 ? item.previousClose : first.price
        let delta = last.price - baseline
        let pct = baseline > 0 ? (delta / baseline) * 100.0 : 0.0
        
        let sign = delta >= 0 ? "+" : ""
        let isPos = delta >= 0
        let color: UIColor = isPos ? .systemGreen : .systemRed
        
        let text = String(format: "%@$%.2f (%@%.2f%%) %@", sign, delta, sign, pct, selectedTimeframe.rawValue)
        changeNode.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: color
            ]
        )
        
        let subtitle: String
        switch selectedTimeframe {
        case .day: subtitle = "Today"
        case .week: subtitle = "Past week"
        case .month: subtitle = "Past month"
        case .year: subtitle = "Past year"
        case .all: subtitle = "All time"
        }
        
        dateNode.attributedText = NSAttributedString(
            string: subtitle,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }
    
    private func showScrubbedPoint(_ point: StockChartDataPoint) {
        guard let first = currentPoints.first else { return }
        
        let baseline = selectedTimeframe == .day && (currentItem?.previousClose ?? 0) > 0 ? currentItem!.previousClose : first.price
        let delta = point.price - baseline
        let pct = baseline > 0 ? (delta / baseline) * 100.0 : 0.0
        
        let sign = delta >= 0 ? "+" : ""
        let color: UIColor = delta >= 0 ? .systemGreen : .systemRed
        
        let text = String(format: "$%.2f (%@$%.2f, %@%.2f%%)", point.price, sign, delta, sign, pct)
        changeNode.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: color
            ]
        )
        
        let formatter = DateFormatter()
        if selectedTimeframe == .day {
            formatter.dateFormat = "MMM d, h:mm a"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        dateNode.attributedText = NSAttributedString(
            string: formatter.string(from: point.date),
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.label
            ]
        )
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let headerStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [changeNode, dateNode]
        )
        
        let buttons = StockChartTimeframe.allCases.compactMap { timeframeButtons[$0] }
        let selectorStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 6,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: buttons
        )
        
        let mainStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 12,
            justifyContent: .start,
            alignItems: .stretch,
            children: [headerStack, canvasNode, selectorStack]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0),
            child: mainStack
        )
    }
}
