//
//  Domain.swift
//  Nabi
//
//  Created by aaron.du on 2018/9/28.
//  Copyright © 2018年 aaron.du. All rights reserved.
//

import UIKit

class Domain: NSObject {
    static var DEVICE_TYPE = "device_type"
    static var DEVICE_TYPE_IPHONE = "1"
    static var APP_VERSION = "app_version"
    static var COOKIE_DOMAIN = "*.104.com.tw"
    static var NABI_COOKIE_NAME = "APPSID"
    static var NABI_COOKIE_NAME_DEVICE_ID = "DEVICEID"
    static var NABI_COOKIE_NAME_DEVICE_TYPE = "DEVICETYPE"
    #if DEBUG
    @objc
    static var CONNECT_DOMAIN = "https://xxx.104-dev.com.tw/"
    #else
    @objc
    static var CONNECT_DOMAIN = "https://xxx.104.com.tw/"
    #endif
    static var AUTH_T = "t"
    
}
