import SwiftUI
import SwiftData

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

struct RouteTrainSuggestion: Identifiable {
    let id = UUID()
    let trainNumber: String
    let operatorName: String
    let originCode: String
    let destinationCode: String
    let scheduledDeparture: Date?
    let scheduledArrival: Date?
}

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var trainNumber = ""
    @State private var selectedOperator = "VIA"
    @State private var departureDate = Date()
    @State private var arrivalDate = Date().addingTimeInterval(3600 * 3)

    @State private var routeTrains: [RouteTrainSuggestion] = []
    @State private var isFetchingSuggestions = false

    @State private var originQuery = ""
    @State private var destinationQuery = ""
    @State private var originResults: [Station] = []
    @State private var destinationResults: [Station] = []
    @State private var selectedOrigin: Station?
    @State private var selectedDestination: Station?

    @State private var isSaving = false
    @State private var isLookingUp = false
    @State private var lookupError: String? = nil

    @FocusState private var isOriginFocused: Bool
    @FocusState private var isDestinationFocused: Bool
    @FocusState private var isTrainFocused: Bool

    private let operators = ["VIA", "Amtrak", "GO", "Other"]

    init(
        initialOrigin: Station? = nil,
        initialDestination: Station? = nil,
        initialTrainNumber: String = "",
        initialOperator: String = "VIA"
    ) {
        _selectedOrigin = State(initialValue: initialOrigin)
        _originQuery = State(initialValue: initialOrigin?.name ?? "")
        _selectedDestination = State(initialValue: initialDestination)
        _destinationQuery = State(initialValue: initialDestination?.name ?? "")
        _trainNumber = State(initialValue: initialTrainNumber)
        _selectedOperator = State(initialValue: initialOperator)
    }

    private func operatorDisplayName(_ op: String) -> String {
        switch op {
        case "VIA": return "VIA Rail"
        case "Amtrak": return "Amtrak"
        case "GO": return "GO Transit"
        default: return "Other"
        }
    }

    private var originCode: String {
        if let o = selectedOrigin { return o.code }
        if !originQuery.isEmpty { return String(originQuery.prefix(3)).uppercased() }
        return "---"
    }

    private var originName: String {
        if let o = selectedOrigin { return o.shortName }
        if !originQuery.isEmpty { return originQuery }
        return "Select Origin"
    }

    private var destinationCode: String {
        if let d = selectedDestination { return d.code }
        if !destinationQuery.isEmpty { return String(destinationQuery.prefix(3)).uppercased() }
        return "---"
    }

    private var destinationName: String {
        if let d = selectedDestination { return d.shortName }
        if !destinationQuery.isEmpty { return destinationQuery }
        return "Select Destination"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        ticketCard
                        
                        searchResultsCard
                        
                        suggestionsCard
                        
                        if let error = lookupError {
                            Text(error)
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.accentRed)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        scheduleCard

                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
                .onChange(of: trainNumber) { _, newValue in
                    let lower = newValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    if lower.hasPrefix("via") {
                        selectedOperator = "VIA"
                    } else if lower.hasPrefix("amtrak") || lower.hasPrefix("amt") {
                        selectedOperator = "Amtrak"
                    } else if lower.hasPrefix("go") {
                        selectedOperator = "GO"
                    }
                }
                .onChange(of: selectedOrigin) { _, _ in
                    fetchRouteSuggestions()
                }
                .onChange(of: selectedDestination) { _, _ in
                    fetchRouteSuggestions()
                }
                .onChange(of: departureDate) { _, _ in
                    fetchRouteSuggestions()
                }
                .onAppear {
                    if !trainNumber.isEmpty {
                        lookupSchedule()
                    }
                    if selectedOrigin != nil && selectedDestination != nil {
                        fetchRouteSuggestions()
                    }
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(ColorTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveTrip()
                    } label: {
                        Text("Add")
                            .font(.rtSubhead.bold())
                            .foregroundStyle(isFormValid ? .white : ColorTheme.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isFormValid ? ColorTheme.accent : ColorTheme.surfaceHigh, in: Capsule())
                            .overlay(Capsule().stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var ticketCard: some View {
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

    @ViewBuilder
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
                            originResults = StationDatabase.shared.search(new)
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
                    .background(ColorTheme.surface, in: Circle())
                    .overlay(Circle().stroke(ColorTheme.textTertiary.opacity(0.12), lineWidth: 1))
            }
            .frame(width: 50)
            
            // Destination
            VStack(alignment: .leading, spacing: 4) {
                Text("TO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                
                ZStack(alignment: .leading) {
                    TextField("Search…", text: $destinationQuery, prompt: Text("Search…").foregroundColor(ColorTheme.textTertiary.opacity(0.5)))
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                        .focused($isDestinationFocused)
                        .autocorrectionDisabled()
                        .opacity(isDestinationFocused || (selectedDestination == nil && destinationQuery.isEmpty) ? 1 : 0)
                        .onChange(of: destinationQuery) { _, new in
                            destinationResults = StationDatabase.shared.search(new)
                        }
                    
                    if !isDestinationFocused && (selectedDestination != nil || !destinationQuery.isEmpty) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(destinationCode)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(selectedDestination != nil ? ColorTheme.textPrimary : ColorTheme.textTertiary.opacity(0.6))
                            Text(destinationName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(ColorTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDestination = nil
                            destinationQuery = ""
                            isDestinationFocused = true
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 22)
        .padding(.bottom, 28)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
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
                        trainNumber = cleanTrainNumber(trainNumber)
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
                        lookupSchedule()
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

    @ViewBuilder
    private var searchResultsCard: some View {
        if isOriginFocused && !originResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("MATCHING ORIGIN STATIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                ForEach(originResults.prefix(4)) { station in
                    Button {
                        selectedOrigin = station
                        originQuery = station.name
                        originResults = []
                        isOriginFocused = false
                        if let op = station.railOperator {
                            selectedOperator = op
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(station.code)
                                .font(.rtMono)
                                .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text(station.city)
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    if station.id != originResults.prefix(4).last?.id {
                        Divider().padding(.leading, 64).opacity(0.08)
                    }
                }
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.15), lineWidth: 1)
            )
        } else if isDestinationFocused && !destinationResults.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("MATCHING DESTINATION STATIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                
                ForEach(destinationResults.prefix(4)) { station in
                    Button {
                        selectedDestination = station
                        destinationQuery = station.name
                        destinationResults = []
                        isDestinationFocused = false
                        if let op = station.railOperator {
                            selectedOperator = op
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(station.code)
                                .font(.rtMono)
                                .foregroundStyle(ColorTheme.operatorColor(for: station.railOperator ?? ""))
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(station.name)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                Text(station.city)
                                    .font(.rtCaption)
                                    .foregroundStyle(ColorTheme.textTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    
                    if station.id != destinationResults.prefix(4).last?.id {
                        Divider().padding(.leading, 64).opacity(0.08)
                    }
                }
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.15), lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private var scheduleCard: some View {
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
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorTheme.operatorColor(for: selectedOperator).opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !trainNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!originQuery.trimmingCharacters(in: .whitespaces).isEmpty || selectedOrigin != nil) &&
        (!destinationQuery.trimmingCharacters(in: .whitespaces).isEmpty || selectedDestination != nil) &&
        (selectedOrigin?.id != selectedDestination?.id || selectedOrigin == nil) &&
        arrivalDate > departureDate
    }

    // MARK: - Save

    private func cleanTrainNumber(_ input: String) -> String {
        let lower = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for op in ["via", "amtrak", "amt", "go"] {
            if lower.hasPrefix(op) {
                return String(input.dropFirst(op.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveTrip() {
        isSaving = true
        let finalNumber = cleanTrainNumber(trainNumber)
        let origin = selectedOrigin ?? StationDatabase.shared.station(for: originQuery, operator: selectedOperator)
        let destination = selectedDestination ?? StationDatabase.shared.station(for: destinationQuery, operator: selectedOperator)
        let record = TripRecord(
            trainNumber: finalNumber,
            trainOperator: selectedOperator,
            origin: origin,
            destination: destination,
            scheduledDeparture: departureDate,
            scheduledArrival: arrivalDate
        )
        modelContext.insert(record)
        NotificationService.shared.scheduleDepartureReminder(for: record.toTrip(), minutesBefore: 30)
        dismiss()
    }
    
    // MARK: - Suggestions UI
    
    @ViewBuilder
    private var suggestionsCard: some View {
        if isFetchingSuggestions {
            HStack(spacing: 8) {
                ProgressView().tint(ColorTheme.accent)
                Text("Finding trains on this route...")
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
        } else if !routeTrains.isEmpty && trainNumber.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("RECOMMENDED TRAINS ON THIS ROUTE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 0) {
                    ForEach(routeTrains) { suggestion in
                        Button {
                            trainNumber = suggestion.trainNumber
                            selectedOperator = suggestion.operatorName
                            if let dep = suggestion.scheduledDeparture {
                                departureDate = dep
                            }
                            if let arr = suggestion.scheduledArrival {
                                arrivalDate = arr
                            }
                            routeTrains = []
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "tram.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(ColorTheme.operatorColor(for: suggestion.operatorName))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(suggestion.operatorName) Train \(suggestion.trainNumber)")
                                        .font(.rtBody.bold())
                                        .foregroundStyle(ColorTheme.textPrimary)
                                    
                                    if let dep = suggestion.scheduledDeparture {
                                        Text("Departs \(dep.formatted(.dateTime.hour().minute()))")
                                            .font(.rtCaption)
                                            .foregroundStyle(ColorTheme.textSecondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text("Select")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(ColorTheme.operatorColor(for: suggestion.operatorName))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(ColorTheme.operatorColor(for: suggestion.operatorName).opacity(0.12), in: Capsule())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if suggestion.id != routeTrains.last?.id {
                            Divider().padding(.leading, 42).opacity(0.08)
                        }
                    }
                }
                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorTheme.accent.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Route Suggestion Matching
    
    private func fetchRouteSuggestions() {
        guard let origin = selectedOrigin, let destination = selectedDestination else {
            routeTrains = []
            return
        }
        
        isFetchingSuggestions = true
        let originCode = origin.code
        let destinationCode = destination.code
        let targetDate = departureDate
        
        Task {
            var suggestions: [RouteTrainSuggestion] = []
            
            // 1. Fetch from VIA Rail
            let viaMatches = await VIALiveDataService.shared.findTrains(originCode: originCode, destinationCode: destinationCode, date: targetDate)
            for (trainNum, train) in viaMatches {
                let depTime = train.times.first(where: { $0.code == originCode })?.departure?.scheduled
                    ?? train.times.first(where: { $0.code == originCode })?.scheduled
                let arrTime = train.times.first(where: { $0.code == destinationCode })?.arrival?.scheduled
                    ?? train.times.first(where: { $0.code == destinationCode })?.scheduled
                
                suggestions.append(RouteTrainSuggestion(
                    trainNumber: trainNum,
                    operatorName: "VIA",
                    originCode: originCode,
                    destinationCode: destinationCode,
                    scheduledDeparture: VIALiveDataService.shared.parseISO8601Date(depTime),
                    scheduledArrival: VIALiveDataService.shared.parseISO8601Date(arrTime)
                ))
            }
            
            // 2. Fetch from Amtrak
            let amtrakMatches = await AmtrakLiveDataService.shared.findTrains(originCode: originCode, destinationCode: destinationCode, date: targetDate)
            for train in amtrakMatches {
                let depTime = train.stations.first(where: { $0.code == originCode })?.schDep
                let arrTime = train.stations.first(where: { $0.code == destinationCode })?.schArr
                
                suggestions.append(RouteTrainSuggestion(
                    trainNumber: train.trainNum,
                    operatorName: "Amtrak",
                    originCode: originCode,
                    destinationCode: destinationCode,
                    scheduledDeparture: AmtrakLiveDataService.shared.parseISO8601Date(depTime),
                    scheduledArrival: AmtrakLiveDataService.shared.parseISO8601Date(arrTime)
                ))
            }
            
            // 3. Fetch from GO Transit
            let goMatches = await GOLiveDataService.shared.findTrains(originCode: originCode, destinationCode: destinationCode, date: targetDate)
            for (trainNum, train) in goMatches {
                let depTime = train.times.first(where: { $0.code == originCode })?.departure?.scheduled
                    ?? train.times.first(where: { $0.code == originCode })?.scheduled
                let arrTime = train.times.first(where: { $0.code == destinationCode })?.arrival?.scheduled
                    ?? train.times.first(where: { $0.code == destinationCode })?.scheduled
                
                suggestions.append(RouteTrainSuggestion(
                    trainNumber: trainNum,
                    operatorName: "GO",
                    originCode: originCode,
                    destinationCode: destinationCode,
                    scheduledDeparture: GOLiveDataService.shared.parseISO8601Date(depTime),
                    scheduledArrival: GOLiveDataService.shared.parseISO8601Date(arrTime)
                ))
            }
            
            // Sort suggestions by departure time
            self.routeTrains = suggestions.sorted { s1, s2 in
                guard let d1 = s1.scheduledDeparture else { return false }
                guard let d2 = s2.scheduledDeparture else { return true }
                return d1 < d2
            }
            self.isFetchingSuggestions = false
        }
    }
    
    // MARK: - Schedule Lookup
    
    private func tryLookup(operatorName: String, cleanedTrainNumber: String) async -> Bool {
        if operatorName == "VIA" {
            if let train = await VIALiveDataService.shared.lookupTrainSchedule(trainNumber: cleanedTrainNumber, departureDate: departureDate) {
                if let firstTime = train.times.first {
                    let originStation = StationDatabase.shared.stations.first { $0.id == "VIA-\(firstTime.code)" }
                    ?? Station(
                        id: "VIA-\(firstTime.code)",
                        name: firstTime.station,
                        shortName: firstTime.station,
                        code: firstTime.code,
                        coordinate: Coordinate(latitude: 0, longitude: 0),
                        timezone: "America/Toronto",
                        railOperator: "VIA",
                        city: firstTime.station,
                        country: "CA"
                    )
                    selectedOrigin = originStation
                    originQuery = originStation.name
                    
                    if let schedStr = firstTime.departure?.scheduled ?? firstTime.scheduled,
                       let date = VIALiveDataService.shared.parseISO8601Date(schedStr) {
                        departureDate = date
                    }
                }
                
                if let lastTime = train.times.last {
                    let destStation = StationDatabase.shared.stations.first { $0.id == "VIA-\(lastTime.code)" }
                    ?? Station(
                        id: "VIA-\(lastTime.code)",
                        name: lastTime.station,
                        shortName: lastTime.station,
                        code: lastTime.code,
                        coordinate: Coordinate(latitude: 0, longitude: 0),
                        timezone: "America/Toronto",
                        railOperator: "VIA",
                        city: lastTime.station,
                        country: "CA"
                    )
                    selectedDestination = destStation
                    destinationQuery = destStation.name
                    
                    if let schedStr = lastTime.arrival?.scheduled ?? lastTime.scheduled,
                       let date = VIALiveDataService.shared.parseISO8601Date(schedStr) {
                        arrivalDate = date
                    }
                }
                return true
            }
        } else if operatorName == "Amtrak" {
            if let train = await AmtrakLiveDataService.shared.lookupTrainSchedule(trainNumber: cleanedTrainNumber, departureDate: departureDate) {
                if let firstStop = train.stations.first {
                    let originStation = StationDatabase.shared.stations.first { $0.id == "AMT-\(firstStop.code)" }
                    ?? Station(
                        id: "AMT-\(firstStop.code)",
                        name: firstStop.name,
                        shortName: firstStop.name,
                        code: firstStop.code,
                        coordinate: Coordinate(latitude: 0, longitude: 0),
                        timezone: firstStop.tz,
                        railOperator: "Amtrak",
                        city: firstStop.name,
                        country: "US"
                    )
                    selectedOrigin = originStation
                    originQuery = originStation.name
                    
                    if let schedStr = firstStop.schDep,
                       let date = AmtrakLiveDataService.shared.parseISO8601Date(schedStr) {
                        departureDate = date
                    }
                }
                
                if let lastStop = train.stations.last {
                    let destStation = StationDatabase.shared.stations.first { $0.id == "AMT-\(lastStop.code)" }
                    ?? Station(
                        id: "AMT-\(lastStop.code)",
                        name: lastStop.name,
                        shortName: lastStop.name,
                        code: lastStop.code,
                        coordinate: Coordinate(latitude: 0, longitude: 0),
                        timezone: lastStop.tz,
                        railOperator: "Amtrak",
                        city: lastStop.name,
                        country: "US"
                    )
                    selectedDestination = destStation
                    destinationQuery = destStation.name
                    
                    if let schedStr = lastStop.schArr,
                       let date = AmtrakLiveDataService.shared.parseISO8601Date(schedStr) {
                        arrivalDate = date
                    }
                }
                return true
            }
        } else if operatorName == "GO" {
            if let train = await GOLiveDataService.shared.lookupTrainSchedule(trainNumber: cleanedTrainNumber, departureDate: departureDate) {
                if let firstStop = train.times.first {
                    let originStation = GOLiveDataService.shared.resolveStation(code: firstStop.code, name: firstStop.station)
                    selectedOrigin = originStation
                    originQuery = originStation.name
                    
                    if let schedStr = firstStop.departure?.scheduled ?? firstStop.scheduled,
                       let date = GOLiveDataService.shared.parseISO8601Date(schedStr) {
                        departureDate = date
                    }
                }
                
                if let lastStop = train.times.last {
                    let destStation = GOLiveDataService.shared.resolveStation(code: lastStop.code, name: lastStop.station)
                    selectedDestination = destStation
                    destinationQuery = destStation.name
                    
                    if let schedStr = lastStop.arrival?.scheduled ?? lastStop.scheduled,
                       let date = GOLiveDataService.shared.parseISO8601Date(schedStr) {
                        arrivalDate = date
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func lookupSchedule() {
        guard !trainNumber.isEmpty else { return }
        isLookingUp = true
        lookupError = nil
        
        let cleaned = cleanTrainNumber(trainNumber)
        
        Task {
            var operatorsToTry = [selectedOperator]
            for op in ["VIA", "Amtrak", "GO"] {
                if !operatorsToTry.contains(op) {
                    operatorsToTry.append(op)
                }
            }
            
            for op in operatorsToTry {
                let success = await tryLookup(operatorName: op, cleanedTrainNumber: cleaned)
                if success {
                    selectedOperator = op
                    isLookingUp = false
                    return
                }
            }
            
            lookupError = "Train not found for selected date."
            isLookingUp = false
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: TripRecord.self, inMemory: true)
}
