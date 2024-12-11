// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The type of callback that [TapRegion.onTapOutside] and
/// [TapRegion.onTapInside] take.
///
/// The event is the pointer event that caused the callback to be called.
public typealias TapRegionCallback = (PointerDownEvent) -> Void
