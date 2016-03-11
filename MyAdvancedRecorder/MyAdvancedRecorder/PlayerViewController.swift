//
//  PlayerViewController.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/23.
//  Copyright © 2015年 Linsw. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
class PlayerViewController: UIViewController {
    var isPlaying = false
    var volumeTimer:NSTimer!
    var player:AVAudioPlayer?
    var playPath:String?{
        didSet{
            configureView()
        }
    }
    func configureView() {
        // Update the user interface
        if let path = self.playPath {
            if let content = self.myTextView {
                content.text = path
            }
        }
        
    }
    
    
    
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var myTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var playButton: UIButton!
    // MARK:播放录音文件
    @IBAction func playRecord(sender: AnyObject) {
        if playPath == nil {
            statusLabel.text = "没有文件路径"
        }else{
            if isPlaying {
                pausePlay()
            }else{
                startPlay()
            }
        }
        
    }
    func startPlay() {
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "pausePlay"), forState: UIControlState.Normal)
        if player == nil{
            do{
                player = try AVAudioPlayer(contentsOfURL: NSURL(string: playPath!)!)
                player!.prepareToPlay()
                
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        //开启仪表计数功能
        player!.meteringEnabled = true
        volumeTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self,
            selector: "levelTimer", userInfo: nil, repeats: true)
        player!.play()
        print("play")
    }
    func pausePlay() {
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "playRecord"), forState: UIControlState.Normal)
        player!.pause()
        //暂停定时器
        volumeTimer.invalidate()
        volumeTimer = nil

    }
    // MARK:初始化
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // Do any additional setup after loading the view.
        isPlaying = false
        /// 初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        /// 设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        /// 设置支持后台
        try! session.setActive(true)
       
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if isPlaying {
            pausePlay()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func levelTimer(){
        player!.updateMeters() // 刷新音量数据
        let maxVolumedB:Float = player!.peakPowerForChannel(0) //获取音量最大值
        let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
        volumeLabel.text = "播放音量:\(maxVolume)"
        
    }
    
}
