import SwiftUI

extension View {
    func settingsSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            SettingsView()
        }
    }
}

private struct SettingsView: View {
    @AppStorage("FontSize") var fontSize: Double = 14

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Font configuration")) {
                    Stepper("Font Size: \(Int(fontSize))", value: $fontSize, in: 14 ... 20)
                }
            }
            .navigationTitle("Settings")
        }
        .background(Color(red: 41 / 255.0, green: 42 / 255.0, blue: 47 / 255.0).ignoresSafeArea())
        .colorScheme(.dark)
    }
}
