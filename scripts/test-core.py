#!/usr/bin/env python3
"""Run Shared and receiver core tests on macOS without launching the receiver app."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    if sys.platform != "darwin":
        raise SystemExit("These tests require macOS (Security, Network and CoreGraphics).")
    repo = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="snap-core-tests-") as directory:
        package = Path(directory)
        (package / "Package.swift").write_text('''// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "SnapRegression", platforms: [.macOS(.v14)], targets: [
    .target(name: "Shared"),
    .target(name: "MacReceiver", dependencies: ["Shared"]),
    .testTarget(name: "SharedTests", dependencies: ["Shared"]),
    .testTarget(name: "MacReceiverTests", dependencies: ["MacReceiver", "Shared"])
])
''')
        shutil.copytree(repo / "Projects/Shared/Sources", package / "Sources/Shared")
        shutil.copytree(repo / "Projects/Shared/Tests", package / "Tests/SharedTests")
        shutil.copytree(repo / "Projects/MacReceiver/Tests", package / "Tests/MacReceiverTests")
        receiver = package / "Sources/MacReceiver"
        receiver.mkdir(parents=True)
        for name in ("SnapServer", "InputSimulator", "WindowController"):
            shutil.copy2(repo / f"Projects/MacReceiver/Sources/Server/{name}.swift", receiver)
        return subprocess.run(
            ["swift", "test", "--package-path", str(package), "-j", "4", *sys.argv[1:]],
            check=False,
        ).returncode


if __name__ == "__main__":
    sys.exit(main())
