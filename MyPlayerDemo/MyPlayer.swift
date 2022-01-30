//
//  MyPlayer.swift
//  PlayerDemo
//
//  Created by samuel on 2022/1/20.
//

import Foundation
import AVFoundation

public enum MyPlayerItemStatus: Int {
    /// unknow
    case unknow
    /// Player is ready to play
    case readyToPlay
    /// Error with playing
    case error
    
    /// Return a readable description
    public var description: String {
        switch self {
        case .unknow: return "未知状态"
        case .readyToPlay: return "可用播放"
        case .error: return "Error"
        }
    }
}

//反馈给前台播放器现在的状态
public enum MyPlayerShowStatus: Int {
    case none
    case readytoplay
    case play
    case playing
    case pause
    case stop
    case loading
    case error
    var description: String {
        switch self {
        case .none: return "没选择电台"
        case .readytoplay: return "准备播放"
        case .play: return "播放"
        case .playing: return "正在播放"
        case .pause: return "暂停"
        case .stop: return "停止"
        case .loading: return "加载中"
        case .error: return "播放失败"
        }
    }
}

struct MyPlayerInfo {
    var isPlaybackBufferEmpty = ""
    var isPlaybackLikelyToKeepUp = ""
    var isPlaybackBufferFull = ""
    var loadedTimeRanges = ""
    var playerItemStatus = MyPlayerItemStatus.unknow
    var msg = ""
}

protocol MyPlayerProtocol: NSObject {
    var delegate: MyPlayerDelegate? { get set }
    var isAutoPlay: Bool {get set}
    func setRadio(with url: String)
    func play()
    func pause()
    func stop()
    func togglePlaying()
}

class MyPlayer: NSObject, MyPlayerProtocol {
    static let instance = MyPlayer()
    var player = AVPlayer()
    var playerItemContext = 0 //KVO监控标记
    var playerItem:AVPlayerItem?
    var tempPlayerItem:AVPlayerItem?
    var tempUrl:String?
    var isAutoPlay = true // 是否自动播放
    var delegate: MyPlayerDelegate?
    var myPlayerInfo = MyPlayerInfo()
    
    var playerShowStatus = MyPlayerShowStatus.none {
        didSet {
            guard oldValue != playerShowStatus else { return }
            delegate?.observeValueDelegate(stateDidChange: playerShowStatus)
            delegate?.observeValueDelegate(info: myPlayerInfo)
        }
    }
    var isPlay: Bool = false {
        didSet {
            guard oldValue != isPlay else { return }
            delegate?.observeValueDelegate(isPlay: isPlay)
        }
    }
    var msg = "" {
        didSet {
            myPlayerInfo.msg = msg
            delegate?.observeValueDelegate(info: myPlayerInfo)
            print(msg)
        }
    }
        
    override init() {
        super.init()
        
        #if !os(macOS)
        let options: AVAudioSession.CategoryOptions

        // Enable bluetooth playback
        #if os(iOS)
        options = [.defaultToSpeaker, .allowBluetooth, .allowAirPlay]
        #else
        options = []
        #endif

        // Start audio session
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: options)
        #endif
        

