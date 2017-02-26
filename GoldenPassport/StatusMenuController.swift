//
//  StatusMenuController.swift
//  GoldenPassport
//
//  Created by StanZhai on 2017/2/25.
//  Copyright © 2017年 StanZhai. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    var addVerifyKeyWindow: AddVerifyKeyWindow!
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
    var statusItem: NSStatusItem!
    var timerMenuItem: NSMenuItem!
    var authCodeMenuItems: [NSMenuItem] = []
    
    var statusIcon: NSImage!
    var copyIcon: NSImage!
    var removeIcon: NSImage!
    
    var markDeleteVerifiedKey: Bool = false
    var needRefreshCodeMenus: Bool = true
    let authCodeMenuItemTagStartIndex = 100
    
    override func awakeFromNib() {
        addVerifyKeyWindow = AddVerifyKeyWindow()
        loadIcons()
        initStatusItem()
        initStatusMenuItems()
    }
    
    private func loadIcons() {
        let iconSize = NSMakeSize(14, 14)
        statusIcon = NSImage(named: "statusIcon")
        statusIcon.size = iconSize
        statusIcon.isTemplate = true
        
        copyIcon = NSImage(named: "copyIcon")
        copyIcon.size = iconSize
        copyIcon.isTemplate = true
        
        removeIcon = NSImage(named: "removeIcon")
        removeIcon.size = iconSize
        removeIcon.isTemplate = true
    }
    
    private func initStatusItem() {
        statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
        statusItem.image = statusIcon
        statusItem.target = self
        statusItem.action = #selector(openMenu)
    }
    
    private func initStatusMenuItems() {
        statusMenu.insertItem(NSMenuItem.separator(), at: 0)
        timerMenuItem = NSMenuItem()
        statusMenu.insertItem(timerMenuItem, at: 0)
    }
    
    func openMenu(_ sender: AnyObject?) {
        updateMenu()
        let runLoop = RunLoop.current
        let timer = Timer(timeInterval: TimeInterval(1), target: self, selector: #selector(updateMenu), userInfo: nil, repeats: true)
        runLoop.add(timer, forMode: RunLoopMode.eventTrackingRunLoopMode)
        statusItem.popUpMenu(statusMenu)
        timer.invalidate()
    }
    
    func updateMenu() {
        let now = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let dateComponents = calendar.dateComponents([.second], from: now)
        let second = 30 - dateComponents.second! % 30
        
        timerMenuItem.title = "\(EXPIRE_TIME_STR)\(second)s"
        
        let authCodes = DataManager.shared.allAuthCode()
        
        if needRefreshCodeMenus {
            authCodeMenuItems.removeAll()
            
            for menuItem in statusMenu.items {
                if menuItem.tag >= authCodeMenuItemTagStartIndex {
                    statusMenu.removeItem(menuItem)
                }
            }
            
            var idx = 0
            for codeInfo in authCodes {
                let authCodeMenuItem = NSMenuItem()
                authCodeMenuItem.title = "\(codeInfo.key): \(codeInfo.value)"
                authCodeMenuItem.target = self
                authCodeMenuItem.action = #selector(authCodeMenuItemClicked)
                authCodeMenuItem.tag = authCodeMenuItemTagStartIndex + idx
                authCodeMenuItem.toolTip = markDeleteVerifiedKey ? DELETE_VERIFY_KEY_STR : COPY_AUTH_CODE_STR
                authCodeMenuItem.image = markDeleteVerifiedKey ? removeIcon : copyIcon
                authCodeMenuItems.append(authCodeMenuItem)
                statusMenu.insertItem(authCodeMenuItem, at: 0)
                idx = idx + 1
            }
            needRefreshCodeMenus = false
        } else {
            var idx = 0
            for codeInfo in authCodes {
                authCodeMenuItems[idx].title = "\(codeInfo.key): \(codeInfo.value)"
                idx = idx + 1
            }
        }
    }
    
    func authCodeMenuItemClicked(_ sender: NSMenuItem) {
        let authCodes = DataManager.shared.allAuthCode()
        let dataIdx = sender.tag - authCodeMenuItemTagStartIndex
        if dataIdx < authCodes.count {
            var idx = 0
            for codeInfo in authCodes {
                if idx == dataIdx {
                    if markDeleteVerifiedKey {
                        DataManager.shared.removeOTPAuthURL(tag: codeInfo.key)
                        needRefreshCodeMenus = true
                        updateMenu()
                    } else {
                        let pasteboard = NSPasteboard.general()
                        pasteboard.clearContents()
                        pasteboard.setString(codeInfo.value, forType: NSStringPboardType)
                    }
                    break
                }
                idx = idx + 1
            }
        }
    }
    
    @IBAction func addVerifyClicked(_ sender: NSMenuItem) {
        addVerifyKeyWindow.showWindow(nil)
        addVerifyKeyWindow.window?.makeKeyAndOrderFront(nil)
        addVerifyKeyWindow.clearTextField()
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func aboutClicked(sender: NSMenuItem) {
        if let url = URL(string: "https://github.com/stanzhai/GoldenPassport") {
            NSWorkspace.shared().open(url)
        }
    }
    
    @IBAction func deleteClicked(_ sender: NSMenuItem) {
        markDeleteVerifiedKey = !markDeleteVerifiedKey
        deleteMenuItem.title = markDeleteVerifiedKey ? DONE_REMOVE_STR : REMOVE_STR
        for authCodeMenuItem in authCodeMenuItems {
            authCodeMenuItem.toolTip = markDeleteVerifiedKey ? DELETE_VERIFY_KEY_STR : COPY_AUTH_CODE_STR
            authCodeMenuItem.image = markDeleteVerifiedKey ? removeIcon : copyIcon
        }
    }
    
    @IBAction func quitClicked(sender: NSMenuItem) {
        NSApplication.shared().terminate(self)
    }
}
