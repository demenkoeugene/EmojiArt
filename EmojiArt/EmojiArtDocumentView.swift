//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    let defaultEmojiFontSize: CGFloat = 40
    var body: some View {
        VStack(spacing: 0){
            documentBody
            pallet
        }
    }
    
    var documentBody: some View{
        GeometryReader {geometry in
            ZStack{
                Color.white.overlay{
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0,0), in: geometry))
                }
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fatching{
                    ProgressView()
                }else{
                    ForEach(document.emojis){emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
       
       
    }
    
    // MARK: - Drag and Drop
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy)-> Bool{
        var found = providers.loadObjects(ofType: URL.self) {url in
            document.setBackground(EmojiArtModel.Background.url(url))
        }
        if !found{
            found = providers.loadObjects(ofType: UIImage.self) {image in
                if let data = image.jpegData(compressionQuality: 1.0){
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found{
            found = providers.loadObjects(ofType: String.self){ string in
                if let emoji = string.first, emoji.isEmoji{
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }
        
    // MARK: - Positioning/Sizing Emoji
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy)-> CGPoint{
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint{
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x+CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y+CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    private func convertToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - center.x) / zoomScale,
            y: (location.y - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
    
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat{
        CGFloat(emoji.size)
    }
 
    
    // MARK: - Panning
    @State private var steadyStatePanOffset: CGSize = CGSize.zero
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    
    // MARK: - Zooming
    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var  gestureZoomScale: CGFloat = 1
     
    private func zoomGesture()->some Gesture{
        MagnificationGesture()
            .updating($gestureZoomScale){ latestGestureScale, gestureZoomScale, transaction in
                gestureZoomScale = latestGestureScale
            }
            .onEnded{gestureScaleAtEnd in
                withAnimation{
                    steadyStateZoomScale *= gestureScaleAtEnd
                }
            }
    }
    private func doubleTapToZoom(in size: CGSize) -> some Gesture{
        return TapGesture(count: 2)
            .onEnded {
                withAnimation{
                    zoomFit(document.backgroundImage, in: size)
                }
            }
    }
    private func zoomFit(_ image: UIImage?, in size: CGSize){
        if let image = image, image.size.width>0, image.size.height>0, size.width>0, size.height>0{
            let hZoom = (size.width/image.size.width) / zoomScale
            let vZoom = (size.height/image.size.height) / zoomScale
            steadyStateZoomScale = min(hZoom,vZoom)
        }
    }
    private var zoomScale: CGFloat{
        steadyStateZoomScale * gestureZoomScale
    }
    
    // MARK: - Palette
    var pallet: some View{
        ScrollEmojisView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmojis = "😄😀🥹😅😂🤣🥲☺️😊😌😜👽👾👣👁️👀👤🧠🚶‍♀️🐧🐔🐵🐸🐒🦊🐻"
}


struct ScrollEmojisView: View{
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal){
            HStack{
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji).onDrag{NSItemProvider(object: emoji as NSString)}
                }
            }
        }
    }
}
                              



struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
