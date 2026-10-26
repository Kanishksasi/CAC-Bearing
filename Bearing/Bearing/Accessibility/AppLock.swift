import SwiftUI
import SwiftData
import LocalAuthentication
import UIKit

@MainActor
enum DeviceAuthentication {
    private static var receipt = AuthenticationReceipt()
    static func consumeRecentAuthentication() -> Bool { receipt.consume(now: ProcessInfo.processInfo.systemUptime) }
    static func authenticate() async -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else { return false }
        let accepted = (try? await context.evaluatePolicy(.deviceOwnerAuthentication,
            localizedReason: Loc.t("Unlock your personal movement records."))) ?? false
        if accepted { receipt.issue(now: ProcessInfo.processInfo.systemUptime) }
        return accepted
    }
}

struct AppLock<Content: View>: View {
    let content: Content
    @Query private var settings: [UserSettings]
    @Environment(\.scenePhase) private var phase
    @State private var unlocked = false
    @State private var working = false
    @State private var error = false
    @State private var generation = UUID()
    @State private var shield = PrivacyShield()
    private var enabled: Bool { settings.first?.appLockEnabled ?? false }

    var body: some View {
        ZStack {
            if !enabled || unlocked { content }
            else {
                VStack(spacing: 24) {
                    Image(systemName: "lock.shield").font(.largeTitle).foregroundStyle(Color.accentColor)
                    Text("Your records are locked").font(.title2.bold())
                    Text("Use your device authentication to open Bearing.").multilineTextAlignment(.center)
                    Button("Unlock Bearing") { Task { await unlock() } }.buttonStyle(BearingPrimaryButton()).disabled(working)
                    if error { Text("Bearing could not unlock. Try again using your device authentication.").foregroundStyle(BearingStyle.muted) }
                }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity).background(BearingStyle.paper)
            }
        }
        .onChange(of: enabled) { _, value in
            if value { unlocked = phase == .active && DeviceAuthentication.consumeRecentAuthentication() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            if enabled { shield.show() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in shield.hide() }
        .onChange(of: phase) { _, value in
            if value == .background { generation = UUID(); unlocked = false }
        }
    }
    private func unlock() async {
        guard !working else { return }
        working = true; error = false
        let token = generation
        let result = await DeviceAuthentication.authenticate()
        working = false
        _ = DeviceAuthentication.consumeRecentAuthentication()
        guard token == generation else { return }
        unlocked = result; error = !result
    }
}

@MainActor
private final class PrivacyShield {
    private var windows: [UIWindow] = []
    func show() {
        guard windows.isEmpty else { return }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            let window = UIWindow(windowScene: scene)
            window.windowLevel = .alert + 1
            let controller = UIViewController()
            controller.view.backgroundColor = UIColor(BearingStyle.paper)
            window.rootViewController = controller
            window.isUserInteractionEnabled = false
            window.isHidden = false
            windows.append(window)
        }
    }
    func hide() { windows.forEach { $0.isHidden = true }; windows = [] }
}

struct AuthenticationReceipt {
    private var issuedAt: TimeInterval?
    mutating func issue(now: TimeInterval) { issuedAt = now }
    mutating func consume(now: TimeInterval) -> Bool {
        defer { issuedAt = nil }
        guard let issuedAt, now.isFinite, issuedAt.isFinite else { return false }
        return now >= issuedAt && now - issuedAt <= 10
    }
}
