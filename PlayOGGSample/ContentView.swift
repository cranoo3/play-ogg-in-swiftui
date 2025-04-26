//
//  ContentView.swift
//  PlayOGGSample
//
//  Created by cranoo on 2025/03/24.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @State private var resultURL: URL?
    @State private var player: AVPlayer?
    
    @State private var selectedOGGMedia: OGGURL = .sample_opus
    @State private var selectedMethod: UseMethod = .convertOpusOGGtoM4A
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Picker("Media", selection: $selectedOGGMedia) {
                ForEach(OGGURL.allCases) { oggURL in
                    Text(oggURL.rawValue)
                        .tag(oggURL)
                }
                .pickerStyle(.menu)
            }
            
            
            Picker("Use Method", selection: $selectedMethod) {
                ForEach(UseMethod.allCases) { useMethod in
                    Text(useMethod.rawValue)
                        .tag(useMethod)
                }
                .pickerStyle(.menu)
            }
            
            
            Button("Start Convert") {
                Task {
                    isLoading = true
                    do {
                        let sourceURL = selectedOGGMedia.url
                        let helper = OGGHelper()
                        
                        switch selectedMethod {
                        case .convertOpusOGGtoM4A:
                            let result = try await helper.convertOpusOGGtoM4A(sourceURL: sourceURL)
                            print(result.absoluteString)
                            resultURL = result
                        case .convertVorbisOGGtoWAV:
                            let result = try await helper.convertVorbisOGGtoWAV(sourceURL: sourceURL)
                            print(result.absoluteString)
                            resultURL = result
                        }
                    } catch {
                        print("エラー: \(error)")
                    }
                    isLoading = false
                }
            }
            
            Button("Play") {
                guard let resultURL else {
                    return
                }
                player = AVPlayer(url: resultURL)
                player?.play()
            }
            .disabled(resultURL == nil)
            
            Button("Stop") {
                player?.pause()
                resultURL = nil
            }
            .disabled(resultURL == nil)
        }
        .padding()
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }
}

private extension ContentView {
    enum OGGURL: String, CaseIterable, Identifiable {
        case sample_opus = "sample_opus"
        case sample_vorbis = "sample_vorbis"
 
        var id: UUID { UUID() }
        
        var url: URL {
            switch self {
            case .sample_opus:
                URL(string: "")!
            case .sample_vorbis:
                URL(string: "")!
            }
        }
    }
    
    enum UseMethod: String, CaseIterable, Identifiable {
        case convertOpusOGGtoM4A = "convertOpusOGGtoM4A"
        case convertVorbisOGGtoWAV = "convertVorbisOGGtoWAV"
        
        var id: UUID { UUID() }
    }
}

#Preview {
    ContentView()
}
