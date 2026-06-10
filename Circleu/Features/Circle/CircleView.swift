import PhotosUI
import SwiftUI

struct CircleView: View {
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = CircleViewModel()

    @State private var creating = false
    @State private var newName = ""
    @State private var newIntention = ""
    @State private var newCoverItems: [PhotosPickerItem] = []
    @State private var newCoverData: [Data] = []
    @State private var editingCircle: CircleSpace?
    @State private var editName = ""
    @State private var editIntention = ""
    @State private var editCoverItems: [PhotosPickerItem] = []
    @State private var editCoverData: [Data] = []
    @State private var pendingDelete: CircleSpace?

    private var joinedCount: Int {
        circleStore.circles.filter { $0.joined }.count
    }

    private var memberCount: Int {
        circleStore.circles.reduce(0) { $0 + $1.members }
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PinguAurora()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 54)

                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            privacyPill

                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(Array(circleStore.circles.enumerated()), id: \.element.id) { index, circle in
                                    CircleHeroCard(
                                        circle: circle,
                                        accent: CircleHeroPalette.accent(for: index),
                                        heroHeight: CircleHeroPalette.heroHeight(for: index),
                                        onOpen: { viewModel.open(circle) },
                                        onEdit: { beginEdit(circle) },
                                        onDelete: { pendingDelete = circle }
                                    )
                                    .slideUp(Double(index) * 0.04)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }

                if creating {
                    createModal
                }

