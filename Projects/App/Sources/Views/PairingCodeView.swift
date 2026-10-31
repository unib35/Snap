import AVFoundation
import SwiftUI
import VisionKit

struct PairingCodeView: View {
    let serverName: String
    let errorMessage: String?
    let onCode: (String) -> Void
    let onCancel: () -> Void
    @State private var isScanning = false
    @State private var cameraError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                    Text("\(serverName) 확인")
                        .font(.title2.bold())
                    Text("Mac의 Snap에 표시된 QR 코드를 스캔하세요. 최초 연결이나 기존 연결 정보가 없는 경우 한 번 확인합니다.")
                        .multilineTextAlignment(.center)
                    Button("Mac 코드 스캔", systemImage: "camera") {
                        Task {
                            guard DataScannerViewController.isSupported else {
                                cameraError = "이 기기에서는 스캔을 사용할 수 없습니다. Mac에서 코드를 복사한 뒤 붙여넣으세요."
                                return
                            }
                            guard await AVCaptureDevice.requestAccess(for: .video) else {
                                cameraError = "설정에서 카메라 접근을 허용하거나 Mac에서 코드를 복사해 붙여넣으세요."
                                return
                            }
                            isScanning = true
                        }
                    }
                    .buttonStyle(SnapActionButtonStyle())
                    PasteButton(payloadType: String.self) { values in
                        if let code = values.first { onCode(code) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    Text("직접 보고 있는 Mac에서 복사한 코드만 붙여넣으세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let message = cameraError ?? errorMessage {
                        Text(message).foregroundStyle(SnapColors.destructive)
                    }
                }
                .padding(24)
            }
            .background(SnapColors.background)
            .navigationTitle("안전한 연결")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", action: onCancel)
                }
            }
            .sheet(isPresented: $isScanning) {
                NavigationStack {
                    PairingScanner { code in
                        isScanning = false
                        onCode(code)
                    } onError: { message in
                        isScanning = false
                        cameraError = message
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("Mac의 QR 코드 스캔")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("닫기") { isScanning = false }
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

private struct PairingScanner: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onError: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerController {
        ScannerController(onCode: onCode, onError: onError)
    }

    func updateUIViewController(_ controller: ScannerController, context: Context) {}

    final class ScannerController: UIViewController, DataScannerViewControllerDelegate {
        private let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        private let onCode: (String) -> Void
        private let onError: (String) -> Void
        private var delivered = false

        init(onCode: @escaping (String) -> Void, onError: @escaping (String) -> Void) {
            self.onCode = onCode
            self.onError = onError
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("Use init(onCode:onError:)") }

        override func viewDidLoad() {
            super.viewDidLoad()
            scanner.delegate = self
            addChild(scanner)
            scanner.view.frame = view.bounds
            scanner.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(scanner.view)
            scanner.didMove(toParent: self)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            do { try scanner.startScanning() } catch { onError(error.localizedDescription) }
        }

        override func viewWillDisappear(_ animated: Bool) {
            scanner.stopScanning()
            super.viewWillDisappear(animated)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            guard !delivered else { return }
            delivered = true
            scanner.stopScanning()
            onError(error.localizedDescription)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !delivered else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue,
                   value.hasPrefix("snap-pair:") {
                    delivered = true
                    scanner.stopScanning()
                    onCode(value)
                    return
                }
            }
        }
    }
}
