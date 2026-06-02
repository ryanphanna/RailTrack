import SwiftUI

struct TicketShape: Shape {
    var notchRadius: CGFloat = 12
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        let notchY = rect.maxY * 0.62
        // Right notch
        path.addLine(to: CGPoint(x: rect.maxX, y: notchY - notchRadius))
        path.addArc(center: CGPoint(x: rect.maxX, y: notchY),
                    radius: notchRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(90),
                    clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        
        // Left notch
        path.addLine(to: CGPoint(x: rect.minX, y: notchY + notchRadius))
        path.addArc(center: CGPoint(x: rect.minX, y: notchY),
                    radius: notchRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(-90),
                    clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        
        return path
    }
}

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
