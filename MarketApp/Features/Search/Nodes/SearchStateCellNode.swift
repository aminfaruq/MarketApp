//
//  SearchStateCellNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit

public final class SearchStateCellNode: ASCellNode {
    private let iconNode = ASImageNode()
    private let messageNode = ASTextNode()
    
    public init(state: SearchStateType) {
        super.init()
        
        automaticallyManagesSubnodes = true
        backgroundColor = .systemBackground
        selectionStyle = .none
        
        configure(state: state)
    }
    
    private func configure(state: SearchStateType) {
        let iconName: String
        let message: String
        let iconColor: UIColor
        
        switch state {
        case .prompt(let text):
            iconName = "magnifyingglass"
            message = text
            iconColor = .tertiaryLabel
        case .empty(let text):
            iconName = "magnifyingglass"
            message = text
            iconColor = .secondaryLabel
        case .error(let text):
            iconName = "exclamationmark.triangle"
            message = text
            iconColor = .systemOrange
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
        iconNode.image = UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
        iconNode.style.preferredSize = CGSize(width: 48, height: 48)
        iconNode.contentMode = .scaleAspectFit
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 4
        
        messageNode.attributedText = NSAttributedString(
            string: message,
            attributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: paragraph
            ]
        )
    }
    
    public override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 16,
            justifyContent: .center,
            alignItems: .center,
            children: [iconNode, messageNode]
        )
        
        return ASInsetLayoutSpec(
            insets: UIEdgeInsets(top: 80, left: 32, bottom: 40, right: 32),
            child: stack
        )
    }
}
