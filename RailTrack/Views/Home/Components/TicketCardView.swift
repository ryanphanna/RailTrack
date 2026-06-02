import SwiftUI

struct TicketCardView: View {
    @Binding var originQuery: String
    @Binding var selectedOrigin: Station?
    @Binding var destinationQuery: String
    @Binding var selectedDestination: Station?
    @Binding var trainNumber: String
    @Binding var selectedOperator: String
    @Binding var isLookingUp: Bool
    
    let originCode: String
    let originName: String
    let destinationCode: String
    let destinationName: String
    let operators: [String]
    
    @FocusState.Binding var isOriginFocused: Bool
    @FocusState.Binding var isDestinationFocused: Bool
    @FocusState.Binding var isTrainFocused: Bool
    
    let onLookup: () -> Void
    let onOriginChange: (String) -> Void
    let onTrainSubmit: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            routeSection
            
            // Ticket dashed separator
            GeometryReader { geo in
                let notchY = geo.size.height / 2
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.25))
                    .frame(height: 1)
                    .position(x: geo.size.width / 2, y: notchY)
            }
            .frame(height: 1)
            
            trainSection
        }
        .background(
            TicketShape()
                .fill(ColorTheme.surface)
        )
        .overlay(
            TicketShape()
                .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.12), lineWidth: 1.5)
        )
    }
    
    private var routeSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Origin
            VStack(alignment: .leading, spacing: 4) {
                Text("FROM")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                
                ZStack(alignment: .leading) {
                    TextField("Search…", text: $originQuery, prompt: Text("Search…").foregroundColor(ColorTheme.textTertiary.opacity(0.5)))
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                        .focused($isOriginFocused)
                        .autocorrectionDisabled()
                        .opacity(isOriginFocused || (selectedOrigin == nil && originQuery.isEmpty) ? 1 : 0)
                        .onChange(of: originQuery) { _, new in
                            onOriginChange(new)
                        }
                    
                    if !isOriginFocused && (selectedOrigin != nil || !originQuery.isEmpty) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(originCode)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(selectedOrigin != nil ? ColorTheme.textPrimary : ColorTheme.textTertiary.opacity(0.6))
                            Text(originName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(ColorTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOrigin = nil
                            originQuery = ""
                            isOriginFocused = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Connection line and train icon
            ZStack {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .foregroundStyle(ColorTheme.textTertiary.opacity(0.3))
                    .frame(height: 1)
                
                Image(systemName: "tram.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                    .padding(6)
                    .background(ColorTheme.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
            }
            .frame(width: 40)
            
            // Destination
            VStack(alignment: .trailing, spacing: 4) {
                Text("TO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                
                ZStack(alignment: .trailing) {
                    TextField("Search…", text: $destinationQuery, prompt: Text("Search…").foregroundColor(ColorTheme.textTertiary.opacity(0.5)))
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                        .focused($isDestinationFocused)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .opacity(isDestinationFocused || (selectedDestination == nil && destinationQuery.isEmpty) ? 1 : 0)
                    
                    if !isDestinationFocused && (selectedDestination != nil || !destinationQuery.isEmpty) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(destinationCode)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(selectedDestination != nil ? ColorTheme.textPrimary : ColorTheme.textTertiary.opacity(0.6))
                            Text(destinationName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(ColorTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDestination = nil
                            destinationQuery = ""
                            isDestinationFocused = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
        .padding(.horizontal, 22)
    }
    
    private var trainSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TRAIN NUMBER")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(ColorTheme.textTertiary)
                .tracking(1)
            
            HStack(spacing: 12) {
                TextField("e.g. 60", text: $trainNumber, prompt: Text("e.g. 60").foregroundColor(ColorTheme.textTertiary.opacity(0.5)))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .focused($isTrainFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit {
                        onTrainSubmit()
                    }
                
                Spacer()
                
                // Smart operator switcher badge
                Menu {
                    ForEach(operators, id: \.self) { op in
                        Button(operatorDisplayName(op)) {
                            selectedOperator = op
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(operatorDisplayName(selectedOperator))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ColorTheme.operatorColor(for: selectedOperator), in: Capsule())
                }
                
                // Schedule lookup button
                if (selectedOperator == "VIA" || selectedOperator == "Amtrak" || selectedOperator == "GO") && !trainNumber.isEmpty {
                    Button {
                        onLookup()
                    } label: {
                        if isLookingUp {
                            ProgressView().tint(.white)
                                .scaleEffect(0.8)
                                .frame(width: 44, height: 25)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Find")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.operatorColor(for: selectedOperator), in: Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isLookingUp)
                }
            }
        }
        .padding(.top, 26)
        .padding(.bottom, 22)
        .padding(.horizontal, 20)
    }
    
    private func operatorDisplayName(_ op: String) -> String {
        switch op {
        case "VIA": return "VIA Rail"
        case "Amtrak": return "Amtrak"
        case "GO": return "GO Transit"
        default: return "Other"
        }
    }
}
