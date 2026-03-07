import i6502Assembler
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Editor", systemImage: "pencil") {
                NavigationStack {
                    EditorView()
                }
            }
            if UIDevice.current.userInterfaceIdiom == .phone {
                Tab("Hexdump", systemImage: "number") {
                    HexdumpTabView(originalText: "lda $10")
                }
            }
            Tab("Emulator", systemImage: "display") {
                Text("TBD!")
            }
        }
        .environment(\.colorScheme, .dark)
        .background(Color(red: 41 / 255.0, green: 42 / 255.0, blue: 47 / 255.0).ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