                if editingCircle != nil {
                    editModal
                }
            }
            .navigationBarHidden(true)
            .alert(
                "Delete this circle?",
                isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
                ),
                presenting: pendingDelete
            ) { circle in
                Button("Delete", role: .destructive) {
                    circleStore.deleteCircle(circle)
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingDelete = nil
                }
            } message: { circle in
                Text("\(circle.name) and all its posts will be removed from this device. This can't be undone.")
            }
            .navigationDestination(item: $viewModel.selectedCircle) { circle in
                CircleDetailView(circleID: circle.id)
                    .environmentObject(circleStore)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Kicker("GENTLE COMMUNITIES")
                Text("Circle")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
            }

            Spacer()

            Button {
                creating = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(GlassPrimaryFill(cornerRadius: 999))
                    .clipShape(Circle())
            }
            .buttonStyle(PressableButtonStyle())
        }
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            CircleMiniStat(value: "\(circleStore.circles.count)", label: "Groups")
            CircleMiniStat(value: "\(joinedCount)", label: "Joined")
            CircleMiniStat(value: "\(memberCount)", label: "Members")
        }
    }

    private var privacyPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Pingu.accent)

            Text("Private mode — only privacy-safe summaries are shared, never your raw recordings.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Pingu.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(.pill, cornerRadius: 16)
    }

    private var createModal: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismissCreate() }

            GlassCard(style: .strong, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Create a circle")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.ink)
                        Spacer()
                        Button {
                            dismissCreate()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Pingu.muted)
                        }
                    }
                    .padding(.bottom, 4)

                    Text("A small, private space for one intention.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Pingu.slate)
                        .padding(.bottom, 16)

                    modalField("Circle name", text: $newName, size: 15)
                        .padding(.bottom, 12)
                    modalField("Its intention (e.g. saying no kindly)", text: $newIntention, size: 14)
                        .padding(.bottom, 12)

                    coverPickerRow(
                        items: $newCoverItems,
                        data: $newCoverData,
                        label: "Add cover photos"
                    )
                    .padding(.bottom, 20)

                    Button {
                        circleStore.createCircle(
                            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
                            intention: newIntention.trimmingCharacters(in: .whitespacesAndNewlines),
                            coverImages: newCoverData
                        )
                        dismissCreate()
                    } label: {
                        Text("Create circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PinguPrimaryButtonStyle())
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(24)
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    private func modalField(_ placeholder: String, text: Binding<String>, size: CGFloat) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: size, weight: .regular, design: .rounded))
            .foregroundStyle(Pingu.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.white.opacity(0.7))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.7), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func dismissCreate() {
        creating = false
        newName = ""
        newIntention = ""
        newCoverItems = []
        newCoverData = []
    }

    private func beginEdit(_ circle: CircleSpace) {
        editingCircle = circle
        editName = circle.name
        editIntention = circle.intention
        editCoverItems = []
        editCoverData = circle.coverImages
    }

    private func dismissEdit() {
        editingCircle = nil
        editName = ""
        editIntention = ""
        editCoverItems = []
        editCoverData = []
    }

    @ViewBuilder
    private func coverPickerRow(
        items: Binding<[PhotosPickerItem]>,
        data: Binding<[Data]>,
        label: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PhotosPicker(
                    selection: items,
                    maxSelectionCount: 6,
                    matching: .images
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 13, weight: .bold))
                        Text(label)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Pingu.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Pingu.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
                .onChange(of: items.wrappedValue) { _, newItems in
                    Task {
                        var loaded: [Data] = []
                        for item in newItems {
                            if let raw = try? await item.loadTransferable(type: Data.self),
                               let compressed = compress(imageData: raw) {
                                loaded.append(compressed)
                            }
                        }
                        await MainActor.run { data.wrappedValue = loaded }
                    }
                }

                if !data.wrappedValue.isEmpty {
                    Text("\(data.wrappedValue.count) selected")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Pingu.muted)
                    Spacer()
                    Button {
                        items.wrappedValue = []
                        data.wrappedValue = []
                    } label: {
                        Text("Clear")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.red)
                    }
                } else {
                    Text("Optional · up to 6")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Pingu.muted)
                }
            }

            if !data.wrappedValue.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(data.wrappedValue.enumerated()), id: \.offset) { _, bytes in
                            if let img = UIImage(data: bytes) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    /// Downscale and JPEG-compress so UserDefaults storage stays reasonable.
    private func compress(imageData: Data) -> Data? {
        guard let img = UIImage(data: imageData) else { return nil }
        let maxDim: CGFloat = 1200
        let scale = min(1, maxDim / max(img.size.width, img.size.height))
        let target = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.75)
    }

    private var editModal: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { dismissEdit() }

            GlassCard(style: .strong, cornerRadius: 24) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Edit circle")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.ink)
                        Spacer()
                        Button {
                            dismissEdit()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Pingu.muted)
                        }
                    }
                    .padding(.bottom, 4)

                    Text("Refine the name or intention.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Pingu.slate)
                        .padding(.bottom, 16)

                    modalField("Circle name", text: $editName, size: 15)
                        .padding(.bottom, 12)
                    modalField("Its intention", text: $editIntention, size: 14)
                        .padding(.bottom, 12)

                    coverPickerRow(
                        items: $editCoverItems,
                        data: $editCoverData,
                        label: "Replace cover photos"
                    )
                    .padding(.bottom, 20)

                    Button {
                        if let editing = editingCircle {
                            circleStore.updateCircle(
                                editing.id,
                                name: editName,
                                intention: editIntention,
                                coverImages: editCoverData
                            )
                        }
                        dismissEdit()
                    } label: {
                        Text("Save changes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PinguPrimaryButtonStyle())
                    .disabled(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(editName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(24)
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

// MARK: - Hero palette

private enum CircleHeroPalette {
    /// Mixed staggered heights to give the Pinterest-style feel without breaking the grid.
    static func heroHeight(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [180, 220, 200, 240]
        return pattern[index % pattern.count]
    }

    static func accent(for index: Int) -> [Color] {
        let palette: [[Color]] = [
            [Color(hex: 0xFCA5A5), Color(hex: 0xF472B6)],
            [Color(hex: 0xFCD34D), Color(hex: 0xFB923C)],
            [Color(hex: 0x86EFAC), Color(hex: 0x22D3EE)],
            [Color(hex: 0xA5B4FC), Color(hex: 0x60A5FA)],
            [Color(hex: 0xF9A8D4), Color(hex: 0xC084FC)],
            [Color(hex: 0x67E8F9), Color(hex: 0x6366F1)]
        ]
        return palette[index % palette.count]
    }
}

// MARK: - Hero card (vertical, big-image style)

private struct CircleHeroCard: View {
    let circle: CircleSpace
    let accent: [Color]
    let heroHeight: CGFloat
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 0) {
                heroArea
                titleArea
            }
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var heroArea: some View {
        ZStack(alignment: .topTrailing) {
            if let firstCover = circle.coverImages.first,
               let img = UIImage(data: firstCover) {
                // Color.clear sizes to the available column width/height;
                // the image is overlaid + clipped so .scaledToFill cannot
                // push the ZStack wider than the grid column.
                Color.clear
                    .overlay(
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    )
                LinearGradient(
                    colors: [.black.opacity(0.0), .black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                // Small emoji badge in the bottom-left for the photo variant
                VStack {
                    Spacer()
                    HStack {
                        Text(circle.emoji)
                            .font(.system(size: 22))
                            .padding(8)
                            .background(.white.opacity(0.85))
                            .clipShape(Circle())
                        Spacer()
                    }
                    .padding(10)
                }
            } else {
                LinearGradient(colors: accent, startPoint: .topLeading, endPoint: .bottomTrailing)

                // Decorative blurred blobs for depth.
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 90, height: 90)
                    .blur(radius: 6)
                    .offset(x: -30, y: 90)
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .blur(radius: 4)
                    .offset(x: 50, y: -10)

                // Centered hero emoji
                VStack {
                    Spacer()
                    Text(circle.emoji)
                        .font(.system(size: 56))
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            // Top row: joined badge + menu (if owned)
            HStack(alignment: .top) {
                if circle.joined {
                    Text("JOINED")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.28))
                        .clipShape(Capsule())
                }
                Spacer()
                if circle.isOwnedByMe {
                    menuButton
                }
            }
            .padding(10)
        }
        .frame(height: heroHeight)
        .clipped()
    }

    private var menuButton: some View {
        Menu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.black.opacity(0.22))
                .clipShape(Circle())
        }
    }

    private var titleArea: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(circle.name)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("\(circle.members)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                Text("·")
                Text(circle.isOwnedByMe ? "Yours" : "Community")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Pingu.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
    }
}

private struct CircleMiniStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glass(.regular, cornerRadius: 16)
    }
}

#Preview {
    CircleView()
        .environmentObject(CircleStore())
        .environmentObject(ReflectionJournalStore())
}
