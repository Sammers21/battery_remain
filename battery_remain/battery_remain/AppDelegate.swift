// MIT License
// 
// Copyright (c) 2020 Pavel Drankov
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Cocoa
import SwiftUI
import Foundation
import LaunchAtLogin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let CALC_CONST = "Calculating ..."
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.menu()
        self.periodic(seconds: 10)
        self.updTitle()
    }

    private func periodic(seconds: Int) -> Timer {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: true) { timer in
            self.updTitle()
        }
    }

    private func updTitle() {
        if let button = self.statusItem.button {
            button.title = self.remain()
        }
    }

    private func menu() {
        let menu = NSMenu()
        let symb = LaunchAtLogin.isEnabled ? "✓ on" :"✗ off"
        menu.addItem(NSMenuItem(title: "Run at startup: \(symb)", action: #selector(AppDelegate.toggleStartup(_:)), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc func toggleStartup(_ sender: Any?){
        LaunchAtLogin.isEnabled = !LaunchAtLogin.isEnabled
        menu()
    }
    
    func remain() -> String {
        var result = CALC_CONST
        let task = Process()
        let pipe = Pipe()

        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        let toMatch = output.components(separatedBy: ";")[2]
        if let match = try? NSRegularExpression(
            pattern: " ([0-9:]+) remaining present: true",
            options: .caseInsensitive
        ).firstMatch(in: toMatch, options: [], range: NSRange(location: 0, length: toMatch.count)) {
            if let time = Range(match.range(at: 1), in: toMatch){
                result = String(toMatch[time])
            }
        }
        if output.components(separatedBy: ";")[1] == " charged" {
            result = "Charged"
        }
        return result
    }
}
