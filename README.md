# PhotoPicker

高仿iOS微信图片选择器`swift`版，基于`Photokit`（photo picker like WeChat by PhotoKit）

![](./swift-wechar-photo-picker.gif)

## 支持版本
```
iOS8.0+
```


## 使用说明

在需要使用的地方，直接调用以下代码即可：

```
let picker = PhotoPickerController(type: PageType.RecentAlbum)
picker.imageSelectDelegate = self
picker.modalPresentationStyle = .Popover
        
// max select number
PhotoPickerController.imageMaxSelectedNum = 4
        
self.showViewController(picker, sender: nil)
```
图片选择器默认打开最近添加相册列表，如果需要打开其他相册，或者首先打开相册列表，请直接设置`PageType`枚举具体类型即可：

```
enum PageType{
    case List      // 打开相册列表
    case RecentAlbum // 直接打开最近添加相册
    case AllAlbum // 直接打开所有相册列表
}
```
更多参数配置选项，请参照`PhotoPickerConfig.swift`配置文件。

## 注意
1. 当前版本不支持视频，如有需求请反馈

