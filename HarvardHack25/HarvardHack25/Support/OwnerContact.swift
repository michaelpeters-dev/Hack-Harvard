import Foundation

/// Canonical contact info for Pierce. Keep this in one place so other services stay DRY.
struct OwnerContact {
    enum ContactError: LocalizedError {
        case missingConfiguration

        var errorDescription: String? {
            switch self {
            case .missingConfiguration:
                return "Owner contact details missing from configuration."
            }
        }
    }

    let phoneNumber: String?
    let facetimeAddress: String?

    init(phoneNumber: String? = Bundle.main.object(forInfoDictionaryKey: "PiercePhoneNumber") as? String,
         facetimeAddress: String? = Bundle.main.object(forInfoDictionaryKey: "PierceFaceTimeAddress") as? String)
    {
        self.phoneNumber = phoneNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.facetimeAddress = facetimeAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// URL priority: FaceTime email -> FaceTime phone -> Tel
    func prioritizedContactURLs() throws -> [URL] {
        var urls: [URL] = []

        if let facetimeAddress, facetimeAddress.isEmpty == false,
           let facetimeURL = URL(string: "facetime://\(facetimeAddress)") {
            urls.append(facetimeURL)
        }

        if let phoneNumber, phoneNumber.isEmpty == false,
           let telURL = URL(string: "tel://\(digitsOnly(from: phoneNumber))") {
            urls.append(telURL)
        }

        guard urls.isEmpty == false else {
            throw ContactError.missingConfiguration
        }

        return urls
    }

    private func digitsOnly(from value: String) -> String {
        value.filter { $0.isNumber || $0 == "+" }
    }
}
