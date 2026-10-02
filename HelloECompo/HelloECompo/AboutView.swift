import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    private let revision = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("AboutAppIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .accessibilityLabel("HelloECompoのアプリアイコン")

                Text("HelloECompo")
                    .font(.title2.bold())

                VStack(spacing: 12) {
                    LabeledContent("Version", value: version)
                    LabeledContent("Revision", value: revision)
                }
                .frame(maxWidth: 280)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("HelloECompoについて")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}
