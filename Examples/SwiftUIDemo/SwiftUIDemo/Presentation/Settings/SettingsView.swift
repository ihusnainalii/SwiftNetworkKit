import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State private var model: SettingsViewModel
    @State private var importingCertificate = false

    init(model: AppModel) {
        _model = State(wrappedValue: SettingsViewModel(model: model))
    }

    private static let logLevels = ["Off", "Errors", "Basic", "Verbose", "Debug"]

    var body: some View {
        NavigationStack {
            Form {
                connectionSection
                retrySection
                requestsSection
                cacheSection
                pinningSection
                privacySection
                actionsSection
            }
            .navigationTitle("Settings")
            .fileImporter(
                isPresented: $importingCertificate,
                allowedContentTypes: [.x509Certificate, UTType(filenameExtension: "der") ?? .data, .data],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    urls.forEach(model.importCertificate)
                }
            }
        }
    }

    // MARK: Sections

    private var connectionSection: some View {
        Section("Connection") {
            VStack(alignment: .leading, spacing: 6) {
                TextField("Base URL", text: $model.draft.baseURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                Menu("Presets") {
                    ForEach(DemoSettings.baseURLPresets, id: \.self) { preset in
                        Button(preset) {
                            model.draft.baseURL = preset
                            model.syncPinnedHost()
                        }
                    }
                }
                .font(.caption)
            }

            Stepper("Timeout: \(Int(model.draft.timeout)) s", value: $model.draft.timeout, in: 5...120, step: 5)

            Picker("Log level", selection: $model.draft.logLevel) {
                ForEach(Array(Self.logLevels.enumerated()), id: \.offset) { index, label in
                    Text(label).tag(index)
                }
            }
        }
    }

    private var retrySection: some View {
        Section("Retry") {
            Picker("Policy", selection: $model.draft.retry) {
                ForEach(DemoSettings.RetryPreset.allCases, id: \.self) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private var requestsSection: some View {
        Section("Request management") {
            Stepper(
                "Max concurrent: \(model.draft.maxConcurrentRequests)",
                value: $model.draft.maxConcurrentRequests, in: 1...10
            )
            Toggle("Deduplicate identical GETs", isOn: $model.draft.deduplication)
        }
    }

    private var cacheSection: some View {
        Section("Response cache") {
            Toggle("Enable cache", isOn: $model.draft.cacheEnabled)
            if model.draft.cacheEnabled {
                Picker("Policy", selection: $model.draft.cachePolicy) {
                    ForEach(model.cachePolicyNames, id: \.self) { Text($0).tag($0) }
                }
                Stepper(
                    "TTL: \(Int(model.draft.cacheTTL)) s",
                    value: $model.draft.cacheTTL, in: 30...900, step: 30
                )
            }
        }
    }

    private var pinningSection: some View {
        Section {
            Picker("Mode", selection: $model.draft.pinningMode) {
                ForEach(DemoSettings.PinningMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            Text(model.draft.pinningMode.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)

            if model.draft.pinningMode != .off {
                HStack {
                    TextField("Host", text: $model.draft.pinnedHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Use base URL host") { model.syncPinnedHost() }
                        .font(.caption)
                        .buttonStyle(.borderless)
                }
            }

            switch model.draft.pinningMode {
            case .publicKeys:
                ForEach(model.draft.pinnedPublicKeys, id: \.self) { key in
                    Text(key).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle)
                }
                .onDelete(perform: model.removePublicKeys)
                HStack {
                    TextField("sha256/…", text: $model.publicKeyDraft)
                        .font(.caption.monospaced())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Add", action: model.addPublicKey)
                        .buttonStyle(.borderless)
                }
            case .certificate:
                ForEach(model.draft.pinnedCertificates) { cert in
                    Label(cert.name, systemImage: "doc.badge.gearshape")
                        .font(.callout)
                }
                .onDelete(perform: model.removeCertificates)
                Button {
                    importingCertificate = true
                } label: {
                    Label("Import .cer / .der / .pem", systemImage: "square.and.arrow.down")
                }
            case .recordOnly:
                Text("Make any request, then check Xcode's console for a line like `pinning: observed sha256/… for \(model.draft.pinnedHost)`. Paste it into the Public-key hashes mode to enforce.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .off:
                EmptyView()
            }

            if let warning = model.appliedPinningWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("Certificate / public-key pinning")
        }
    }

    private var privacySection: some View {
        Section("Redacted body keys") {
            ForEach(model.draft.redactedBodyKeys, id: \.self) { Text($0).font(.callout.monospaced()) }
                .onDelete(perform: model.removeBodyKeys)
            HStack {
                TextField("key name", text: $model.bodyKeyDraft)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add", action: model.addBodyKey).buttonStyle(.borderless)
            }
        }
    }

    private var actionsSection: some View {
        Section {
            if let error = model.validationError {
                Label(error, systemImage: "xmark.octagon.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button {
                model.apply()
            } label: {
                Text(model.isDirty ? "Apply & Rebuild Client" : "Applied")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.isDirty)

            Button("Reset to Defaults", role: .destructive, action: model.reset)
        } footer: {
            Text("Applying rebuilds the NetworkClient and reloads every screen. Settings persist across launches.")
        }
    }
}
