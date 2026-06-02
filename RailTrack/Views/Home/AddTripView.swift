import SwiftUI
import SwiftData

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
                        TicketCardView(
                            originQuery: $originQuery,
                            selectedOrigin: $selectedOrigin,
                            destinationQuery: $destinationQuery,
                            selectedDestination: $selectedDestination,
                            trainNumber: $trainNumber,
                            selectedOperator: $selectedOperator,
                            isLookingUp: $isLookingUp,
                            originCode: originCode,
                            originName: originName,
                            destinationCode: destinationCode,
                            destinationName: destinationName,
                            operators: operators,
                            isOriginFocused: $isOriginFocused,
                            isDestinationFocused: $isDestinationFocused,
                            isTrainFocused: $isTrainFocused,
                            onLookup: lookupSchedule,
                            onOriginChange: { new in
                                originResults = StationDatabase.shared.search(new)
                            },
                            onTrainSubmit: {
                                trainNumber = cleanTrainNumber(trainNumber)
                            }
                        )
                        .onChange(of: destinationQuery) { _, new in
                            destinationResults = StationDatabase.shared.search(new)
                        }
                        
                        StationSearchResultsCard(
                            selectedOrigin: $selectedOrigin,
                            originQuery: $originQuery,
                            originResults: $originResults,
                            isOriginFocused: $isOriginFocused,
                            selectedDestination: $selectedDestination,
                            destinationQuery: $destinationQuery,
                            destinationResults: $destinationResults,
                            isDestinationFocused: $isDestinationFocused,
                            selectedOperator: $selectedOperator
                        )
                        
                        RouteSuggestionsCard(
                            isFetchingSuggestions: isFetchingSuggestions,
                            routeTrains: $routeTrains,
                            trainNumber: $trainNumber,
                            selectedOperator: $selectedOperator,
                            departureDate: $departureDate,
                            arrivalDate: $arrivalDate
                        )
                        
                        if let error = lookupError {
                            Text(error)
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.accentRed)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ScheduleCard(
                            departureDate: $departureDate,
                            arrivalDate: $arrivalDate,
                            selectedOperator: selectedOperator
                        )

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
