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
import CoreData
class RecorderViewController: UIViewController {
    // MARK:变量定义
    /// 录音路径
    let appFilePath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
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
    @IBOutlet weak var volumeProgress: UIProgressView!
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
            startPlay()
        }else{
            pausePlay()
        }
        
    }
    func startPlay(){
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "pausePlay"), forState: UIControlState.Normal)
        if player == nil{
            do{
                player = try AVAudioPlayer(contentsOfURL: NSURL(string: accPath!)!)
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
        
        recordButton.enabled = false
    }
    func pausePlay(){
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "playRecord"), forState: UIControlState.Normal)
        recordButton.enabled = true
        player!.pause()
        //暂停定时器
        volumeTimer.invalidate()
        volumeTimer = nil
    }
//    func stopPlay() {
//        player!.stop()
//        player = nil
//    }
    /**
     button:record action
    
     :param: sender button:record
     */
    @IBAction func record(sender: AnyObject) {
        if isRecording {
            stopRecord()
        }else{
            startRecord()
        }
    }
    func startRecord() {
        accPath = newRecordURL()
        NSLog("start record:   \(accPath) ")
        
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
        volumeTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self,
            selector: "levelTimer", userInfo: nil, repeats: true)
        
        playButton.enabled = false
        player = nil
    }
    func stopRecord() {
        isRecording = !isRecording
        recordButton.setImage(UIImage.init(named: "startRecord"),forState: UIControlState.Normal)
        recorder!.stop()
        print("stop")
        
        //暂停定时器
        volumeTimer.invalidate()
        volumeTimer = nil
        //录音器释放
        recorder = nil
        volumeLabel.text = "录音音量:0"
        playButton.enabled = true
    }
    // MARK: 初始化
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isRecording = false
        isPlaying = false
        playButton.enabled = false
        /// 初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        
        /// 设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        /// 设置支持后台
        try! session.setActive(true)
        recorderSettingDic=[
            AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey:AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey:320000,
            AVSampleRateKey:44100.0
        ]
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        playButton.enabled = false
        // 从coredata中获取数据
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        //2
        let fetchRequest = NSFetchRequest(entityName: "MyRecordFile")
        //3
        do {
            let path = try managedContext.executeFetchRequest(fetchRequest)
            let myRecordURL = path as! [NSManagedObject]
            if myRecordURL.count > 0 {
                accPath = appFilePath + (myRecordURL[myRecordURL.count-1].valueForKey("fileName")?.description)!
                playButton.enabled = true
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if isPlaying {
            pausePlay()
        }
        if isRecording {
            stopRecord()
        }
        player = nil
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
        if isRecording {
            recorder!.updateMeters() // 刷新音量数据
            let maxVolumedB:Float = recorder!.peakPowerForChannel(0) //获取音量最大值
            let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
            volumeProgress.progress = Float(maxVolume)
            //        volumeProgress.progress = (maxVolumedB / 160)+1.0
            volumeLabel.text = "录音音量:\(volumeProgress.progress)"
        }
        if isPlaying {
            player!.updateMeters() // 刷新音量数据
            let maxVolumedB:Float = player!.peakPowerForChannel(0) //获取音量最大值
            let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
            volumeProgress.progress = Float(maxVolume)
            volumeLabel.text = "播放音量:\(volumeProgress.progress)"
        }
    }
    
    func newRecordURL() -> String{
        let designDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        let designDateString = dateFormatter.stringFromDate(designDate)
        let fileName = "/" + designDateString + ".acc"
        let path = appFilePath + fileName

        //在数据中插入新项
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        //2
        let entity = NSEntityDescription.entityForName("MyRecordFile", inManagedObjectContext:managedContext)
        let recordFile = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        //3
        recordFile.setValue(fileName, forKey: "fileName")
        recordFile.setValue(designDateString, forKey: "saveDate")
        //4
        do {
            //下面这一步是是修改的结果保存到coredata中，前面几步只是在managedObjectContext中进行修改，还没有真正保存
            try managedContext.save()
       
        }
        catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        
        return path
    }
    
}


