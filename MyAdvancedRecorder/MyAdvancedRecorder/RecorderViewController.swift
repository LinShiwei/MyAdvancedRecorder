//
//  ViewController.swift
//  MyAdvancedRecorder
//
//  Created by Linsw on 15/12/17.
//  Copyright © 2015年 Linsw. All rights reserved.
//


/**
*  @brief  实现基础的录音功能，参考自印象笔记：Swift－制作一个录音机
*  包含的按钮主要有，play、start、stop、next、previous
*  点击start开始录音，stop停止录音，play播放录音，next和previous分别是下一个和上一个录音
*
*  @since 2015.12.16 1.0
*/
import UIKit
import AVFoundation
import CoreData
class RecorderViewController: UIViewController {
    // MARK:变量定义
    let appFilePath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]) + "/"
    var myRecordFile = [NSManagedObject]()
    var isRecording:Bool = false
    var isPlaying:Bool = false
    var recorder:AVAudioRecorder?
    var player:AVAudioPlayer?
    var recorderSettingDic:[String:AnyObject]?
    var accPath:String?
    var volumeTimer:NSTimer!
    var fileNameIndexPathRow :Int?
    // MARK: IBOutlet
    @IBOutlet weak var playerCurrentTimeLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var volumeLabel: UILabel!

    @IBOutlet weak var volumeProgress: UIProgressView!
    @IBOutlet weak var playerSlider: UISlider!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
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
            let path = self.appFilePath + self.fileNameLabel.text! + ".acc"
            let toPath = self.appFilePath + textField!.text! + ".acc"
            self.saveFileName(textField!.text!,atPath: path, toPath: toPath)
            self.fileNameLabel.text = textField!.text!
            self.myRecordFile[self.fileNameIndexPathRow!].setValue(textField!.text!, forKey: "fileName")
            self.accPath = self.appFilePath + textField!.text! + ".acc"
            self.saveToCoreData()
            self.fileListTableView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "取消", style: .Default) { (action: UIAlertAction) -> Void in }
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        presentViewController(alert, animated: true, completion: nil)
    }

    @IBAction func nextRecord(sender: AnyObject) {
        
        if !isRecording,let selectedIndex = fileListTableView.indexPathForSelectedRow {
            if isPlaying {
                stopPlay()
            }
            player = nil
            prepareForPlay(selectedIndex.row + 1)
            let nextIndexPath=NSIndexPath(forRow: selectedIndex.row + 1, inSection: selectedIndex.section);
            fileListTableView.selectRowAtIndexPath(nextIndexPath, animated: true, scrollPosition:.None)
            canPlayNextOrPrevious(nextIndexPath.row, fileCount: myRecordFile.count)
            startPlay()
        }
    }
    @IBAction func previousRecord(sender: AnyObject) {
    
        if !isRecording,let selectedIndex = fileListTableView.indexPathForSelectedRow {
            if isPlaying {
                stopPlay()
            }
            player = nil
            prepareForPlay(selectedIndex.row - 1)
            let previousIndexPath=NSIndexPath(forRow: selectedIndex.row - 1, inSection: selectedIndex.section);
            fileListTableView.selectRowAtIndexPath(previousIndexPath, animated: true, scrollPosition:.None)
            canPlayNextOrPrevious(previousIndexPath.row, fileCount: myRecordFile.count)
            startPlay()
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
        recorderSettingDic = initSettingDic()
        addNewRecordFileObjectToMyRecordFile()
        accPath = getNewRecordURL()
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
        isRecording = false
        isPlaying = false
        initSession()
        myRecordFile = initMyRecordFile()
        recorderSettingDic = initSettingDic()
        initPlayButton()
        view.backgroundColor = themeOne.viewBackgroundColor
        fileListTableView.backgroundView = UIView.init()
        fileListTableView.backgroundView?.backgroundColor = themeOne.tableViewBackgroundColor
        
        self.navigationController!.navigationBar.barTintColor = themeOne.navigationBarColor


    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    func initSettingDic()->[String:AnyObject]{
        let settingObject = fetchSettingObject()
        if settingObject.count > 0 {
            print("find setting parameter")
            let settingDic=[
                AVFormatIDKey:settingObject[0].valueForKey("formatIDKey")!,
                AVNumberOfChannelsKey:settingObject[0].valueForKey("numberOfChannelsKey")!,
                AVEncoderAudioQualityKey:settingObject[0].valueForKey("qualityKey")!,
                AVEncoderBitRateKey:settingObject[0].valueForKey("bitRateKey")!,
                AVSampleRateKey:settingObject[0].valueForKey("sampleRateKey")!
            ]
            return settingDic
        }else{
            print("no find")
            let settingDic=[
                AVFormatIDKey:NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey:2,
                AVEncoderAudioQualityKey:AVAudioQuality.Medium.rawValue,
                AVEncoderBitRateKey:320000,
                AVSampleRateKey:44100.0
            ]
            let managedContext = getManagedContext()
            let entity = NSEntityDescription.entityForName("SettingParameter", inManagedObjectContext:managedContext)
            let para = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            para.setValue(NSNumber(unsignedInt: kAudioFormatMPEG4AAC), forKey: "formatIDKey")
            para.setValue(2, forKey: "numberOfChannelsKey")
            para.setValue(AVAudioQuality.Medium.rawValue, forKey: "qualityKey")
            para.setValue(320000, forKey: "bitRateKey")
            para.setValue(44100.0, forKey: "sampleRateKey")
            do {
                try managedContext.save()
            }catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            return settingDic
        }
    }
    func initMyRecordFile()->[NSManagedObject] {
        let managedContext = getManagedContext()
        let fetchRequest = NSFetchRequest(entityName: "MyRecordFile")
        var fileObject = [NSManagedObject]()
        do {
            let path = try managedContext.executeFetchRequest(fetchRequest)
            fileObject = path as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return fileObject
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

    //MARK: 自定义函数
    func prepareForPlay(indexPathRow:Int){
        let recordFile = myRecordFile[indexPathRow]
        fileNameLabel.text = recordFile.valueForKey("fileName")?.description
        fileNameIndexPathRow = indexPathRow
        accPath = appFilePath + (recordFile.valueForKey("fileName")?.description)! + ".acc"
    }
    func getNewRecordURL() -> String{
        let fileNames = myRecordFile.last!.valueForKey("fileName") as! String
        return appFilePath + fileNames + ".acc"
    }
    func addNewRecordFileObjectToMyRecordFile(){
        let designDateString = dateString()
        let fileName = designDateString
        let managedContext = getManagedContext()
        let entity = NSEntityDescription.entityForName("MyRecordFile", inManagedObjectContext:managedContext)
        let recordFile = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
        recordFile.setValue(fileName, forKey: "fileName")
        recordFile.setValue(designDateString, forKey: "recordDate")
        do {
            try managedContext.save()
            myRecordFile.append(recordFile)
            fileNameLabel.text = fileName
            fileNameIndexPathRow = myRecordFile.count - 1
        }
        catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
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
    }
    func saveFileName(name:String,atPath:String,toPath:String) {
        let tempManager = NSFileManager.defaultManager()
        do{
            
            try tempManager.moveItemAtPath(atPath, toPath: toPath)
        }catch let error as NSError {
            print("Could not moveItemAtPath \(error), \(error.userInfo)")
        }
        
    }
    func saveToCoreData() {
        let managedContext = getManagedContext()
        do {
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
    func canPlayNextOrPrevious(selectedIndexRow:Int,fileCount:Int){
        if selectedIndexRow == (fileCount - 1) {
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
    func fetchSettingObject()->[NSManagedObject]{
        var object=[NSManagedObject]()
        let managedContext = getManagedContext()
        let fetchRequest = NSFetchRequest(entityName: "SettingParameter")
        do {
            object = try managedContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return object
    }
    func getManagedContext()->NSManagedObjectContext{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }
}
//MARK: TableViewDelegate
extension RecorderViewController:UITableViewDelegate{
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = themeOne.tableViewCellBackgroundColor
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        prepareForPlay(indexPath.row)
        canPlayNextOrPrevious(indexPath.row, fileCount: myRecordFile.count)
        stopRecordAndPlay()
    }
}
//MARK: TableViewDataSource
extension RecorderViewController:UITableViewDataSource{
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fileListCell", forIndexPath: indexPath) as! FileListTableViewCell
        let recordFile = myRecordFile[indexPath.row]
        cell.fileNameLabel.text = recordFile.valueForKey("fileName")?.description
        cell.recordDateLabel.text = recordFile.valueForKey("recordDate")?.description
        let intDuration = Int((recordFile.valueForKey("duration") as! Double))
        cell.recordDurationLabel.text = "Duration:" + String(intDuration) + " s"
        let cellSelectColorView = UIView()
        cellSelectColorView.backgroundColor = themeOne.tableViewCellSeletedBackgroundColor
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
            let managedContext = getManagedContext()
            managedContext.deleteObject(myRecordFile[indexPath.row])
            do {
                try managedContext.save()
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            myRecordFile.removeAtIndex(indexPath.row)
            initPlayButton()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            tableView.reloadData()
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

}
//MARK: AVAudioPlayerDelegate
extension RecorderViewController:AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stopPlay()
        }
    }
}

