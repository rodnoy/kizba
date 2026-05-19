import Foundation
import XCTest
@testable import Kizba

/// MVP9.2 — pins down `AddTOTPSheet.buildSecret(...)`: the pure
/// (no-SwiftUI) submission pipeline that the four input methods
/// share. The UI calls this directly; tests exercise every branch
/// without instantiating the view.
final class AddTOTPSheetBuildSecretTests: XCTestCase {

    // MARK: - generateRandom

    func testGenerateRandom_returnsValidSecret_withIssuerAndLabel() throws {
        let result = AddTOTPSheet.buildSecret(
            method: .generateRandom,
            issuer: "Acme",
            label: "alice",
            passphrase: "",
            pastedURI: "",
            typedSecret: ""
        )
        let secret = try unwrapSuccess(result)
        XCTAssertEqual(secret.issuer, "Acme")
        XCTAssertEqual(secret.label, "alice")
        XCTAssertNotNil(Base32.decode(secret.secretBase32))
    }

    func testGenerateRandom_ignoresOtherFields() throws {
        // The random branch must not read passphrase/URI/secret; if
        // it did, this test would surface as a behavioural change.
        let result = AddTOTPSheet.buildSecret(
            method: .generateRandom,
            issuer: nil,
            label: nil,
            passphrase: "irrelevant",
            pastedURI: "irrelevant",
            typedSecret: "irrelevant"
        )
        let secret = try unwrapSuccess(result)
        XCTAssertEqual(Base32.decode(secret.secretBase32)?.count, 20)
    }

    // MARK: - passphrase

    func testPassphrase_emptyInput_returnsEmptyPassphraseError() {
        let result = AddTOTPSheet.buildSecret(
            method: .passphrase,
            issuer: nil,
            label: nil,
            passphrase: "",
            pastedURI: "",
            typedSecret: ""
        )
        XCTAssertEqual(unwrapFailure(result), .emptyPassphrase)
    }

    func testPassphrase_nonEmpty_isDeterministic() throws {
        let first = try unwrapSuccess(
            AddTOTPSheet.buildSecret(
                method: .passphrase,
                issuer: "Acme",
                label: "alice",
                passphrase: "correct horse battery staple",
                pastedURI: "",
                typedSecret: ""
            )
        )
        let second = try unwrapSuccess(
            AddTOTPSheet.buildSecret(
                method: .passphrase,
                issuer: "Acme",
                label: "alice",
                passphrase: "correct horse battery staple",
                pastedURI: "",
                typedSecret: ""
            )
        )
        XCTAssertEqual(first.secretBase32, second.secretBase32)
    }

    // MARK: - pasteURI

    func testPasteURI_validURI_parses() throws {
        let uri = "otpauth://totp/ExampleCo:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ExampleCo"
        let result = AddTOTPSheet.buildSecret(
            method: .pasteURI,
            issuer: nil,
            label: nil,
            passphrase: "",
            pastedURI: uri,
            typedSecret: ""
        )
        let secret = try unwrapSuccess(result)
        XCTAssertEqual(secret.secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(secret.issuer, "ExampleCo")
        XCTAssertEqual(secret.label, "alice@example.com")
    }

    func testPasteURI_invalidScheme_returnsInvalidURIError() {
        let result = AddTOTPSheet.buildSecret(
            method: .pasteURI,
            issuer: nil,
            label: nil,
            passphrase: "",
            pastedURI: "https://example.com/?secret=ABC",
            typedSecret: ""
        )
        guard case .invalidURI = unwrapFailure(result) else {
            XCTFail("expected .invalidURI; got \(String(describing: unwrapFailure(result)))")
            return
        }
    }

    func testPasteURI_issuerOverride_winsOverEmbeddedIssuer() throws {
        let uri = "otpauth://totp/ExampleCo:alice?secret=JBSWY3DPEHPK3PXP&issuer=ExampleCo"
        let result = AddTOTPSheet.buildSecret(
            method: .pasteURI,
            issuer: "Override",
            label: "newlabel",
            passphrase: "",
            pastedURI: uri,
            typedSecret: ""
        )
        let secret = try unwrapSuccess(result)
        XCTAssertEqual(secret.issuer, "Override")
        XCTAssertEqual(secret.label, "newlabel")
        // Secret material must be preserved unchanged.
        XCTAssertEqual(secret.secretBase32, "JBSWY3DPEHPK3PXP")
    }

    // MARK: - typeSecret

    func testTypeSecret_validBase32_succeeds() throws {
        let result = AddTOTPSheet.buildSecret(
            method: .typeSecret,
            issuer: "Acme",
            label: "alice",
            passphrase: "",
            pastedURI: "",
            typedSecret: "jbswy3dpehpk3pxp"
        )
        let secret = try unwrapSuccess(result)
        XCTAssertEqual(secret.secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(secret.issuer, "Acme")
        XCTAssertEqual(secret.label, "alice")
    }

    func testTypeSecret_invalidCharacters_returnsInvalidBase32Error() {
        let result = AddTOTPSheet.buildSecret(
            method: .typeSecret,
            issuer: nil,
            label: nil,
            passphrase: "",
            pastedURI: "",
            typedSecret: "JBSW!Y3DP"
        )
        XCTAssertEqual(unwrapFailure(result), .invalidBase32)
    }

    func testTypeSecret_empty_returnsInvalidBase32Error() {
        let result = AddTOTPSheet.buildSecret(
            method: .typeSecret,
            issuer: nil,
            label: nil,
            passphrase: "",
            pastedURI: "",
            typedSecret: ""
        )
        XCTAssertEqual(unwrapFailure(result), .invalidBase32)
    }

    // MARK: - Error message contracts

    func testErrorMessages_areUserFacing() {
        XCTAssertFalse(AddTOTPSheet.SubmissionError.emptyPassphrase.message.isEmpty)
        XCTAssertFalse(AddTOTPSheet.SubmissionError.invalidBase32.message.isEmpty)
        XCTAssertFalse(AddTOTPSheet.SubmissionError.invalidURI("detail").message.isEmpty)
    }

    // MARK: - Helpers

    private func unwrapSuccess(
        _ result: Result<OTPSecret, AddTOTPSheet.SubmissionError>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> OTPSecret {
        switch result {
        case .success(let secret): return secret
        case .failure(let error):
            XCTFail("expected success; got failure: \(error)", file: file, line: line)
            throw error
        }
    }

    private func unwrapFailure(
        _ result: Result<OTPSecret, AddTOTPSheet.SubmissionError>
    ) -> AddTOTPSheet.SubmissionError? {
        if case .failure(let error) = result { return error }
        return nil
    }
}
