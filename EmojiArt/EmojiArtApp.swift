//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var document = EmojiArtDocument()
    @StateObject var palletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
                .environmentObject(palletteStore)
        }
    }
}
