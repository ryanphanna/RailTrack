import SwiftUI

struct ScheduleCard: View {
    @Binding var departureDate: Date
    @Binding var arrivalDate: Date
    let selectedOperator: String
    
    var body: some View {
        HStack(spacing: 20) {
            // Departs
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                    Text("DEPARTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                }
                
                DatePicker("", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(ColorTheme.operatorColor(for: selectedOperator))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Vertical Divider
            Rectangle()
                .fill(ColorTheme.textTertiary.opacity(0.08))
                .frame(width: 1, height: 44)
            
            // Arrives
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.left.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                    Text("ARRIVES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                }
                
                DatePicker("", selection: $arrivalDate,
                           in: departureDate...,
                           displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(ColorTheme.operatorColor(for: selectedOperator))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(ColorTheme.surface, in: UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0))
        .overlay(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 16, bottomTrailingRadius: 16, topTrailingRadius: 0)
                .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.08), lineWidth: 1)
        )
    }
}