        #if os(iOS)
        setupInterruptionNotification()
        setupRouteChangeNotification()
        #endif
    }
    
    func setRadio(with url: String) {
        tempUrl = url
        if (isAutoPlay) {
            prepareToPlay(with: url)
            player.play()
        } else if (!isPlay) {
            playerShowStatus = .readytoplay
        }
    }
    
    func prepareToPlay(with url: String) {
        
        playerShowStatus = .loading
        isPlay = true
        
        tempUrl = url
        let url: URL = URL(string: url)!
        let options = [AVURLAssetAllowsCellularAccessKey: true]//允许在蜂窝网络下加载
        let asset = AVURLAsset(url: url, options: options)
        let assetKeys = ["playable","hasProtectedContent"]
        playerItem = AVPlayerItem(asset: asset,automaticallyLoadedAssetKeys: assetKeys)
        
        if let playerItem = playerItem {
            player.replaceCurrentItem(with: playerItem)
        }
        //注销KVO
        removeObserver()
        //注册KVO
        addObserver()
        //临时变量，用来判断是否有playeritem
        tempPlayerItem = playerItem

    }
    
    func play() {
        //0.判断网络连接
        //1.判断是否选择了电台
        //2.判断有没有缓存
        //2.1.没有缓存 需要重新加载
        //2.2.有缓存，继续播放
        playerShowStatus = .loading
        isPlay = true
        player.play()
        
        if let playerItem = playerItem {
            if (playerItem.isPlaybackLikelyToKeepUp) {
                //有缓存，可以继续播放
                msg = "有缓存，可以继续播放"
                playerShowStatus = .playing
            } else {
                //没有缓存，重新加载播放
                msg = "没有缓存，重新加载播放"
                if let tempUrl = tempUrl {
                    prepareToPlay(with: tempUrl)
                }
            }
        } else {
            if let tempUrl = tempUrl {
                prepareToPlay(with: tempUrl)
            } else {
                msg = "没有选择电台"
                playerShowStatus = .none
                isPlay = false
                player.pause()
            }
        }
    }
    
    func pause() {
        isPlay = false
        playerShowStatus = .pause
        player.pause()
    }

    func stop() {
        msg = "停止"
        playerShowStatus = .stop
        isPlay = false
        player.pause()
        playerItem = nil
        player.replaceCurrentItem(with: nil)
    }
    
    func togglePlaying() {
        self.isPlay ? self.pause() : self.play()
    }
    
    //注册KVO
    private func addObserver() {
        if let playerItem = playerItem {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            playerItem.addObserver(self,
                                       forKeyPath: #keyPath(AVPlayerItem.status),
                                       options: [.old, .new],
                                       context: &playerItemContext)
            playerItem.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp),
                                       options: [.old, .new],
                                       context: &playerItemContext)
            playerItem.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty),
                                       options: [.old, .new],
                                       context: &playerItemContext)
            playerItem.addObserver(self,
                                   forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),
                                       options: [.old, .new],
                                       context: &playerItemContext)
        }
    }
    
    //注销KVO
    private func removeObserver() {
        if let playerItem = tempPlayerItem {
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status),context: &playerItemContext)
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp),context: &playerItemContext)
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty),context: &playerItemContext)
            playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),context: &playerItemContext)
        }
    }
    
    //观察KVO
    override func observeValue(forKeyPath keyPath: String?,of object: Any?,change: [NSKeyValueChangeKey : Any]?,context:UnsafeMutableRawPointer?) {
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,of: object,change: change,context: context)
            return
        }
        
        if let item = object as? AVPlayerItem {
            //获取最新缓存的区间
            if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
                let loadTimeArray = item.loadedTimeRanges
                if (loadTimeArray.count > 0) {
                    let newTimeRange : CMTimeRange = loadTimeArray.first as! CMTimeRange
                    let startSeconds = CMTimeGetSeconds(newTimeRange.start);
                    let durationSeconds = CMTimeGetSeconds(newTimeRange.duration);
                    let totalBuffer = startSeconds + durationSeconds;//缓冲总长度
                    print("当前缓冲时间：\(totalBuffer)%")
                    myPlayerInfo.loadedTimeRanges = String(totalBuffer)
                    delegate?.observeValueDelegate(info: myPlayerInfo)
                }
            }
            //缓存是否充足？
            if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
                if(item.isPlaybackBufferEmpty) {
                    msg = "没有缓冲"
                } else {
                    msg = "有缓存"
                }
                myPlayerInfo.isPlaybackBufferEmpty = msg
            }
            if keyPath == #keyPath(AVPlayerItem.status) {
                let status: AVPlayerItem.Status
                
                // Get the status change from the change dictionary
                if let statusNumber = change?[.newKey] as? NSNumber {
                    status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
                } else {
                    status = .unknown
                }
                
                switch status {
                    case .readyToPlay:
                        // Player item is ready to play.
                        myPlayerInfo.playerItemStatus = MyPlayerItemStatus.readyToPlay
                        msg = "URL可用，ReadyToPlay准备播放"
                        playerShowStatus = .loading
                    case .failed:
                        // Player item failed. See error.
                        myPlayerInfo.playerItemStatus = MyPlayerItemStatus.error
                        msg = "有错，URL不可用，或者网络有问题"
                        playerShowStatus = .error
                        isPlay = false
                    case .unknown:
                        // Player item is not yet ready.
                        myPlayerInfo.playerItemStatus = MyPlayerItemStatus.unknow
                        msg = "未知"
                        playerShowStatus = .none
                        isPlay = false
                    @unknown default:
                        break
                }
            }
            //是否可以继续播放
            if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
                isPlaybackLikelyToKeepUpDidChange(isPlaybackLikelyToKeepUp: item.isPlaybackLikelyToKeepUp)
            }
        }
    }
    
    //是否可以继续播放发生变化后的操作
    func isPlaybackLikelyToKeepUpDidChange(isPlaybackLikelyToKeepUp:Bool) {
        if (isPlay) {
            if(isPlaybackLikelyToKeepUp) {
                playerShowStatus = .playing
                //提前点击播放按钮，但avplayeritem还没加载完，需要在这里延时播放
//                player.play()
                msg = "KEEP UP SUCCESS 开始播放"
            } else {
                playerShowStatus = .loading
                msg = "KEEP UP FAIL 不能播放"
            }
            myPlayerInfo.isPlaybackLikelyToKeepUp = msg
        } else {
            print("暂停中，虽然有数据，但不播放")
        }
    }

}

