//
//  StockDetailPriceNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation
import UIKit

public final class StockDetailPriceNode: ASDisplayNode {
    private let priceNode = ASTextNode()
    private let changeNode = ASTextNode()
    private let liveBadgeNode = ASTextNode()
    private let tradeInfoNode = ASTextNode()
    
    private var lastConfiguredViewModel: StockDetailItemViewModel?
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        cornerRadius = 12
        clipsToBounds = true
        
        updateConnectionStatus(isConnected: false)
    }
    
    public func configure(with viewModel: StockDetailItemViewModel) {
        self.lastConfiguredViewModel = viewModel
        priceNode.attributedText = NSAttributedString(
            string: viewModel.formattedPrice,
            attributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        
        let changeColor: UIColor = viewModel.isPositive ? .systemGreen : .systemRed
        changeNode.attributedText = NSAttributedString(
            string: viewModel.formattedChange,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: changeColor
            ]
        )
        
        setNeedsLayout()
    }
    
    public func showScrubbedPrice(_ price: Double) {
        priceNode.attributedText = NSAttributedString(
            string: String(format: "$%.2f", price),
            attributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        setNeedsLayout()
    }
    
    public func restorePrice() {
        guard let vm = lastConfiguredViewModel else { return }
        priceNode.attributedText = NSAttributedString(
            string: vm.formattedPrice,
            attributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        setNeedsLayout()
    }
    
    public func updateConnectionStatus(isConnected: Bool) {
        let statusString = isConnected ? "● LIVE" : "○ OFFLINE"
        let statusColor: UIColor = isConnected ? .systemGreen : .secondaryLabel
        
        liveBadgeNode.attributedText = NSAttributedString(
            string: statusString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: statusColor
            ]
        )
        setNeedsLayout()
    }
    
    public func updateLiveTrade(_ trade: LiveTradeItemViewModel) {
        priceNode.attributedText = NSAttributedString(
            string: trade.formattedPrice,
            attributes: [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: trade.timestamp)
        let infoStr = String(format: "Vol: %.0f • %@", trade.volume, timeStr)
        
        tradeInfoNode.attributedText = NSAttributedString(
            string: infoStr,
            attributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        flashPrice(direction: trade.direction)
        setNeedsLayout()
    }
    
    private func flashPrice(direction: PriceChangeDirection) {
        guard isNodeLoaded, direction != .same else { return }
        
        let flashColor: UIColor = direction == .up
            ? UIColor.systemGreen.withAlphaComponent(0.2)
            : UIColor.systemRed.withAlphaComponent(0.2)
        
        UIView.animate(withDuration: 0.15, animations: {
            self.view.backgroundColor = flashColor
        }) { _ in
            UIView.animate(withDuration: 0.45) {
                self.view.backgroundColor = .clear
            }
        }
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spacer = ASLayoutSpec()
        spacer.style.flexGrow = 1.0
        
        let topRow = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 8,
            justifyContent: .start,
            alignItems: .center,
            children: [priceNode, spacer, liveBadgeNode]
        )
        
        var verticalChildren: [ASLayoutElement] = [topRow, changeNode]
        if tradeInfoNode.attributedText != nil {
            verticalChildren.append(tradeInfoNode)
        }
        
        let mainStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 6,
            justifyContent: .start,
            alignItems: .stretch,
            children: verticalChildren
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0),
            child: mainStack
        )
    }
}
