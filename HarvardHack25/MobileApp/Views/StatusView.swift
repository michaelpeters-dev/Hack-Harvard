import SwiftUI

struct StatusView: View {
    let state: StreamSessionState
    let lastError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)
                Text(statusTitle)
                    .font(.headline)
                Spacer()
                if let bitrate = state.lastBitrate {
                    Text("\(bitrate) kbps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let latency = state.lastLatencyMeasurement {
                Text(String(format: "Latency %.0f ms", latency * 1000))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var indicatorColor: Color {
        switch state.connectionState {
        case .idle:
            return .gray
        case .connecting, .reconnecting:
            return .yellow
        case .streaming:
            return .green
        case .failed:
            return .red
        }
    }

    private var statusTitle: String {
        switch state.connectionState {
        case .idle:
            return "Idle"
        case .connecting:
            return "Connecting"
        case .streaming:
            return "Streaming"
        case .reconnecting(let attempt):
            return "Reconnecting (\(attempt))"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
}
