import FirebaseFirestore
import Foundation

indirect enum FirebasePayloadValue: Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    case stringArray([String])
    case dictionary([String: FirebasePayloadValue])
    case dictionaryArray([[String: FirebasePayloadValue]])

    var firestoreValue: Any {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .bool(let value):
            return value
        case .date(let value):
            return value
        case .stringArray(let value):
            return value
        case .dictionary(let value):
            return value.mapValues(\.firestoreValue)
        case .dictionaryArray(let values):
            return values.map { $0.mapValues(\.firestoreValue) }
        }
    }
}

struct FirebaseDocumentPayload: Equatable {
    var path: String
    var data: [String: FirebasePayloadValue]
    var scope: BackendSyncScope

    var firestoreData: [String: Any] {
        data.mapValues(\.firestoreValue)
    }
}

enum FirebaseSyncMapper {
    static func privateBackupDocuments(for snapshot: BackendSyncSnapshot) -> [FirebaseDocumentPayload] {
        let uid = snapshot.userID

        let journalDocuments = snapshot.journalEntries.map { entry in
            FirebaseDocumentPayload(
                path: "users/\(uid)/journalEntries/\(entry.id.uuidString)",
                data: entry.firebasePayload,
                scope: .journalEntries
            )
        }

        let questDocuments = snapshot.quests.map { quest in
            FirebaseDocumentPayload(
                path: "users/\(uid)/quests/\(quest.id.uuidString)",
                data: quest.firebasePayload,
                scope: .quests
            )
        }

        let aiSessionDocuments = snapshot.aiSessions.map { session in
            FirebaseDocumentPayload(
                path: "users/\(uid)/aiReflectionSessions/\(session.id.uuidString)",
                data: session.firebasePayload,
                scope: .aiSessions
            )
        }

        return journalDocuments + questDocuments + aiSessionDocuments
    }
}

protocol FirebaseFirestoreClient {
    func setData(_ data: [String: Any], at documentPath: String, merge: Bool) async throws
}

struct FirebaseUploadOnlySyncer: ReflectionSyncing {
    private let client: FirebaseFirestoreClient

    init(client: FirebaseFirestoreClient = LiveFirebaseFirestoreClient()) {
        self.client = client
    }

    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult {
        let documents = FirebaseSyncMapper.privateBackupDocuments(for: snapshot)
        var uploadedCounts = BackendSyncCounts.zero
        var failedScopes = Set<BackendSyncScope>()

        for document in documents {
            do {
                try await client.setData(document.firestoreData, at: document.path, merge: true)
                uploadedCounts.increment(document.scope)
            } catch {
                failedScopes.insert(document.scope)
            }
        }

        return BackendSyncResult(
            uploadedCounts: uploadedCounts,
            downloadedCounts: .zero,
            failedScopes: BackendSyncScope.allCases.filter { failedScopes.contains($0) }
        )
    }
}

struct LiveFirebaseFirestoreClient: FirebaseFirestoreClient {
    func setData(_ data: [String: Any], at documentPath: String, merge: Bool) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Firestore.firestore().document(documentPath).setData(data, merge: merge) { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }
    }
}

private extension BackendSyncCounts {
    mutating func increment(_ scope: BackendSyncScope) {
        switch scope {
        case .journalEntries:
            journalEntryCount += 1
        case .quests:
            questCount += 1
        case .circles:
            circleCount += 1
        case .circlePosts:
            circlePostCount += 1
        case .aiSessions:
            aiSessionCount += 1
        }
    }
}

private extension JournalReflectionEntry {
    var firebasePayload: [String: FirebasePayloadValue] {
        compactPayload([
            "entryID": .string(id.uuidString),
            "createdAt": .date(createdAt),
            "updatedAt": .date(lastEditedAt ?? createdAt),
            "durationSeconds": .int(durationSeconds),
            "transcript": .string(transcript),
            "engineName": .string(engineName),
            "sessionID": sessionID.map { .string($0.uuidString) },
            "editableTitle": editableTitle.map(FirebasePayloadValue.string),
            "editableEmotion": editableEmotion.map(FirebasePayloadValue.string),
            "privateNote": .string(privateNote),
            "tags": .stringArray(tags),
            "result": .dictionary(result.firebasePayload)
        ])
    }
}

private extension Quest {
    var firebasePayload: [String: FirebasePayloadValue] {
        compactPayload([
            "questID": .string(id.uuidString),
            "title": .string(title),
            "detail": .string(detail),
            "sourceEntryID": sourceEntryID.map { .string($0.uuidString) },
            "createdAt": .date(createdAt),
            "completedAt": completedAt.map(FirebasePayloadValue.date),
            "status": .string(status.rawValue)
        ])
    }
}

private extension AIReflectionSession {
    var firebasePayload: [String: FirebasePayloadValue] {
        compactPayload([
            "sessionID": .string(id.uuidString),
            "createdAt": .date(createdAt),
            "updatedAt": .date(updatedAt),
            "entryID": entryID.map { .string($0.uuidString) },
            "engineName": .string(engineName),
            "source": .string(source.rawValue),
            "transcript": .string(transcript),
            "durationSeconds": .int(durationSeconds),
            "selectedAttemptID": selectedAttemptID.map { .string($0.uuidString) },
            "mergedSessionIDs": .stringArray(mergedSessionIDs.map(\.uuidString)),
            "attempts": .dictionaryArray(attempts.map(\.firebasePayload))
        ])
    }
}

private extension AIReflectionAttempt {
    var firebasePayload: [String: FirebasePayloadValue] {
        compactPayload([
            "attemptID": .string(id.uuidString),
            "createdAt": .date(createdAt),
            "engineName": .string(engineName),
            "status": .string(status.rawValue),
            "result": result.map { .dictionary($0.firebasePayload) },
            "errorMessage": errorMessage.map(FirebasePayloadValue.string),
            "elapsedMilliseconds": elapsedMilliseconds.map(FirebasePayloadValue.int)
        ])
    }
}

private extension AIReflectionResult {
    var firebasePayload: [String: FirebasePayloadValue] {
        [
            "title": .string(title),
            "emotion": .string(emotion),
            "summary": .string(summary),
            "insight": .string(insight),
            "expressionMoment": .string(expressionMoment),
            "quote": .string(quote),
            "confidenceScore": .double(confidenceScore),
            "suggestedQuest": .string(suggestedQuest)
        ]
    }
}

private func compactPayload(_ values: [String: FirebasePayloadValue?]) -> [String: FirebasePayloadValue] {
    values.reduce(into: [:]) { result, item in
        guard let value = item.value else { return }
        result[item.key] = value
    }
}
