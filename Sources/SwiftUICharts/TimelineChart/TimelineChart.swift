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
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity:Double = 0
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

    public var body: some View {
        GeometryReader{ geometry in
            ZStack{
                GeometryReader{ reader in
                    Legend(
                        data: self.data,
                        frame: .constant(reader.frame(in: .local)),
                        hideHorizontalLines: self.$showHovar
                    )
                    .transition(.opacity)
                    .animation(Animation.easeOut(duration: 1).delay(1))
                    
                    Line(
                        data: self.data,
                        frame: .constant(CGRect(
                            x: 0,
                            y: 0,
                            width: reader.frame(in: .local).width - 30,
                            height: reader.frame(in: .local).height
                        )),
                        touchLocation: self.$indicatorLocation,
                        showIndicator: self.$showHovar,
                        minDataValue: .constant(nil),
                        maxDataValue: .constant(nil),
                        showBackground: false,
                        gradient: self.currentStyle.gradientColor
                    )
                    // x offset for legend
                    // y offset for hover padding
                    .offset(x: 30, y: -20)
                }
                .offset(x: 0, y: 40 )
                
                HoverView(
                    currentNumber: self.$currentDataNumber,
                    currentLabel:  self.$currentDataString,
                    style: currentStyle
                )
                .opacity(self.opacity)
                .offset(
                    x: self.dragLocation.x - geometry.frame(in: .local).size.width/2,
                    y: 36
                )
            }
            .frame(
                width: geometry.frame(in: .local).size.width,
                height: 240
            )
            .gesture(DragGesture()
                        .onChanged({ value in
                            self.dragLocation = value.location
                            self.indicatorLocation = CGPoint(
                                x: max(value.location.x-30,0),
                                y: 32
                            )
                            self.opacity = 1
                            self.closestPoint = self.getClosestDataPoint(
                                toPoint: value.location,
                                width: geometry.frame(in: .local).size.width-30,
                                height: 240
                            )
                            self.showHovar = true
                        })
                        .onEnded({ value in
                            self.opacity = 0
                            self.showHovar = false
                        })
            )
            
        }
    }
    
    func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
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
