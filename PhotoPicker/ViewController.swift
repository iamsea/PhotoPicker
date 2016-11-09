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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var selectModel = [PhotoImageModel]()
    var containerView = UIView()
    
//    var triggerRefresh = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.containerView)
        self.checkNeedAddButton()
//        self.renderView()
    }
    
    //判断是否需要加入添加图片按钮
    private func checkNeedAddButton(){
        if self.selectModel.count < PhotoPickerController.imageMaxSelectedNum && !hasButton() {
            selectModel.append(PhotoImageModel(type: ModelType.Button, data: nil))
        }
    }
    
    
    //判断是否有添加按钮的存在
    private func hasButton() -> Bool{
        for item in self.selectModel {
            if item.type == ModelType.Button {
                return true
            }
        }
        return false
    }
    
    func removeElement(element: PhotoImageModel?){
        print(selectModel.count)
        if let current = element {
            self.selectModel = self.selectModel.filter({$0 != current});
        }
        print(selectModel.count)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.tintColor = self.view.tintColor
        
        checkNeedAddButton()
        collectionView.reloadData()
    }

    
    //已选图片预览
    func eventPreview(page: Int){
        let preview = SinglePhotoPreviewViewController()
        let data = self.getModelExceptButton()
        preview.selectImages = data
        preview.sourceDelegate = self
        preview.currentPage = page
        self.show(preview, sender: nil)
    }
    
    
    //点击添加图片按钮
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
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            
            self.present(picker, animated: true, completion: nil)
        }
        else {
            print("不支持拍照")
        }
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
    
    //显示权限管理弹框
    private func showNoPermissionDailog(){
        let alert = UIAlertController.init(title: nil, message: "没有打开相册的权限", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "确定", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //显示图片选择器
    private func showLocalPhotoGallery(){
        let picker = PhotoPickerController(type: PageType.RecentAlbum)
        picker.imageSelectDelegate = self
        picker.modalPresentationStyle = .popover
        
        // max select number
        PhotoPickerController.imageMaxSelectedNum = 8
        
        // already selected image num
        let realModel = self.getModelExceptButton()
        PhotoPickerController.alreadySelectedImageNum = realModel.count
        
        self.show(picker, sender: nil)
    }
    
    //选择图片后回调
    func onImageSelectFinished(images: [PHAsset]) {
        self.renderSelectImages(images: images)
    }
    
    
    //渲染已选择的图片
    func renderSelectImages(images: [PHAsset]){
        for item in images {
            self.selectModel.insert(PhotoImageModel(type: ModelType.Image, data: item), at: 0)
        }
        
        let total = self.selectModel.count
        if total > PhotoPickerController.imageMaxSelectedNum {
            for i in 0 ..< total {
                let item = self.selectModel[i]
                if item.type == .Button {
                    self.selectModel.remove(at: i)

                }
            }
        }
//        self.renderView()
        collectionView.reloadData()
    }
    
    //过滤添加按钮
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
    
    func getCellWidth() -> CGFloat {
        let totalWidth = UIScreen.main.bounds.width
        let space:CGFloat = 8
        let lineImageTotal = 4
        let lessItemWidth = (totalWidth - (CGFloat(lineImageTotal) + 1) * space)
        let itemWidth = lessItemWidth / CGFloat(lineImageTotal)
        return itemWidth
    }
    
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return selectModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var reuseIdentifier: String!
        if selectModel[indexPath.item].type == .Image {
            reuseIdentifier = "ImageCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            let imageView = cell.viewWithTag(1) as! UIImageView
            if let asset = selectModel[indexPath.item].data {
                
                let pixSize = UIScreen.main.scale * getCellWidth()
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: pixSize, height: pixSize), contentMode: PHImageContentMode.aspectFill, options: nil, resultHandler: { (image, info) -> Void in
                    if image != nil {
                        imageView.image = image
                    }
                })
            }
            return cell
        } else {
            reuseIdentifier = "AddImageCell"
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
            let button = cell.viewWithTag(1) as! UIButton
            button.backgroundColor = UIColor.clear
//            button.addTarget(self, action: #selector(ViewController.eventAddImage), for: .touchUpInside)
            button.contentMode = .scaleAspectFill
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.init(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
            button.setImage(UIImage(named: "image_select"), for: UIControlState.normal)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectModel[indexPath.item].type == .Image {
            eventPreview(page: indexPath.item)
        } else {
            eventAddImage()
        }
    }
    
    //collectionView自适应布局
   
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = getCellWidth()
        let size = CGSize(width: width, height: width)
        return size
    }

}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let imageGot = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        UIImageWriteToSavedPhotosAlbum(imageGot, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
        
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func image(image:UIImage,didFinishSavingWithError error:NSError?,contextInfo:AnyObject) {
        
        if error != nil {
            print("保存拍摄的图片失败")
//            SVProgressHUD.showErrorWithStatus("保存失败")
//            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        } else {
            if let asset = fetchLastPhoto() {
                self.renderSelectImages(images: [asset])
            }
//            SVProgressHUD.showSuccessWithStatus("保存成功")
//            SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        }
    }
    
    func fetchLastPhoto() -> PHAsset? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        //        fetchOptions.fetchLimit = 1 // Available in iOS 9
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        if fetchResult.count != 0 {
            let asset = fetchResult.firstObject
            return asset!
        }
        return nil
//        if let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions) {
//            if let asset = fetchResult.firstObject as? PHAsset {
//                let manager = PHImageManager.defaultManager()
//                let targetSize = size == nil ? CGSize(width: asset.pixelWidth, height: asset.pixelHeight) : size!
//                manager.requestImageForAsset(asset,
//                                             targetSize: targetSize,
//                                             contentMode: .AspectFit,
//                                             options: nil,
//                                             resultHandler: { image, info in
//                                                imageCallback(image)
//                })
//            } else {
//                imageCallback(nil)
//            }
//        }
    }
}

