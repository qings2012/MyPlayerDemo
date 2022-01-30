//
//  ContentView.swift
//  PlayerDemo
//
//  Created by samuel on 2022/1/20.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var radioPlayer = MyRadioPlayer()
    
    var body: some View {
        Form {
            Section(header: Text("准备阶段按钮:")) {
                Button(action: {
                    radioPlayer.setRadio(with: "https://rthkaudio1-lh.akamaihd.net/i/radio1_1@355864/index_56_a-p.m3u8?sd=10&rebase=on")
                }) {
                    Image(systemName: "radio.fill")
                }.font(.title2).foregroundColor(.primary)
            }
            Section(header: Text("手动操作按钮:")) {
                Button(action: {
                    radioPlayer.play()
                }) {
                    Image(systemName: "play.fill")
                }.font(.title2).foregroundColor(.primary)
                Button(action: {
                    radioPlayer.pause()
                }) {
                    Image(systemName: "pause.fill")
                }.font(.title2).foregroundColor(.primary)
                Button(action: {
                    radioPlayer.stop()
                }) {
                    Image(systemName: "stop.fill")
                }.font(.title2).foregroundColor(.primary)
            }
            Section(header: Text("要实现的播放器:"),footer: Text("点击可以播放，暂停就是暂停")) {
                
                Button(action: {
                    radioPlayer.setRadio(with: "https://rthkaudio1-lh.akamaihd.net/i/radio1_1@355864/index_56_a-p.m3u8?sd=10&rebase=on")
                }) {
                    Image(systemName: "radio.fill")
                }.font(.title2).foregroundColor(.primary)
                
                Button(action: {
                    radioPlayer.togglePlaying()
                }) {
                    Image(systemName: radioPlayer.isPlay ? "pause.fill" : "play.fill")
                }.font(.title2).foregroundColor(.primary)
                HStack {
                    Text("电台状态：")
                    Text(radioPlayer.myPlayerShowStatus.description)
                }
                HStack {
                    Text("消息：")
                    Text(radioPlayer.info.msg)
                }
            }
            
            Section(header: Text("AvPlayerItem状态:")) {
                HStack {
                    Text("state：")
                    Text(radioPlayer.info.playerItemStatus.description)
                }
                HStack {
                    Text("isPlaybackBufferEmpty：")
                    Text(radioPlayer.info.isPlaybackBufferEmpty)
                }
                HStack {
                    Text("isPlaybackLikelyToKeepUp：")
                    Text(radioPlayer.info.isPlaybackLikelyToKeepUp)
                }
                HStack {
                    Text("isPlaybackBufferFull：")
                    Text(radioPlayer.info.isPlaybackBufferFull)
                }
                HStack {
                    Text("当前缓冲时间：")
                    Text(radioPlayer.info.loadedTimeRanges)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
//            Timer
            print("切换到前台!")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            print("进入后台!")
            if (radioPlayer.isPlay == false) {
            // radioPlayer.stop //播放器停止，后台也不会读取数据，需要做一个开关
                radioPlayer.stop()
            }
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView(radioPlayer: MyPlayer.instance)
//    }
//}
