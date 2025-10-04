import SwiftUI
import RealityKit

struct ImmersiveView: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel

    var body: some View {
        RealityView { _ in
            // TODO: add anchors and 3D overlays once ARKit pipeline is wired.
        }
        .background(clickGestureOverlay)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .overlay(alignment: .topLeading) {
            overlayPanel
                .padding(.top, 28)
                .padding(.leading, 36)
        }
    }

    private var overlayPanel: some View {
        HStack(alignment: .top, spacing: 28) {
            GlassPanel(tone: .neutral, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    streamingStatus

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Endpoint: \(viewModel.endpointDescription)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Button("Ping Local Server") { viewModel.pingServer() }
                                .buttonStyle(.bordered)
                            Text("Ping: \(viewModel.lastPingStatus)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let error = viewModel.lastErrorDescription, !error.isEmpty {
                        ErrorCallout(message: error)
                    }

                    Divider().blendMode(.plusLighter)

                    Button {
                        viewModel.scanOnceHardcoded()
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isBusy { ProgressView().scaleEffect(0.85) }
                            Label(viewModel.isBusy ? "Scanning…" : "Scan & Describe",
                                  systemImage: "viewfinder.rectangular")
                                .font(.title3.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isBusy)
                    .accessibilityHint("Triggers spatial scan without needing to target the button visually.")
                    .accessibilityAction(.default) {
                        viewModel.scanOnceHardcoded()
                    }

                    debugMetrics
                    helperStatusView

                    Divider().blendMode(.plusLighter)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.objects) { object in
                                ObjectOverlayView(object: object)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 260)
                }
                .frame(maxWidth: 420)
            }

            GlassPanel(cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Helper Escalation")
                        .font(.title3.weight(.semibold))
                    Text("Request live support when you need more context.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                    ControlPanelView { context in
                        viewModel.submitHelperRequest(with: context)
                    }
                }
                .frame(width: 320)
            }
        }
    }

    private var streamingStatus: some View {
        HStack(alignment: .center, spacing: 12) {
            StatusBadge(isActive: viewModel.isStreaming)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isStreaming ? "Demo Mode Active" : "Demo Mode Paused")
                    .font(.title3.weight(.semibold))
                Text("Spatial scan pipeline ready for a single capture.")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 6)
    }

    private var debugMetrics: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    metricTile(title: "Caption", value: viewModel.lastLANCaption)
                    metricTile(title: "JPEG", value: "\(viewModel.lastJPEGBytes) B")
                }
                GridRow {
                    metricTile(title: "Crop", value: "\(viewModel.lastCropSide)×\(viewModel.lastCropSide)")
                    metricTile(title: "Objects", value: "\(viewModel.objects.count)")
                }
            }
        }
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value.isEmpty ? "—" : value)
                .font(.callout.monospacedDigit().weight(.medium))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.15))
        )
    }

    @ViewBuilder
    private var helperStatusView: some View {
        if viewModel.helperStatus != .idle {
            HelperStatusIndicator(status: viewModel.helperStatus)
                .transition(.opacity.combined(with: .scale))
        }
    }

    private var clickGestureOverlay: some View {
        AccessibilityClickGesture {
            viewModel.scanOnceHardcoded()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct StatusBadge: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(isActive ? Color.green.gradient : Color.yellow.gradient)
                .opacity(0.65)
            Label(isActive ? "Ready" : "Paused", systemImage: isActive ? "waveform" : "pause.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black.opacity(0.85))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .fixedSize()
        .overlay(
            Capsule(style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 6, y: 4)
    }
}

private struct HelperStatusIndicator: View {
    let status: ImmersiveViewModel.HelperStatus

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)

            if case .sending = status {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(backgroundTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderTint, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 6)
    }

    private var title: String {
        switch status {
        case .idle: return ""
        case .sending: return "Contacting Helper"
        case .sent: return "Helper Ping Sent"
        case .failed: return "Request Failed"
        case .simulatedAcknowledged: return "Preview Only"
        }
    }

    private var message: String {
        switch status {
        case .idle: return ""
        case .sending: return "Stay focused on the object—help is on the way."
        case .sent: return "We'll relay any helper responses as soon as they arrive."
        case .failed: return "We couldn't reach the network. Try again or check connectivity."
        case let .simulatedAcknowledged(context):
            return "Saved context locally: \(context)."
        }
    }

    private var icon: String {
        switch status {
        case .idle: return ""
        case .sending: return "paperplane.fill"
        case .sent: return "checkmark.seal.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .simulatedAcknowledged: return "eyeglasses"
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle: return .clear
        case .sending: return .cyan
        case .sent: return .green
        case .failed: return .yellow
        case .simulatedAcknowledged: return .mint
        }
    }

    private var backgroundTint: Color {
        switch status {
        case .idle: return .clear
        case .sending: return Color.cyan.opacity(0.22)
        case .sent: return Color.green.opacity(0.22)
        case .failed: return Color.yellow.opacity(0.22)
        case .simulatedAcknowledged: return Color.mint.opacity(0.22)
        }
    }

    private var borderTint: Color {
        switch status {
        case .idle: return .clear
        case .sending: return Color.cyan.opacity(0.45)
        case .sent: return Color.green.opacity(0.45)
        case .failed: return Color.yellow.opacity(0.55)
        case .simulatedAcknowledged: return Color.mint.opacity(0.45)
        }
    }
}

private struct ErrorCallout: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "warningtriangle.fill")
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.yellow)
                .font(.title3)
            Text(message)
                .font(.callout.weight(.medium))
                .foregroundStyle(.yellow)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.yellow.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.yellow.opacity(0.35), lineWidth: 1)
        )
    }
}
