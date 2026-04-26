//
//  ClipboardSoundPlayer.swift
//  ClipSense
//

import AVFoundation
import Foundation
import os

@MainActor
final class ClipboardSoundPlayer {
    private let logger = Logger(subsystem: "com.junichihashimoto.ClipSense", category: "ClipboardSound")
    private var player: AVAudioPlayer?

    init() {
        guard let soundURL = Bundle.main.url(forResource: "cursor-bgm", withExtension: "mp3") else {
            logger.warning("Clipboard sound file was not found in the app bundle.")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.prepareToPlay()
        } catch {
            logger.error("Failed to load clipboard sound: \(error.localizedDescription)")
        }
    }

    func playCopySound() {
        guard let player else {
            return
        }

        player.currentTime = 0
        player.play()
    }
}
