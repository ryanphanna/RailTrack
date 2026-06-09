import SwiftUI

struct SelectedTrainInfo: Identifiable, Equatable {
    var id: String { "\(operatorName)-\(trainNumber)" }
    let trainNumber: String
    let operatorName: String
    let originCode: String
    let originName: String
    let destCode: String
    let destName: String
    let speed: Int?
    let delayMinutes: Int
    let lat: Double
    let lon: Double
    
    static func == (lhs: SelectedTrainInfo, rhs: SelectedTrainInfo) -> Bool {
        lhs.id == rhs.id
    }
}

struct SelectedTrainDrawerView: View {
    let info: SelectedTrainInfo
    let onClose: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Train \(info.trainNumber)")
                        .font(.rtHeadline)
                        .foregroundStyle(ColorTheme.textPrimary)
                    
                    Text(info.operatorName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(ColorTheme.operatorColor(for: info.operatorName), in: RoundedRectangle(cornerRadius: 4))
                    
                    Spacer().frame(height: 8)
                    
                    if let speed = info.speed, speed > 0 {
                        Text("\(speed) \(info.operatorName == "Amtrak" ? "mph" : "km/h")")
                            .font(.rtMono.bold())
                            .foregroundStyle(ColorTheme.accentGreen)
                    } else {
                        Text("Stationary")
                            .font(.rtCaption.bold())
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(info.originCode)
                            .font(.rtMono.bold())
                            .foregroundStyle(ColorTheme.textPrimary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(ColorTheme.textTertiary)
                        Text(info.destCode)
                            .font(.rtMono.bold())
                            .foregroundStyle(ColorTheme.textPrimary)
                    }
                    
                    Text("\(info.originName) ➔ \(info.destName)")
                        .font(.rtCaption)
                        .foregroundStyle(ColorTheme.textSecondary)
                        .lineLimit(2)
                    
                    Spacer().frame(height: 6)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(info.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                            .frame(width: 6, height: 6)
                        
                        Text(info.delayMinutes > 0 ? "\(info.delayMinutes) min delay" : "On Time")
                            .font(.rtCaption.bold())
                            .foregroundStyle(info.delayMinutes > 0 ? ColorTheme.accentAmber : ColorTheme.accentGreen)
                    }
                }
                
                Spacer()

                VStack(spacing: 10) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ColorTheme.textSecondary)
                            .padding(10)
                            .background(ColorTheme.surface, in: Circle())
                            .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)

                    Button(action: onAdd) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(ColorTheme.accent, in: Circle())
                            .shadow(color: ColorTheme.accent.opacity(0.4), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
