//
//  MyRadio.swift
//  PlayerDemo
//
//  Created by samuel on 2022/1/22.
//

import Foundation
import MediaPlayer
import SwiftUI

struct Radio {
    var name: String = ""
    var url: String = ""
}

class MyRadioPlayer: ObservableObject, MyPlayerDelegate {
    
    let myPlayer: MyPlayerProtocol
    
    @Published var info = MyPlayerInfo()
    @Published var myPlayerShowStatus: MyPlayerShowStatus = .none
    @Published var isPlay: Bool = false
    
    init() {
        myPlayer = MyPlayer.instance
        myPlayer.delegate = self
        myPlayer.isAutoPlay = false
    }
    
    func observeValueDelegate(isPlay: Bool) {
        self.isPlay = isPlay
    }
    
    func observeValueDelegate(stateDidChange state: MyPlayerShowStatus) {
        myPlayerShowStatus = state
//        print(myPlayerShowStatus.description)
    }
    
    func observeValueDelegate(info: MyPlayerInfo) {
        self.info = info
    }
    
    func setRadio(with url: String) {
        myPlayer.setRadio(with: url)
    }
    
    func play() {
        isPlay = true
        myPlayer.play()
    }
    
    func pause() {
        isPlay = false
        myPlayer.pause()
    }
    
    func stop() {
        isPlay = false
        myPlayer.stop()
    }
    
    func togglePlaying() {
        isPlay ? pause() : play()
    }
    
}
