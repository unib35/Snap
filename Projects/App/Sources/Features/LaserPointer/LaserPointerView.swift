import ComposableArchitecture
import SwiftUI

public struct LaserPointerView: View {
    @Bindable var store: StoreOf<LaserPointerFeature>

    public init(store: StoreOf<LaserPointerFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 상태 표시
                statusIndicator

                // 메인 버튼
                laserButton

                // 모드 선택
                activationModeSelector

                // 감도 조절
                sensitivityControl

                // 캘리브레이션 버튼
                calibrateButton
            }
            .padding()
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .overlay {
            if store.showCalibrationGuide {
                calibrationGuideOverlay
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(store.isActive ? "레이저 포인터 활성화됨" : "레이저 포인터 대기 중")
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
        .accessibilityLabel("레이저 포인터")
        .accessibilityValue(store.isActive ? "활성화됨" : "비활성화됨")
        .accessibilityHint(store.isActive ? "탭하여 끄기" : "탭하여 레이저 포인터 시작")
    }

    @ViewBuilder
    private var activationModeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("활성화 모드")
                .font(.subheadline)
                .foregroundStyle(SnapColors.textSecondary)

            Picker("활성화 모드", selection: Binding(
                get: { store.activationMode },
                set: { store.send(.setActivationMode($0)) }
            )) {
                ForEach(LaserPointerFeature.ActivationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(store.activationMode.description)
                .font(.caption)
                .foregroundStyle(SnapColors.textSecondary)
        }
        .padding()
        .background(SnapColors.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("활성화 모드 선택")
        .accessibilityValue(store.activationMode.displayName)
    }

    @ViewBuilder
    private var sensitivityControl: some View {
        VStack(spacing: 12) {
            HStack {
                Text("감도")
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.textSecondary)

                Spacer()

                Text(store.sensitivityPreset.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }

            // 프리셋 버튼
            HStack(spacing: 8) {
                ForEach(
                    LaserPointerFeature.SensitivityPreset.allCases.filter { $0 != .custom },
                    id: \.self
                ) { preset in
                    Button {
                        store.send(.setSensitivityPreset(preset))
                    } label: {
                        Text(preset.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                store.sensitivityPreset == preset
                                    ? SnapColors.laserPointer
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                store.sensitivityPreset == preset
                                    ? .white
                                    : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(preset.displayName) 감도")
                    .accessibilityAddTraits(store.sensitivityPreset == preset ? .isSelected : [])
                }
            }

            // 세밀 조정 슬라이더
            VStack(spacing: 4) {
                HStack {
                    Text("세밀 조정")
                        .font(.caption)
                        .foregroundStyle(SnapColors.textSecondary)

                    Spacer()

                    Text("\(Int(store.sensitivity))")
                        .font(.caption)
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
                .accessibilityLabel("감도 슬라이더")
                .accessibilityValue("\(Int(store.sensitivity))")
            }
        }
        .padding()
        .background(SnapColors.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var calibrateButton: some View {
        VStack(spacing: 12) {
            Button {
                store.send(.calibrate)
            } label: {
                Label("현재 위치로 기준점 설정", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!store.isActive)
            .accessibilityLabel("기준점 설정")
            .accessibilityHint("현재 기기 위치를 레이저 포인터의 기준점으로 설정합니다")

            Button {
                store.send(.showCalibrationGuide)
            } label: {
                Label("캘리브레이션 가이드 보기", systemImage: "questionmark.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(SnapColors.textSecondary)
            .accessibilityLabel("캘리브레이션 가이드")
            .accessibilityHint("캘리브레이션 방법을 단계별로 안내합니다")
        }
    }

    @ViewBuilder
    private var calibrationGuideOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // 헤더
                HStack {
                    Text("캘리브레이션 가이드")
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        store.send(.dismissCalibrationGuide)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("닫기")
                }

                // 진행률 표시
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= store.calibrationStep ? SnapColors.laserPointer : Color(.systemGray4))
                            .frame(width: 10, height: 10)
                    }
                }
                .accessibilityLabel("진행 단계 \(store.calibrationStep + 1) / 3")

                // 단계별 내용
                calibrationStepContent

                Spacer()

                // 버튼
                if store.calibrationStep < 2 {
                    Button {
                        store.send(.calibrationStepCompleted)
                    } label: {
                        Text("다음")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SnapColors.laserPointer)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("다음 단계")
                } else {
                    Button {
                        store.send(.calibrationStepCompleted)
                    } label: {
                        Text("캘리브레이션 완료")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SnapColors.success)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("캘리브레이션 완료")
                }
            }
            .padding(24)
            .background(SnapColors.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(24)
        }
    }

    @ViewBuilder
    private var calibrationStepContent: some View {
        switch store.calibrationStep {
        case 0:
            calibrationStep(
                icon: "iphone",
                title: "기기를 잡으세요",
                description: "iPhone을 편안하게 잡고, Mac 화면을 바라보세요. 프레젠테이션할 때와 같은 자세를 취하세요."
            )
        case 1:
            calibrationStep(
                icon: "hand.point.up.fill",
                title: "기준 위치 정하기",
                description: "커서가 화면 중앙에 위치하길 원하는 방향으로 iPhone을 향하세요. 이 위치가 기준점이 됩니다."
            )
        case 2:
            calibrationStep(
                icon: "checkmark.circle.fill",
                title: "준비 완료",
                description: "기준 위치가 정해졌습니다. 이제 기기를 움직이면 그에 따라 커서가 움직입니다."
            )
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func calibrationStep(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(SnapColors.laserPointer)
                .symbolEffect(.pulse)

            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(description)
                .font(.body)
                .foregroundStyle(SnapColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Laser Pointer Section (for TrackpadView)

public struct LaserPointerSection: View {
    @Bindable var store: StoreOf<LaserPointerFeature>

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
                .accessibilityLabel("레이저 포인터")
                .accessibilityValue(store.isActive ? "켜짐" : "꺼짐")
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
                            .accessibilityHint("현재 위치를 기준점으로 설정")
                        }
                    }
                    .frame(height: 200)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("레이저 포인터 활성 영역")

                    // 감도 프리셋
                    HStack(spacing: 8) {
                        ForEach(
                            LaserPointerFeature.SensitivityPreset.allCases.filter { $0 != .custom },
                            id: \.self
                        ) { preset in
                            Button {
                                store.send(.setSensitivityPreset(preset))
                            } label: {
                                Text(preset.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        store.sensitivityPreset == preset
                                            ? SnapColors.laserPointer
                                            : Color(.systemGray5)
                                    )
                                    .foregroundStyle(
                                        store.sensitivityPreset == preset
                                            ? .white
                                            : .primary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(preset.displayName) 감도")
                            .accessibilityAddTraits(store.sensitivityPreset == preset ? .isSelected : [])
                        }
                    }

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
                        .accessibilityLabel("감도 조절")
                        .accessibilityValue("\(Int(store.sensitivity))")

                        Image(systemName: "hare")
                            .foregroundStyle(SnapColors.textSecondary)
                    }
                }
            } else {
                // 비활성화 상태 - 안내
                VStack(spacing: 12) {
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

                    // 모드 선택
                    Picker("활성화 모드", selection: Binding(
                        get: { store.activationMode },
                        set: { store.send(.setActivationMode($0)) }
                    )) {
                        ForEach(LaserPointerFeature.ActivationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("활성화 모드")
                }
                .padding()
                .background(SnapColors.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .overlay {
            if store.showCalibrationGuide {
                calibrationGuideOverlay
            }
        }
    }

    @ViewBuilder
    private var calibrationGuideOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("캘리브레이션 가이드")
                        .font(.headline)

                    Spacer()

                    Button {
                        store.send(.dismissCalibrationGuide)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("닫기")
                }

                // 진행률
                HStack(spacing: 6) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index <= store.calibrationStep ? SnapColors.laserPointer : Color(.systemGray4))
                            .frame(width: 8, height: 8)
                    }
                }

                calibrationStepContentCompact

                Button {
                    store.send(.calibrationStepCompleted)
                } label: {
                    Text(store.calibrationStep < 2 ? "다음" : "완료")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.calibrationStep < 2 ? SnapColors.laserPointer : SnapColors.success)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
            .background(SnapColors.systemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(16)
        }
    }

    @ViewBuilder
    private var calibrationStepContentCompact: some View {
        let steps = [
            ("iphone", "기기를 편안하게 잡으세요"),
            ("hand.point.up.fill", "원하는 방향으로 기기를 향하세요"),
            ("checkmark.circle.fill", "준비 완료!")
        ]

        if store.calibrationStep < steps.count {
            let step = steps[store.calibrationStep]
            VStack(spacing: 12) {
                Image(systemName: step.0)
                    .font(.system(size: 40))
                    .foregroundStyle(SnapColors.laserPointer)

                Text(step.1)
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
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
