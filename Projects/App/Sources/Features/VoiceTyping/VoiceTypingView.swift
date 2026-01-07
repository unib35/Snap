import ComposableArchitecture
import SwiftUI

public struct VoiceTypingView: View {
    @Bindable var store: StoreOf<VoiceTypingFeature>

    public init(store: StoreOf<VoiceTypingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            // 상태 표시
            statusIndicator

            // 인식된 텍스트
            recognizedTextView

            // 컨트롤 버튼
            controlButtons
        }
        .padding()
        .onAppear {
            store.send(.onAppear)
        }
        .alert(
            "오류",
            isPresented: .init(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.send(.dismissError) } }
            )
        ) {
            Button("확인") {
                store.send(.dismissError)
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        VStack(spacing: 12) {
            ZStack {
                // 배경 원
                Circle()
                    .fill(store.isRecording ? SnapColors.recording.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 120, height: 120)

                // 펄스 애니메이션
                if store.isRecording {
                    PulseView()
                }

                // 마이크 아이콘
                Image(systemName: store.isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(store.isRecording ? SnapColors.recording : .gray)
                    .symbolEffect(.variableColor.iterative, isActive: store.isRecording)
            }

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        switch store.authorizationStatus {
        case .notDetermined:
            return "권한 확인 중..."
        case .authorized:
            return store.isRecording ? "듣고 있어요..." : "마이크를 탭하여 시작"
        case .denied:
            return "권한이 거부됨"
        case .restricted:
            return "사용할 수 없음"
        }
    }

    @ViewBuilder
    private var recognizedTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("인식된 텍스트")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !store.recognizedText.isEmpty {
                    Button {
                        store.send(.clearText)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            ScrollView {
                Text(store.recognizedText.isEmpty ? "음성 인식 결과가 여기에 표시됩니다" : store.recognizedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(store.recognizedText.isEmpty ? .tertiary : .primary)
            }
            .frame(minHeight: 100, maxHeight: 200)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        HStack(spacing: 16) {
            // 녹음 토글 버튼
            Button {
                store.send(.toggleRecording)
            } label: {
                Label(
                    store.isRecording ? "중지" : "시작",
                    systemImage: store.isRecording ? "stop.fill" : "mic.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(store.isRecording ? SnapColors.recording : .accentColor)
            .controlSize(.large)
            .disabled(store.authorizationStatus != .authorized)

            // 전송 버튼
            Button {
                store.send(.sendText)
            } label: {
                Label("전송", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(SnapColors.success)
            .controlSize(.large)
            .disabled(store.recognizedText.isEmpty || store.isRecording)
        }
    }
}

// MARK: - Pulse Animation View

private struct PulseView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(SnapColors.recording.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 0.5)
                    .animation(
                        .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Voice Typing Section (for ProductivityView)

public struct VoiceTypingSection: View {
    let store: StoreOf<VoiceTypingFeature>

    public init(store: StoreOf<VoiceTypingFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("보이스 타이핑", systemImage: "mic.fill")
                .font(.headline)

            HStack(spacing: 12) {
                // 녹음 버튼
                Button {
                    store.send(.toggleRecording)
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: store.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title2)
                            .symbolEffect(.variableColor.iterative, isActive: store.isRecording)

                        Text(store.isRecording ? "중지" : "녹음")
                            .font(.caption)
                    }
                    .frame(width: 70, height: 70)
                    .background(store.isRecording ? SnapColors.recording : Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(store.authorizationStatus != .authorized)

                // 텍스트 미리보기 및 전송
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.recognizedText.isEmpty ? "음성을 인식하면 여기에 표시됩니다" : store.recognizedText)
                        .font(.subheadline)
                        .foregroundStyle(store.recognizedText.isEmpty ? .tertiary : .primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !store.recognizedText.isEmpty && !store.isRecording {
                        Button {
                            store.send(.sendText)
                        } label: {
                            Label("Mac으로 전송", systemImage: "paperplane.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

#Preview {
    VoiceTypingView(
        store: Store(initialState: VoiceTypingFeature.State()) {
            VoiceTypingFeature()
        }
    )
}
