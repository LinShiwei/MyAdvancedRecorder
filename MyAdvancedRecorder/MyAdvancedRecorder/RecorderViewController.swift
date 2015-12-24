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
class RecorderViewController: UIViewController ,UITableViewDataSource ,UITableViewDelegate{
    // MARK:变量定义
    /// 录音路径
    let appFilePath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]) + "/"
    var myRecordFile = [NSManagedObject]()
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
    @IBOutlet weak var fileNameLabel: UILabel!
    /// 录音按钮
    @IBOutlet weak var recordButton: UIButton!
    /// 播放按钮
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fileListTableView: FileListTableView!
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
    @IBAction func record(sender: AnyObject) {
        if isRecording {
            stopRecord()
            fileListTableView.reloadData()
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
        view.backgroundColor = UIColor(white: 0.3, alpha: 1)
        
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
        
        fileListTableView.backgroundView = UIView.init()
        fileListTableView.backgroundView?.backgroundColor = UIColor(white: 0.4, alpha: 1)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        initMyRecordFile()
        playButton.enabled = false
        if myRecordFile.count > 0 {
            accPath = appFilePath + (myRecordFile[myRecordFile.count-1].valueForKey("fileName")?.description)!
            playButton.enabled = true
        }

        
        let tempManager = NSFileManager.defaultManager()
        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        do{
            let pathString = try tempManager.contentsOfDirectoryAtPath(path)
            NSLog("\(pathString),")
            
        }catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        
    }
    func initMyRecordFile() {
        // 从coredata中获取数据
        //1
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        //2
        let fetchRequest = NSFetchRequest(entityName: "MyRecordFile")
        //3
        do {
            let path = try managedContext.executeFetchRequest(fetchRequest)
            myRecordFile = path as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
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
        let fileName = designDateString + ".acc"
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
            myRecordFile.append(recordFile)
       
        }
        catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        
        return path
    }
    
    // MARK: tableview Datasourse
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileListCell", forIndexPath: indexPath) as! FileListTableViewCell
        let recordFile = myRecordFile[indexPath.row]
        cell.fileNameLabel.text = recordFile.valueForKey("saveDate")?.description
        let cellSelectColorView = UIView()
        cellSelectColorView.backgroundColor = UIColor(white: 0.5, alpha: 1)
        cell.selectedBackgroundView = cellSelectColorView
        return cell
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myRecordFile.count
    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            let fileManager = NSFileManager.defaultManager()
            let path = appFilePath + myRecordFile[indexPath.row].valueForKey("fileName")!.description
            do{
                try fileManager.removeItemAtPath(path)
                
            }catch let error as NSError {
                print("Could not fetch \(error), \(error.userInfo)")
            }
            
            //            从数据库中删除该项
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(myRecordFile[indexPath.row])
            NSLog("\(indexPath.row)")
            do {
                //                保存删除的结果（使删除生效）
                try managedContext.save()
                
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            
            //            再从数组中移除数据
            myRecordFile.removeAtIndex(indexPath.row)
            playButton.enabled = false
            player = nil
            if myRecordFile.count > 0 {
                accPath = appFilePath + (myRecordFile[myRecordFile.count-1].valueForKey("fileName")?.description)!
                playButton.enabled = true
            }
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.reloadData()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor(white: 0.4, alpha: 1)
    }
    //MARK: tableview delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let recordFile = myRecordFile[indexPath.row]
        fileNameLabel.text = recordFile.valueForKey("fileName")?.description
        accPath = appFilePath + (recordFile.valueForKey("fileName")?.description)!
        if isPlaying {
            pausePlay()
        }
        player = nil
        if isRecording {
            stopRecord()
            fileListTableView.reloadData()
        }
        volumeLabel.text = "000"
    }
}


