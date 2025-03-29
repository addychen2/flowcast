import SwiftUI

// Environment value extension to access safe area insets
private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        return EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// Add this to your SceneDelegate or App body
struct SafeAreaInsetsModifier: ViewModifier {
    @State private var insets: EdgeInsets = EdgeInsets()
    
    func body(content: Content) -> some View {
        content
            .environment(\.safeAreaInsets, insets)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            insets = geometry.safeAreaInsets
                        }
                        .onChange(of: geometry.safeAreaInsets) { newInsets in
                            insets = newInsets
                        }
                }
            )
    }
}

extension View {
    func withSafeAreaInsets() -> some View {
        modifier(SafeAreaInsetsModifier())
    }
}
