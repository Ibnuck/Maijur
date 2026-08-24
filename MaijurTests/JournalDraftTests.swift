import Foundation
import Testing
@testable import Maijur

@Suite("Journal draft")
struct JournalDraftTests {

    private let original = JournalEntry(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        date: Date(timeIntervalSince1970: 1_777_593_600),
        text: "A quiet morning."
    )

    @Test("Whitespace-only drafts are invalid")
    func whitespaceOnlyIsInvalid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: "  \n\t  "
        )

        #expect(!draft.isValid)
    }

    @Test("Meaningful drafts are valid without changing their text")
    func meaningfulTextIsValid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: "  Something worth remembering.  "
        )

        #expect(draft.isValid)
        #expect(draft.text == "  Something worth remembering.  ")
    }

    @Test("Draft at the character limit is valid")
    func exactCharacterLimitIsValid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: String(repeating: "a", count: JournalDraft.maximumCharacterCount)
        )

        #expect(draft.isValid)
        #expect(draft.remainingCharacterCount == 0)
        #expect(draft.characterLimitProgress == 1)
    }

    @Test("Draft over the character limit is invalid")
    func overCharacterLimitIsInvalid() {
        let draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: String(repeating: "a", count: JournalDraft.maximumCharacterCount + 1)
        )

        #expect(!draft.isValid)
    }

    @Test("Editor input stops at the character limit")
    func updateTextEnforcesCharacterLimit() {
        var draft = JournalDraft(
            date: Date(timeIntervalSince1970: 1_777_593_600),
            text: ""
        )

        draft.updateText(String(repeating: "a", count: JournalDraft.maximumCharacterCount + 50))

        #expect(draft.characterCount == JournalDraft.maximumCharacterCount)
        #expect(draft.isValid)
    }

    @Test("An unchanged draft is not dirty")
    func unchangedDraftIsNotDirty() {
        let draft = JournalDraft(entry: original)

        #expect(!draft.isDirty(comparedTo: original))
    }

    @Test("Changing the date makes a draft dirty")
    func changedDateIsDirty() {
        var draft = JournalDraft(entry: original)
        draft.date = original.date.addingTimeInterval(86_400)

        #expect(draft.isDirty(comparedTo: original))
    }

    @Test("Changing the content makes a draft dirty")
    func changedTextIsDirty() {
        var draft = JournalDraft(entry: original)
        draft.text = "A different memory."

        #expect(draft.isDirty(comparedTo: original))
    }
}

@Suite("Journal analysis input")
struct JournalAnalysisInputTests {

    @Test("Short journal remains one analysis chunk")
    func shortJournalRemainsWhole() {
        #expect(JournalAnalysisInput.chunks(from: "A short journal.") == ["A short journal."])
    }

    @Test("Long journal keeps paragraph content across chunks")
    func longJournalIsChunkedWithoutContentLoss() {
        let first = String(repeating: "First paragraph. ", count: 150)
        let second = String(repeating: "Second paragraph. ", count: 150)
        let text = "\(first)\n\n\(second)"
        let chunks = JournalAnalysisInput.chunks(from: text)

        #expect(chunks.count > 1)
        #expect(chunks.allSatisfy { $0.count <= JournalAnalysisInput.maximumCharactersPerChunk })
        #expect(chunks.joined(separator: " ").contains("First paragraph."))
        #expect(chunks.joined(separator: " ").contains("Second paragraph."))
    }
}

@Suite("Overall insight planning")
struct OverallInsightPlannerTests {
    @Test("Insights are processed chronologically in groups of at most three")
    func batchesAreLimitedToThree() {
        let snapshots = (0..<5).reversed().map { offset in
            HistorySnapshot(
                id: UUID(),
                sourceJournalID: UUID(),
                sourceJournalDate: Date(timeIntervalSince1970: TimeInterval(offset)),
                createdAt: Date(timeIntervalSince1970: TimeInterval(offset)),
                summary: "Summary \(offset)",
                reflection: "Reflection \(offset)",
                digest: "Theme \(offset)"
            )
        }

        let batches = OverallInsightPlanner.batches(from: snapshots)

        #expect(batches.map(\.count) == [3, 2])
        #expect(batches.flatMap { $0 }.map(\.sourceJournalDate) == snapshots.reversed().map(\.sourceJournalDate))
    }
}

@Suite("Reflection perspective")
struct ReflectionPerspectiveTests {
    @Test("Second-person reflection is accepted")
    func acceptsSecondPerson() {
        #expect(!ReflectionPerspective.usesFirstPerson("You may be noticing what this connection means to you."))
    }

    @Test("First-person reflection is rejected")
    func rejectsFirstPerson() {
        #expect(ReflectionPerspective.usesFirstPerson("I enjoyed the date and I am looking forward to another one."))
        #expect(ReflectionPerspective.usesFirstPerson("This made me reconsider my expectations."))
    }
}

@Suite("Overall insight quality")
struct OverallInsightQualityTests {
    @Test("Patterns cannot repeat the overview")
    func rejectsRepeatedOverview() {
        #expect(OverallInsightQuality.needsRevision(
            overview: "You are exploring changing romantic connections.",
            patterns: ["You are exploring changing romantic connections."],
            recentFocus: "You had dinner with Alisa.",
            previousRecentFocus: nil
        ))
    }

    @Test("Patterns must remain concise")
    func rejectsParagraphPattern() {
        #expect(OverallInsightQuality.needsRevision(
            overview: "Your recent entries describe two different connections.",
            patterns: ["You repeatedly write long narrative paragraphs that describe every event instead of naming one recurring pattern across dated insights."],
            recentFocus: "You had dinner with Alisa.",
            previousRecentFocus: nil
        ))
    }

    @Test("Recent focus must change when new evidence arrives")
    func rejectsUnchangedRecentFocus() {
        #expect(OverallInsightQuality.needsRevision(
            overview: "Your recent entries describe two different connections.",
            patterns: ["Seeking closeness"],
            recentFocus: "You went to the cinema with Grand Cheval.",
            previousRecentFocus: "You went to the cinema with Grand Cheval."
        ))
    }

    @Test("Distinct fields with a new focus are accepted")
    func acceptsDistinctUpdatedOutput() {
        #expect(!OverallInsightQuality.needsRevision(
            overview: "Your recent entries show your attention moving between two connections.",
            patterns: ["Attraction and uncertainty", "Seeking closeness"],
            recentFocus: "You had dinner with Alisa and wondered whether it was a date.",
            previousRecentFocus: "You went to the cinema with Grand Cheval."
        ))
    }
}
