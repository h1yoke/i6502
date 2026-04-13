import i6502Assembler
import SwiftUI

#if !os(macOS)
import UIKit
#endif

struct EditorView: View {
    @AppStorage("AppTheme") private var appTheme: AppTheme = .defaultDark
    @AppStorage("FontSize") private var fontSize: Double = 14
    @State private var onSettings: Bool = false
    @State private var showInspector: Bool = true

    private let codeStorage: CodeStorage

    init(codeStorage: CodeStorage) {
        self.codeStorage = codeStorage
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            CodeEditorView(
                text: .init(
                    get: { codeStorage.code },
                    set: { codeStorage.code = $0 }
                ),
                fontSize: CGFloat(fontSize),
                appTheme: appTheme
            )

            if showInspector {
                HexdumpOverlayView(originalText: codeStorage.code)
                    .transition(.move(edge: .trailing))
                    .padding([.trailing, .bottom], 12)
                    .ignoresSafeArea(.all, edges: [.trailing, .bottom])
                    .simultaneousGesture(DragGesture().onEnded {
                        if $0.predictedEndTranslation.width > 50 {
                            withAnimation {
                                showInspector = false
                            }
                        }
                    })
            }
        }
        .background(appTheme.palette.backgroundPrimary.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Hexdump", systemImage: "sidebar.squares.trailing") {
                    withAnimation {
                        showInspector.toggle()
                    }
                }
            }

            #if os(macOS)
            ToolbarItem(placement: .secondaryAction) {
                Button("Settings", systemImage: "gear") { onSettings = true }
            }
            #else
            ToolbarItem(placement: .topBarTrailing) {
                Menu("", systemImage: "ellipsis") {
                    Button("Settings", systemImage: "gear") { onSettings = true }
                    Divider()
                    Button("Import as..", systemImage: "square.and.arrow.down") {}
                    Button("Export as..", systemImage: "square.and.arrow.up") {}
                    Divider()
                    Button("About", systemImage: "info.circle") {}
                }
            }
            #endif
        }
        .settingsSheet(isPresented: $onSettings)
        .toolbarBackground(.hidden, for: .automatic)
    }
}

#if os(macOS)
struct CodeEditorView: NSViewRepresentable {
    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var fontSize: CGFloat
        var appTheme: AppTheme

        init(text: Binding<String>, fontSize: CGFloat, appTheme: AppTheme) {
            _text = text
            self.fontSize = fontSize
            self.appTheme = appTheme
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }
            textView.typingAttributes = [
                .foregroundColor: NSColor(appTheme.palette.foregroundPrimary),
                .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            ]
            text = textView.string
        }
    }

    @Binding var text: String
    let fontSize: CGFloat
    let appTheme: AppTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, fontSize: fontSize, appTheme: appTheme)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let storage = HighlightingTextStorage(appTheme: context.coordinator.appTheme)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        let container = NSTextContainer()
        container.widthTracksTextView = true
        container.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        layoutManager.addTextContainer(container)

        let scrollView = NSTextView.scrollableTextView()

        let textView = NSTextView(frame: scrollView.bounds, textContainer: container)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = NSColor(context.coordinator.appTheme.palette.backgroundPrimary)
        textView.typingAttributes = [
            .foregroundColor: NSColor(context.coordinator.appTheme.palette.foregroundPrimary),
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        ]
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        textView.string = text

        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.appTheme = appTheme
        context.coordinator.fontSize = fontSize
        guard let textView = nsView.documentView as? NSTextView else {
            return
        }

        (textView.textContainer?.layoutManager?.textStorage as? HighlightingTextStorage)?.appTheme = appTheme

        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = NSColor(appTheme.palette.backgroundPrimary)
        textView.typingAttributes = [
            .foregroundColor: NSColor(appTheme.palette.foregroundPrimary),
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        ]
    }
}
#else
struct CodeEditorView: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let fontSize: CGFloat
        let appTheme: AppTheme

        init(text: Binding<String>, fontSize: CGFloat, appTheme: AppTheme) {
            _text = text
            self.fontSize = fontSize
            self.appTheme = appTheme
        }

        func textViewDidChange(_ textView: UITextView) {
            textView.typingAttributes = [
                .foregroundColor: UIColor(appTheme.palette.foregroundPrimary),
                .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            ]
            text = textView.text
        }
    }

    @Binding var text: String
    let fontSize: CGFloat
    let appTheme: AppTheme

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, fontSize: fontSize, appTheme: appTheme)
    }

    func makeUIView(context: Context) -> UITextView {
        let storage = HighlightingTextStorage(appTheme: appTheme)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        layoutManager.addTextContainer(container)

        let textView = UITextView(frame: .zero, textContainer: container)
        textView.delegate = context.coordinator
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.backgroundColor = UIColor(appTheme.palette.backgroundPrimary)
        textView.typingAttributes = [
            .foregroundColor: UIColor(appTheme.palette.foregroundPrimary),
            .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        ]

        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.smartInsertDeleteType = .no
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.keyboardType = .asciiCapable

        textView.text = text
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        uiView.backgroundColor = UIColor(appTheme.palette.backgroundPrimary)
        uiView.typingAttributes = [
            .foregroundColor: UIColor(appTheme.palette.foregroundPrimary),
            .font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        ]
    }
}
#endif

