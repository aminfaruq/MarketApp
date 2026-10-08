//
//  MarketNewsCellNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import AsyncDisplayKit
import MarketPresentation
import UIKit

public final class MarketNewsCellNode: ASCellNode {
    
    private let imageNode = ASNetworkImageNode()
    private let sourceNode = ASTextNode()
    private let headlineNode = ASTextNode()
    private let summaryNode = ASTextNode()
    
    public init(viewModel: MarketNewsItemViewModel) {
        super.init()
        
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        setupImage(with: viewModel.imageURL)
        
        setupText(with: viewModel)
    }
    
    private func setupImage(with url: URL?) {
        imageNode.style.preferredSize = CGSize(width: 80, height: 80)
        imageNode.cornerRadius = 8
        imageNode.clipsToBounds = true
        imageNode.contentMode = .scaleAspectFill
        imageNode.placeholderColor = .secondarySystemBackground
        
        imageNode.url = url
    }
    
    private func setupText(with viewModel: MarketNewsItemViewModel) {
        sourceNode.attributedText = NSAttributedString(
            string: viewModel.source.uppercased(),
            attributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        headlineNode.maximumNumberOfLines = 2
        headlineNode.truncationMode = .byTruncatingTail
        headlineNode.attributedText = NSAttributedString(
            string: viewModel.headline,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        )
        
        summaryNode.maximumNumberOfLines = 2
        summaryNode.truncationMode = .byTruncatingTail
        summaryNode.attributedText = NSAttributedString(
            string: viewModel.summary,
            attributes: [
                .font: UIFont.systemFont(ofSize: 13, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let textStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .start,
            children: [sourceNode, headlineNode, summaryNode]
        )
        textStack.style.flexShrink = 1.0
        textStack.style.flexGrow = 1.0
        
        let contentHorizontalStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 12,
            justifyContent: .start,
            alignItems: .center,
            children: [imageNode, textStack]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(
                top: 12,
                left: 16,
                bottom: 12,
                right: 16),
            child: contentHorizontalStack
        )
    }
}
