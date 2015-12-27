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
class RecorderViewController: UIViewController ,UITableViewDataSource ,UITableViewDelegate,AVAudioPlayerDelegate{
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
    var fileNameIndexPathRow :Int?
    // MARK: IBOutlet
    @IBOutlet weak var playerCurrentTimeLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var volumeProgress: UIProgressView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var playerSlider: UISlider!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var fileListTableView: FileListTableView!
    //MARK: IBAction
    @IBAction func sliderTouchUpInside(sender: AnyObject) {
        player?.prepareToPlay()
        player?.play()
    }
    @IBAction func sliderTouchUpOutside(sender: AnyObject) {
        player?.prepareToPlay()
        player?.play()
    }
    @IBAction func slliderTouchDown(sender: AnyObject) {
        player?.stop()
    }
    @IBAction func sliderChanged(sender: AnyObject) {
        player?.currentTime = Double(playerSlider.value)
    }
    @IBAction func editFileNameButton(sender: AnyObject) {
        stopRecordAndPlay()
        let alert = UIAlertController(title: "设置新名称", message: nil, preferredStyle: .Alert)
        let saveAction = UIAlertAction(title: "保存", style: .Default,handler: { (action:UIAlertAction) -> Void in
            let textField = alert.textFields!.first
            self.saveFileName(textField!.text!)
            self.fileListTableView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "取消", style: .Default) { (action: UIAlertAction) -> Void in }
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    @IBAction func nextRecord(sender: AnyObject) {
        if isRecording {
            print("Error can't play next record while recording")
        }else{
            if let selectedIndex = fileListTableView.indexPathForSelectedRow {
                if isPlaying {
                    stopPlay()
                }
                player = nil
                prepareForPlay(selectedIndex.row + 1)
                let nextIndexPath=NSIndexPath(forRow: selectedIndex.row + 1, inSection: selectedIndex.section);
                fileListTableView.selectRowAtIndexPath(nextIndexPath, animated: true, scrollPosition:.None)
                canPlayNextOrPrevious(nextIndexPath.row)
                startPlay()
            }

        }
    
    }
    @IBAction func previousRecord(sender: AnyObject) {
        if isRecording {
            print("Error can't play previous record while recording")
        }else{
            if let selectedIndex = fileListTableView.indexPathForSelectedRow {
                if isPlaying {
                    stopPlay()
                }
                player = nil
                prepareForPlay(selectedIndex.row - 1)
                let previousIndexPath=NSIndexPath(forRow: selectedIndex.row - 1, inSection: selectedIndex.section);
                fileListTableView.selectRowAtIndexPath(previousIndexPath, animated: true, scrollPosition:.None)
                canPlayNextOrPrevious(previousIndexPath.row)
                startPlay()
            }
            
        }
    }
    @IBAction func playRecord(sender: AnyObject) {
        if isPlaying {
            pausePlay()
        }else{
            startPlay()
        }
    }
    func startPlay(){
        isPlaying = !isPlaying
        playerSlider.enabled = true
        playButton.setImage(UIImage.init(named: "pausePlay"), forState: UIControlState.Normal)
        if player == nil{
            do{
                player = try AVAudioPlayer(contentsOfURL: NSURL(string: accPath!)!)
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        player!.delegate = self
        //开启仪表计数功能
        player!.meteringEnabled = true
        volumeTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self,
            selector: "playTimer", userInfo: nil, repeats: true)
        playerSlider.maximumValue = Float(player!.duration)
        player!.prepareToPlay()
        player!.play()
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
    func stopPlay(){
        player!.stop()
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "playRecord"), forState: UIControlState.Normal)
        recordButton.enabled = true
        
        volumeTimer.invalidate()
        volumeTimer = nil
        playerCurrentTimeLabel.text = "0:0:0"
        playerSlider.enabled = false
        playerSlider.value = 0
    }
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
        playerSlider.enabled = false
        isRecording = !isRecording
        recordButton.setImage(UIImage.init(named: "stopRecord"),forState: UIControlState.Normal)
        do{
            /// init the recorder object
            recorder = try AVAudioRecorder(URL: NSURL(string: accPath!)!, settings: recorderSettingDic!)
        }
        catch let error as NSError {
            print("Could not init recorder \(error), \(error.userInfo)")
        }
        recorder!.prepareToRecord()
        recorder!.record()
        //开启仪表计数功能
        recorder!.meteringEnabled = true
        volumeTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self,
            selector: "recordTimer", userInfo: nil, repeats: true)
        playButton.enabled = false
        player = nil
    }
    func stopRecord() {
        isRecording = !isRecording
        recordButton.setImage(UIImage.init(named: "startRecord"),forState: UIControlState.Normal)
        let recordDuration = recorder!.currentTime
        myRecordFile[fileNameIndexPathRow!].setValue(recordDuration, forKey: "duration")
        saveToCoreData()
        recorder!.stop()
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
        playerSlider.enabled = false
        nextButton.enabled = false
        previousButton.enabled = false
        // Do any additional setup after loading the view, typically from a nib.
        isRecording = false
        isPlaying = false
        initSession()
        recorderSettingDic=[
            AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey:2,
            AVEncoderAudioQualityKey:AVAudioQuality.Medium.rawValue,
            AVEncoderBitRateKey:320000,
            AVSampleRateKey:44100.0
        ]
        view.backgroundColor = UIColor(white: 0.3, alpha: 1)
        fileListTableView.backgroundView = UIView.init()
        fileListTableView.backgroundView?.backgroundColor = UIColor(white: 0.4, alpha: 1)
        
        initMyRecordFile()
        initPlayButton()

    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        
//        let tempManager = NSFileManager.defaultManager()
//        let path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
//        do{
//            let pathString = try tempManager.contentsOfDirectoryAtPath(path)
//            NSLog("\(pathString),")
//            
//        }catch let error as NSError {
//            print("Could not fetch \(error), \(error.userInfo)")
//        }
    }
    func initMyRecordFile() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "MyRecordFile")
        do {
            let path = try managedContext.executeFetchRequest(fetchRequest)
            myRecordFile = path as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    func initSession(){
        /// 初始化录音器
        let session:AVAudioSession = AVAudioSession.sharedInstance()
        /// 设置录音类型
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        /// 设置支持后台
        try! session.setActive(true)
    }
    func initPlayButton(){
        player = nil
        playButton.enabled = false
        if myRecordFile.count > 0 {
            let fileName = myRecordFile[myRecordFile.count-1].valueForKey("fileName")?.description
            accPath = appFilePath + fileName! + ".acc"
            playButton.enabled = true
            fileNameLabel.text = fileName
            fileNameIndexPathRow = myRecordFile.count-1
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
    func playTimer(){
        player!.updateMeters() // 刷新音量数据
        let maxVolumedB:Float = player!.peakPowerForChannel(0) //获取音量最大值
        let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
        volumeProgress.progress = Float(maxVolume)
        volumeLabel.text = "播放音量:\(volumeProgress.progress)"
        playerSlider.value = Float(player!.currentTime)
        playerCurrentTimeLabel.text = changeTimeFormat(player!.currentTime)
    }
    func recordTimer(){
        recorder!.updateMeters() // 刷新音量数据
        let maxVolumedB:Float = recorder!.peakPowerForChannel(0) //获取音量最大值
        let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
        volumeProgress.progress = Float(maxVolume)
        volumeLabel.text = "录音音量:\(volumeProgress.progress)"
    }
    // MARK: audio
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
           stopPlay()
        }
    }
    // MARK: tableview Datasourse
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileListCell", forIndexPath: indexPath) as! FileListTableViewCell
        let recordFile = myRecordFile[indexPath.row]
        cell.fileNameLabel.text = recordFile.valueForKey("fileName")?.description
        cell.recordDateLabel.text = recordFile.valueForKey("recordDate")?.description
        let intDuration = Int((recordFile.valueForKey("duration") as! Double))
        cell.recordDurationLabel.text = "Duration:" + String(intDuration) + " s"
        let cellSelectColorView = UIView()
        cellSelectColorView.backgroundColor = UIColor(white: 0.5, alpha: 1)
        cellSelectColorView.layer.masksToBounds = true
        cell.selectedBackgroundView = cellSelectColorView
        let fileManager = NSFileManager.defaultManager()
        let path = appFilePath + recordFile.valueForKey("fileName")!.description + ".acc"
        do{
            let dictionary = try fileManager.attributesOfItemAtPath(path) as NSDictionary
            cell.fileSizeLabel.text = String((dictionary.fileSize())/1024)+"KB"
        }catch let error as NSError {
            print("Could not get attributes \(error), \(error.userInfo)")
        }
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
            let path = appFilePath + myRecordFile[indexPath.row].valueForKey("fileName")!.description + ".acc"
            do{
                try fileManager.removeItemAtPath(path)
            }catch let error as NSError {
                print("Could not removeItemAtPath \(error), \(error.userInfo)")
            }
//            从数据库中删除该项
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            managedContext.deleteObject(myRecordFile[indexPath.row])
            do {
//                保存删除的结果（使删除生效）
                try managedContext.save()
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
//            再从数组中移除数据
            myRecordFile.removeAtIndex(indexPath.row)
            initPlayButton()
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
        prepareForPlay(indexPath.row)
        canPlayNextOrPrevious(indexPath.row)
        stopRecordAndPlay()
    }
    //MARK: 自定义函数
    func prepareForPlay(indexPathRow:Int){
        let recordFile = myRecordFile[indexPathRow]
        fileNameLabel.text = recordFile.valueForKey("fileName")?.description
        fileNameIndexPathRow = indexPathRow
        accPath = appFilePath + (recordFile.valueForKey("fileName")?.description)! + ".acc"
    }
    func newRecordURL() -> String{
        let designDateString = dateString()
        let fileName = designDateString
        let path = appFilePath + fileName + ".acc"
        //在数据中插入新项
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        //2
        let entity = NSEntityDescription.entityForName("MyRecordFile", inManagedObjectContext:managedContext)
        let recordFile = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        //3
        recordFile.setValue(fileName, forKey: "fileName")
        recordFile.setValue(designDateString, forKey: "recordDate")
        //4
        do {
            //下面这一步是是修改的结果保存到coredata中，前面几步只是在managedObjectContext中进行修改，还没有真正保存
            try managedContext.save()
            myRecordFile.append(recordFile)
            fileNameLabel.text = fileName
            fileNameIndexPathRow = myRecordFile.count - 1
        }
        catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        return path
    }

    func stopRecordAndPlay() {
        if isPlaying {
            stopPlay()
        }
        player = nil
        if isRecording {
            stopRecord()
            fileListTableView.reloadData()
        }
        volumeLabel.text = "stop success"
    }
    func saveFileName(name:String) {
        let tempManager = NSFileManager.defaultManager()
        do{
            let path = appFilePath + fileNameLabel.text! + ".acc"
            let toPath = appFilePath + name + ".acc"
            try tempManager.moveItemAtPath(path, toPath: toPath)
        }catch let error as NSError {
            print("Could not moveItemAtPath \(error), \(error.userInfo)")
        }
        fileNameLabel.text = name
        
        myRecordFile[fileNameIndexPathRow!].setValue(name, forKey: "fileName")
        accPath = appFilePath + name + ".acc"
        saveToCoreData()
    }
    func saveToCoreData() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        do {
            //下面这一步是是修改的结果保存到coredata中
            try managedContext.save()
        }
        catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    func dateString()->String {
        let designDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return  dateFormatter.stringFromDate(designDate)
    }
    func canPlayNextOrPrevious(selectedIndexRow:Int){
        if selectedIndexRow == (myRecordFile.count - 1) {
            nextButton.enabled = false
        }else{
            nextButton.enabled = true
        }
        if selectedIndexRow == 0 {
            previousButton.enabled = false
        }else{
            previousButton.enabled = true
        }
    }
    func changeTimeFormat(time:Double)->String {
        let hour = Int(time/3600)
        let minute = Int((time%3600)/60)
        let second = Int(time%60)
        return String(hour)+":"+String(minute)+":"+String(second)
    }
}