class HighlightingTextStorage: NSTextStorage {
    var appTheme: AppTheme

    init(appTheme: AppTheme) {
        self.appTheme = appTheme
        super.init()
    }

    #if os(macOS)
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }
    #endif

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let backingStore = NSMutableAttributedString()

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?)
        -> [NSAttributedString.Key: Any]
    {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    private var lastSpaceInsertTime: CFAbsoluteTime = 0

    override func replaceCharacters(in range: NSRange, with str: String) {
        // A very dummy solution to prevent autoperiod on iOS and MacOS
        var actualStr = str
        if str == " ", range.length == 0 {
            lastSpaceInsertTime = CFAbsoluteTimeGetCurrent()
        }
        if str == ". " || str == ".", range.length >= 1 {
            let replaced = backingStore.attributedSubstring(from: range).string
            let timeSinceSpace = CFAbsoluteTimeGetCurrent() - lastSpaceInsertTime
            if replaced == " ", timeSinceSpace < 0.5 {
                actualStr = String(repeating: " ", count: str.count)
            }
        }
        beginEditing()
        backingStore.replaceCharacters(in: range, with: actualStr)
        edited(.editedCharacters, range: range, changeInLength: actualStr.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    override func processEditing() {
        var affectedRange = (string as NSString).paragraphRange(for: editedRange)
        let afterEnd = affectedRange.location + affectedRange.length
        if afterEnd < (string as NSString).length {
            let nextParagraph = (string as NSString).paragraphRange(
                for: NSRange(location: afterEnd, length: 0)
            )
            affectedRange = NSUnionRange(affectedRange, nextParagraph)
        }
        let text = (string as NSString).substring(with: affectedRange)

        updateColor(.foregroundColor, value: appTheme.palette.foregroundPrimary, range: affectedRange)
        highlightingMatches(text, offset: affectedRange.location, of: "\\.\\w*", color: appTheme.palette.directives)
        highlightingMatches(text, offset: affectedRange.location, of: "\\S*:", color: appTheme.palette.labels)
        highlightingMatches(
            text,
            offset: affectedRange.location,
            of: "\\$[0-9A-Fa-f]+",
            color: appTheme.palette.literals
        )
        highlightingMatches(text, offset: affectedRange.location, of: "\\b\\d+\\b", color: appTheme.palette.literals)
        highlightingMatches(text, offset: affectedRange.location, of: ";.*", color: appTheme.palette.comments)

        super.processEditing()
    }

    private func highlightingMatches(
        _ text: String,
        offset: Int,
        of pattern: String,
        color: Color = .blue
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return
        }

        let nsRange = NSRange(text.startIndex ..< text.endIndex, in: text)
        let matches = regex.matches(in: text, options: [], range: nsRange)

        for match in matches.reversed() {
            let absoluteRange = NSRange(location: match.range.location + offset, length: match.range.length)
            updateColor(.foregroundColor, value: color, range: absoluteRange)
        }
    }

    private func updateColor(_ key: NSAttributedString.Key, value: Color, range: NSRange) {
        #if os(macOS)
        backingStore.addAttribute(key, value: NSColor(value), range: range)
        #else
        backingStore.addAttribute(key, value: UIColor(value), range: range)
        #endif
    }
}
