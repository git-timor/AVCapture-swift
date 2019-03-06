//
//  ViewController.swift
//  AVCapture
//
//  Created by 周周旗 on 2019/3/5.
//  Copyright © 2019 ZQ. All rights reserved.
//
/**
 技能 : 1.UIView动画 2.二维码扫描
 坑
 1.deviceInput的声明
 2.Privacy - Camera Usage Description 开启相机权限
 3.AVMetadataMachineReadableCodeObject
 */
import UIKit
import AVFoundation

class AVCaptureVC: UIViewController {
    //Block输出扫描结果
    var compeletionCallBack:((_ result:String) ->())?
    
    // 扫描线
    private lazy var scanLine = UIImageView(frame: CGRect(x: 25, y: 100, width: self.view.bounds.width - 50, height: 2))
    
    // 扫描框
    private lazy var scan_bg_kuang = UIImageView(frame: CGRect(x: 25, y: 100, width:self.view.bounds.width - 50, height: self.view.bounds.width - 50))
    
    //AVCapture核心类
    private lazy var session = AVCaptureSession.init()
    
    //给Session添加input输入
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        // 获取摄像头
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        do{
            // 创建输入对象
            let input = try AVCaptureDeviceInput(device: device!)
            return input
        }catch
        {
            print(error)
            return nil
        }
    }()
    
    //给Session添加output输出
    private lazy var output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    
    // 创建预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.frame = UIScreen.main.bounds
        return layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        startAnimation()
        checkCameraStatus()
    }
}

// MARK: - 动画效果设置
extension AVCaptureVC {
    func setUpUI(){
        setUpBgkuang()
        setUpScanLine()
    }
    //    设置扫描框
    func setUpBgkuang(){
        view.addSubview(scan_bg_kuang)
        scan_bg_kuang.image = UIImage(named: "scann_kuang")
    }
    //    设置扫描线
    func setUpScanLine() {
        view.insertSubview(scanLine, aboveSubview: scan_bg_kuang)
        scanLine.image = UIImage(named: "scann_line")
    }
    
    /// 开启动画效果
    func startAnimation(){
        let originCenter = scanLine.center.y
        let opts: UIView.AnimationOptions = [.autoreverse , .repeat]
        UIView.animate(withDuration: 2, delay: 0.1, options: opts, animations: {
            self.scanLine.center.y += self.scan_bg_kuang.bounds.height
        }) { (isfinish:Bool) in
            self.scanLine.center.y = originCenter
        }
    }
    
    /// 删除动画效果
    func removeAnimation(){
        scanLine.layer.removeAllAnimations()
    }
}

// MARK: - 设置二维码扫描主体
extension AVCaptureVC{
    //1.判断相机是否开启
    func checkCameraStatus(){
        let mediaType = AVMediaType.video
        //>1.核心方法authorizationStatus判断device权限是否开启
        /**
         case notDetermined: 用户还未决定是否开启
         
         case restricted: 此应用程序没有被授权访问的照片数据
         
         case denied: 用户明确拒绝开启
         
         case authorized: 用户同意开启权限
         */
        let status : AVAuthorizationStatus =  AVCaptureDevice.authorizationStatus(for: mediaType)
        switch status {
        case AVAuthorizationStatus.notDetermined,AVAuthorizationStatus.authorized:
            setupSession()
        default:
            tipSetting()
        }
    }
    //    开启camera
    func setupCamera() {
        tipSetting()
    }
    //    创建session
    func setupSession(){
        if session.canAddInput(deviceInput!) {
            session.addInput(deviceInput!)
        }else{
            return
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }else{
            return
        }
        //1.设置sesson的分辨率
        session.sessionPreset = .high
        // 条码类型 AVMetadataObjectTypeQRCode
        // 注意: 设置能够解析的数据类型, 一定要在输出对象添加到会员之后设置, 否则会报错
        output.metadataObjectTypes =  [AVMetadataObject.ObjectType.qr]
        // 设置输出对象的代理, 只要解析成功就会通知代理
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // 添加预览图层,必须要插入到最下层的图层
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // session开始扫描
        session.startRunning()
    }
    
    //    提醒设置开启
    func tipSetting() {
        let alert = UIAlertController.init(title: "温馨提示", message: "请在iPhone的“设置－隐私－相机”选项中，允许访问你的相机", preferredStyle: .alert)
        let agreeAction = UIAlertAction(title: "好", style: .default) { (action) in
            self .present(alert, animated: true, completion: {})
        }
        alert.addAction(agreeAction)
    }
}

// MARK: - 代理AVCaptureMetadataOutputObjectsDelegate

extension AVCaptureVC:AVCaptureMetadataOutputObjectsDelegate{
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if metadataObjects.count > 0  {
            //            此处回传扫描返回的值 ，这里注意要as强转为`AVMetadataMachineReadableCodeObject`才会有stringValue
            if let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                if (compeletionCallBack != nil)  {
                    compeletionCallBack?(metadataObj.stringValue!)
                }
                session.stopRunning()
                removeAnimation()
            }
        }
    }
}

