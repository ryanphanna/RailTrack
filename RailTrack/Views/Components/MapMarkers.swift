import SwiftUI
import MapKit

struct StationMarker: View {
    let code: String
    let isOrigin: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(code)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(isOrigin ? Color.white.opacity(0.2) : Color.white.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.4), lineWidth: 1))

            Triangle()
                .fill(isOrigin ? Color.white.opacity(0.5) : Color.white.opacity(0.3))
                .frame(width: 8, height: 5)
        }
    }
}

struct TrainPositionMarker: View {
    let operatorColor: Color
    let trainNumber: String?
    @State private var pulse = false

    init(operatorColor: Color, trainNumber: String? = nil) {
        self.operatorColor = operatorColor
        self.trainNumber = trainNumber
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(operatorColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .scaleEffect(pulse ? 1.5 : 1.0)
                    .opacity(pulse ? 0 : 1)
                    .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: false), value: pulse)

                Circle()
                    .fill(operatorColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "tram.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: operatorColor.opacity(0.4), radius: 4)
            }
            
            if let num = trainNumber {
                Text(num)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.6), in: Capsule())
            }
        }
        .onAppear { pulse = true }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
