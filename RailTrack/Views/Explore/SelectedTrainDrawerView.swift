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
                
                Button(action: onAdd) {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(ColorTheme.accent)
                        Text("Add")
                            .font(.rtCaption.bold())
                            .foregroundStyle(ColorTheme.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            
            Button(action: onClose) {
                Text("Close")
                    .font(.rtSubhead.bold())
                    .foregroundStyle(ColorTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(ColorTheme.surfaceHigh, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ColorTheme.textTertiary.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
    }
}
