//
//  StockDetailMetricsNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation
import UIKit

public final class StockDetailMetricsNode: ASDisplayNode {
    private let titleNode = ASTextNode()
    
    private let openItem = MetricItemNode(title: "Open")
    private let highItem = MetricItemNode(title: "High")
    private let lowItem = MetricItemNode(title: "Low")
    private let prevCloseItem = MetricItemNode(title: "Prev Close")
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        
        backgroundColor = .secondarySystemBackground
        cornerRadius = 16
        
        titleNode.attributedText = NSAttributedString(
            string: "Key Statistics",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
    }
    
    public func configure(with viewModel: StockDetailItemViewModel) {
        openItem.setValue(viewModel.formattedOpen)
        highItem.setValue(viewModel.formattedHigh)
        lowItem.setValue(viewModel.formattedLow)
        prevCloseItem.setValue(viewModel.formattedPrevClose)
        setNeedsLayout()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        openItem.style.flexGrow = 1.0
        highItem.style.flexGrow = 1.0
        lowItem.style.flexGrow = 1.0
        prevCloseItem.style.flexGrow = 1.0
        
        let row1 = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 16,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [openItem, highItem]
        )
        
        let row2 = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 16,
            justifyContent: .spaceBetween,
            alignItems: .start,
            children: [lowItem, prevCloseItem]
        )
        
        let cardStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .start,
            alignItems: .stretch,
            children: [titleNode, row1, row2]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            child: cardStack
        )
    }
}

private final class MetricItemNode: ASDisplayNode {
    private let titleLabel = ASTextNode()
    private let valueLabel = ASTextNode()
    
    init(title: String) {
        super.init()
        automaticallyManagesSubnodes = true
        
        titleLabel.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        valueLabel.attributedText = NSAttributedString(
            string: "-",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
    }
    
    func setValue(_ value: String) {
        valueLabel.attributedText = NSAttributedString(
            string: value,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        setNeedsLayout()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [titleLabel, valueLabel]
        )
    }
}
