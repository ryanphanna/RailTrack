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
    @State private var pulse = false

    var body: some View {
        ZStack {
            Circle()
                .fill(operatorColor.opacity(0.25))
                .frame(width: 40, height: 40)
                .scaleEffect(pulse ? 1.4 : 1.0)
                .opacity(pulse ? 0 : 1)
                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)

            Circle()
                .fill(operatorColor)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "tram.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: operatorColor.opacity(0.6), radius: 6)
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
