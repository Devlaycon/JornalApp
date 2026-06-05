import Foundation

struct CommunicationCoachEngine {
    func startSession(
        message: String,
        scene: TipsPracticeScene,
        customScene: String?,
        tone: TipsPracticeTone,
        situation: String,
        attachedImageCount: Int
    ) -> TipsPracticeSession {
        let cleanMessage = clean(message)
        let cleanSituation = clean(situation)
        let output = coachOutput(
            message: cleanMessage,
            scene: scene,
            customScene: customScene,
            tone: tone,
            situation: cleanSituation,
            latestReply: nil
        )

        let turns = [
            TipsPracticeTurn(role: .user, label: "You said", text: cleanMessage),
            TipsPracticeTurn(role: .coach, label: "Suggested phrasing", text: output.suggestedPhrasing),
            TipsPracticeTurn(role: .simulatedPerson, label: "They replied", text: output.simulatedReply),
            TipsPracticeTurn(role: .coach, label: "Now what?", text: output.roomReading)
        ]

        return TipsPracticeSession(
            originalMessage: cleanMessage,
            scene: scene,
            customScene: clean(customScene ?? ""),
            tone: tone,
            situation: cleanSituation,
            turns: turns,
            coachOutput: output,
            attachedImageCount: attachedImageCount
        )
    }

    func continueSession(
        _ session: TipsPracticeSession,
        withReply reply: String,
        extraContext: String
    ) -> TipsPracticeSession {
        let cleanReply = clean(reply)
        let cleanContext = clean(extraContext)
        let combinedSituation = [session.situation, cleanContext]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let output = coachOutput(
            message: session.originalMessage,
            scene: session.scene,
            customScene: session.customScene,
            tone: session.tone,
            situation: combinedSituation,
            latestReply: cleanReply
        )

        var updated = session
        updated.updatedAt = Date()
        if !cleanReply.isEmpty {
            updated.turns.append(TipsPracticeTurn(role: .simulatedPerson, label: "They replied", text: cleanReply))
        }
        if !cleanContext.isEmpty {
            updated.turns.append(TipsPracticeTurn(role: .user, label: "Extra context", text: cleanContext))
        }
        updated.turns.append(TipsPracticeTurn(role: .coach, label: "Coach feedback", text: output.roomReading))
        updated.coachOutput = output
        return updated
    }

    private func coachOutput(
        message: String,
        scene: TipsPracticeScene,
        customScene: String?,
        tone: TipsPracticeTone,
        situation: String,
        latestReply: String?
    ) -> TipsCoachOutput {
        let sceneTitle = scene.displayTitle(customScene: customScene).lowercased()
        let toneLine = toneGuidance(for: tone)
        let basePhrasing = phrasing(message: message, scene: scene, tone: tone, situation: situation)
        let simulatedReply = simulatedReply(for: scene, tone: tone, latestReply: latestReply)
        let roomReading = roomReading(for: scene, tone: tone, latestReply: latestReply)

        return TipsCoachOutput(
            suggestedPhrasing: basePhrasing,
            whyItWorks: "This keeps your point clear, uses a \(tone.title.lowercased()) tone, and gives the other person a useful next step instead of leaving the moment open-ended. \(toneLine)",
            simulatedReply: simulatedReply,
            roomReading: roomReading,
            replyOptions: replyOptions(for: scene, tone: tone, sceneTitle: sceneTitle)
        )
    }

    private func phrasing(
        message: String,
        scene: TipsPracticeScene,
        tone: TipsPracticeTone,
        situation: String
    ) -> String {
        let context = situation.isEmpty ? "" : " Given the context, "
        switch scene {
        case .workplace:
            switch tone {
            case .soft:
                return "Thanks for thinking of me. I want to be transparent: I am close to capacity this week.\(context)Could we look at what should move if this becomes the priority?"
            case .diplomatic:
                return "I want to help, and I also want to be realistic about capacity. I can take one focused part of this, but I would need to adjust the current deadlines. Which outcome matters most this week?"
            case .firm:
                return "I cannot take the full project this week without dropping committed work. I can offer a scoped handoff or revisit it next week once the current deadlines are complete."
            }
        case .family:
            return "I care about this, and I want to say it clearly. \(message) I am not trying to create distance; I am trying to be honest so we can understand each other better."
        case .friendship:
            return "I value our friendship, so I want to be direct instead of letting this sit awkwardly. \(message) Can we talk about it in a way that is fair to both of us?"
        case .romantic:
            return "I want to share this with care, not blame. \(message) What I need is for us to slow down and understand what each of us is feeling."
        case .custom:
            return "I want to say this clearly and respectfully. \(message) The main thing I need is a next step that works for both sides."
        }
    }

