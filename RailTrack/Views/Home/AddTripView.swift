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
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.characters)
                                    .onSubmit {
                                        trainNumber = cleanTrainNumber(trainNumber)
                                    }
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
}




#Preview {
    AddTripView()
        .modelContainer(for: TripRecord.self, inMemory: true)
}
