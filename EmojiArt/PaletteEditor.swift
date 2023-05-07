//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 03.05.2023.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
    var body: some View {
        Form{
            nameSection
            addEmojisSection
            removeEmojiSection
            
        }.frame(minWidth: 300, minHeight: 350)
       
        
    }
    @State private var emojisToAdd = ""
    
    var addEmojisSection: some View{
        Section(header: Text("Add Emojis")){
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd){emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    func addEmojis(_ emojis: String){
        withAnimation{
            palette.emojis = (emojis+palette.emojis)
                .filter{$0.isEmoji}
//                .removingDuplicateCharacters
        }
    
    }
    var nameSection: some View{
        Section(header: Text("Name")){
            TextField("Name", text: $palette.name)
        }
    }
    
    var removeEmojiSection: some View{
        Section(header: Text("Remove Emoji")){
            let emojis = palette.emojis.withNoRepeatedCharacters.map{String($0)}
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]){
                ForEach(emojis, id: \.self){emoji in
                    Text(emoji)
                        .onTapGesture{
                            withAnimation{
                                palette.emojis.removeAll(where: {String($0) == emoji})
                            }
                        }
                    }
                }
            }
        }
    }





//struct PaletteEditor_Previews: PreviewProvider {
//    static var previews: some View {
//        //PaletteEditor()
//    }
//}
