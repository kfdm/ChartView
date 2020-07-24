//
//  SwiftUIView.swift
//  
//
//  Created by Paul Traylor on 2020/07/24.
//

import SwiftUI


public struct TimelineChart: View {
    @ObservedObject var data: ChartData
    
    // For hover state
    @State private var dragLocation:CGPoint = .zero
    @State private var indicatorLocation:CGPoint = .zero
    @State private var currentDataNumber: Double = 0
    @State private var currentDataString: String = ""
    @State private var showHovar: Bool = false
    
    // Color styles
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    public var lightStyle: ChartStyle
    public var darkStyle: ChartStyle
    public var currentStyle: ChartStyle {
        return self.colorScheme == .dark ? darkStyle : lightStyle
    }
    
    // Constants
    private let leftPadding :CGFloat = 30
    private let verticalPadding: CGFloat = 20
    
    public var body: some View {
        GeometryReader{ geometry in
            ZStack{
                GeometryReader{ reader in
                    Legend(
                        data: self.data,
                        frame: .constant(reader.frame(in: .local)),
                        hideHorizontalLines: self.$showHovar
                    )
                    
                    Line(
                        data: self.data,
                        frame: .constant(CGRect(
                            x: 0,
                            y: 0,
                            width: reader.frame(in: .local).width - leftPadding * 2,
                            height: reader.frame(in: .local).height - verticalPadding * 2
                        )),
                        touchLocation: self.$indicatorLocation,
                        showIndicator: self.$showHovar,
                        minDataValue: .constant(nil),
                        maxDataValue: .constant(nil),
                        showBackground: false,
                        gradient: self.currentStyle.gradientColor
                    )
                    .offset(x: leftPadding, y: verticalPadding * -1)
                }
                .offset(x: 0, y: verticalPadding * 2 )
                
                HoverView(
                    currentNumber: self.$currentDataNumber,
                    currentLabel:  self.$currentDataString,
                    style: currentStyle
                )
                .opacity(self.showHovar ? 1 : 0)
                .offset(
                    x: self.dragLocation.x - geometry.frame(in: .local).size.width/2,
                    y: verticalPadding
                )
            }
            .gesture(DragGesture()
                        .onChanged({ value in
                            self.dragLocation = value.location
                            self.indicatorLocation = CGPoint(
                                x: max(value.location.x-leftPadding,0),
                                y: 32
                            )
                            self.getClosestDataPoint(
                                toPoint: value.location,
                                width: geometry.frame(in: .local).size.width-leftPadding,
                                height: geometry.frame(in: .local).size.height
                            )
                            self.showHovar = true
                        })
                        .onEnded({ value in
                            self.showHovar = false
                        })
            )
        }
    }
    
    @discardableResult func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(points.max()! + points.min()!)
        
        let index:Int = Int(floor((toPoint.x-15)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentDataString = data.points[index].0
            self.currentDataNumber = data.points[index].1
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }
}

public struct HoverView: View {
    @Binding var currentNumber: Double
    @Binding var currentLabel: String
    var style: ChartStyle
    var valueSpecifier = "%.1f"
    
    public var body: some View {
        ZStack{
            VStack {
                Text("\(self.currentLabel)")
                Text("\(self.currentNumber, specifier: valueSpecifier)")
            }
            .font(.system(size: 18, weight: .bold))
            .offset(x: 0, y:-110)
            .foregroundColor(self.style.textColor)
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 60, height: 280)
                .foregroundColor(Color.white)
                .shadow(color: Colors.LegendText, radius: 12, x: 0, y: 6 )
                .blendMode(.multiply)
        }
    }
}

extension TimelineChart {
    public init(data: ChartData, lightStyle: ChartStyle = Styles.lineChartStyleOne, darkStyle: ChartStyle = Styles.lineViewDarkMode) {
        self.data = data
        self.lightStyle = lightStyle
        self.darkStyle = darkStyle
    }
}


struct TimelineChart_Previews: PreviewProvider {
    static var previews: some View {
        TimelineChart(data: ChartData(values: [("test", 1)]))
    }
}
