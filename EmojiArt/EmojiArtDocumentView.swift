//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []
    @State private var offsetValue = CGSize.zero
    @Environment(\.undoManager) var undoManager
    let defaultEmojiFontSize: CGFloat = 40
    @State private var autozoom = false
    
    var body: some View {
        VStack(spacing: 0){
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
        .onTapGesture {
            selectedEmojis.removeAll()
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
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                }else{
                    ForEach(document.emojis){emoji in
                        ZStack {
                            Text(emoji.text)
                                .font(.system(size: fontSize(for: emoji)))
                                .foregroundColor(selectedEmojis.contains(emoji) ? .white : .black)
                                .scaleEffect(selectedEmojis.contains(emoji) ? 1.5 : 1.0)
                                .opacity(selectedEmojis.contains(emoji) ? 0.5 : 1.0)
                                .position(position(for: emoji, in: geometry))
                                .offset(offsetValue)
                                .gesture(selectedEmojis.contains(emoji) ? self.panEmojiGesture(emoji: emoji) : nil)
                        }
                        .onTapGesture {
                            tapToSelect(emoji: emoji)
                        }
                        .animation(.spring(), value: selectedEmojis)
                    }

                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                    return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow){ alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus){status in
                switch status{
                case .failed(let url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage){image in
                zoomFit(image, in: geometry.size)
            }
        }
       
    }
    
    @State private var alertToShow: IdentifiableAlert?
    private func showBackgroundImageFetchFailedAlert(_ url: URL){
        alertToShow = IdentifiableAlert(id: "fetch failed: "+url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)"),
                dismissButton: .default(Text("OK"))
            )
        })
    }
   
//    @GestureState private var gestureZoomScaleEmoji: CGFloat = 1.0
//
//    private func scale(for emoji: EmojiArtModel.Emoji) -> CGFloat {
//        if selectedEmojis.contains(emoji){
//            return emoji.fontSize * self.zoomScale * self.gestureZoomScaleEmoji
//        } else {
//            return emoji.fontSize * self.zoomScale
//        }
//    }
    
    @GestureState private var gesturePanOffsetEmoji: CGSize = .zero
    
   
        
    private func panEmojiGesture(emoji: EmojiArtModel.Emoji) -> some Gesture {
            DragGesture()
                .onChanged { _ in
                    singleEmoji = selectedEmojis.contains(emoji) ? nil : emoji
                }
                .updating($gesturePanOffsetEmoji) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    withAnimation(.easeIn) {
                           if selectedEmojis.contains(emoji) {
                               for e in selectedEmojis {
                                   document.moveEmoji(e, by: value.translation / self.zoomScale, undoManager: undoManager)
                               }
                           } else {
                               document.moveEmoji(emoji, by: value.translation / self.zoomScale, undoManager: undoManager)
                               singleEmoji = nil
                           }
                    }
                }
        }


    
    // MARK: - Pan Single Emoji Gesture (Extra Credit)

    @State private var singleEmoji: EmojiArtModel.Emoji?
    
    private var singleEmojiText: String {
        return singleEmoji?.text ?? "nil"
    }


    
    
    
    private func tapToSelect(emoji: EmojiArtModel.Emoji){
        if selectedEmojis.contains(emoji){
            selectedEmojis.remove(emoji)
        } else {
            selectedEmojis.insert(emoji)
        }
    }

    
    // MARK: - Drag and Drop
    
    
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            autozoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autozoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
                        // L14 pass undo manager to Intent functions
                        undoManager: undoManager
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
    
    private func resizeFont(for emoji: EmojiArtModel.Emoji) -> CGFloat{
        CGFloat(emoji.size)+3
    }

    
    // MARK: - Panning
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
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
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
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
    
   }



                              
struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
