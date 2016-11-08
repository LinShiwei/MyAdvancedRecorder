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

let theme = themeOne

class RecorderViewController: UIViewController {
    // MARK:变量定义
    let appFilePath = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]) + "/"
    var myRecordFile = [NSManagedObject]()
    var isRecording:Bool = false
    var isPlaying:Bool = false
    var recorder:AVAudioRecorder?
    var player:AVAudioPlayer?
    var recorderSettingDic:[String:AnyObject]?
    var accPath:String?
    var volumeTimer:Timer!
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
    @IBAction func sliderTouchUpInside(_ sender: AnyObject) {
        player?.prepareToPlay()
        player?.play()
    }
    @IBAction func sliderTouchUpOutside(_ sender: AnyObject) {
        player?.prepareToPlay()
        player?.play()
    }
    @IBAction func slliderTouchDown(_ sender: AnyObject) {
        player?.stop()
    }
    @IBAction func sliderChanged(_ sender: AnyObject) {
        player?.currentTime = Double(playerSlider.value)
    }
    @IBAction func editFileNameButton(_ sender: AnyObject) {
        stopRecordAndPlay()
        let alert = UIAlertController(title: "设置新名称", message: nil, preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "保存", style: .default,handler: { (action:UIAlertAction) -> Void in
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
        let cancelAction = UIAlertAction(title: "取消", style: .default) { (action: UIAlertAction) -> Void in }
        alert.addTextField { (textField: UITextField) -> Void in }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func nextRecord(_ sender: AnyObject) {
        
        if !isRecording,let selectedIndex = fileListTableView.indexPathForSelectedRow {
            if isPlaying {
                stopPlay()
            }
            player = nil
            prepareForPlay((selectedIndex as NSIndexPath).row + 1)
            let nextIndexPath=IndexPath(row: (selectedIndex as NSIndexPath).row + 1, section: (selectedIndex as NSIndexPath).section);
            fileListTableView.selectRow(at: nextIndexPath, animated: true, scrollPosition:.none)
            canPlayNextOrPrevious((nextIndexPath as NSIndexPath).row, fileCount: myRecordFile.count)
            startPlay()
        }
    }
    @IBAction func previousRecord(_ sender: AnyObject) {
    
        if !isRecording,let selectedIndex = fileListTableView.indexPathForSelectedRow {
            if isPlaying {
                stopPlay()
            }
            player = nil
            prepareForPlay((selectedIndex as NSIndexPath).row - 1)
            let previousIndexPath=IndexPath(row: (selectedIndex as NSIndexPath).row - 1, section: (selectedIndex as NSIndexPath).section);
            fileListTableView.selectRow(at: previousIndexPath, animated: true, scrollPosition:.none)
            canPlayNextOrPrevious((previousIndexPath as NSIndexPath).row, fileCount: myRecordFile.count)
            startPlay()
        }
            
        
    }
    @IBAction func playRecord(_ sender: AnyObject) {
        if isPlaying {
            pausePlay()
        }else{
            startPlay()
        }
    }
    func startPlay(){
        isPlaying = !isPlaying
        playerSlider.isEnabled = true
        playButton.setImage(UIImage.init(named: "pausePlay"), for: UIControlState())
        if player == nil{
            do{
                player = try AVAudioPlayer(contentsOf: URL(string: accPath!)!)
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        player!.delegate = self
        //开启仪表计数功能
        player!.isMeteringEnabled = true
        volumeTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self,
            selector: #selector(RecorderViewController.playTimer), userInfo: nil, repeats: true)
        playerSlider.maximumValue = Float(player!.duration)
        player!.prepareToPlay()
        player!.play()
        recordButton.isEnabled = false
    }
    func pausePlay(){
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "playRecord"), for: UIControlState())
        recordButton.isEnabled = true
        player!.pause()
        //暂停定时器
        volumeTimer.invalidate()
        volumeTimer = nil
    }
    func stopPlay(){
        player!.stop()
        isPlaying = !isPlaying
        playButton.setImage(UIImage.init(named: "playRecord"), for: UIControlState())
        recordButton.isEnabled = true
        
        volumeTimer.invalidate()
        volumeTimer = nil
        playerCurrentTimeLabel.text = "0:0:0"
        playerSlider.isEnabled = false
        playerSlider.value = 0
    }
    @IBAction func record(_ sender: AnyObject) {
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
        playerSlider.isEnabled = false
        isRecording = !isRecording
        recordButton.setImage(UIImage.init(named: "stopRecord"),for: UIControlState())
        do{
            /// init the recorder object
            recorder = try AVAudioRecorder(url: URL(string: accPath!)!, settings: recorderSettingDic!)
        }
        catch let error as NSError {
            print("Could not init recorder \(error), \(error.userInfo)")
        }
        recorder!.prepareToRecord()
        recorder!.record()
        //开启仪表计数功能
        recorder!.isMeteringEnabled = true
        volumeTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self,
            selector: #selector(RecorderViewController.recordTimer), userInfo: nil, repeats: true)
        playButton.isEnabled = false
        player = nil
    }
    func stopRecord() {
        isRecording = !isRecording
        recordButton.setImage(UIImage.init(named: "startRecord"),for: UIControlState())
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
        playButton.isEnabled = true
    }
    // MARK: 初始化
    override func viewDidLoad() {
        
        super.viewDidLoad()
        playerSlider.isEnabled = false
        nextButton.isEnabled = false
        previousButton.isEnabled = false
        isRecording = false
        isPlaying = false
        initSession()
        myRecordFile = initMyRecordFile()
        recorderSettingDic = initSettingDic()
        initPlayButton()
        view.backgroundColor = theme.viewBackgroundColor
        fileListTableView.backgroundView = UIView.init()
        fileListTableView.backgroundView?.backgroundColor = theme.tableViewBackgroundColor
        
        self.navigationController!.navigationBar.barTintColor = theme.navigationBarColor


    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    func initSettingDic()->[String:AnyObject]{
        let settingObject = fetchSettingObject()
        if settingObject.count > 0 {
            print("find setting parameter")
            let settingDic=[
                AVFormatIDKey:settingObject[0].value(forKey: "formatIDKey")!,
                AVNumberOfChannelsKey:settingObject[0].value(forKey: "numberOfChannelsKey")!,
                AVEncoderAudioQualityKey:settingObject[0].value(forKey: "qualityKey")!,
                AVEncoderBitRateKey:settingObject[0].value(forKey: "bitRateKey")!,
                AVSampleRateKey:settingObject[0].value(forKey: "sampleRateKey")!
            ]
            return settingDic as [String : AnyObject]
        }else{
            print("no find")
            let settingDic=[
                AVFormatIDKey:NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                AVNumberOfChannelsKey:2,
                AVEncoderAudioQualityKey:AVAudioQuality.medium.rawValue,
                AVEncoderBitRateKey:320000,
                AVSampleRateKey:44100.0
            ] as [String : Any]
            let managedContext = getManagedContext()
            let entity = NSEntityDescription.entity(forEntityName: "SettingParameter", in:managedContext)
            let para = NSManagedObject(entity: entity!, insertInto: managedContext)
            para.setValue(NSNumber(value: kAudioFormatMPEG4AAC as UInt32), forKey: "formatIDKey")
            para.setValue(2, forKey: "numberOfChannelsKey")
            para.setValue(AVAudioQuality.medium.rawValue, forKey: "qualityKey")
            para.setValue(320000, forKey: "bitRateKey")
            para.setValue(44100.0, forKey: "sampleRateKey")
            do {
                try managedContext.save()
            }catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            return settingDic as [String : AnyObject]
        }
    }
    func initMyRecordFile()->[NSManagedObject] {
        let managedContext = getManagedContext()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "MyRecordFile")
        var fileObject = [NSManagedObject]()
        do {
            let path = try managedContext.fetch(fetchRequest)
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
        playButton.isEnabled = false
        if myRecordFile.count > 0 {
            let fileName = (myRecordFile[myRecordFile.count-1].value(forKey: "fileName") as AnyObject).description
            accPath = appFilePath + fileName! + ".acc"
            playButton.isEnabled = true
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
        let maxVolumedB:Float = player!.peakPower(forChannel: 0) //获取音量最大值
        let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
        volumeProgress.progress = Float(maxVolume)
        volumeLabel.text = "播放音量:\(volumeProgress.progress)"
        playerSlider.value = Float(player!.currentTime)
        playerCurrentTimeLabel.text = changeTimeFormat(player!.currentTime)
    }
    func recordTimer(){
        recorder!.updateMeters() // 刷新音量数据
        let maxVolumedB:Float = recorder!.peakPower(forChannel: 0) //获取音量最大值
        let maxVolume:Double = pow(Double(10), Double(maxVolumedB/10))
        volumeProgress.progress = Float(maxVolume)
        volumeLabel.text = "录音音量:\(volumeProgress.progress)"
    }

    //MARK: 自定义函数
    func prepareForPlay(_ indexPathRow:Int){
        let recordFile = myRecordFile[indexPathRow]
        fileNameLabel.text = (recordFile.value(forKey: "fileName") as AnyObject).description
        fileNameIndexPathRow = indexPathRow
        accPath = appFilePath + ((recordFile.value(forKey: "fileName") as AnyObject).description)! + ".acc"
    }
    func getNewRecordURL() -> String{
        let fileNames = myRecordFile.last!.value(forKey: "fileName") as! String
        return appFilePath + fileNames + ".acc"
    }
    func addNewRecordFileObjectToMyRecordFile(){
        let designDateString = dateString()
        let fileName = designDateString
        let managedContext = getManagedContext()
        let entity = NSEntityDescription.entity(forEntityName: "MyRecordFile", in:managedContext)
        let recordFile = NSManagedObject(entity: entity!, insertInto: managedContext)
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
    func saveFileName(_ name:String,atPath:String,toPath:String) {
        let tempManager = FileManager.default
        do{
            
            try tempManager.moveItem(atPath: atPath, toPath: toPath)
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
        let designDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return  dateFormatter.string(from: designDate)
    }
    func canPlayNextOrPrevious(_ selectedIndexRow:Int,fileCount:Int){
        if selectedIndexRow == (fileCount - 1) {
            nextButton.isEnabled = false
        }else{
            nextButton.isEnabled = true
        }
        if selectedIndexRow == 0 {
            previousButton.isEnabled = false
        }else{
            previousButton.isEnabled = true
        }
    }
    func changeTimeFormat(_ time:Double)->String {
        let hour = Int(time/3600)
        let minute = Int((time.truncatingRemainder(dividingBy: 3600))/60)
        let second = Int(time.truncatingRemainder(dividingBy: 60))
        return String(hour)+":"+String(minute)+":"+String(second)
    }
    func fetchSettingObject()->[NSManagedObject]{
        var object=[NSManagedObject]()
        let managedContext = getManagedContext()
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "SettingParameter")
        do {
            object = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return object
    }
    func getManagedContext()->NSManagedObjectContext{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.managedObjectContext
    }
}
//MARK: TableViewDelegate
extension RecorderViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = theme.tableViewCellBackgroundColor
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        prepareForPlay((indexPath as NSIndexPath).row)
        canPlayNextOrPrevious((indexPath as NSIndexPath).row, fileCount: myRecordFile.count)
        stopRecordAndPlay()
    }
}
//MARK: TableViewDataSource
extension RecorderViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileListCell", for: indexPath) as! FileListTableViewCell
        let recordFile = myRecordFile[(indexPath as NSIndexPath).row]
        cell.fileNameLabel.text = (recordFile.value(forKey: "fileName") as AnyObject).description
        cell.recordDateLabel.text = (recordFile.value(forKey: "recordDate") as AnyObject).description
        let intDuration = Int((recordFile.value(forKey: "duration") as! Double))
        cell.recordDurationLabel.text = "Duration:" + String(intDuration) + " s"
        let cellSelectColorView = UIView()
        cellSelectColorView.backgroundColor = theme.tableViewCellSeletedBackgroundColor
        cellSelectColorView.layer.masksToBounds = true
        cell.selectedBackgroundView = cellSelectColorView
        let fileManager = FileManager.default
        let path = appFilePath + (recordFile.value(forKey: "fileName")! as AnyObject).description + ".acc"
        do{
            let dictionary = try fileManager.attributesOfItem(atPath: path) as NSDictionary
            cell.fileSizeLabel.text = String((dictionary.fileSize())/1024)+"KB"
        }catch let error as NSError {
            print("Could not get attributes \(error), \(error.userInfo)")
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myRecordFile.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let fileManager = FileManager.default
            let path = appFilePath + (myRecordFile[(indexPath as NSIndexPath).row].value(forKey: "fileName")! as AnyObject).description + ".acc"
            do{
                try fileManager.removeItem(atPath: path)
            }catch let error as NSError {
                print("Could not removeItemAtPath \(error), \(error.userInfo)")
            }
            let managedContext = getManagedContext()
            managedContext.delete(myRecordFile[(indexPath as NSIndexPath).row])
            do {
                try managedContext.save()
            }
            catch let error as NSError {
                print("Could not save \(error), \(error.userInfo)")
            }
            myRecordFile.remove(at: (indexPath as NSIndexPath).row)
            initPlayButton()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }

}
//MARK: AVAudioPlayerDelegate
extension RecorderViewController:AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stopPlay()
        }
    }
}

