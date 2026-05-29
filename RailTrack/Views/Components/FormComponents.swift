import SwiftUI

// MARK: - Station Picker Field

struct StationPickerField: View {
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

struct FormCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(ColorTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct FormRow<Content: View>: View {
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

struct FieldLabel: View {
    let text: String
    let icon: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.rtCaption)
            .foregroundStyle(ColorTheme.textSecondary)
    }
}
