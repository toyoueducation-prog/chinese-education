//
//  Chinese_EducationTests.swift
//  Chinese EducationTests
//
//  Created by J Ko on 4/2/2025.
//

import XCTest
@testable import Chinese_Education

final class Chinese_EducationTests: XCTestCase {

    func testPIRLSClassifierRetrieving() {
        let passage = "文章說明春天很溫暖，花會開。"
        let q = "文章中提到，春天有什麼特徵？"
        let answer = "A. 溫暖且花會開"
        let (process, confidence) = PIRLSQuestionClassifier.classifyQuestionEnhanced(q, passageText: passage, answer: answer)
        XCTAssertEqual(process, .retrieving)
        XCTAssertGreaterThan(confidence, 0.2)
    }

    func testPIRLSClassifierEvaluatingLeansEvaluatingOrInterpreting() {
        let passage = "故事中的小華決定幫助同學。"
        let q = "你認為小華這樣做對嗎？為什麼？"
        let answer = "B. 對，因為能建立友誼"
        let (process, _) = PIRLSQuestionClassifier.classifyQuestionEnhanced(q, passageText: passage, answer: answer)
        XCTAssertTrue([.evaluating, .interpreting].contains(process), "Unexpected process: \(process)")
    }

    func testQuestionBankCoverageReport() {
        let report = QuestionBank.shared.buildCoverageReport()
        XCTAssertEqual(report.totalQuestions, 36)
        XCTAssertEqual(report.passageCount, 9)
        XCTAssertEqual(report.pirlsCounts.values.reduce(0, +), 36)
        for p in PIRLSProcess.allCases {
            XCTAssertGreaterThanOrEqual(report.pirlsCounts[p] ?? 0, 1, "Expected at least one question per PIRLS process: \(p)")
        }
    }

    func testVocabularyMasteryProgression() {
        var word = VocabularyWord(word: "測試")
        word.encounters = 5
        word.correctUses = 4
        word.updateMastery()
        XCTAssertGreaterThanOrEqual(word.masteryLevel, 3)
    }

    func testQuestionBankPassageKeyLookup() {
        let p = QuestionBank.shared.getPassageForQuestion("q1") ?? ""
        XCTAssertEqual(QuestionBank.shared.passageKey(matchingPassageText: p), "passage1")
    }
}
