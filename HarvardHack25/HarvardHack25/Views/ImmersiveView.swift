import SwiftUI

struct ImmersiveView: View {
    @EnvironmentObject private var viewModel: ImmersiveViewModel

    // One source of truth for sizing/shape
    private enum Panel {
        static let width: CGFloat  = 360     // change once, both layers follow
        static let corner: CGFloat = 22
    }

    @State private var panelScale: CGFloat = 1.0   // if you ever want to animate scale

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            overlayPanel
            captionPanel
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 28)
        .padding(.leading, 36)
    }

    // MARK: - Matched outer+inner panels
    private var overlayPanel: some View {
        ZStack {
            // OUTER monitor — same frame, zero inner padding so visual bounds == frame
            GlassPanel(tone: .neutral,
                       cornerRadius: Panel.corner,
                       contentPadding: 0) {
                EmptyView()
            }
            .frame(width: Panel.width)
            .allowsHitTesting(false)

            // INNER content — no panel, just content with padding
            VStack(alignment: .leading, spacing: 16) {
                if let error = viewModel.lastErrorDescription {
                    ErrorCallout(message: error)
                }

                Divider().blendMode(.plusLighter)

                // Primary action – manual trigger uses the same pipeline as the watcher
                Button(action: viewModel.processLatestPhotoNow) {
                    Label("Scan & Describe", systemImage: "viewfinder.rectangular")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // Preview (driven by viewModel.latestPreview)
                LatestPhotoPreview()
                    .environmentObject(viewModel)

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
            .padding(20)
            .frame(width: Panel.width)
        }
        .frame(width: Panel.width)
        .scaleEffect(panelScale)  // optional single knob to scale both together
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Caption monitor
    private var captionPanel: some View {
        ZStack {
            // OUTER monitor — same frame, zero inner padding so visual bounds == frame
            GlassPanel(tone: .neutral,
                       cornerRadius: Panel.corner,
                       contentPadding: 0) {
                EmptyView()
            }
            .frame(width: Panel.width)
            .allowsHitTesting(false)

            // INNER content — no panel, just content with padding
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "quote.bubble.fill")
                        .foregroundStyle(.cyan)
                    Text("Caption")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    PreseedLogoCircle(size: 20)
                        .accessibilityLabel("Brand logo")
                }

                Divider().blendMode(.plusLighter)

                ScrollView(showsIndicators: false) {
                    TypewriterCaptionText(text: viewModel.lastLANCaption)
                }
                .frame(maxHeight: 260)
            }
            .padding(20)
            .frame(width: Panel.width)
        }
        .frame(width: Panel.width)
        .scaleEffect(panelScale)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Diagnostics block
    private var debugMetrics: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    metricTile(title: "JPEG", value: "\(viewModel.lastJPEGBytes) B")
                    metricTile(title: "Objects", value: "\(viewModel.objects.count)")
                }
                GridRow {
                    metricTile(title: "Crop", value: "\(viewModel.lastCropSide)×\(viewModel.lastCropSide)")
                    metricTile(title: "Caption", value: viewModel.lastLANCaption.isEmpty ? "" : "\(viewModel.lastLANCaption.count)")
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
            OverlayHelperStatusIndicator(status: viewModel.helperStatus)
                .transition(.opacity.combined(with: .scale))
        }
    }
}

// MARK: - UI helpers (kept local for convenience)

struct ErrorCallout: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
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

struct OverlayHelperStatusIndicator: View {
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
                ProgressView().progressViewStyle(.circular)
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

struct TypewriterCaptionText: View {
    let text: String
    var speed: Double = 0.028   // seconds per character

    @State private var displayed: String = ""
    @State private var showCursor: Bool = true

    var body: some View {
        Text((displayed.isEmpty ? "" : displayed) + (showCursor ? "▌" : " "))
            .font(.callout.monospaced().weight(.medium))
            .foregroundStyle(.cyan)
            .textSelection(.enabled)
            .multilineTextAlignment(.leading)
            .animation(nil, value: displayed)
            .task(id: text) {
                await typeOut(newText: text)
            }
            .onAppear {
                startCursorBlink()
            }
    }

    private func typeOut(newText: String) async {
        let content = newText.isEmpty ? "Waiting for caption…" : newText
        displayed = ""
        for ch in content {
            displayed.append(ch)
            try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
        }
    }

    private func startCursorBlink() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
            showCursor.toggle()
        }
    }
}

import SwiftUI

struct PreseedLogoCircle: View {
    var size: CGFloat = 24
    @Environment(\.displayScale) private var scale

    private func snap(_ v: CGFloat) -> CGFloat { (v * scale).rounded() / scale }

    var body: some View {
        let inset = snap(size * 0.18)
        let ring  = max(1, snap(1))

        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.displayP3, red: 0.18, green: 0.80, blue: 1.00),
                            Color(.displayP3, red: 0.02, green: 0.45, blue: 1.00)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: ring))

            // Size SF Symbol with .font (keeps it vector & crisp)
            Image(systemName: "sparkles")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white)
                .font(.system(size: snap(size - inset * 2), weight: .semibold))
                .offset(y: snap(-0.25))
                .accessibilityHidden(true)
        }
        .frame(width: snap(size), height: snap(size))
        .compositingGroup()
        // If your SDK supports colorMode:
        .drawingGroup(opaque: false, colorMode: .linear)
        // Otherwise, use:
        // .drawingGroup()
    }
}
