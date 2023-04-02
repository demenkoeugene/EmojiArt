//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
