import XCTest
@testable import SharedModels

final class NetworkModelsTests: XCTestCase {
    func testEnvelopeRoundTripEncoding() throws {
        let description = SessionDescription(kind: .offer, sdp: "v=0\r\no=- 0 0 IN IP4 127.0.0.1")
        let envelope = SignalingEnvelope(
            sessionID: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            timestamp: Date(timeIntervalSince1970: 0),
            payload: .offer(description)
        )

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(SignalingEnvelope.self, from: data)

        XCTAssertEqual(decoded.sessionID, envelope.sessionID)
        XCTAssertEqual(decoded.timestamp.timeIntervalSince1970, 0)
        guard case .offer(let decodedDescription) = decoded.payload else {
            XCTFail("Unexpected payload")
            return
        }
        XCTAssertEqual(decodedDescription.kind, .offer)
        XCTAssertEqual(decodedDescription.sdp, description.sdp)
    }
}
