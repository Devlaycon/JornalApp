import SwiftUI

struct CircleView: View {
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = CircleViewModel()

    @State private var creating = false
    @State private var newName = ""
    @State private var newIntention = ""

    private var joinedCount: Int {
        circleStore.circles.filter { $0.joined }.count
    }

    private var memberCount: Int {
        circleStore.circles.reduce(0) { $0 + $1.members }
    }

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
                        VStack(spacing: 12) {
                            privacyPill
                            ForEach(Array(circleStore.circles.enumerated()), id: \.element.id) { index, circle in
                                CircleCard(circle: circle) {
                                    viewModel.open(circle)
                                }
                                .slideUp(Double(index) * 0.05)
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
            }
            .navigationBarHidden(true)
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
                        .padding(.bottom, 20)

                    Button {
                        circleStore.createCircle(
                            name: newName.trimmingCharacters(in: .whitespacesAndNewlines),
                            intention: newIntention.trimmingCharacters(in: .whitespacesAndNewlines)
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

private struct CircleCard: View {
    let circle: CircleSpace
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Text(circle.emoji)
                    .font(.system(size: 22))
                    .frame(width: 48, height: 48)
                    .glass(.pill, cornerRadius: 16)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(circle.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.ink)
                            .lineLimit(1)

                        if circle.joined {
                            Text("JOINED")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: 0x16A34A))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(hex: 0x16A34A).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(circle.intention)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.slate)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(circle.members) members")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Pingu.muted)
                    .padding(.top, 2)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Pingu.muted)
            }
            .padding(16)
            .glass(.regular, cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CircleView()
        .environmentObject(CircleStore())
        .environmentObject(ReflectionJournalStore())
}
