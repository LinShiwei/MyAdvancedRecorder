//
//  ViewController.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/17.
//  Copyright © 2015年 Linsw. All rights reserved.
//


/**
*  @brief  实现基础的录音功能，参考自印象笔记：Swift－制作一个录音机
*  只包含三个按钮，play、start、stop
*  点击start开始录音，stop停止录音，play播放录音
*
*  @since 2015.12.16 1.0
*/
import UIKit
import AVFoundation
class ViewController: UIViewController {
    // MARK:变量定义
    /// 储存录音的状态，正在录音或者不在录音
    var isRecording:Bool = false
    /// 储存播放状态，正在播放或者不在播放
    var isPlaying:Bool = false
    /// a recorder object
    var recorder:AVAudioRecorder?
    /// a player object
    var player:AVAudioPlayer?
    /// recorder setting dictionary
    var recorderSettingDic:[String:AnyObject]?
    /// the save path of record
    var accPath:String?
    /// 定时器线程，循环监测录音的音量大小
    var volumeTimer:NSTimer!
    /// 录音音量标签，用来显示音量大小
    @IBOutlet weak var volumeLabel: UILabel!
    /// 录音按钮
    @IBOutlet weak var recordButton: UIButton!
    /// 播放按钮
    @IBOutlet weak var playButton: UIButton!
    //MARK:播放和录音响应函数
    /**
     play按钮响应函数
     
     :param: sender button：play
     */
    @IBAction func playRecord(sender: AnyObject) {
        if !isPlaying {
            /**
            执行播放功能
            
            :param: UIImage.initnamed 设置暂停图标
            :param: forState          Normal状态
            */
            isPlaying = !isPlaying
            playButton.setImage(UIImage.init(named: "pausePlay"), forState: UIControlState.Normal)
            if player == nil{
                do{
                    /**
                    *  @brief  初始化player播放器
                    *
                    */
                    player = try AVAudioPlayer(contentsOfURL: NSURL(string: accPath!)!)
                    player!.prepareToPlay()
                
                }
                catch let error as NSError {
                    print("Could not save \(error), \(error.userInfo)")
                }
            }
            
            player!.play()

        
            print("play")
            
            recordButton.enabled = false
        }else{
            /**
            执行暂停功能
            
            :param: UIImage.initnamed 设置播放图标
            :param: forState          Normal状态
            */
            isPlaying = !isPlaying
            playButton.setImage(UIImage.init(named: "playRecord"), forState: UIControlState.Normal)
            recordButton.enabled = true
            player!.pause()
        }
        
    }
//    /**
//     button:stop action
//     
//     :param: sender button:stop
//     */
//    @IBAction func stopRecord(sender: AnyObject) {
//        recorder!.stop()
//        print("stop")
//    }
    /**
     button:record action
    
     :param: sender button:record
     */
    @IBAction func record(sender: AnyObject) {
        if isRecording {
            /**
            执行停止录音功能
            
            :param: UIImage.initnamed 设置开始录音按钮
            :param: forState          Normal状态
            */
            isRecording = !isRecording
            recordButton.setImage(UIImage.init(named: "startRecord"),forState: UIControlState.Normal)
            recorder!.stop()
            print("stop")
            //录音器释放
            recorder = nil
            //暂停定时器
            volumeTimer.invalidate()
            volumeTimer = nil
            volumeLabel.text = "录音音量:0"
            
            playButton.enabled = true

        }else{
            /**
            执行开始录音功能
            
            :param: UIImage.initnamed 设置停止录音按钮
            :param: forState          Normal状态
            */
            isRecording = !isRecording
            recordButton.setImage(UIImage.init(named: "stopRecord"),forState: UIControlState.Normal)
            do{
                /// init the recorder object
                recorder = try AVAudioRecorder(URL: NSURL(string: accPath!)!, settings: recorderSettingDic!)
                
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            print("\(recorder!.prepareToRecord())，perpare")
            print("\(recorder!.record())，start")
            //开启仪表计数功能
            recorder!.meteringEnabled = true
            volumeTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self,
                selector: "levelTimer", userInfo: nil, repeats: true)

            playButton.enabled = false
            player = nil
        }
    }
  
    
    // MARK: 初始化
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isRecording = false
        isPlaying = false
        /// 初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        /// 设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        /// 设置支持后台
        try! session.setActive(true)
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        
        accPath = paths + "/sound.acc"///把aac改成wav灰出现初始化错误，是否不支持wav？
        
        recorderSettingDic=[
            AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey:320000,
            AVSampleRateKey:44100.0
        ]
       
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    // MARK:定时器
    /**
     定时器响应函数，定时更新录音音量大小
     */
    func levelTimer(){
        recorder!.updateMeters() // 刷新音量数据
//        let averageV:Float = recorder!.averagePowerForChannel(0) //获取音量的平均值
        let maxV:Float = recorder!.peakPowerForChannel(0) //获取音量最大值
        let lowPassResult:Double = pow(Double(10), Double(0.05*maxV))
        volumeLabel.text = "录音音量:\(lowPassResult)"
    }
    
    
}


