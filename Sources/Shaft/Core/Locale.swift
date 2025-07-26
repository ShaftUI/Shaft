/// An identifier used to select a user's language and formatting preferences.
///
/// This represents a [Unicode Language
/// Identifier](https://www.unicode.org/reports/tr35/#Unicode_language_identifier)
/// (i.e. without Locale extensions), except variants are not supported.
///
/// Locales are canonicalized according to the "preferred value" entries in the
/// [IANA Language Subtag
/// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).
/// For example, `const Locale('he')` and `const Locale('iw')` are equal and
/// both have the [languageCode] `he`, because `iw` is a deprecated language
/// subtag that was replaced by the subtag `he`.
///
/// See also:
///
///  * [PlatformDispatcher.locale], which specifies the system's currently selected
///    [Locale].
public struct Locale: Equatable, Hashable {
    /// Creates a new Locale object. The first argument is the
    /// primary language subtag, the second is the region (also
    /// referred to as 'country') subtag.
    ///
    /// For example:
    ///
    /// ```dart
    /// const Locale swissFrench = Locale('fr', 'CH');
    /// const Locale canadianFrench = Locale('fr', 'CA');
    /// ```
    ///
    /// The primary language subtag must not be null. The region subtag is
    /// optional. When there is no region/country subtag, the parameter should
    /// be omitted or passed `null` instead of an empty-string.
    ///
    /// The subtag values are _case sensitive_ and must be one of the valid
    /// subtags according to CLDR supplemental data:
    /// [language](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml),
    /// [region](https://github.com/unicode-org/cldr/blob/master/common/validity/region.xml). The
    /// primary language subtag must be at least two and at most eight lowercase
    /// letters, but not four letters. The region subtag must be two
    /// uppercase letters or three digits. See the [Unicode Language
    /// Identifier](https://www.unicode.org/reports/tr35/#Unicode_language_identifier)
    /// specification.
    ///
    /// Validity is not checked by default, but some methods may throw away
    /// invalid data.
    ///
    /// See also:
    ///
    ///  * [Locale.fromSubtags], which also allows a [scriptCode] to be
    ///    specified.
    public init(
        _ languageCode: String,
        countryCode: String? = nil
    ) {
        assert(!languageCode.isEmpty)
        self._languageCode = languageCode
        self._countryCode = countryCode
        self.scriptCode = nil
    }

    /// Creates a new Locale object.
    ///
    /// The keyword arguments specify the subtags of the Locale.
    ///
    /// The subtag values are _case sensitive_ and must be valid subtags according
    /// to CLDR supplemental data:
    /// [language](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml),
    /// [script](https://github.com/unicode-org/cldr/blob/master/common/validity/script.xml) and
    /// [region](https://github.com/unicode-org/cldr/blob/master/common/validity/region.xml) for
    /// each of languageCode, scriptCode and countryCode respectively.
    ///
    /// The [languageCode] subtag is optional. When there is no language subtag,
    /// the parameter should be omitted or set to "und". When not supplied, the
    /// [languageCode] defaults to "und", an undefined language code.
    ///
    /// The [countryCode] subtag is optional. When there is no country subtag,
    /// the parameter should be omitted or passed `null` instead of an empty-string.
    ///
    /// Validity is not checked by default, but some methods may throw away
    /// invalid data.
    public init(
        languageCode: String = "und",
        scriptCode: String? = nil,
        countryCode: String? = nil
    ) {
        assert(!languageCode.isEmpty)
        assert(scriptCode == nil || !scriptCode!.isEmpty)
        assert(countryCode == nil || !countryCode!.isEmpty)
        self._languageCode = languageCode
        self.scriptCode = scriptCode
        self._countryCode = countryCode
    }

