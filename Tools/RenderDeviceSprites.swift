// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

// mog: renders each headset model fetched by Tools/fetch-device-models.sh into
// a sprite sheet of one full turn, so the app plays frames instead of running
// SceneKit. The sheets come from copyrighted models: they stay beside them on
// this Mac and are never committed. A sheet newer than its model is kept.
//
//   swift Tools/RenderDeviceSprites.swift <models folder>
//
// Each <model>-turn-48.png is one row of 48 frames, 54 × 46 px each (the
// notice's 27 × 23 pt slot at 2×), turning 7.5° per frame from the front.

import AppKit
import ImageIO
import SceneKit
import SceneKit.ModelIO

let frames = 48, frameSize = CGSize(width: 54, height: 46)

enum Turntable {
    /// The model centered on a turntable, framed for a slot at least 27 × 23.
    static func load(_ url: URL) -> SCNScene? {
        // SCNScene(url:) decodes 4K textures into an image cache it never
        // releases (~200 MB per Beats model); ModelIO reads them lazily instead.
        let asset = MDLAsset(url: url)
        guard asset.count > 0 else { return nil }
        let scene = SCNScene(mdlAsset: asset)
        smallTextures(scene, archive: url)
        let model = SCNNode()
        scene.rootNode.childNodes.forEach { model.addChildNode($0) }
        // Where the model first splits, two parts are buds and their taller
        // case (AirPods, AirPods Pro): only the buds show. Others stay whole.
        func height(_ node: SCNNode) -> CGFloat { node.boundingBox.max.y - node.boundingBox.min.y }
        var parts = [model]
        while parts.count == 1 { parts = parts[0].childNodes.filter { height($0) > 0 } }
        var shown = model
        if parts.count == 2 {
            let tall = height(parts[0]) > height(parts[1]) ? 0 : 1
            parts[tall].isHidden = true
            shown = parts[1 - tall]
        }
        let (lo, hi) = shown.boundingBox
        let corners = [lo.x, hi.x].flatMap { x in [lo.y, hi.y].flatMap { y in [lo.z, hi.z].map { z in
            model.convertPosition(SCNVector3(x, y, z), from: shown) } } }
        let minY = corners.map(\.y).min()!, maxY = corners.map(\.y).max()!
        let center = SCNVector3((corners.map(\.x).min()! + corners.map(\.x).max()!) / 2, (minY + maxY) / 2,
                                (corners.map(\.z).min()! + corners.map(\.z).max()!) / 2)
        let radius = corners.map { hypot($0.x - center.x, $0.z - center.z) }.max()!
        model.position = SCNVector3(-center.x, -center.y, -center.z)

        let turn = SCNNode()
        turn.addChildNode(model)
        scene.rootNode.addChildNode(turn)
        turn.name = "turn"

        // Ortho, tilted 10° down, sized so the whole sweep fits the slot.
        let tilt: CGFloat = .pi / 18
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        camera.orthographicScale = 1.04 * max((maxY - minY) / 2 * cos(tilt) + radius * sin(tilt), radius * 23 / 27)
        camera.zNear = radius
        camera.zFar = radius * 20
        let eye = SCNNode()
        eye.name = "camera"
        eye.camera = camera
        eye.position = SCNVector3(0, radius * 10 * sin(tilt), radius * 10 * cos(tilt))
        eye.eulerAngles.x = -tilt
        scene.rootNode.addChildNode(eye)

        // Dark headphones vanish on the black island without a strong rim from
        // behind; a key and a soft fill model the front.
        func light(_ type: SCNLight.LightType, _ intensity: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
            let node = SCNNode()
            node.light = SCNLight()
            node.light!.type = type
            node.light!.intensity = intensity
            node.eulerAngles = SCNVector3(x, y, 0)
            scene.rootNode.addChildNode(node)
        }
        light(.directional, 3000, x: -.pi / 5, y: -.pi / 6)
        light(.directional, 6000, x: -.pi / 8, y: .pi * 0.9)
        light(.ambient, 800)
        scene.lightingEnvironment.contents = NSColor(white: 0.75, alpha: 1)
        scene.lightingEnvironment.intensity = 1
        scene.background.contents = nil
        return scene
    }

