// Copyright 2024 The Shaft Authors.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#if canImport(WinSDK)
    import Foundation
    import WinSDK
    import CSkiaResource

    private var executablePath: String {
        var buffer = [WCHAR](repeating: 0, count: Int(MAX_PATH))
        GetModuleFileNameW(nil, &buffer, DWORD(buffer.count))
        return String(decodingCString: buffer, as: UTF16.self)
    }

    internal func loadICU() {
        let executableDir = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        let icudtlURL = CSkiaResource.icudtl!

        // copy icudtl.dat to the same directory as the executable so that Skia can find it
        let icudtlDestURL = executableDir.appendingPathComponent("icudtl.dat")
        if !FileManager.default.fileExists(atPath: icudtlDestURL.path) {
            try! FileManager.default.copyItem(at: icudtlURL, to: icudtlDestURL)
        }
    }

#else

    internal func loadICU() {
        return  // No-op
    }

#endif
