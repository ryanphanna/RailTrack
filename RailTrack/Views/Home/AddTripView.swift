import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var trainNumber = ""
    @State private var selectedOperator = "VIA"
    @State private var departureDate = Date()
    @State private var originQuery = ""
    @State private var destinationQuery = ""
    @State private var isSaving = false

    private let operators = ["VIA", "Amtrak", "GO", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Operator picker
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Operator", systemImage: "tram")
                                .font(.rtCaption)
                                .foregroundStyle(ColorTheme.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(operators, id: \.self) { op in
                                    Button {
                                        selectedOperator = op
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
                        FormField(label: "Train Number", icon: "number") {
                            TextField("e.g. 60", text: $trainNumber)
                                .keyboardType(.numberPad)
                                .font(.rtBody)
                                .foregroundStyle(ColorTheme.textPrimary)
                        }

                        // Stations
                        VStack(spacing: 0) {
                            FormField(label: "From", icon: "mappin.circle") {
                                TextField("Origin station", text: $originQuery)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }

                            Divider().padding(.leading, 44).opacity(0.15)

                            FormField(label: "To", icon: "mappin.and.ellipse") {
                                TextField("Destination station", text: $destinationQuery)
                                    .font(.rtBody)
                                    .foregroundStyle(ColorTheme.textPrimary)
                            }
                        }
                        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))

                        // Date
                        VStack(alignment: .leading, spacing: 0) {
                            FormField(label: "Departure", icon: "calendar") {
                                DatePicker("", selection: $departureDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                        .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))

                        // Save button
                        Button {
                            saveTrip()
                        } label: {
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

    private var isFormValid: Bool {
        !trainNumber.isEmpty && !originQuery.isEmpty && !destinationQuery.isEmpty
    }

    private func saveTrip() {
        isSaving = true
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

// MARK: - Form Field

private struct FormField<Content: View>: View {
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
        .padding(16)
    }
}

#Preview {
    AddTripView()
}