    /// The primary language subtag for the locale.
    ///
    /// This must not be null. It may be 'und', representing 'undefined'.
    ///
    /// This is expected to be string registered in the [IANA Language Subtag
    /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
    /// with the type "language". The string specified must match the case of the
    /// string in the registry.
    ///
    /// Language subtags that are deprecated in the registry and have a preferred
    /// code are changed to their preferred code. For example, `const
    /// Locale('he')` and `const Locale('iw')` are equal, and both have the
    /// [languageCode] `he`, because `iw` is a deprecated language subtag that was
    /// replaced by the subtag `he`.
    ///
    /// This must be a valid Unicode Language subtag as listed in [Unicode CLDR
    /// supplemental
    /// data](https://github.com/unicode-org/cldr/blob/master/common/validity/language.xml).
    ///
    /// See also:
    ///
    ///  * [Locale.fromSubtags], which describes the conventions for creating
    ///    [Locale] objects.
    public var languageCode: String {
        return Self._deprecatedLanguageSubtagMap[_languageCode] ?? _languageCode
    }

    private let _languageCode: String

    // This map is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2019-02-27.
    private static let _deprecatedLanguageSubtagMap: [String: String] = [
        "in": "id",  // Indonesian; deprecated 1989-01-01
        "iw": "he",  // Hebrew; deprecated 1989-01-01
        "ji": "yi",  // Yiddish; deprecated 1989-01-01
        "jw": "jv",  // Javanese; deprecated 2001-08-13
        "mo": "ro",  // Moldavian, Moldovan; deprecated 2008-11-22
        "aam": "aas",  // Aramanik; deprecated 2015-02-12
        "adp": "dz",  // Adap; deprecated 2015-02-12
        "aue": "ktz",  // ǂKxʼauǁʼein; deprecated 2015-02-12
        "ayx": "nun",  // Ayi (China); deprecated 2011-08-16
        "bgm": "bcg",  // Baga Mboteni; deprecated 2016-05-30
        "bjd": "drl",  // Bandjigali; deprecated 2012-08-12
        "ccq": "rki",  // Chaungtha; deprecated 2012-08-12
        "cjr": "mom",  // Chorotega; deprecated 2010-03-11
        "cka": "cmr",  // Khumi Awa Chin; deprecated 2012-08-12
        "cmk": "xch",  // Chimakum; deprecated 2010-03-11
        "coy": "pij",  // Coyaima; deprecated 2016-05-30
        "cqu": "quh",  // Chilean Quechua; deprecated 2016-05-30
        "drh": "khk",  // Darkhat; deprecated 2010-03-11
        "drw": "prs",  // Darwazi; deprecated 2010-03-11
        "gav": "dev",  // Gabutamon; deprecated 2010-03-11
        "gfx": "vaj",  // Mangetti Dune ǃXung; deprecated 2015-02-12
        "ggn": "gvr",  // Eastern Gurung; deprecated 2016-05-30
        "gti": "nyc",  // Gbati-ri; deprecated 2015-02-12
        "guv": "duz",  // Gey; deprecated 2016-05-30
        "hrr": "jal",  // Horuru; deprecated 2012-08-12
        "ibi": "opa",  // Ibilo; deprecated 2012-08-12
        "ilw": "gal",  // Talur; deprecated 2013-09-10
        "jeg": "oyb",  // Jeng; deprecated 2017-02-23
        "kgc": "tdf",  // Kasseng; deprecated 2016-05-30
        "kgh": "kml",  // Upper Tanudan Kalinga; deprecated 2012-08-12
        "koj": "kwv",  // Sara Dunjo; deprecated 2015-02-12
        "krm": "bmf",  // Krim; deprecated 2017-02-23
        "ktr": "dtp",  // Kota Marudu Tinagas; deprecated 2016-05-30
        "kvs": "gdj",  // Kunggara; deprecated 2016-05-30
        "kwq": "yam",  // Kwak; deprecated 2015-02-12
        "kxe": "tvd",  // Kakihum; deprecated 2015-02-12
        "kzj": "dtp",  // Coastal Kadazan; deprecated 2016-05-30
        "kzt": "dtp",  // Tambunan Dusun; deprecated 2016-05-30
        "lii": "raq",  // Lingkhim; deprecated 2015-02-12
        "lmm": "rmx",  // Lamam; deprecated 2014-02-28
        "meg": "cir",  // Mea; deprecated 2013-09-10
        "mst": "mry",  // Cataelano Mandaya; deprecated 2010-03-11
        "mwj": "vaj",  // Maligo; deprecated 2015-02-12
        "myt": "mry",  // Sangab Mandaya; deprecated 2010-03-11
        "nad": "xny",  // Nijadali; deprecated 2016-05-30
        "ncp": "kdz",  // Ndaktup; deprecated 2018-03-08
        "nnx": "ngv",  // Ngong; deprecated 2015-02-12
        "nts": "pij",  // Natagaimas; deprecated 2016-05-30
        "oun": "vaj",  // ǃOǃung; deprecated 2015-02-12
        "pcr": "adx",  // Panang; deprecated 2013-09-10
        "pmc": "huw",  // Palumata; deprecated 2016-05-30
        "pmu": "phr",  // Mirpur Panjabi; deprecated 2015-02-12
        "ppa": "bfy",  // Pao; deprecated 2016-05-30
        "ppr": "lcq",  // Piru; deprecated 2013-09-10
        "pry": "prt",  // Pray 3; deprecated 2016-05-30
        "puz": "pub",  // Purum Naga; deprecated 2014-02-28
        "sca": "hle",  // Sansu; deprecated 2012-08-12
        "skk": "oyb",  // Sok; deprecated 2017-02-23
        "tdu": "dtp",  // Tempasuk Dusun; deprecated 2016-05-30
        "thc": "tpo",  // Tai Hang Tong; deprecated 2016-05-30
        "thx": "oyb",  // The; deprecated 2015-02-12
        "tie": "ras",  // Tingal; deprecated 2011-08-16
        "tkk": "twm",  // Takpa; deprecated 2011-08-16
        "tlw": "weo",  // South Wemale; deprecated 2012-08-12
        "tmp": "tyj",  // Tai Mène; deprecated 2016-05-30
        "tne": "kak",  // Tinoc Kallahan; deprecated 2016-05-30
        "tnf": "prs",  // Tangshewi; deprecated 2010-03-11
        "tsf": "taj",  // Southwestern Tamang; deprecated 2015-02-12
        "uok": "ema",  // Uokha; deprecated 2015-02-12
        "xba": "cax",  // Kamba (Brazil); deprecated 2016-05-30
        "xia": "acn",  // Xiandao; deprecated 2013-09-10
        "xkh": "waw",  // Karahawyana; deprecated 2016-05-30
        "xsj": "suj",  // Subi; deprecated 2015-02-12
        "ybd": "rki",  // Yangbye; deprecated 2012-08-12
        "yma": "lrr",  // Yamphe; deprecated 2012-08-12
        "ymt": "mtm",  // Mator-Taygi-Karagas; deprecated 2015-02-12
        "yos": "zom",  // Yos; deprecated 2013-09-10
        "yuu": "yug",  // Yugh; deprecated 2014-02-28
    ]