extension MyPlayer {
    //音频中断
    func setupInterruptionNotification() {
    let nc = NotificationCenter.default
        nc.addObserver(self,selector: #selector(handleInterruption),name: AVAudioSession.interruptionNotification,object: nil)
    }
        
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        // Switch over the interruption type.
        switch type {

            case .began:
                // An interruption began. Update the UI as necessary.
                msg = "音频中断"
                guard let optionsValue = userInfo[AVAudioSessionInterruptionReasonKey] as? UInt else { return }
                switch optionsValue {
                    case AVAudioSession.InterruptionReason.default.rawValue:
                        print("因为另一个会话被激活,音频中断")
                        pause()
                        break
                    case AVAudioSession.InterruptionReason.appWasSuspended.rawValue:
                        //这里有延时收到中断通知，因为系统只能在App再次运行时发送，如果这里调用暂停会造成系统刚启动就调用暂停
                        print("由于APP被系统挂起，音频中断。会在系统启动时通知")
                        break
                    case AVAudioSession.InterruptionReason.builtInMicMuted.rawValue:
                        print("音频因内置麦克风静音而中断(例如iPad智能关闭套iPad's Smart Folio关闭)")
                        break
                    default: break
                }

            case .ended:
               // An interruption ended. Resume playback, if appropriate.
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // An interruption ended. Resume playback.
                    msg = "中断后恢复播放"
                    play()
                } else {
                    // An interruption ended. Don't resume playback.
                    msg = "中断不能恢复播放"
                    pause()
                }

            default: ()
        }
    }
}

extension MyPlayer {
    //耳机中断
    func setupRouteChangeNotification() {
        let nc = NotificationCenter.default
        nc.addObserver(self,selector: #selector(handleRouteChange),name: AVAudioSession.routeChangeNotification,object: nil)
    }
    
    @objc func handleRouteChange(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
             let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
             let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                 return
         }
        // Switch over the route change reason.
        switch reason {

            case .newDeviceAvailable: // New device found.
                let session = AVAudioSession.sharedInstance()
                let headphonesConnected = hasHeadphones(in: session.currentRoute)
                if(headphonesConnected) { print("插入耳机后处理方法") }
            
            case .oldDeviceUnavailable: // Old device removed.
                if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                    let headphonesConnected = hasHeadphones(in: previousRoute)
                    if (!headphonesConnected) {
                        msg = "耳机拨出中断"
                        pause()
                    }
                }
            
            default: ()
        }
    }
    
    func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        // Filter the outputs to only those with a port type of headphones.
        return !routeDescription.outputs.filter({$0.portType == .headphones}).isEmpty
    }
}

protocol MyPlayerDelegate: AnyObject {

    func observeValueDelegate(info: MyPlayerInfo)
    func observeValueDelegate(stateDidChange state: MyPlayerShowStatus)
    func observeValueDelegate(isPlay: Bool)
    
}
