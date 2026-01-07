import ComposableArchitecture
import SwiftUI

public struct LaserPointerView: View {
    @Bindable var store: StoreOf<LaserPointerFeature>

    public init(store: StoreOf<LaserPointerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 24) {
            // 상태 표시
            statusIndicator

            // 메인 버튼
            laserButton

            // 감도 조절
            sensitivityControl

            // 캘리브레이션 버튼
            calibrateButton
        }
        .padding()
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
        VStack(spacing: 8) {
            Text(store.isActive ? "레이저 활성화" : "레이저 대기")
                .font(.headline)
                .foregroundStyle(store.isActive ? SnapColors.laserPointer : .secondary)

            if store.isActive && store.isCalibrated {
                Text("기기를 움직여 커서를 이동하세요")
                    .font(.caption)
                    .foregroundStyle(SnapColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var laserButton: some View {
        Button {
            store.send(.toggleActive)
        } label: {
            ZStack {
                // 배경 글로우
                if store.isActive {
                    Circle()
                        .fill(SnapColors.laserPointer.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)
                }

                // 메인 버튼
                Circle()
                    .fill(
                        store.isActive
                            ? LinearGradient(
                                colors: [SnapColors.laserPointer, SnapColors.warning],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color(.systemGray4), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(
                        color: store.isActive ? SnapColors.laserPointer.opacity(0.5) : .clear,
                        radius: 20
                    )

                // 아이콘
                VStack(spacing: 12) {
                    Image(systemName: "scope")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, isActive: store.isActive)

                    Text(store.isActive ? "누르고 있기" : "터치하여 시작")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var sensitivityControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("감도")
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.textSecondary)

                Spacer()

                Text("\(Int(store.sensitivity))")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { Double(store.sensitivity) },
                    set: { store.send(.setSensitivity(Float($0))) }
                ),
                in: 1...50,
                step: 1
            )
            .tint(SnapColors.laserPointer)
        }
        .padding()
        .background(SnapColors.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var calibrateButton: some View {
        Button {
            store.send(.calibrate)
        } label: {
            Label("현재 위치로 기준점 설정", systemImage: "scope")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(!store.isActive)
    }
}

// MARK: - Laser Pointer Section (for TrackpadView)

public struct LaserPointerSection: View {
    let store: StoreOf<LaserPointerFeature>

    public init(store: StoreOf<LaserPointerFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // 모드 토글
            HStack {
                Label("레이저 포인터", systemImage: "scope")
                    .font(.headline)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { store.isActive },
                    set: { _ in store.send(.toggleActive) }
                ))
                .labelsHidden()
                .tint(SnapColors.laserPointer)
            }

            if store.isActive {
                // 활성화 상태
                VStack(spacing: 16) {
                    // 큰 터치 영역
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(SnapColors.laserPointer.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(SnapColors.laserPointer.opacity(0.3), lineWidth: 2)
                            )

                        VStack(spacing: 12) {
                            Image(systemName: "scope")
                                .font(.system(size: 40))
                                .foregroundStyle(SnapColors.laserPointer)
                                .symbolEffect(.pulse)

                            Text("기기를 움직여 커서 제어")
                                .font(.subheadline)
                                .foregroundStyle(SnapColors.textSecondary)

                            // 캘리브레이션 버튼
                            Button {
                                store.send(.calibrate)
                            } label: {
                                Label("기준점 재설정", systemImage: "arrow.counterclockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .frame(height: 200)

                    // 감도 슬라이더
                    HStack {
                        Image(systemName: "tortoise")
                            .foregroundStyle(SnapColors.textSecondary)

                        Slider(
                            value: Binding(
                                get: { Double(store.sensitivity) },
                                set: { store.send(.setSensitivity(Float($0))) }
                            ),
                            in: 1...50
                        )
                        .tint(SnapColors.laserPointer)

                        Image(systemName: "hare")
                            .foregroundStyle(SnapColors.textSecondary)
                    }
                }
            } else {
                // 비활성화 상태 - 안내
                HStack(spacing: 12) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 32))
                        .foregroundStyle(SnapColors.laserPointer)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Air Mouse 모드")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("iPhone을 허공에 움직여 Mac 커서를 제어합니다")
                            .font(.caption)
                            .foregroundStyle(SnapColors.textSecondary)
                    }

                    Spacer()
                }
                .padding()
                .background(SnapColors.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    LaserPointerView(
        store: Store(initialState: LaserPointerFeature.State()) {
            LaserPointerFeature()
        }
    )
}