    /// The script subtag for the locale.
    ///
    /// This may be null, indicating that there is no specified script subtag.
    ///
    /// This must be a valid Unicode Language Identifier script subtag as listed
    /// in [Unicode CLDR supplemental
    /// data](https://github.com/unicode-org/cldr/blob/master/common/validity/script.xml).
    ///
    /// See also:
    ///
    ///  * [Locale.fromSubtags], which describes the conventions for creating
    ///    [Locale] objects.
    public let scriptCode: String?

    /// The region subtag for the locale.
    ///
    /// This may be null, indicating that there is no specified region subtag.
    ///
    /// This is expected to be string registered in the [IANA Language Subtag
    /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
    /// with the type "region". The string specified must match the case of the
    /// string in the registry.
    ///
    /// Region subtags that are deprecated in the registry and have a preferred
    /// code are changed to their preferred code. For example, `const Locale('de',
    /// 'DE')` and `const Locale('de', 'DD')` are equal, and both have the
    /// [countryCode] `DE`, because `DD` is a deprecated language subtag that was
    /// replaced by the subtag `DE`.
    ///
    /// See also:
    ///
    ///  * [Locale.fromSubtags], which describes the conventions for creating
    ///    [Locale] objects.
    public var countryCode: String? {
        return Self._deprecatedRegionSubtagMap[_countryCode ?? ""] ?? _countryCode
    }

