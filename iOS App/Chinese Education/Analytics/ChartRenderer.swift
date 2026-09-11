import Foundation
import UIKit
import CoreGraphics

/**
 * CHART RENDERER - Visual Data Representation
 * 
 * Creates visual charts for reports and dashboards:
 * - Line charts for progress over time
 * - Bar charts for PIRLS process comparison
 * - Pie charts for reading purpose distribution
 * - Heat maps for vocabulary mastery
 * - Radar charts for overall PIRLS profile
 */
// MARK: - 📊 CHART RENDERER
class ChartRenderer {
    static let shared = ChartRenderer()
    
    private init() {}
    
    // MARK: - Render Bar Chart (PIRLS Processes)
    /**
     * Renders a bar chart comparing PIRLS process scores.
     * Returns UIImage that can be embedded in PDF reports.
     */
    func renderBarChart(processScores: [PIRLSProcess: Double], size: CGSize = CGSize(width: 400, height: 250)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Chart area
            let chartMargin: CGFloat = 50
            let chartWidth = size.width - 2 * chartMargin
            let chartHeight = size.height - 2 * chartMargin
            let chartRect = CGRect(x: chartMargin, y: chartMargin, width: chartWidth, height: chartHeight)
            
            // Draw bars
            let processes = PIRLSProcess.allCases
            let barWidth = chartWidth / CGFloat(processes.count + 1)
            let maxValue: CGFloat = 1.0
            
            for (index, process) in processes.enumerated() {
                if let score = processScores[process] {
                    let barHeight = CGFloat(score) * chartHeight
                    let barX = chartMargin + CGFloat(index + 1) * barWidth
                    let barY = chartMargin + chartHeight - barHeight
                    
                    // Bar color based on score
                    let color: UIColor
                    if score >= 0.7 {
                        color = .systemGreen
                    } else if score >= 0.5 {
                        color = .systemYellow
                    } else {
                        color = .systemRed
                    }
                    
                    color.setFill()
                    cgContext.fillRect(CGRect(x: barX - barWidth / 2, y: barY, width: barWidth * 0.8, height: barHeight))
                    
                    // Process label
                    let labelText = process.displayName
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12),
                        .foregroundColor: UIColor.black
                    ]
                    let attributedString = NSAttributedString(string: labelText, attributes: attributes)
                    let textSize = attributedString.size()
                    attributedString.draw(at: CGPoint(x: barX - textSize.width / 2, y: chartMargin + chartHeight + 5))
                    
                    // Score label
                    let scoreText = "\(Int(score * 100))%"
                    let scoreAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 14),
                        .foregroundColor: UIColor.black
                    ]
                    let scoreString = NSAttributedString(string: scoreText, attributes: scoreAttributes)
                    let scoreSize = scoreString.size()
                    scoreString.draw(at: CGPoint(x: barX - scoreSize.width / 2, y: barY - scoreSize.height - 5))
                }
            }
            
            // Y-axis labels
            for i in 0...5 {
                let value = CGFloat(i) / 5.0
                let y = chartMargin + chartHeight - (value * chartHeight)
                let labelText = "\(Int(value * 100))%"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.gray
                ]
                let attributedString = NSAttributedString(string: labelText, attributes: attributes)
                attributedString.draw(at: CGPoint(x: 5, y: y - 8))
            }
        }
    }
    
    // MARK: - Render Line Chart (Progress Over Time)
    /**
     * Renders a line chart showing progress over time.
     */
    func renderLineChart(dataPoints: [(date: Date, value: Double)], size: CGSize = CGSize(width: 400, height: 250)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            guard !dataPoints.isEmpty else { return }
            
            // Chart area
            let chartMargin: CGFloat = 50
            let chartWidth = size.width - 2 * chartMargin
            let chartHeight = size.height - 2 * chartMargin
            
            // Find min/max values
            let values = dataPoints.map { $0.value }
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1.0
            let valueRange = maxValue - minValue
            
            // Draw line
            UIColor.systemBlue.setStroke()
            cgContext.setLineWidth(2)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            
            var pathPoints: [CGPoint] = []
            for (index, point) in dataPoints.enumerated() {
                let x = chartMargin + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * chartWidth
                let normalizedValue = valueRange > 0 ? (point.value - minValue) / valueRange : 0.5
                let y = chartMargin + chartHeight - (CGFloat(normalizedValue) * chartHeight)
                pathPoints.append(CGPoint(x: x, y: y))
            }
            
            if pathPoints.count > 1 {
                cgContext.move(to: pathPoints[0])
                for point in pathPoints.dropFirst() {
                    cgContext.addLine(to: point)
                }
                cgContext.strokePath()
            }
            
            // Draw data points
            UIColor.systemBlue.setFill()
            for point in pathPoints {
                cgContext.fillEllipse(in: CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8))
            }
        }
    }
    
    // MARK: - Render Pie Chart (Reading Purpose Distribution)
    /**
     * Renders a pie chart showing reading purpose distribution.
     */
    func renderPieChart(literary: Double, informational: Double, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 20
            
            let total = literary + informational
            guard total > 0 else { return }
            
            // Literary slice
            let literaryAngle = (literary / total) * 2 * .pi
            UIColor.systemBlue.setFill()
            cgContext.move(to: center)
            cgContext.addArc(center: center, radius: radius, startAngle: 0, endAngle: CGFloat(literaryAngle), clockwise: false)
            cgContext.closePath()
            cgContext.fillPath()
            
            // Informational slice
            UIColor.systemOrange.setFill()
            cgContext.move(to: center)
            cgContext.addArc(center: center, radius: radius, startAngle: CGFloat(literaryAngle), endAngle: 2 * .pi, clockwise: false)
            cgContext.closePath()
            cgContext.fillPath()
            
            // Labels
            let literaryLabel = "文學類: \(Int((literary / total) * 100))%"
            let informationalLabel = "資訊類: \(Int((informational / total) * 100))%"
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            NSAttributedString(string: literaryLabel, attributes: attributes).draw(at: CGPoint(x: 20, y: 20))
            NSAttributedString(string: informationalLabel, attributes: attributes).draw(at: CGPoint(x: 20, y: 40))
        }
    }
    
    // MARK: - Render Radar Chart (PIRLS Profile)
    /**
     * Renders a radar chart showing overall PIRLS profile.
     */
    func renderRadarChart(processScores: [PIRLSProcess: Double], size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background
            UIColor.white.setFill()
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 40
            
            let processes = PIRLSProcess.allCases
            let angleStep = 2 * .pi / CGFloat(processes.count)
            
            // Draw grid circles
            UIColor.lightGray.setStroke()
            cgContext.setLineWidth(0.5)
            for i in 1...5 {
                let r = radius * CGFloat(i) / 5.0
                cgContext.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                cgContext.strokePath()
            }
            
            // Draw axes
            for (index, process) in processes.enumerated() {
                let angle = CGFloat(index) * angleStep - .pi / 2
                let endX = center.x + radius * cos(angle)
                let endY = center.y + radius * sin(angle)
                
                UIColor.lightGray.setStroke()
                cgContext.setLineWidth(0.5)
                cgContext.move(to: center)
                cgContext.addLine(to: CGPoint(x: endX, y: endY))
                cgContext.strokePath()
                
                // Process label
                let labelX = endX + 20 * cos(angle)
                let labelY = endY + 20 * sin(angle)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                NSAttributedString(string: process.displayName, attributes: attributes).draw(at: CGPoint(x: labelX - 20, y: labelY - 8))
            }
            
            // Draw data polygon
            var points: [CGPoint] = []
            for (index, process) in processes.enumerated() {
                let score = processScores[process] ?? 0.0
                let angle = CGFloat(index) * angleStep - .pi / 2
                let r = radius * CGFloat(score)
                let x = center.x + r * cos(angle)
                let y = center.y + r * sin(angle)
                points.append(CGPoint(x: x, y: y))
            }
            
            // Fill polygon
            UIColor.systemBlue.withAlphaComponent(0.3).setFill()
            if points.count > 2 {
                cgContext.move(to: points[0])
                for point in points.dropFirst() {
                    cgContext.addLine(to: point)
                }
                cgContext.closePath()
                cgContext.fillPath()
            }
            
            // Stroke polygon
            UIColor.systemBlue.setStroke()
            cgContext.setLineWidth(2)
            if points.count > 2 {
                cgContext.move(to: points[0])
                for point in points.dropFirst() {
                    cgContext.addLine(to: point)
                }
                cgContext.closePath()
                cgContext.strokePath()
            }
        }
    }
}

