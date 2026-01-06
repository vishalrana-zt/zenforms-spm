//
//  CircularProgressView.swift
//  ZenFormsLib
//
//  Created by Harshit on 27/02/25.
//

import UIKit

@IBDesignable public class CircularProgressView: UIView {
    
    @IBInspectable public var totalProgress: CGFloat = 10.0 {
        didSet {
            updateProgress()
        }
    }
    
    @IBInspectable public var currentProgress: CGFloat = 0.0 {
        didSet {
            updateProgress()
        }
    }
    
    @IBInspectable public var totalColor: UIColor = .lightGray {
        didSet {
            totalLayer.strokeColor = totalColor.cgColor
        }
    }
    
    @IBInspectable public var progressColor: UIColor = .blue {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    private let totalLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        layer.addSublayer(totalLayer)
        layer.addSublayer(progressLayer)
        configureLayers()
    }
    
    private func configureLayers() {
        let lineWidth: CGFloat = 3.0
        let radius = (min(frame.width, frame.height) - lineWidth) / 2
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        
        let circularPath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        
        totalLayer.path = circularPath.cgPath
        totalLayer.strokeColor = totalColor.cgColor
        totalLayer.fillColor = UIColor.clear.cgColor
        totalLayer.lineWidth = lineWidth
        totalLayer.lineCap = .round
        
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = currentProgress / totalProgress
    }
    
    private func updateProgress() {
        let progress = max(0, min(currentProgress / totalProgress, 1))
        progressLayer.strokeEnd = progress
    }
}
