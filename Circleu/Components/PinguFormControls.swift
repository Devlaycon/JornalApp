import SwiftUI

struct PinguTextInput: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            if axis == .vertical {
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(3...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(minHeight: 92)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PinguDesign.border.opacity(0.74), lineWidth: 1)
                    }
            } else {
                TextField(placeholder, text: $text)
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(1)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PinguDesign.border.opacity(0.74), lineWidth: 1)
                    }
            }
        }
    }
}
