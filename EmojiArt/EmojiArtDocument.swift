//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Eugene Demenko on 30.03.2023.
//

import SwiftUI


class EmojiArtDocument: ObservableObject{
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            sheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    private var autosaveTimer: Timer?
    
    private func sheduleAutosave(){
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false){_ in
            self.autosave()
        }
    }
    
    private struct Autosave{
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    
    private func autosave(){
        if let url = Autosave.url{
            save(to: url)
        }
    }
    private func save(to url: URL){
        let thisfunction = "\(String(describing:self)).\(#function)"
        do{
            let data: Data = try emojiArt.json()
            try data.write(to: url)
            print("\(thisfunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
        }catch let encodingError where encodingError is EncodingError{
            print("\(thisfunction) couldn't encode EmojiArt as JSON because \(encodingError.localizedDescription)")
        }catch{
            print("EmojiArtDocument.save(to:) error = \(error) ")
        }
    }
    
    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url){
            emojiArt = autosavedEmojiArt
        }else{
            self.emojiArt = EmojiArtModel()
            //        emojiArt.addEmoji("🐼", at: (-200, -200), size: 80)
            //        emojiArt.addEmoji("🦁", at: (50, 100), size: 40)
        }
    }

    var emojis: [EmojiArtModel.Emoji]{ emojiArt.emojis}
    var background: EmojiArtModel.Background{ emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background set on \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(of: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    
    enum BackgroundImageFetchStatus: Equatable{
        case idle
        case fatching
        case failed(URL)
    }
    
    private func fetchBackgroundImageDataIfNecessary(){
        backgroundImage = nil
        switch emojiArt.background{
        case .url(let url):
            backgroundImageFetchStatus = .fatching
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if self?.emojiArt.background == EmojiArtModel.Background.url(url){
                    self?.backgroundImageFetchStatus = .idle
                    let imageData = try? Data(contentsOf: url)
                    DispatchQueue.main.async {
                        if imageData != nil {
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                        if self?.backgroundImage == nil{
                            self?.backgroundImageFetchStatus = .failed(url)
                        }
                    }
                }
            }
            
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
    
}
extension EmojiArtModel.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
