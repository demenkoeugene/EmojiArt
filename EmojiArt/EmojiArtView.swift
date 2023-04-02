//
//  ContentView.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI

struct EmojiArtView: View {
      
    @ObservedObject var document: EmojiArtDocument
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtView(document: EmojiArtDocument)
    }
}
