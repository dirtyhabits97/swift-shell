import Foundation

// source: https://rderik.com/blog/understanding-the-runloop-model-by-creating-a-basic-shell/

let customMode = "com.gerh.swift-shell"
let promptPlaceHolder = "[00:00:00] $ "

func list() -> [String] {
    let fm = FileManager.default
    // get the contents of the current directory
    return (try? fm.contentsOfDirectory(atPath: ".")) ?? []
}

func processCommand(
    _ fd: CFFileDescriptorNativeDescriptor = STDIN_FILENO
) -> Int8 {
    let fileH = FileHandle(fileDescriptor: fd)
    let command = String(data: fileH.availableData, encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines)
        ?? ""
    switch command {
    case "exit":
        return -1
    case "ls":
        print(list(), terminator: "\n\(promptPlaceHolder)")
        fflush(__stdoutp)
        return 0
    case "":
        return 1
    default:
        print("Your command: \(command)", terminator: "\n\(promptPlaceHolder)")
        fflush(__stdoutp)
        return 0
    }
}

// MARK: - RunLoop

// the method that runs when there is something to
// process from the registered file descriptor,
// in this case `stdin`
func fileDescriptorCallback(
    _ fd: CFFileDescriptor?,
    _ flags: CFOptionFlags,
    _ info: UnsafeMutableRawPointer?
) {
    let nfd = CFFileDescriptorGetNativeDescriptor(fd)
    let result = processCommand(nfd)
    switch result {
    case -1:
        print("Bye bye now.")
    default:
        // recursively register the stdin file descriptor
        // this is similar to the FileWatcher implementation,
        // in which the register happens in the callback
        //
        // "Important note: a RunLoop can only run on a specific mode
        // if there is at least one input source or timer to monitor.
        // If there are none the RunLoop will not run (or stop after
        // all the input sources and/or timers have completed)."
        registerStdinFileDescriptor()
        RunLoop.main.run(
            mode: RunLoop.Mode(rawValue: customMode),
            before: .distantFuture
        )
    }
}

// boilerplate method,
// registers the CFFileDescriptor as input source,
// ins this case `stdin`
func registerStdinFileDescriptor() {
    let fd = CFFileDescriptorCreate(
        kCFAllocatorDefault,
        STDIN_FILENO,
        false,
        fileDescriptorCallback(_:_:_:),
        nil
    )
    CFFileDescriptorEnableCallBacks(fd, kCFFileDescriptorReadCallBack)
    let source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fd, 0)
    
    let cfCustomMode = CFRunLoopMode(customMode as CFString)
    CFRunLoopAddSource(RunLoop.main.getCFRunLoop(), source, cfCustomMode)
}

// MARK: - Execution

//print(Date.distantFuture)
//print(Date.distantFuture)

print("Welcome to my shell \n\(promptPlaceHolder)", terminator: "")
fflush(__stdoutp)
registerStdinFileDescriptor()

// Important Note this won't work correctly on the Xcode
// console because the debug console is not a full terminal
// and doesn't support all the control escape sequences
let pt = PromptTimer()
pt.start()

RunLoop.main.run(
    mode: RunLoop.Mode(rawValue: customMode),
    before: .distantFuture
)

//print("Welcome to my shell \n% ", terminator: "")
//
//outerLoop: while true {
//    let result = processCommand()
//    switch result {
//    case -1:
//        break outerLoop
//    case 1:
//        print("Error reading command")
//        break outerLoop
//    default:
//        break
//    }
//}
//
//print("Bye bye now.")