    private func simulatedReply(
        for scene: TipsPracticeScene,
        tone: TipsPracticeTone,
        latestReply: String?
    ) -> String {
        if let latestReply, !latestReply.isEmpty {
            return latestReply
        }

        switch scene {
        case .workplace:
            return tone == .firm
                ? "I hear you, but this is urgent. Is there any part you can still take?"
                : "That makes sense. What would you be able to help with this week?"
        case .family:
            return "I did not realize it was coming across that way. Can you explain what you need from me?"
        case .friendship:
            return "I get what you mean, but I also felt a little left out."
        case .romantic:
            return "I want to understand, but I am worried this means you are pulling away."
        case .custom:
            return "I understand part of that. What would you like to happen next?"
        }
    }

    private func roomReading(
        for scene: TipsPracticeScene,
        tone: TipsPracticeTone,
        latestReply: String?
    ) -> String {
        if let latestReply, !latestReply.isEmpty {
            return "They gave you new information. Reflect one sentence back first, then answer with a specific next step. That keeps the conversation grounded instead of defensive."
        }

        switch scene {
        case .workplace:
            return "They are testing whether your boundary has room. Keep the boundary, then offer a narrow option or trade-off."
        case .family:
            return "This is a good moment to reassure them before repeating your need. Warmth makes the boundary easier to hear."
        case .friendship:
            return "Name the relationship first, then the issue. That lowers defensiveness and keeps repair possible."
        case .romantic:
            return "Lead with care and avoid proving who is right. The goal is emotional clarity, not winning the exchange."
        case .custom:
            return "Stay specific. A clear next step will help more than a long explanation."
        }
    }

    private func replyOptions(
        for scene: TipsPracticeScene,
        tone: TipsPracticeTone,
        sceneTitle: String
    ) -> [TipsCoachReplyOption] {
        switch scene {
        case .workplace:
            return [
                TipsCoachReplyOption(label: "BOUNDARY", text: "I can take one defined piece, but I cannot own the whole project this week."),
                TipsCoachReplyOption(label: "TRADE-OFF", text: "If this becomes priority, I need to move one current deadline. Which should shift?"),
                TipsCoachReplyOption(label: "REDIRECT", text: "I can prepare the handoff notes so someone with capacity can move faster.")
            ]
        case .family:
            return [
                TipsCoachReplyOption(label: "REASSURE", text: "I care about you, and I am saying this because I want us to be closer, not farther apart."),
                TipsCoachReplyOption(label: "REQUEST", text: "Could you listen first, then we can talk about what each of us needs?"),
                TipsCoachReplyOption(label: "REPAIR", text: "I may not be saying this perfectly, but I do want to understand each other.")
            ]
        case .friendship:
            return [
                TipsCoachReplyOption(label: "HONEST", text: "I value you, so I want to be honest instead of pretending this did not bother me."),
                TipsCoachReplyOption(label: "CARE", text: "I am not blaming you. I want us to find a better way to handle this next time."),
                TipsCoachReplyOption(label: "ASK", text: "Can you tell me how it felt from your side too?")
            ]
        case .romantic:
            return [
                TipsCoachReplyOption(label: "SOFT START", text: "I love us, and I want to talk about this before it turns into resentment."),
                TipsCoachReplyOption(label: "FEELING", text: "When that happened, I felt unsure and a little disconnected."),
                TipsCoachReplyOption(label: "NEXT STEP", text: "Could we pause and talk about what each of us needed in that moment?")
            ]
        case .custom:
            return [
                TipsCoachReplyOption(label: "CLEAR", text: "The main thing I want to say is this, and I want us to decide one next step."),
                TipsCoachReplyOption(label: "CHECK", text: "Before I explain more, can I check how this is landing for you?"),
                TipsCoachReplyOption(label: "RESET", text: "Let me say that more simply so we can stay on the same page.")
            ]
        }
    }

    private func toneGuidance(for tone: TipsPracticeTone) -> String {
        switch tone {
        case .soft:
            return "The phrasing adds reassurance before the ask."
        case .diplomatic:
            return "The phrasing balances care with clear limits."
        case .firm:
            return "The phrasing names the limit without overexplaining."
        }
    }

    private func clean(_ value: String) -> String {
        value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
