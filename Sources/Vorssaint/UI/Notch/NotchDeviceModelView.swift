// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import ImageIO
import SwiftUI

// mog: the connected device turning in the notice's mark slot, played from the
// sprite sheet Tools/RenderDeviceSprites.swift renders beside its model. Read
// when the notice shows and released with the view: nothing is kept idle.
struct NotchDeviceModelView<Still: View>: View {
    let url: URL
    let still: Still
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frames: [CGImage] = []

    var body: some View {
        Group {
            if frames.isEmpty {
                still
            } else if reduceMotion {
                frame(frames[frames.count / 8]) // 45°
            } else {
                // One turn every 2.2 s, at about 24 frames a second.
                TimelineView(.animation(minimumInterval: 1 / 24)) { context in
                    let turn = (context.date.timeIntervalSinceReferenceDate / 2.2).truncatingRemainder(dividingBy: 1)
                    frame(frames[min(frames.count - 1, Int(turn * Double(frames.count)))])
                }
            }
        }
        .onAppear { frames = Self.frames(url) }
        .onDisappear { frames = [] }
    }

    private func frame(_ image: CGImage) -> some View {
        Image(decorative: image, scale: 2).resizable().scaledToFit()
    }

    /// One row of frames; a missing or unreadable sheet keeps the still art.
    private static func frames(_ url: URL) -> [CGImage] {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let sheet = CGImageSourceCreateImageAtIndex(source, 0,
                  [kCGImageSourceShouldCacheImmediately: true] as CFDictionary) else { return [] }
        let count = NotchAccessorySupport.turnFrames, width = sheet.width / count
        return (0..<count).compactMap { sheet.cropping(to: CGRect(x: $0 * width, y: 0, width: width, height: sheet.height)) }
    }
}
