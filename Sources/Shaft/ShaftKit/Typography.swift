extension TextStyle {
    /// A font with the large title text style.
    public static var largeTitle: TextStyle {
        TextStyle(
            fontSize: 26,
            fontWeight: .w400,
            letterSpacing: 0.22
        )
    }

    /// A font with the title text style.
    public static var title: TextStyle {
        TextStyle(
            fontSize: 22,
            fontWeight: .w400,
            letterSpacing: -0.26
        )
    }

    /// Create a font for second level hierarchical headings.
    public static var title2: TextStyle {
        TextStyle(
            fontSize: 17,
            fontWeight: .w400,
            letterSpacing: -0.43
        )
    }

    /// Create a font for third level hierarchical headings.
    public static var title3: TextStyle {
        TextStyle(
            fontSize: 15,
            fontWeight: .w400,
            letterSpacing: -0.23
        )
    }

    /// A font with the headline text style.
    public static var headline: TextStyle {
        TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.08
        )
    }

    /// A font with the subheadline text style.
    public static var body: TextStyle {
        TextStyle(
            fontSize: 13,
            fontWeight: .w400,
            letterSpacing: 0.06
        )
    }

    /// A font with the body text style.
    public static var callout: TextStyle {
        TextStyle(
            fontSize: 12,
            fontWeight: .w400
        )
    }

    /// A font with the callout text style.
    public static var subheadline: TextStyle {
        TextStyle(
            fontSize: 11,
            fontWeight: .w400,
            letterSpacing: 0.06
        )
    }

    /// A font with the footnote text style.
    public static var footnote: TextStyle {
        TextStyle(
            fontSize: 10,
            fontWeight: .w400,
            letterSpacing: 0.12
        )
    }

    /// A font with the caption text style.
    public static var caption1: TextStyle {
        TextStyle(
            fontSize: 10,
            fontWeight: .w400,
            letterSpacing: 0.12
        )
    }

    /// Create a font with the alternate caption text style.
    public static var caption2: TextStyle {
        TextStyle(
            fontSize: 10,
            fontWeight: .w500,  // w510
            letterSpacing: 0.12
        )
    }
}
