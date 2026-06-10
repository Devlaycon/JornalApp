import SwiftUI

struct SupportView: View {

    var body: some View {

        ScrollView {

            VStack(spacing: 16) {

                FAQCard(
                    question: "What is CircleU?",
                    answer: "CircleU is a reflection companion designed to help people build social confidence through reflection, growth, and connection."
                )

                FAQCard(
                    question: "Why use voice reflection?",
                    answer: "Voice allows users to express thoughts and emotions naturally, making reflection more accessible and personal."
                )

                FAQCard(
                    question: "Is my reflection private?",
                    answer: "Your reflections are intended to support your personal growth experience. You remain in control of what you choose to save or share."
                )

                FAQCard(
                    question: "Does CircleU provide therapy?",
                    answer: "No. CircleU supports self-reflection and personal growth, but it does not replace professional mental health services."
                )

                FAQCard(
                    question: "How does AI help?",
                    answer: "AI helps identify themes, emotions, and opportunities for growth within reflections and may provide supportive suggestions."
                )

                FAQCard(
                    question: "Can I choose what to share?",
                    answer: "Yes. You remain in control of what you choose to save, keep private, or share with the CircleU community."
                )

                contactCard

                feedbackCard
            }
            .padding()
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contactCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(
                "Contact Us",
                systemImage: "envelope.fill"
            )
            .font(.headline)

            Text(
                "Questions, suggestions, or ideas?"
            )
            .foregroundStyle(.secondary)

            Text("circleu2026@gmail.com")
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }

    private var feedbackCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            Label(
                "Send Feedback",
                systemImage: "bubble.left.and.bubble.right.fill"
            )
            .font(.headline)

            Text(
                "Your feedback helps CircleU grow. We welcome ideas about features, usability, accessibility, and community experiences."
            )
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }
}

struct FAQCard: View {

    let question: String
    let answer: String

    var body: some View {

        DisclosureGroup {

            Text(answer)
                .padding(.top, 8)

        } label: {

            Text(question)
                .font(.headline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
    }
}
