//
//  SwiftUIView.swift
//  
//
//  Created by Paul Traylor on 2020/07/24.
//

import SwiftUI


public struct TimelineChart: View {
    @ObservedObject var data: ChartData
    public var style: ChartStyle

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @State private var dragLocation:CGPoint = .zero
    @State private var indicatorLocation:CGPoint = .zero
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity:Double = 0
    @State private var currentDataNumber: Double = 0
    @State private var currentDataString: String = ""
    @State private var hideHorizontalLines: Bool = false
    
    public var body: some View {
        GeometryReader{ geometry in
            ZStack{
                GeometryReader{ reader in
                    Legend(data: self.data,
                           frame: .constant(reader.frame(in: .local)), hideHorizontalLines: self.$hideHorizontalLines)
                        .transition(.opacity)
                        .animation(Animation.easeOut(duration: 1).delay(1))
                    
                    Line(data: self.data,
                         frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 30, height: reader.frame(in: .local).height)),
                         touchLocation: self.$indicatorLocation,
                         showIndicator: self.$hideHorizontalLines,
                         minDataValue: .constant(nil),
                         maxDataValue: .constant(nil),
                         showBackground: false,
                         gradient: self.style.gradientColor
                    )
                    .offset(x: 30, y: -20)
                }
                .frame(width: geometry.frame(in: .local).size.width, height: 240)
                .offset(x: 0, y: 40 )
                HoverView(currentNumber: self.$currentDataNumber, currentLabel:  self.$currentDataString, scheme: style)
                    .opacity(self.opacity)
                    .offset(x: self.dragLocation.x - geometry.frame(in: .local).size.width/2, y: 36)
            }
            .frame(width: geometry.frame(in: .local).size.width, height: 240)
            .gesture(DragGesture()
                        .onChanged({ value in
                            self.dragLocation = value.location
                            self.indicatorLocation = CGPoint(x: max(value.location.x-30,0), y: 32)
                            self.opacity = 1
                            self.closestPoint = self.getClosestDataPoint(toPoint: value.location, width: geometry.frame(in: .local).size.width-30, height: 240)
                            self.hideHorizontalLines = true
                        })
                        .onEnded({ value in
                            self.opacity = 0
                            self.hideHorizontalLines = false
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
    var scheme: ChartStyle
    
    public var body: some View {
        ZStack{
            Text("\(self.currentNumber, specifier: self.currentLabel)")
                .font(.system(size: 18, weight: .bold))
                .offset(x: 0, y:-110)
                .foregroundColor(self.scheme.textColor)
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 60, height: 280)
                .foregroundColor(Color.white)
                .shadow(color: Colors.LegendText, radius: 12, x: 0, y: 6 )
                .blendMode(.multiply)
        }
    }
}

extension TimelineChart {
    public init(data: ChartData) {
        self.data = data
        self.style = Styles.lineChartStyleOne
    }
}


struct TimelineChart_Previews: PreviewProvider {
    static var previews: some View {
        TimelineChart(data: ChartData(values: [("test", 1)]))
    }
}
