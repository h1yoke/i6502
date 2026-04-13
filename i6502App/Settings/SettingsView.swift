import Combine
import SwiftUI

extension View {
    func settingsSheet(isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            SettingsView()
                .frame(minWidth: 500, minHeight: 300)
        }
    }
}

private struct SettingsView: View {
    @AppStorage("FontSize") private var fontSize: Double = 14
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Font configuration")) {
                    Stepper("Font Size: \(Int(fontSize))", value: $fontSize, in: 14 ... 20)
                }
                Section(header: Text("Appearance")) {

                    Picker("Theme", selection: $appTheme) {
                        Text("Default (Dark)").tag(AppTheme.defaultDark)
                        Text("Default (Light)").tag(AppTheme.defaultLight)
                        Text("Civic").tag(AppTheme.civic)
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: appTheme) {
                print(appTheme)
            }
        }
        .background(appTheme.palette.backgroundPrimary.ignoresSafeArea())
    }
}
