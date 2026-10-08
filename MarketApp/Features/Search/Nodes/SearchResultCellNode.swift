//
//  SearchResultCellNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit
import MarketPresentation

public final class SearchResultCellNode: ASCellNode {
    private let symbolNode = ASTextNode()
    private let companyNameNode = ASTextNode()
    private let typeBadgeNode = ASTextNode()
    private let badgeBackgroundNode = ASDisplayNode()
    
    public init(viewModel: SearchResultItemViewModel) {
        super.init()
        
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground
        selectionStyle = .default
        
        setupBadge()
        configure(with: viewModel)
    }
    
    private func setupBadge() {
        badgeBackgroundNode.backgroundColor = .secondarySystemFill
        badgeBackgroundNode.cornerRadius = 6
        badgeBackgroundNode.clipsToBounds = true
    }
    
    private func configure(with viewModel: SearchResultItemViewModel) {
        symbolNode.attributedText = NSAttributedString(
            string: viewModel.symbol,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                .foregroundColor: UIColor.label
            ]
        )
        
        companyNameNode.maximumNumberOfLines = 1
        companyNameNode.truncationMode = .byTruncatingTail
        companyNameNode.attributedText = NSAttributedString(
            string: viewModel.companyName,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        let displayType = viewModel.type.isEmpty ? "Stock" : viewModel.type
        typeBadgeNode.attributedText = NSAttributedString(
            string: displayType.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let leftStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 3,
            justifyContent: .start,
            alignItems: .start,
            children: [symbolNode, companyNameNode]
        )
        leftStack.style.flexGrow = 1.0
        leftStack.style.flexShrink = 1.0
        
        let badgeInset = ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8),
            child: typeBadgeNode
        )
        let badgeSpec = ASBackgroundLayoutSpec(child: badgeInset, background: badgeBackgroundNode)
        
        let mainStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 12,
            justifyContent: .spaceBetween,
            alignItems: .center,
            children: [leftStack, badgeSpec]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
            child: mainStack
        )
    }
}
