//
//  MusicPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import SwiftUI
import MediaPlayer

struct NowPlayingTrack: Equatable {
    let title: String
    let artist: String
    let album: String
    let artwork: NSImage?
    let isPlaying: Bool
    let duration: TimeInterval
    let elapsed: TimeInterval
    let bundleID: String?
}

struct MusicPane: View {
    @State private var track: NowPlayingTrack?
    
    var body: some View {
        HStack(spacing: 12) {
            artwork
            
            VStack(alignment: .leading, spacing: 3) {
                Text(displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(displayArtist)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                
                Text(track?.album ?? "")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                if track?.isPlaying == true {
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                }
            }
            
            Spacer(minLength: 0)
        }
        .task {
            while !Task.isCancelled {
                refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }
    
    private var displayTitle: String {
        if let title = track?.title, !title.isEmpty { return title }
        return "Not Playing"
    }
    
    private var displayArtist: String {
        if let artist = track?.artist, !artist.isEmpty { return artist }
        return "—"
    }
    
    @ViewBuilder
    private var artwork: some View {
        if let image = track?.artwork {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
                .frame(width: 90, height: 90)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.3))
                )
        }
    }
    
    private func refresh() {
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let state = MPNowPlayingInfoCenter.default().playbackState
           
        
        guard let info else {
            track = nil
            return
        }
        
        let title = info[MPMediaItemPropertyTitle] as? String ?? ""
        let artist = info[MPMediaItemPropertyArtist] as? String ?? ""
        let album = info[MPMediaItemPropertyAlbumTitle] as? String ?? ""
        let artworkImage = (info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)?
            .image(at: CGSize(width: 200, height: 200))
        
        track = NowPlayingTrack(
            title: title,
            artist: artist,
            album: album,
            artwork: artworkImage,
            isPlaying: state == .playing,
            duration: 0,
            elapsed: 0,
            bundleID: nil
        )
    }
}
