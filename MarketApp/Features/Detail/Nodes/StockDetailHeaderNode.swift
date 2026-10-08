//
//  StockDetailHeaderNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation
import UIKit

public final class StockDetailHeaderNode: ASDisplayNode {
    private let logoNode = ASNetworkImageNode()
    private let nameNode = ASTextNode()
    private let metaNode = ASTextNode()
    private let industryNode = ASTextNode()
    
    public override init() {
        super.init()
        automaticallyManagesSubnodes = true
        
        logoNode.style.preferredSize = CGSize(width: 56, height: 56)
        logoNode.cornerRadius = 12
        logoNode.clipsToBounds = true
        logoNode.contentMode = .scaleAspectFit
        logoNode.placeholderColor = .secondarySystemBackground
        logoNode.borderWidth = 0.5
        logoNode.borderColor = UIColor.separator.cgColor
        
        nameNode.maximumNumberOfLines = 2
        nameNode.truncationMode = .byTruncatingTail
    }
    
    public func configurePlaceholder(symbol: String) {
        metaNode.attributedText = NSAttributedString(
            string: symbol,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        nameNode.attributedText = NSAttributedString(
            string: "Loading company profile...",
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.placeholderText
            ]
        )
        setNeedsLayout()
    }
    
    public func configure(with viewModel: StockDetailItemViewModel) {
        logoNode.url = viewModel.logoURL
        
        nameNode.attributedText = NSAttributedString(
            string: viewModel.companyName,
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        
        let metaText = "\(viewModel.symbol) • \(viewModel.exchange)"
        metaNode.attributedText = NSAttributedString(
            string: metaText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        if !viewModel.industry.isEmpty {
            industryNode.attributedText = NSAttributedString(
                string: viewModel.industry.uppercased(),
                attributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                    .foregroundColor: UIColor.systemBlue
                ]
            )
        }
        
        setNeedsLayout()
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var textElements: [ASLayoutElement] = []
        if industryNode.attributedText != nil {
            textElements.append(industryNode)
        }
        textElements.append(nameNode)
        textElements.append(metaNode)
        
        let textStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: textElements
        )
        textStack.style.flexShrink = 1.0
        textStack.style.flexGrow = 1.0
        
        let horizontalStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 14,
            justifyContent: .start,
            alignItems: .center,
            children: [logoNode, textStack]
        )
        
        return horizontalStack
    }
}
