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
                                TextField("e.g. 60", text: $trainNumber)
                                    .keyboardType(.numberPad)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
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

                        // Save button
                        Button { saveTrip() } label: {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Add Trip")
                                        .font(.rtSubhead)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                isFormValid ? ColorTheme.accent : ColorTheme.textTertiary,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
                        }
                        .disabled(!isFormValid || isSaving)

                        Color.clear.frame(height: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(ColorTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !trainNumber.trimmingCharacters(in: .whitespaces).isEmpty &&
        (!originQuery.isEmpty) &&
        (!destinationQuery.isEmpty) &&
        arrivalDate > departureDate
    }

    // MARK: - Save

    private func saveTrip() {
        isSaving = true
        let origin = selectedOrigin ?? StationDatabase.shared.station(for: originQuery, operator: selectedOperator)
        let destination = selectedDestination ?? StationDatabase.shared.station(for: destinationQuery, operator: selectedOperator)
        let record = TripRecord(
            trainNumber: trainNumber.trimmingCharacters(in: .whitespaces),
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
}

// MARK: - Station Picker Field

private struct StationPickerField: View {
    let label: String
    let icon: String
    @Binding var query: String
    @Binding var results: [Station]
    @Binding var selected: Station?
    let operatorFilter: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormRow(label: label, icon: icon) {
                if let s = selected {
                    HStack {
                        Text(s.name)
                            .font(.rtBody)
                            .foregroundStyle(ColorTheme.textPrimary)
                        Spacer()
                        Button {
                            selected = nil
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(ColorTheme.textTertiary)
                        }
                    }
                } else {
                    TextField("Search stations…", text: $query)
                        .font(.rtBody)
                        .foregroundStyle(ColorTheme.textPrimary)
                        .onChange(of: query) { _, new in
                            results = StationDatabase.shared.search(new)
                        }
                }
            }
            .padding(16)

            // Results list
            if selected == nil && !results.isEmpty && !query.isEmpty {
                Divider().opacity(0.1)
                ForEach(results.prefix(4)) { station in
                    Button {
                        selected = station
                        query = station.name
                        results = []
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
                    if station.id != results.prefix(4).last?.id {
                        Divider().padding(.leading, 64).opacity(0.08)
                    }
                }
            }
        }
        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reusable form helpers

private struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct FormRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(ColorTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.rtCaption)
                    .foregroundStyle(ColorTheme.textTertiary)
                content
            }
        }
    }
}

private struct FieldLabel: View {
    let text: String
    let icon: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.rtCaption)
            .foregroundStyle(ColorTheme.textSecondary)
    }
}

#Preview {
    AddTripView()
        .modelContainer(for: TripRecord.self, inMemory: true)
}
