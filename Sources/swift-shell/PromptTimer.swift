import Foundation

class PromptTimer {
    
    func start() {
        let timer = Timer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(printTime(timer:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(timer, forMode: RunLoop.Mode(customMode))
    }
    
    @objc func printTime(timer: Timer) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let currentDateTime = Date()
        let strTime = formatter.string(from: currentDateTime)
        // control escape sequences:
        // https://www.xfree86.org/current/ctlseqs.html
        // \u{1B} marks the control escape sequence
        // 7 saves the current cursor position
        // 8 restores the saved cursor position
        print("\u{1B}7\r[\(strTime)] $ \u{1B}8", terminator: "")
        fflush(__stdoutp)
    }
    
}
