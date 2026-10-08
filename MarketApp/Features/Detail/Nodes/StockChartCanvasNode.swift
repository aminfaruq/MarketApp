//
//  StockChartCanvasNode.swift
//  MarketApp
//
//  Created by Amin faruq on 08/10/26.
//

import UIKit
import AsyncDisplayKit

public final class StockChartCanvasNode: ASDisplayNode, UIGestureRecognizerDelegate {
    public var onScrub: ((StockChartDataPoint?) -> Void)?
    
    private var points: [StockChartDataPoint] = []
    private var isPositive: Bool = true
    private var baselinePrice: Double?
    
    private let lineLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    private let gradientMaskLayer = CAShapeLayer()
    private let baselineLayer = CAShapeLayer()
    private let cursorLineLayer = CAShapeLayer()
    private let cursorDotLayer = CALayer()
    private let cursorDotInner = CALayer()
    
    private var feedbackGenerator: UISelectionFeedbackGenerator?
    private var lastScrubIndex: Int?
    
    public override init() {
        super.init()
        backgroundColor = .clear
    }
    
    public override func didLoad() {
        super.didLoad()
        
        setupLayers()
        setupGestures()
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
    }
    
    private func setupLayers() {
        guard let view = self.view as? _ASDisplayView else { return }
        
        // Baseline layer (dashed line for previous close)
        baselineLayer.strokeColor = UIColor.quaternaryLabel.cgColor
        baselineLayer.lineWidth = 1.0
        baselineLayer.lineDashPattern = [4, 4]
        baselineLayer.fillColor = nil
        view.layer.addSublayer(baselineLayer)
        
        // Gradient layer masked to area under curve
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.mask = gradientMaskLayer
        view.layer.addSublayer(gradientLayer)
        
        // Line chart stroke
        lineLayer.fillColor = nil
        lineLayer.lineWidth = 2.0
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        view.layer.addSublayer(lineLayer)
        
        // Scrub cursor line
        cursorLineLayer.strokeColor = UIColor.secondaryLabel.cgColor
        cursorLineLayer.lineWidth = 1.0
        cursorLineLayer.lineDashPattern = [3, 3]
        cursorLineLayer.opacity = 0.0
        view.layer.addSublayer(cursorLineLayer)
        
        // Scrub indicator dot
        cursorDotLayer.bounds = CGRect(x: 0, y: 0, width: 14, height: 14)
        cursorDotLayer.cornerRadius = 7
        cursorDotLayer.backgroundColor = UIColor.systemBackground.cgColor
        cursorDotLayer.shadowColor = UIColor.black.cgColor
        cursorDotLayer.shadowOpacity = 0.2
        cursorDotLayer.shadowOffset = CGSize(width: 0, height: 2)
        cursorDotLayer.shadowRadius = 3
        cursorDotLayer.opacity = 0.0
        
        cursorDotInner.bounds = CGRect(x: 0, y: 0, width: 8, height: 8)
        cursorDotInner.cornerRadius = 4
        cursorDotInner.position = CGPoint(x: 7, y: 7)
        cursorDotLayer.addSublayer(cursorDotInner)
        view.layer.addSublayer(cursorDotLayer)
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleScrub(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    public func configure(points: [StockChartDataPoint], isPositive: Bool, baselinePrice: Double? = nil) {
        self.points = points
        self.isPositive = isPositive
        self.baselinePrice = baselinePrice
        
        if isNodeLoaded {
            renderChart()
        }
    }
    
    public override func layout() {
        super.layout()
        if isNodeLoaded {
            renderChart()
        }
    }
    
    private func renderChart() {
        let bounds = self.bounds
        guard bounds.width > 0 && bounds.height > 0 && points.count > 1 else { return }
        
        let prices = points.map { $0.price }
        var minPrice = prices.min() ?? 0
        var maxPrice = prices.max() ?? 1
        
        if let baseline = baselinePrice, baseline > 0 {
            minPrice = min(minPrice, baseline)
            maxPrice = max(maxPrice, baseline)
        }
        
        let range = maxPrice - minPrice
        let safeRange = range > 0.0001 ? range : 1.0
        
        let topPadding: CGFloat = 16.0
        let bottomPadding: CGFloat = 16.0
        let availableHeight = bounds.height - topPadding - bottomPadding
        
        func pointFor(index: Int) -> CGPoint {
            let x = bounds.width * CGFloat(index) / CGFloat(points.count - 1)
            let normalizedPrice = CGFloat((points[index].price - minPrice) / safeRange)
            let y = bounds.height - bottomPadding - (normalizedPrice * availableHeight)
            return CGPoint(x: x, y: y)
        }
        
        // 1. Draw smooth bezier curve
        let linePath = UIBezierPath()
        let startPoint = pointFor(index: 0)
        linePath.move(to: startPoint)
        
        for i in 1..<points.count {
            let current = pointFor(index: i)
            let previous = pointFor(index: i - 1)
            let midX = (previous.x + current.x) / 2.0
            
            let control1 = CGPoint(x: midX, y: previous.y)
            let control2 = CGPoint(x: midX, y: current.y)
            linePath.addCurve(to: current, controlPoint1: control1, controlPoint2: control2)
        }
        
        let strokeColor: UIColor = isPositive ? .systemGreen : .systemRed
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = strokeColor.cgColor
        
        // 2. Closed fill path for gradient
        let fillPath = linePath.copy() as! UIBezierPath
        let lastPoint = pointFor(index: points.count - 1)
        fillPath.addLine(to: CGPoint(x: lastPoint.x, y: bounds.height))
        fillPath.addLine(to: CGPoint(x: startPoint.x, y: bounds.height))
        fillPath.close()
        
        gradientMaskLayer.path = fillPath.cgPath
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            strokeColor.withAlphaComponent(0.28).cgColor,
            strokeColor.withAlphaComponent(0.0).cgColor
        ]
        
        // 3. Baseline dashed line
        if let baseline = baselinePrice, baseline > 0 {
            let normalized = CGFloat((baseline - minPrice) / safeRange)
            let baselineY = bounds.height - bottomPadding - (normalized * availableHeight)
            let basePath = UIBezierPath()
            basePath.move(to: CGPoint(x: 0, y: baselineY))
            basePath.addLine(to: CGPoint(x: bounds.width, y: baselineY))
            baselineLayer.path = basePath.cgPath
            baselineLayer.isHidden = false
        } else {
            baselineLayer.isHidden = true
        }
        
        cursorDotInner.backgroundColor = strokeColor.cgColor
    }
    
    // MARK: - Gestures & Scrubbing
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        updateScrub(at: location)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.endScrub()
        }
    }
    
    @objc private func handleScrub(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            let location = gesture.location(in: view)
            updateScrub(at: location)
        case .ended, .cancelled, .failed:
            endScrub()
        default:
            break
        }
    }
    
    private func updateScrub(at location: CGPoint) {
        guard points.count > 1, bounds.width > 0 else { return }
        
        let progress = max(0.0, min(1.0, location.x / bounds.width))
        let index = Int(round(progress * CGFloat(points.count - 1)))
        
        if lastScrubIndex != index {
            feedbackGenerator?.selectionChanged()
            lastScrubIndex = index
        }
        
        let point = points[index]
        
        // Calculate point coordinate on canvas
        let prices = points.map { $0.price }
        var minPrice = prices.min() ?? 0
        var maxPrice = prices.max() ?? 1
        if let baseline = baselinePrice, baseline > 0 {
            minPrice = min(minPrice, baseline)
            maxPrice = max(maxPrice, baseline)
        }
        let safeRange = max(maxPrice - minPrice, 0.0001)
        let topPadding: CGFloat = 16.0
        let bottomPadding: CGFloat = 16.0
        let availableHeight = bounds.height - topPadding - bottomPadding
        
        let x = bounds.width * CGFloat(index) / CGFloat(points.count - 1)
        let normalized = CGFloat((point.price - minPrice) / safeRange)
        let y = bounds.height - bottomPadding - (normalized * availableHeight)
        
        // Update cursor line
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: x, y: 0))
        linePath.addLine(to: CGPoint(x: x, y: bounds.height))
        cursorLineLayer.path = linePath.cgPath
        cursorLineLayer.opacity = 1.0
        
        cursorDotLayer.position = CGPoint(x: x, y: y)
        cursorDotLayer.opacity = 1.0
        CATransaction.commit()
        
        onScrub?(point)
    }
    
    private func endScrub() {
        lastScrubIndex = nil
        UIView.animate(withDuration: 0.25) {
            self.cursorLineLayer.opacity = 0.0
            self.cursorDotLayer.opacity = 0.0
        }
        onScrub?(nil)
    }
}
