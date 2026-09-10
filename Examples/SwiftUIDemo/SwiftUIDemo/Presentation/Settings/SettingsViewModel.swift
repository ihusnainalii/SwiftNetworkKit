import Foundation
import Observation
import Security

@MainActor
@Observable
final class SettingsViewModel {
    private let model: AppModel

    var draft: DemoSettings
    var publicKeyDraft = ""
    var bodyKeyDraft = ""
    var validationError: String?
    var didApply = false

    init(model: AppModel) {
        self.model = model
        self.draft = model.settings.applied
    }

    var isDirty: Bool { draft != model.settings.applied }
    var appliedPinningWarning: String? { model.container.pinningWarning }

    // MARK: Cache policy choices for the picker

    var cachePolicyNames: [String] { AppContainer.cachePolicyNames.map(\.name) }

    // MARK: Public-key pins

    func addPublicKey() {
        let value = publicKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        guard Self.looksLikeSPKIHash(value) else {
            validationError = "Not a valid SPKI SHA-256 hash. Expected \"sha256/<base64>\" or a 44-char base64 string."
            return
        }
        guard !draft.pinnedPublicKeys.contains(value) else { publicKeyDraft = ""; return }
        draft.pinnedPublicKeys.append(value)
        publicKeyDraft = ""
        validationError = nil
    }

    func removePublicKeys(at offsets: IndexSet) {
        draft.pinnedPublicKeys.remove(atOffsets: offsets)
    }

    private static func looksLikeSPKIHash(_ s: String) -> Bool {
        let base64 = s.hasPrefix("sha256/") ? String(s.dropFirst("sha256/".count)) : s
        guard let data = Data(base64Encoded: base64) else { return false }
        return data.count == 32
    }

    // MARK: Certificate import

    func importCertificate(from url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let raw = try Data(contentsOf: url)
            let der = Self.derBytes(from: raw)
            guard SecCertificateCreateWithData(nil, der as CFData) != nil else {
                validationError = "\(url.lastPathComponent) is not a readable X.509 certificate (DER or PEM)."
                return
            }
            let name = url.deletingPathExtension().lastPathComponent
            draft.pinnedCertificates.append(.init(name: name, der: der))
            validationError = nil
        } catch {
            validationError = "Could not read \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func removeCertificates(at offsets: IndexSet) {
        draft.pinnedCertificates.remove(atOffsets: offsets)
    }

    /// Accepts raw DER, or PEM (`-----BEGIN CERTIFICATE-----`) which it unwraps to DER.
    private static func derBytes(from raw: Data) -> Data {
        guard let text = String(data: raw, encoding: .ascii),
            text.contains("-----BEGIN CERTIFICATE-----")
        else { return raw }
        let body = text
            .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
            .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        return Data(base64Encoded: body) ?? raw
    }

    // MARK: Redacted body keys

    func addBodyKey() {
        let value = bodyKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !value.isEmpty, !draft.redactedBodyKeys.contains(value) else { bodyKeyDraft = ""; return }
        draft.redactedBodyKeys.append(value)
        bodyKeyDraft = ""
    }

    func removeBodyKeys(at offsets: IndexSet) {
        draft.redactedBodyKeys.remove(atOffsets: offsets)
    }

    // MARK: Apply / reset

    func apply() {
        if draft.pinningMode == .publicKeys && draft.pinnedPublicKeys.isEmpty {
            validationError = "Add at least one public-key hash, or switch the mode to Off."
            return
        }
        if draft.pinningMode == .certificate && draft.pinnedCertificates.isEmpty {
            validationError = "Import at least one certificate, or switch the mode to Off."
            return
        }
        validationError = nil
        model.apply(draft)
        draft = model.settings.applied
        didApply = true
    }

    func reset() {
        model.resetToDefaults()
        draft = model.settings.applied
        validationError = nil
    }

    /// Fill the pinned host from the current base URL.
    func syncPinnedHost() {
        draft.pinnedHost = URL(string: draft.baseURL)?.host ?? draft.pinnedHost
    }
}