    /// ModelIO names a texture as "file.usdz[entry]", which SceneKit cannot
    /// open: each is read from the archive (stored, uncompressed) at 256 px.
    private static func smallTextures(_ scene: SCNScene, archive url: URL) {
        guard let zip = try? Data(contentsOf: url, options: .alwaysMapped) else { return }
        func int(_ at: Int, _ bytes: Int) -> Int { (0..<bytes).reduce(0) { $0 | Int(zip[at + $1]) << (8 * $1) } }
        var entries: [String: Range<Int>] = [:]
        var at = 0
        while at + 30 <= zip.count, int(at, 4) == 0x0403_4b50 {
            let nameEnd = at + 30 + int(at + 26, 2), start = nameEnd + int(at + 28, 2), end = start + int(at + 18, 4)
            guard end <= zip.count else { break }
            entries[String(decoding: zip[(at + 30)..<nameEnd], as: UTF8.self)] = start..<end
            at = end
        }
        var images: [String: CGImage] = [:]
        func image(_ entry: String) -> CGImage? {
            if let image = images[entry] { return image }
            guard let range = entries[entry],
                  let source = CGImageSourceCreateWithData(zip.subdata(in: range) as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                      kCGImageSourceThumbnailMaxPixelSize: 256,
                      kCGImageSourceCreateThumbnailFromImageAlways: true] as CFDictionary) else { return nil }
            images[entry] = image
            return image
        }
        scene.rootNode.enumerateHierarchy { node, _ in
            for material in node.geometry?.materials ?? [] {
                for property in [material.diffuse, material.normal, material.metalness, material.roughness,
                                 material.ambientOcclusion, material.emission, material.transparent] {
                    guard let name = property.contents as? String, name.hasSuffix("]"),
                          let open = name.lastIndex(of: "[") else { continue }
                    property.contents = image(String(name[name.index(after: open)..<name.index(before: name.endIndex)]))
                }
            }
        }
    }
}

let folder = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1]
    : NSHomeDirectory() + "/Library/Application Support/vorssaint-mog/models")
let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
func modified(_ url: URL) -> Date { (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast }
for model in (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
    where model.pathExtension == "usdz" {
    let sheet = folder.appendingPathComponent(model.deletingPathExtension().lastPathComponent + "-turn-\(frames).png")
    if modified(sheet) > modified(model) { print("✓ \(sheet.lastPathComponent) (up to date)"); continue }
    autoreleasepool {
        guard let scene = Turntable.load(model), let turn = scene.rootNode.childNode(withName: "turn", recursively: false),
              let context = CGContext(data: nil, width: frames * Int(frameSize.width), height: Int(frameSize.height),
                                      bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            print("✗ \(model.lastPathComponent): could not load"); return
        }
        renderer.scene = scene
        renderer.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: false)
        for frame in 0..<frames {
            turn.eulerAngles.y = 2 * .pi * CGFloat(frame) / CGFloat(frames)
            let image = renderer.snapshot(atTime: 0, with: frameSize, antialiasingMode: .multisampling4X)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            context.draw(cgImage, in: CGRect(x: CGFloat(frame) * frameSize.width, y: 0,
                                             width: frameSize.width, height: frameSize.height))
        }
        renderer.scene = nil
        guard let strip = context.makeImage(),
              let out = CGImageDestinationCreateWithURL(sheet as CFURL, "public.png" as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(out, strip, nil)
        print(CGImageDestinationFinalize(out) ? "✓ \(sheet.lastPathComponent)" : "✗ \(sheet.lastPathComponent)")
    }
}
