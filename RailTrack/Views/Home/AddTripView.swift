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

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var trainNumber = ""
    @State private var selectedOperator = "VIA"
    @State private var departureDate = Date()
    @State private var arrivalDate = Date().addingTimeInterval(3600 * 3)

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
                    Button("Add") { saveTrip() }
                        .font(.rtSubhead.bold())
                        .foregroundStyle(isFormValid ? ColorTheme.accent : ColorTheme.textTertiary)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedOrigin = nil
                            originQuery = ""
                            isOriginFocused = true
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Router dot line
            VStack(spacing: 4) {
                Image(systemName: "tram.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                
                HStack(spacing: 3) {
                    ForEach(0..<4) { _ in
                        Circle().fill(ColorTheme.textTertiary.opacity(0.3)).frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: 32)
            
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDestination = nil
                            destinationQuery = ""
                            isDestinationFocused = true
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 22)
        .padding(.bottom, 28)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var trainSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TRAIN NUMBER")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(ColorTheme.textTertiary)
                    .tracking(1)
                
                TextField("e.g. 60", text: $trainNumber, prompt: Text("e.g. 60").foregroundColor(ColorTheme.textTertiary.opacity(0.5)))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorTheme.textPrimary)
                    .focused($isTrainFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .onSubmit {
                        trainNumber = cleanTrainNumber(trainNumber)
                    }
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
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(ColorTheme.operatorColor(for: selectedOperator), in: Capsule())
            }
            
            // Schedule lookup button
            if (selectedOperator == "VIA" || selectedOperator == "Amtrak" || selectedOperator == "GO") && !trainNumber.isEmpty {
                Button {
                    lookupSchedule()
                } label: {
                    if isLookingUp {
                        ProgressView().tint(ColorTheme.accent)
                    } else {
                        Text("Lookup")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(ColorTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(ColorTheme.accent.opacity(0.12), in: Capsule())
                    }
                }
                .buttonStyle(.plain)
                .disabled(isLookingUp)
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
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("DEPARTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                    Text(departureDate.formatted(.dateTime.day().month().hour().minute()))
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                DatePicker("", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(ColorTheme.operatorColor(for: selectedOperator))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            
            Divider().opacity(0.08).padding(.leading, 56)
            
            HStack {
                Image(systemName: "arrow.down.left.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(ColorTheme.operatorColor(for: selectedOperator))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("ARRIVES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ColorTheme.textTertiary)
                        .tracking(1)
                    Text(arrivalDate.formatted(.dateTime.day().month().hour().minute()))
                        .font(.rtBody.bold())
                        .foregroundStyle(ColorTheme.textPrimary)
                }
                
                Spacer()
                
                DatePicker("", selection: $arrivalDate,
                           in: departureDate...,
                           displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(ColorTheme.operatorColor(for: selectedOperator))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
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
    
    private func lookupSchedule() {
        guard !trainNumber.isEmpty else { return }
        isLookingUp = true
        lookupError = nil
        
        let cleaned = cleanTrainNumber(trainNumber)
        
        Task {
            if selectedOperator == "VIA" {
                if let train = await VIALiveDataService.shared.lookupTrainSchedule(trainNumber: cleaned, departureDate: departureDate) {
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
                } else {
                    lookupError = "Train not found for selected date."
                }
            } else if selectedOperator == "Amtrak" {
                if let train = await AmtrakLiveDataService.shared.lookupTrainSchedule(trainNumber: cleaned, departureDate: departureDate) {
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
                } else {
                    lookupError = "Train not found for selected date."
                }
            } else if selectedOperator == "GO" {
                if let train = await GOLiveDataService.shared.lookupTrainSchedule(trainNumber: cleaned, departureDate: departureDate) {
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
                } else {
                    lookupError = "Train not found for selected date."
                }
            } else {
                lookupError = "Schedule lookup unsupported for \(selectedOperator)."
            }
            isLookingUp = false
        }
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: TripRecord.self, inMemory: true)
}
