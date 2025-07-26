import XCTest

@testable import Shaft

final class LocaleTests: XCTestCase {

    func testBasicLocaleListResolution_NilPreferredLocales() {
        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("es", countryCode: "ES"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(nil, supportedLocales)

        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "US")
    }

    func testBasicLocaleListResolution_EmptyPreferredLocales() {
        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("es", countryCode: "ES"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution([], supportedLocales)

        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "US")
    }

    func testBasicLocaleListResolution_PerfectMatch() {
        let preferredLocales = [
            Shaft.Locale("fr", countryCode: "FR"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("fr", countryCode: "FR"),
            Shaft.Locale("es", countryCode: "ES"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        XCTAssertEqual(result.languageCode, "fr")
        XCTAssertEqual(result.countryCode, "FR")
    }

    func testBasicLocaleListResolution_LanguageAndScriptMatch() {
        let preferredLocales = [
            Shaft.Locale(languageCode: "zh", scriptCode: "Hans", countryCode: "CN"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale(languageCode: "zh", scriptCode: "Hans", countryCode: "TW"),
            Shaft.Locale(languageCode: "zh", scriptCode: "Hant", countryCode: "TW"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        XCTAssertEqual(result.languageCode, "zh")
        XCTAssertEqual(result.scriptCode, "Hans")
        XCTAssertEqual(result.countryCode, "TW")
    }

    func testBasicLocaleListResolution_LanguageAndCountryMatch() {
        let preferredLocales = [
            Shaft.Locale("en", countryCode: "GB"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("en", countryCode: "GB"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "GB")
    }

    func testBasicLocaleListResolution_LanguageOnlyMatch() {
        let preferredLocales = [
            Shaft.Locale("de", countryCode: "DE"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("de", countryCode: "AT"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        XCTAssertEqual(result.languageCode, "de")
        XCTAssertEqual(result.countryCode, "AT")
    }

    func testBasicLocaleListResolution_LanguageOnlyMatchFirstPreferred() {
        let preferredLocales = [
            Shaft.Locale("de", countryCode: "DE"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let supportedLocales = [
            Shaft.Locale("de", countryCode: "AT"),
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should return language-only match immediately for first preferred locale
        XCTAssertEqual(result.languageCode, "de")
        XCTAssertEqual(result.countryCode, "AT")
    }

    func testBasicLocaleListResolution_LanguageOnlyMatchDeferred() {
        let preferredLocales = [
            Shaft.Locale("de", countryCode: "DE"),
            Shaft.Locale("de", countryCode: "AT"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let supportedLocales = [
            Shaft.Locale("de", countryCode: "AT"),
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should defer language-only match when next preferred locale has same language
        XCTAssertEqual(result.languageCode, "de")
        XCTAssertEqual(result.countryCode, "AT")
    }

    func testBasicLocaleListResolution_CountryOnlyMatch() {
        let preferredLocales = [
            Shaft.Locale("xx", countryCode: "US"),  // Unsupported language
            Shaft.Locale("yy", countryCode: "FR"),  // Another unsupported language
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("fr", countryCode: "FR"),
            Shaft.Locale("es", countryCode: "ES"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should fall back to country-only match
        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "US")
    }

    func testBasicLocaleListResolution_NoMatchFallback() {
        let preferredLocales = [
            Shaft.Locale("xx", countryCode: "ZZ"),  // Completely unsupported
            Shaft.Locale("yy", countryCode: "YY"),  // Also unsupported
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("fr", countryCode: "FR"),
            Shaft.Locale("es", countryCode: "ES"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should return first supported locale as fallback
        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "US")
    }

    func testBasicLocaleListResolution_PriorityOrder() {
        let preferredLocales = [
            Shaft.Locale("en", countryCode: "GB"),
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("en", countryCode: "GB"),  // Perfect match for first preferred
            Shaft.Locale("fr", countryCode: "FR"),  // Perfect match for second preferred
            Shaft.Locale("es", countryCode: "ES"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should return perfect match for first preferred locale
        XCTAssertEqual(result.languageCode, "en")
        XCTAssertEqual(result.countryCode, "GB")
    }

    func testBasicLocaleListResolution_ScriptCodeHandling() {
        let preferredLocales = [
            Shaft.Locale(languageCode: "zh", scriptCode: "Hant", countryCode: "TW"),
            Shaft.Locale(languageCode: "zh", scriptCode: "Hans", countryCode: "CN"),
        ]

        let supportedLocales = [
            Shaft.Locale(languageCode: "zh", scriptCode: "Hans", countryCode: "CN"),
            Shaft.Locale(languageCode: "zh", scriptCode: "Hant", countryCode: "HK"),
            Shaft.Locale("en", countryCode: "US"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should match language+script even if country differs
        XCTAssertEqual(result.languageCode, "zh")
        XCTAssertEqual(result.scriptCode, "Hant")
        XCTAssertEqual(result.countryCode, "HK")
    }

    func testBasicLocaleListResolution_NullValuesInKeys() {
        let preferredLocales = [
            Shaft.Locale("en"),  // No country code
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let supportedLocales = [
            Shaft.Locale("en", countryCode: "US"),
            Shaft.Locale("en"),  // No country code
            Shaft.Locale("fr", countryCode: "FR"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should handle null values in keys properly
        XCTAssertEqual(result.languageCode, "en")
        XCTAssertNil(result.countryCode)
    }

    func testBasicLocaleListResolution_DeprecatedLanguageCodes() {
        // Test that deprecated language codes are handled correctly
        let preferredLocales = [
            Shaft.Locale("iw", countryCode: "IL"),  // Hebrew (deprecated)
            Shaft.Locale("in", countryCode: "ID"),  // Indonesian (deprecated)
        ]

        let supportedLocales = [
            Shaft.Locale("he", countryCode: "IL"),  // Hebrew (current)
            Shaft.Locale("id", countryCode: "ID"),  // Indonesian (current)
            Shaft.Locale("en", countryCode: "US"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should match the current language codes
        XCTAssertEqual(result.languageCode, "he")
        XCTAssertEqual(result.countryCode, "IL")
    }

    func testBasicLocaleListResolution_DeprecatedRegionCodes() {
        // Test that deprecated region codes are handled correctly
        let preferredLocales = [
            Shaft.Locale("de", countryCode: "DD"),  // East Germany (deprecated)
            Shaft.Locale("fr", countryCode: "FX"),  // Metropolitan France (deprecated)
        ]

        let supportedLocales = [
            Shaft.Locale("de", countryCode: "DE"),  // Germany (current)
            Shaft.Locale("fr", countryCode: "FR"),  // France (current)
            Shaft.Locale("en", countryCode: "US"),
        ]

        let result = basicLocaleListResolution(preferredLocales, supportedLocales)

        // Should match the current region codes
        XCTAssertEqual(result.languageCode, "de")
        XCTAssertEqual(result.countryCode, "DE")
    }
}
