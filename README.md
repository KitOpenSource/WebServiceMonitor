# WebServiceMonitor

## Installation AFNetworking with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like AFNetworking in your projects. See the ["Getting Started" guide for more information](https://github.com/AFNetworking/AFNetworking/wiki/Getting-Started-with-AFNetworking). You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build AFNetworking 3.0.0+.

#### Podfile

To integrate AFNetworking into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'AFNetworking', '~> 3.0'

use_frameworks!
```

Then, run the following command:

```bash
$ pod install
```