    private let _countryCode: String?

    // This map is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2019-02-27.
    private static let _deprecatedRegionSubtagMap: [String: String] = [
        "BU": "MM",  // Burma; deprecated 1989-12-05
        "DD": "DE",  // German Democratic Republic; deprecated 1990-10-30
        "FX": "FR",  // Metropolitan France; deprecated 1997-07-14
        "TP": "TL",  // East Timor; deprecated 2002-05-20
        "YD": "YE",  // Democratic Yemen; deprecated 1990-08-14
        "ZR": "CD",  // Zaire; deprecated 1997-07-14
    ]

    private static var _cachedLocale: Locale?
    private static var _cachedLocaleString: String?

    /// Returns a string representing the locale.
    ///
    /// This identifier happens to be a valid Unicode Locale Identifier using
    /// underscores as separator, however it is intended to be used for debugging
    /// purposes only. For parsable results, use [toLanguageTag] instead.
    public var description: String {
        if Self._cachedLocale != self {
            Self._cachedLocale = self
            Self._cachedLocaleString = _rawToString(separator: "_")
        }
        return Self._cachedLocaleString!
    }

    /// Returns a syntactically valid Unicode BCP47 Locale Identifier.
    ///
    /// Some examples of such identifiers: "en", "es-419", "hi-Deva-IN" and
    /// "zh-Hans-CN". See http://www.unicode.org/reports/tr35/ for technical
    /// details.
    public func toLanguageTag() -> String {
        return _rawToString(separator: "-")
    }

    private func _rawToString(separator: String) -> String {
        var out = languageCode
        if let scriptCode = scriptCode, !scriptCode.isEmpty {
            out += "\(separator)\(scriptCode)"
        }
        if let countryCode = _countryCode, !countryCode.isEmpty {
            out += "\(separator)\(countryCode)"
        }
        return out
    }
}

