import Foundation
import SwiftUI
import Testing
@testable import StableBar

private func block(_ json: String) throws -> PopupBlock {
    try JSONDecoder().decode(PopupBlock.self, from: Data(json.utf8))
}

private func symbolEffect(_ json: String) throws -> StableBar.SymbolEffectConfiguration {
    try JSONDecoder().decode(StableBar.SymbolEffectConfiguration.self, from: Data(json.utf8))
}

private func errorMessage(_ error: (any Error)?, for key: String) -> String? {
    guard let error, case let DecodingError.dataCorruptedError(context) = error else { return nil }
    return context.codingPath.last?.stringValue == key ? context.debugDescription : nil
}

@Test func symbolEffectDecodesOnASymbolBlock() throws {
    let configuration = try block(#"{"type":"symbol","name":"lock.rotation","symbolEffect":{"effect":"rotate","variant":"clockwise","repeat":"continuous","speed":2}}"#)
    let effect = try #require(configuration.symbolEffect)
    #expect(effect.effect == .rotate)
    #expect(effect.variant == "clockwise")
    #expect(effect.speed == 2)
    if case .continuous = effect.repeatBehavior {} else { Issue.record("expected continuous repeat") }
}

@Test func symbolEffectDefaultsToContinuousWithoutAValueSource() throws {
    let effect = try symbolEffect(#"{"effect":"pulse"}"#)
    if case .continuous = effect.repeatBehavior {} else { Issue.record("expected continuous repeat") }
    #expect(effect.activeSource == nil)
    #expect(effect.valueSource == nil)
}

@Test func symbolEffectWithAValueSourceStopsRepeating() throws {
    let effect = try symbolEffect(#"{"effect":"bounce","valueSource":"step"}"#)
    #expect(effect.valueSource == "step")
    if case .none = effect.repeatBehavior {} else { Issue.record("expected no repeat") }
}

@Test func symbolEffectRejectsUnsupportedVariant() throws {
    let error = #expect(throws: (any Error).self) { try symbolEffect(#"{"effect":"rotate","variant":"left"}"#) }
    #expect(errorMessage(error, for: "variant") == "The variant is not supported by this symbol effect.")
}

@Test func indefiniteEffectsRunWithoutAValueSource() throws {
    let effect = try symbolEffect(#"{"effect":"variableColor","repeat":3}"#)
    #expect(effect.effect == .variableColor)
    if case let .count(times) = effect.repeatBehavior, times == 3 {} else { Issue.record("expected repeat count 3") }
}

@Test func appearAndDisappearEffectRunIndefinitelyWithoutAValueSource() throws {
    let appear = try symbolEffect(#"{"effect":"appear"}"#)
    #expect(appear.effect == .appear)
    if case .continuous = appear.repeatBehavior {} else { Issue.record("expected continuous repeat") }
    let disappear = try symbolEffect(#"{"effect":"disappear","variant":"down"}"#)
    #expect(disappear.effect == .disappear)
    #expect(disappear.variant == "down")
}

@Test func symbolEffectRejectsValueSourceOnEffectsThatCannotRunDiscretely() throws {
    let error = #expect(throws: (any Error).self) { try symbolEffect(#"{"effect":"scale","valueSource":"step"}"#) }
    #expect(errorMessage(error, for: "valueSource") == "This symbol effect cannot be triggered by a changing value.")
}

@Test func symbolEffectRejectsUnknownKeys() throws {
    #expect(throws: (any Error).self) { try symbolEffect(#"{"effect":"scale","duration":1}"#) }
}

@Test func symbolEffectAppliesOnlyToSymbolBlocks() throws {
    let error = #expect(throws: (any Error).self) { try block(#"{"type":"text","text":"A","symbolEffect":{"effect":"scale"}}"#) }
    #expect(errorMessage(error, for: "symbolEffect") == "Symbol effects and symbol transitions apply only to symbol blocks.")
}

@Test func symbolTransitionAppliesOnlyToSymbolBlocks() throws {
    let error = #expect(throws: (any Error).self) { try block(#"{"type":"field","field":"text","symbolTransition":"replace"}"#) }
    #expect(errorMessage(error, for: "symbolTransition") == "Symbol effects and symbol transitions apply only to symbol blocks.")
}

@Test func symbolEffectAlignmentContentTransition() {
    #expect(SymbolContentTransition.replace.value == ContentTransition.symbolEffect(.replace))
    #expect(SymbolContentTransition.automatic.value == ContentTransition.symbolEffect(.automatic))
    #expect(SymbolContentTransition.downUp.value == ContentTransition.symbolEffect(.replace.downUp))
    #expect(SymbolContentTransition.upUp.value == ContentTransition.symbolEffect(.replace.upUp))
    #expect(SymbolContentTransition.offUp.value == ContentTransition.symbolEffect(.replace.offUp))
}
