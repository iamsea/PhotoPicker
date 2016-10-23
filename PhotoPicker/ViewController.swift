//
//  ViewController.swift
//  PhotoPicker
//
//  Created by liangqi on 16/3/4.
//  Copyright © 2016年 dailyios. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController,PhotoPickerControllerDelegate {
    
    var selectModel = [PhotoImageModel]()
    var containerView = UIView()
    
    var triggerRefresh = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.containerView)
        self.checkNeedAddButton()
        self.renderView()
    }
    
    private func checkNeedAddButton(){
        if self.selectModel.count < PhotoPickerController.imageMaxSelectedNum && !hasButton() {
            selectModel.append(PhotoImageModel(type: ModelType.Button, data: nil))
        }
    }
    
    private func hasButton() -> Bool{
        for item in self.selectModel {
            if item.type == ModelType.Button {
                return true
            }
        }
        return false
    }
    
    func removeElement(element: PhotoImageModel?){
        if let current = element {
            self.selectModel = self.selectModel.filter({$0 != current});
        }
    
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barStyle = .default
        
        if self.triggerRefresh {
            self.triggerRefresh = false
            self.updateView()
        }
        
    }
    
    private func updateView(){
        self.clearAll()
        self.checkNeedAddButton()
        self.renderView()
    }
    
    private func renderView(){
        
        if selectModel.count <= 0 {return;}
        
        let totalWidth = UIScreen.main.bounds.width
        let space:CGFloat = 10
        let lineImageTotal = 4
        
        let line = self.selectModel.count / lineImageTotal
        let lastItems = self.selectModel.count % lineImageTotal
        
        let lessItemWidth = (totalWidth - (CGFloat(lineImageTotal) + 1) * space)
        let itemWidth = lessItemWidth / CGFloat(lineImageTotal)
        
        for i in 0 ..< line {
            let itemY = CGFloat(i+1) * space + CGFloat(i) * itemWidth
            for j in 0 ..< lineImageTotal {
                let itemX = CGFloat(j+1) * space + CGFloat(j) * itemWidth
                let index = i * lineImageTotal + j
                self.renderItemView(itemX: itemX, itemY: itemY, itemWidth: itemWidth, index: index)
            }
        }
        
        // last line
        for i in 0..<lastItems{
            let itemX = CGFloat(i+1) * space + CGFloat(i) * itemWidth
            let itemY = CGFloat(line+1) * space + CGFloat(line) * itemWidth
            let index = line * lineImageTotal + i
            self.renderItemView(itemX: itemX, itemY: itemY, itemWidth: itemWidth, index: index)
        }
        
        let totalLine = ceil(Double(self.selectModel.count) / Double(lineImageTotal))
        let containerHeight = CGFloat(totalLine) * itemWidth + (CGFloat(totalLine) + 1) *  space
        self.containerView.frame = CGRect(x:0, y:0, width:totalWidth,  height:containerHeight)
    }
    
    private func renderItemView(itemX:CGFloat,itemY:CGFloat,itemWidth:CGFloat,index:Int){
        let itemModel = self.selectModel[index]
        let button = UIButton(frame: CGRect(x:itemX, y:itemY, width:itemWidth, height: itemWidth))
        button.backgroundColor = UIColor.red
        button.tag = index
        
        if itemModel.type == ModelType.Button {
            button.backgroundColor = UIColor.clear
            button.addTarget(self, action: #selector(ViewController.eventAddImage), for: .touchUpInside)
            button.contentMode = .scaleAspectFill
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.init(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
            button.setImage(UIImage(named: "image_select"), for: UIControlState.normal)
        } else {
            button.addTarget(self, action: #selector(ViewController.eventPreview), for: .touchUpInside)
            if let asset = itemModel.data {
                let pixSize = UIScreen.main.scale * itemWidth
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: pixSize, height: pixSize), contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image, info) -> Void in
                    if image != nil {
                        button.setImage(image, for: UIControlState.normal)
                        button.contentMode = .scaleAspectFill
                        button.clipsToBounds = true
                    }
                })
            }
        }
        self.containerView.addSubview(button)
    }
    
    private func clearAll(){
        for subview in self.containerView.subviews {
            if let view =  subview as? UIButton {
                view.removeFromSuperview()
            }
        }
    }
    
    // MARK: -  button event
    func eventPreview(button:UIButton){
        let preview = SinglePhotoPreviewViewController()
        let data = self.getModelExceptButton()
        preview.selectImages = data
        preview.sourceDelegate = self
        preview.currentPage = button.tag
        self.show(preview, sender: nil)
    }
    
    
    func eventAddImage() {
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // change the style sheet text color
        alert.view.tintColor = UIColor.black
        
        let actionCancel = UIAlertAction.init(title: "取消", style: .cancel, handler: nil)
        let actionCamera = UIAlertAction.init(title: "拍照", style: .default) { (UIAlertAction) -> Void in
            self.selectByCamera()
        }
        
        let actionPhoto = UIAlertAction.init(title: "从手机照片中选择", style: .default) { (UIAlertAction) -> Void in
            self.selectFromPhoto()
        }
        
        alert.addAction(actionCancel)
        alert.addAction(actionCamera)
        alert.addAction(actionPhoto)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    /**
     拍照获取
     */
    private func selectByCamera(){
        // todo take photo task
    }
    
    /**
     从相册中选择图片
     */
    private func selectFromPhoto(){
        
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .authorized:
                self.showLocalPhotoGallery()
                break
            default:
                self.showNoPermissionDailog()
                break
            }
        }
    }
    
    private func showNoPermissionDailog(){
        let alert = UIAlertController.init(title: nil, message: "没有打开相册的权限", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func showLocalPhotoGallery(){
        let picker = PhotoPickerController(type: PageType.RecentAlbum)
        picker.imageSelectDelegate = self
        picker.modalPresentationStyle = .popover
        
        // max select number
        PhotoPickerController.imageMaxSelectedNum = 4
        
        // already selected image num
        let realModel = self.getModelExceptButton()
        PhotoPickerController.alreadySelectedImageNum = realModel.count
        
        self.show(picker, sender: nil)
    }
    
    func onImageSelectFinished(images: [PHAsset]) {
        self.renderSelectImages(images: images)
    }
    
    private func renderSelectImages(images: [PHAsset]){
        for item in images {
            self.selectModel.insert(PhotoImageModel(type: ModelType.Image, data: item), at: 0)
        }
        
        let total = self.selectModel.count;
        if total > PhotoPickerController.imageMaxSelectedNum {
            for i in 0 ..< total {
                let item = self.selectModel[i]
                if item.type == .Button {
                    self.selectModel.remove(at: i)

                }
            }
        }
        self.renderView()
    }
    
    private func getModelExceptButton()->[PhotoImageModel]{
        var newModels = [PhotoImageModel]()
        for i in 0..<self.selectModel.count {
            let item = self.selectModel[i]
            if item.type != .Button {
                newModels.append(item)
            }
        }
        return newModels
    }
    
}

