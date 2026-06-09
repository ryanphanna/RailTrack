import SwiftUI
import SwiftData

struct EditTripView: View {
    @Environment(\.dismiss) private var dismiss
    let record: TripRecord

    // MARK: - Form state (pre-populated from record)
    @State private var trainNumber: String
    @State private var selectedOperator: String
    @State private var departureDate: Date
    @State private var arrivalDate: Date

    @State private var originQuery: String
    @State private var destinationQuery: String
    @State private var originResults: [Station] = []
    @State private var destinationResults: [Station] = []
    @State private var selectedOrigin: Station?
    @State private var selectedDestination: Station?

    @State private var platformText: String
    @State private var notesText: String
    @State private var statusOption: StatusOption
    @State private var delayMins: Int

    private let operators = ["VIA", "Amtrak", "GO", "Other"]

    // MARK: - Status option

    enum StatusOption: String, CaseIterable, Identifiable {
        case scheduled = "Scheduled"
        case onTime    = "On Time"
        case delayed   = "Delayed"
        case cancelled = "Cancelled"
        case completed = "Completed"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .scheduled: return "clock"
            case .onTime:    return "checkmark.circle.fill"
            case .delayed:   return "exclamationmark.triangle.fill"
            case .cancelled: return "xmark.circle.fill"
            case .completed: return "flag.checkered"
            }
        }

        var color: Color {
            switch self {
            case .scheduled: return ColorTheme.textSecondary
            case .onTime:    return ColorTheme.accentGreen
            case .delayed:   return ColorTheme.accentAmber
            case .cancelled: return ColorTheme.accentRed
            case .completed: return ColorTheme.accent
            }
        }
    }

    // MARK: - Init

    init(record: TripRecord) {
        self.record = record
        _trainNumber     = State(initialValue: record.trainNumber)
        _selectedOperator = State(initialValue: record.trainOperator)
        _departureDate   = State(initialValue: record.scheduledDeparture)
        _arrivalDate     = State(initialValue: record.scheduledArrival)
        _platformText    = State(initialValue: record.currentPlatform ?? "")
        _notesText       = State(initialValue: record.notes ?? "")
        _delayMins       = State(initialValue: max(record.delayMinutes, 5))

        // Reconstruct Station objects from flat fields
        let origin = Station(
            id: record.originID, name: record.originName,
            shortName: record.originShortName, code: record.originCode,
            coordinate: Coordinate(latitude: record.originLat, longitude: record.originLon),
            timezone: record.originTimezone, railOperator: nil,
            city: record.originCity, country: record.originCountry
        )
        let destination = Station(
            id: record.destinationID, name: record.destinationName,
            shortName: record.destinationShortName, code: record.destinationCode,
            coordinate: Coordinate(latitude: record.destinationLat, longitude: record.destinationLon),
            timezone: record.destinationTimezone, railOperator: nil,
            city: record.destinationCity, country: record.destinationCountry
        )
        _selectedOrigin      = State(initialValue: origin)
        _originQuery         = State(initialValue: origin.name)
        _selectedDestination = State(initialValue: destination)
        _destinationQuery    = State(initialValue: destination.name)

        let opt: StatusOption
        switch record.statusRaw {
        case "onTime":    opt = .onTime
        case "delayed":   opt = .delayed
        case "cancelled": opt = .cancelled
        case "completed": opt = .completed
        default:          opt = .scheduled
        }
        _statusOption = State(initialValue: opt)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        operatorSection
                        routeSection
                        statusSection
                        scheduleSection
                        detailsSection

                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                    .animation(.easeInOut(duration: 0.2), value: statusOption)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveChanges() }
                        .font(.rtSubhead)
                        .foregroundStyle(ColorTheme.accent)
                }
            }
        }
    }

    // MARK: - Form Sections

    @ViewBuilder
    private var operatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel(text: "Operator", icon: "tram.fill")
            HStack(spacing: 0) {
                ForEach(operators, id: \.self) { op in
                    Button {
                        selectedOperator = op
                    } label: {
                        Text(op)
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(selectedOperator == op ? .white : ColorTheme.textTertiary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selectedOperator == op
                                    ? ColorTheme.operatorColor(for: op)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .padding(4)
                }
            }
            .padding(2)
            .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(20)
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var routeSection: some View {
        VStack(spacing: 12) {
            // Train number
            FormCard {
                FormRow(label: "Train Number", icon: "number") {
                    TextField("e.g. 60", text: $trainNumber, prompt: Text("e.g. 60").foregroundColor(ColorTheme.textTertiary))
                        .keyboardType(.numberPad)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))

            // Origin
            StationPickerField(
                label: "From", icon: "arrow.up.right.circle.fill",
                query: $originQuery, results: $originResults,
                selected: $selectedOrigin, operatorFilter: selectedOperator
            )
            .padding(16)
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))

            // Destination
            StationPickerField(
                label: "To", icon: "arrow.down.left.circle.fill",
                query: $destinationQuery, results: $destinationResults,
                selected: $selectedDestination, operatorFilter: selectedOperator
            )
            .padding(16)
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FieldLabel(text: "Trip Status", icon: "info.circle.fill")
            VStack(spacing: 0) {
                ForEach(StatusOption.allCases) { opt in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            statusOption = opt
                        }
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: opt.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(opt.color)
                                .frame(width: 24)
                            Text(opt.rawValue.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(ColorTheme.textPrimary)
                                .tracking(0.5)
                            Spacer()
                            if statusOption == opt {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(ColorTheme.accent)
                            } else {
                                Circle()
                                    .stroke(ColorTheme.textTertiary.opacity(0.2), lineWidth: 1.5)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    if opt.id != StatusOption.allCases.last?.id {
                        Divider().opacity(0.08).padding(.leading, 60)
                    }
                }
            }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1)
            )

            // Delay stepper — shown only when Delayed is selected
            if statusOption == .delayed {
                HStack(spacing: 16) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(ColorTheme.accentAmber)
                        .frame(width: 24)
                    Text("DELAY INTENSITY")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(ColorTheme.textPrimary)
                    Spacer()
                    Stepper("", value: $delayMins, in: 1...999, step: 5)
                        .labelsHidden()
                    Text("\(delayMins)m")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTheme.accentAmber)
                        .frame(width: 50, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(ColorTheme.accentAmber.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        VStack(spacing: 12) {
            // Departure
            FormCard {
                FormRow(label: "Departs", icon: "arrow.up.right.circle.fill") {
                    DatePicker("", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .colorScheme(.dark)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))

            // Arrival
            FormCard {
                FormRow(label: "Arrives", icon: "arrow.down.left.circle.fill") {
                    DatePicker("", selection: $arrivalDate, in: departureDate..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .colorScheme(.dark)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var detailsSection: some View {
        VStack(spacing: 12) {
            // Platform
            FormCard {
                FormRow(label: "Platform", icon: "signpost.right.fill") {
                    TextField("e.g. 8", text: $platformText, prompt: Text("e.g. 8").foregroundColor(ColorTheme.textTertiary))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.textPrimary)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))

            // Notes
            FormCard {
                FormRow(label: "Notes", icon: "note.text") {
                    TextField("Optional…", text: $notesText, prompt: Text("Optional…").foregroundColor(ColorTheme.textTertiary), axis: .vertical)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ColorTheme.textTertiary.opacity(0.1), lineWidth: 1))
        }
    }

    // MARK: - Save

    private func saveChanges() {
        record.trainNumber    = trainNumber.trimmingCharacters(in: .whitespaces)
        record.trainOperator  = selectedOperator
        record.scheduledDeparture = departureDate
        record.scheduledArrival   = arrivalDate

        let pl = platformText.trimmingCharacters(in: .whitespaces)
        record.currentPlatform = pl.isEmpty ? nil : pl

        let nt = notesText.trimmingCharacters(in: .whitespaces)
        record.notes = nt.isEmpty ? nil : nt

        // Status
        switch statusOption {
        case .scheduled: record.statusRaw = "scheduled"; record.delayMinutes = 0
        case .onTime:    record.statusRaw = "onTime";    record.delayMinutes = 0
        case .delayed:   record.statusRaw = "delayed";   record.delayMinutes = delayMins
        case .cancelled: record.statusRaw = "cancelled"; record.delayMinutes = 0
        case .completed: record.statusRaw = "completed"; record.delayMinutes = 0
        }

        // Origin
        if let origin = selectedOrigin {
            record.originID        = origin.id
            record.originName      = origin.name
            record.originShortName = origin.shortName
            record.originCode      = origin.code
            record.originLat       = origin.coordinate.latitude
            record.originLon       = origin.coordinate.longitude
            record.originTimezone  = origin.timezone
            record.originCity      = origin.city
            record.originCountry   = origin.country
        }

        // Destination
        if let destination = selectedDestination {
            record.destinationID        = destination.id
            record.destinationName      = destination.name
            record.destinationShortName = destination.shortName
            record.destinationCode      = destination.code
            record.destinationLat       = destination.coordinate.latitude
            record.destinationLon       = destination.coordinate.longitude
            record.destinationTimezone  = destination.timezone
            record.destinationCity      = destination.city
            record.destinationCountry   = destination.country
        }

        // Reschedule notification
        NotificationService.shared.cancelNotifications(for: record.toTrip())
        NotificationService.shared.scheduleDepartureReminder(for: record.toTrip(), minutesBefore: 30)

        dismiss()
    }
}

#Preview {
    EditTripView(record: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: TripRecord.self, configurations: config)
        let station = Station(
            id: "VIA-TRTO", name: "Toronto Union Station", shortName: "Toronto",
            code: "TOR", coordinate: Coordinate(latitude: 43.6453, longitude: -79.3806),
            timezone: "America/Toronto", railOperator: nil, city: "Toronto", country: "CA"
        )
        let dest = Station(
            id: "VIA-OTTW", name: "Ottawa Station", shortName: "Ottawa",
            code: "OTT", coordinate: Coordinate(latitude: 45.4168, longitude: -75.6561),
            timezone: "America/Toronto", railOperator: nil, city: "Ottawa", country: "CA"
        )
        let record = TripRecord(
            trainNumber: "60", trainOperator: "VIA",
            origin: station, destination: dest,
            scheduledDeparture: Date(),
            scheduledArrival: Date().addingTimeInterval(3600 * 4)
        )
        container.mainContext.insert(record)
        return record
    }())
    .modelContainer(for: TripRecord.self, inMemory: true)
}
