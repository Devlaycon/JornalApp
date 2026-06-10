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

        // Initial turns only: user message + suggested phrasing.
        // "They replied" and "Now what" turns are appended later in continueSession,
        // once the user pastes the real reply.
        let turns = [
            TipsPracticeTurn(role: .user, label: "You said", text: cleanMessage),
            TipsPracticeTurn(role: .coach, label: "Suggested phrasing", text: output.suggestedPhrasing)
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

    /// Triggered by "Paste their reply".
    /// Appends a "They replied" bubble and refreshes the room-reading + reply options
    /// that drive the amber "Now what?" card. Does NOT change Suggested phrasing.
    func handleIncomingReply(
        _ session: TipsPracticeSession,
        reply: String
    ) -> TipsPracticeSession {
        let cleanReply = clean(reply)
        guard !cleanReply.isEmpty else { return session }

        let refreshed = coachOutput(
            message: session.originalMessage,
            scene: session.scene,
            customScene: session.customScene,
            tone: session.tone,
            situation: session.situation,
            latestReply: cleanReply
        )

        var updated = session
        updated.updatedAt = Date()
        updated.turns.append(
            TipsPracticeTurn(role: .simulatedPerson, label: "They replied", text: cleanReply)
        )
        // Only update the "now what" half of the output. Keep the existing
        // Suggested phrasing + whyItWorks so the top card doesn't flicker.
        var newOutput = updated.coachOutput
        newOutput.roomReading = refreshed.roomReading
        newOutput.replyOptions = refreshed.replyOptions
        newOutput.simulatedReply = cleanReply
        updated.coachOutput = newOutput
        return updated
    }

    /// Triggered by "Add context".
    /// Folds the new context into the session and regenerates the Suggested phrasing
    /// (treated as the user's own message, restyled by tone + scene + context).
    /// Does NOT generate a "Now what?" — that only happens after a real reply.
    func handleExtraContext(
        _ session: TipsPracticeSession,
        context: String
    ) -> TipsPracticeSession {
        let cleanContext = clean(context)
        guard !cleanContext.isEmpty else { return session }

        let combinedSituation = [session.situation, cleanContext]
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let refreshed = coachOutput(
            message: session.originalMessage,
            scene: session.scene,
            customScene: session.customScene,
            tone: session.tone,
            situation: combinedSituation,
            latestReply: nil
        )

        var updated = session
        updated.updatedAt = Date()
        updated.situation = combinedSituation
        // Show what the user added, then drop in a freshly styled phrasing card.
        updated.turns.append(
            TipsPracticeTurn(role: .user, label: "Extra context", text: cleanContext)
        )
        updated.turns.append(
            TipsPracticeTurn(role: .coach, label: "Suggested phrasing", text: refreshed.suggestedPhrasing)
        )
        // Update the global Suggested-phrasing fields; leave room-reading +
        // reply options untouched (they should only refresh from a real reply).
        var newOutput = updated.coachOutput
        newOutput.suggestedPhrasing = refreshed.suggestedPhrasing
        newOutput.whyItWorks = refreshed.whyItWorks
        updated.coachOutput = newOutput
        return updated
    }

    /// Rotates the suggested-phrasing line through softer variants.
    /// Pure templates — swap this body to call a real LLM later.
    func rephraseSofter(_ session: TipsPracticeSession) -> TipsPracticeSession {
        let variants = softerVariants(
            scene: session.scene,
            tone: session.tone,
            message: session.originalMessage
        )
        guard !variants.isEmpty else { return session }

        let current = session.coachOutput.suggestedPhrasing
        let next = variants.first(where: { $0 != current }) ?? variants[0]

        var updated = session
        var output = updated.coachOutput
        output.suggestedPhrasing = next
        output.whyItWorks = "This version softens the opening, keeps your point clear, and gives the other person an easy way back into the conversation."
        updated.coachOutput = output

        if let idx = updated.turns.firstIndex(where: { $0.role == .coach && $0.label == "Suggested phrasing" }) {
            updated.turns[idx] = TipsPracticeTurn(
                role: .coach,
                label: "Suggested phrasing",
                text: next
            )
        }
        updated.updatedAt = Date()
        return updated
    }

    private func softerVariants(scene: TipsPracticeScene, tone: TipsPracticeTone, message: String) -> [String] {
        switch scene {
        case .workplace:
            return [
                "I really want to help here. Honestly, my plate is full this week — could we look together at what to keep and what to move?",
                "Thanks for trusting me with this. I can take a small piece, but I would need to adjust one of my current deadlines to do it well. Which feels most important?",
                "I appreciate you thinking of me. Right now I am stretched thin — would it work if I helped scope this and we revisit early next week?"
            ]
        case .family:
            return [
                "I love you and I am not trying to push back. I just want to share what I am feeling so we can understand each other.",
                "Can we slow down for a second? I want to say this gently — none of this is meant as criticism, I just want us to feel close again.",
                "I am saying this because I care, not because I am upset. Could we talk through what each of us needs?"
            ]
        case .friendship:
            return [
                "I really value our friendship, so I want to share this kindly: it kind of stayed on my mind, and I would rather talk about it than let it sit.",
                "I am not upset with you — I just want to be honest because you matter to me. Could we talk about what happened?",
                "Hey, no pressure, but something has been on my mind. Is it okay if I share it so we can move past it together?"
            ]
        case .romantic:
            return [
                "I love you and I am bringing this up gently, not as a complaint. I just want us to understand each other better.",
                "Can we pause for a moment? I want to share what I am feeling without it sounding like blame.",
                "I care about us, so I want to say this softly: when that happened, I felt a little disconnected. Can we talk about it?"
            ]
        case .custom:
            return [
                "I want to share this gently, not as criticism. My main hope is that we can land on one clear next step together.",
                "Can I share something with you in a soft way? I want to make sure it lands as care, not as a complaint.",
                "I am bringing this up kindly. Could we talk it through and decide one small next step?"
            ]
        }
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
