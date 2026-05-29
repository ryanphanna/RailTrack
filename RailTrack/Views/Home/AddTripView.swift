import SwiftUI
import SwiftData

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

    private let operators = ["VIA", "Amtrak", "GO", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Operator picker
                        VStack(alignment: .leading, spacing: 10) {
                            FieldLabel(text: "Operator", icon: "tram")
                            HStack(spacing: 8) {
                                ForEach(operators, id: \.self) { op in
                                    Button {
                                        selectedOperator = op
                                        // Clear stations when operator changes
                                        selectedOrigin = nil
                                        selectedDestination = nil
                                        originQuery = ""
                                        destinationQuery = ""
                                    } label: {
                                        Text(op)
                                            .font(.rtCaption.bold())
                                            .foregroundStyle(selectedOperator == op ? .white : ColorTheme.textSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedOperator == op
                                                    ? ColorTheme.operatorColor(for: op)
                                                    : ColorTheme.surface,
                                                in: RoundedRectangle(cornerRadius: 10)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))

                        // Train number
                        FormCard {
                            FormRow(label: "Train Number", icon: "number") {
                                HStack {
                                    TextField("e.g. 60", text: $trainNumber, prompt: Text("e.g. 60").foregroundColor(ColorTheme.textTertiary))
                                        .font(.rtBody)
                                        .foregroundStyle(ColorTheme.textPrimary)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.characters)
                                        .onSubmit {
                                            trainNumber = cleanTrainNumber(trainNumber)
                                        }
                                    
                                    if (selectedOperator == "VIA" || selectedOperator == "Amtrak") && !trainNumber.isEmpty {
                                        Button {

                                            lookupSchedule()
                                        } label: {
                                            if isLookingUp {
                                                ProgressView().tint(ColorTheme.accent)
                                            } else {
                                                Text("Lookup")
                                                    .font(.rtCaption.bold())
                                                    .foregroundStyle(ColorTheme.accent)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(ColorTheme.accent.opacity(0.12), in: Capsule())
                                            }
                                        }
                                        .disabled(isLookingUp)
                                    }
                                }
                            }
                        }
                        
                        if let error = lookupError {
                            Text(error)
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.accentRed)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Origin station
                        StationPickerField(
                            label: "From",
                            icon: "mappin.circle",
                            query: $originQuery,
                            results: $originResults,
                            selected: $selectedOrigin,
                            operatorFilter: selectedOperator
                        )

                        // Destination station
                        StationPickerField(
                            label: "To",
                            icon: "mappin.and.ellipse",
                            query: $destinationQuery,
                            results: $destinationResults,
                            selected: $selectedDestination,
                            operatorFilter: selectedOperator
                        )

                        // Departure
                        FormCard {
                            FormRow(label: "Departs", icon: "arrow.up.right.circle") {
                                DatePicker("", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }

                        // Arrival
                        FormCard {
                            FormRow(label: "Arrives", icon: "arrow.down.left.circle") {
                                DatePicker("", selection: $arrivalDate,
                                           in: departureDate...,
                                           displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }

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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { saveTrip() }
                        .font(.rtSubhead.bold())
                        .foregroundStyle(isFormValid ? ColorTheme.accent : ColorTheme.textTertiary)
                        .disabled(!isFormValid || isSaving)
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !trainNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        selectedOrigin != nil &&
        selectedDestination != nil &&
        selectedOrigin?.id != selectedDestination?.id &&
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
                    // Resolve origin station (first stop)
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
                    
                    // Resolve destination station (last stop)
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
                    // Resolve origin station (first stop)
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
                    
                    // Resolve destination station (last stop)
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
