//
//  ViewModelType.swift
//  MarketApp
//
//  Created by Amin faruq on 07/10/26.
//

import Foundation

public protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}