/// The default locale resolution algorithm.
///
/// Custom resolution algorithms can be provided through
/// [WidgetsApp.localeListResolutionCallback] or
/// [WidgetsApp.localeResolutionCallback].
///
/// When no custom locale resolution algorithms are provided or if both fail
/// to resolve, Flutter will default to calling this algorithm.
///
/// This algorithm prioritizes speed at the cost of slightly less appropriate
/// resolutions for edge cases.
///
/// This algorithm will resolve to the earliest preferred locale that
/// matches the most fields, prioritizing in the order of perfect match,
/// languageCode+countryCode, languageCode+scriptCode, languageCode-only.
///
/// In the case where a locale is matched by languageCode-only and is not the
/// default (first) locale, the next preferred locale with a
/// perfect match can supersede the languageCode-only match if it exists.
///
/// When a preferredLocale matches more than one supported locale, it will
/// resolve to the first matching locale listed in the supportedLocales.
///
/// When all preferred locales have been exhausted without a match, the first
/// countryCode only match will be returned.
///
/// When no match at all is found, the first (default) locale in
/// [supportedLocales] will be returned.
///
/// To summarize, the main matching priority is:
///
///  1. [Locale.languageCode], [Locale.scriptCode], and [Locale.countryCode]
///  2. [Locale.languageCode] and [Locale.scriptCode] only
///  3. [Locale.languageCode] and [Locale.countryCode] only
///  4. [Locale.languageCode] only (with caveats, see above)
///  5. [Locale.countryCode] only when all [preferredLocales] fail to match
///  6. Returns the first element of [supportedLocales] as a fallback
///
/// This algorithm does not take language distance (how similar languages are to each other)
/// into account, and will not handle edge cases such as resolving `de` to `fr` rather than `zh`
/// when `de` is not supported and `zh` is listed before `fr` (German is closer to French
/// than Chinese).
public func basicLocaleListResolution(_ preferredLocales: [Locale]?, _ supportedLocales: [Locale])
    -> Locale
{
    // preferredLocales can be null when called before the platform has had a chance to
    // initialize the locales. Platforms without locale passing support will provide an empty list.
    // We default to the first supported locale in these cases.
    if preferredLocales == nil || preferredLocales!.isEmpty {
        return supportedLocales.first!
    }

    // Hash the supported locales because apps can support many locales and would
    // be expensive to search through them many times.
    var allSupportedLocales: [String: Locale] = [:]
    var languageAndCountryLocales: [String: Locale] = [:]
    var languageAndScriptLocales: [String: Locale] = [:]
    var languageLocales: [String: Locale] = [:]
    var countryLocales: [String?: Locale] = [:]

    for locale in supportedLocales {
        let key = "\(locale.languageCode)_\(locale.scriptCode ?? "")_\(locale.countryCode ?? "")"
        if allSupportedLocales[key] == nil {
            allSupportedLocales[key] = locale
        }

        let scriptKey = "\(locale.languageCode)_\(locale.scriptCode ?? "")"
        if languageAndScriptLocales[scriptKey] == nil {
            languageAndScriptLocales[scriptKey] = locale
        }

        let countryKey = "\(locale.languageCode)_\(locale.countryCode ?? "")"
        if languageAndCountryLocales[countryKey] == nil {
            languageAndCountryLocales[countryKey] = locale
        }

        if languageLocales[locale.languageCode] == nil {
            languageLocales[locale.languageCode] = locale
        }

        if countryLocales[locale.countryCode] == nil {
            countryLocales[locale.countryCode] = locale
        }
    }

    // Since languageCode-only matches are possibly low quality, we don't return
    // it instantly when we find such a match. We check to see if the next
    // preferred locale in the list has a high accuracy match, and only return
    // the languageCode-only match when a higher accuracy match in the next
    // preferred locale cannot be found.
    var matchesLanguageCode: Locale?
    var matchesCountryCode: Locale?

    // Loop over user's preferred locales
    for (localeIndex, userLocale) in preferredLocales!.enumerated() {
        // Look for perfect match.
        let perfectKey =
            "\(userLocale.languageCode)_\(userLocale.scriptCode ?? "")_\(userLocale.countryCode ?? "")"
        if allSupportedLocales[perfectKey] != nil {
            return userLocale
        }

        // Look for language+script match.
        if userLocale.scriptCode != nil {
            let scriptKey = "\(userLocale.languageCode)_\(userLocale.scriptCode!)"
            if let match = languageAndScriptLocales[scriptKey] {
                return match
            }
        }

        // Look for language+country match.
        if userLocale.countryCode != nil {
            let countryKey = "\(userLocale.languageCode)_\(userLocale.countryCode!)"
            if let match = languageAndCountryLocales[countryKey] {
                return match
            }
        }

        // If there was a languageCode-only match in the previous iteration's higher
        // ranked preferred locale, we return it if the current userLocale does not
        // have a better match.
        if matchesLanguageCode != nil {
            return matchesLanguageCode!
        }

        // Look and store language-only match.
        if let match = languageLocales[userLocale.languageCode] {
            matchesLanguageCode = match
            // Since first (default) locale is usually highly preferred, we will allow
            // a languageCode-only match to be instantly matched. If the next preferred
            // languageCode is the same, we defer hastily returning until the next iteration
            // since at worst it is the same and at best an improved match.
            if localeIndex == 0
                && !(localeIndex + 1 < preferredLocales!.count
                    && preferredLocales![localeIndex + 1].languageCode == userLocale.languageCode)
            {
                return matchesLanguageCode!
            }
        }

        // countryCode-only match. When all else except default supported locale fails,
        // attempt to match by country only, as a user is likely to be familiar with a
        // language from their listed country.
        if matchesCountryCode == nil && userLocale.countryCode != nil {
            if let match = countryLocales[userLocale.countryCode] {
                matchesCountryCode = match
            }
        }
    }

    // When there is no languageCode-only match. Fallback to matching countryCode only. Country
    // fallback only applies on iOS. When there is no countryCode-only match, we return first
    // supported locale.
    let resolvedLocale = matchesLanguageCode ?? matchesCountryCode ?? supportedLocales.first!
    return resolvedLocale
}
