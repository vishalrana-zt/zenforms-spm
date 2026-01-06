//
//  LineChart.swift
//  ZenFormsLib
//
//  Created by apple on 12/03/25.
//
import SwiftUI
import Charts

struct LineChartData {
    var id = UUID()
    var x: Double
    var y: Double

}

struct LineChartDataSet {
    var label: String
    var data: [LineChartData]
    var lineColor:Color
}

struct LineChartView: View {
    
    let data: [ LineChartDataSet]
    var chartTitle: String
    var xAxislabel: String
    var yAxislabel: String
    var plotBothValue: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            SwiftUI.Text(chartTitle)
                .foregroundStyle(.black)
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            
            Chart(data, id: \.label) { dataSeries in
                ForEach(dataSeries.data, id: \.id) { data in
                    LineMark(x: .value("X", data.x), y: .value("Y", data.y))
                        .interpolationMethod(.cardinal)
                        .foregroundStyle(dataSeries.lineColor)
                        .lineStyle(.init(lineWidth: 2))
                        .symbol {
                            Circle()
                                .stroke(dataSeries.lineColor, lineWidth: 1.5)
                                .frame(width: 5, height: 5)
                                .overlay {
                                    SwiftUI.Text("(\(Double(data.x).formatted()),\(Double(data.y).formatted()))")
                                        .frame(width: 80, height: 8)
                                        .font(.system(size: 8, weight: .medium))
                                        .offset(y: -12)
                                        .foregroundStyle(plotBothValue ? .black : .clear)
                                }
                        }

                }
                .foregroundStyle(by: .value("Set", dataSeries.label))
            }
            .chartLegend(position: .bottom, alignment: .center){
                if #available(iOS 17.0, *) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(data, id: \.label) { dataSeries in
                                Rectangle()
                                    .fill(dataSeries.lineColor)
                                    .frame(width: 8, height: 8)
                                SwiftUI.Text(dataSeries.label)
                                    .foregroundStyle(.gray)
                                    .font(.system(size: 12, weight: .medium))
                            }
                        }
                    }
                    .defaultScrollAnchor(.center)
                    .scrollBounceBehavior(.basedOnSize, axes: [.horizontal])
                    .padding(.vertical, 10)
                } else {
                    HStack(spacing: 4) {
                        ForEach(data, id: \.label) { dataSeries in
                            Rectangle()
                                .fill(dataSeries.lineColor)
                                .frame(width: 8, height: 8)
                            SwiftUI.Text(dataSeries.label)
                                .foregroundStyle(.gray)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .border(width: 1.0, edges: [.leading, .bottom], color: .gray)
            }
            .chartXAxis {
                AxisMarks(
                    preset: .aligned,
                    position: .bottom,
//                    values: .stride(by: 100)
                    stroke: StrokeStyle(lineWidth: 0.5)
                )
            }
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                SwiftUI.Text(xAxislabel)
                    .foregroundStyle(.black)
            }
            .chartYAxis {
                AxisMarks(
                    preset: .aligned,
                    position: .leading,
//                    values: .stride(by: 25)
                    stroke: StrokeStyle(lineWidth: 0.5)
                )
            }
            .chartYAxisLabel(position: .leading, alignment: .center) {
                SwiftUI.Text(yAxislabel)
                    .foregroundStyle(.black)
                    .rotationEffect(Angle(degrees: 180))
            }
        }
        .padding(.horizontal, 24)
    }
}

extension UIView{
    func removeSubviews() {
        subviews.forEach({$0.removeFromSuperview()})
    }
}
extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        edges.map { edge -> Path in
            switch edge {
            case .top: return Path(.init(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom: return Path(.init(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading: return Path(.init(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing: return Path(.init(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }.reduce(into: Path()) { $0.addPath($1) }
    }
}
