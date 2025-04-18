// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import Shaft

/// Splits text into a list of `TextFragment`s.
///
/// Various implementations can perform the fragmenting based on their own criteria.
///
/// See:
///
/// - `LineBreakFragmenter`: Fragments text based on line break opportunities.
/// - `BidiFragmenter`: Fragments text based on directionality.
protocol TextFragmenter {
    associatedtype FragmentType: TextFragment

    /// The text to be fragmented.
    var text: String { get }

    /// Performs the fragmenting of text and returns a list of `TextFragment`s.
    func fragment() -> [FragmentType]
}

/// Represents a fragment produced by `TextFragmenter`.
protocol TextFragment {
    /// The start index of the fragment.
    var start: TextIndex { get }

    /// The end index of the fragment.
    var end: TextIndex { get }

    /// Whether this fragment's range overlaps with the range from `start` to `end`.
    func overlapsWith(start: TextIndex, end: TextIndex) -> Bool
}

extension TextFragment {
    func overlapsWith(start: TextIndex, end: TextIndex) -> Bool {
        return start < self.end && self.start < end
    }
}
