package muninn

import "core:sys/posix"
import "core:fmt"

orig_termios := posix.termios{}

enable_raw_mode :: proc() {
    posix.atexit(disable_raw_mode)

    raw := orig_termios
    posix.tcgetattr(posix.STDIN_FILENO, &orig_termios)
    raw.c_iflag &= ~{.IXON, .ICRNL, .BRKINT, .INPCK, .ISTRIP}
    raw.c_oflag &= ~({.OPOST})
    raw.c_cflag |= {.CS8}
    raw.c_lflag &= ~{.ECHO, .ICANON, .ISIG, .IEXTEN}
    raw.c_cc[posix.Control_Char.VMIN] = 1
    raw.c_cc[posix.Control_Char.VTIME] = 0

    posix.tcsetattr(posix.STDIN_FILENO, posix.TC_Optional_Action.TCSAFLUSH, &raw)
}

disable_raw_mode :: proc "cdecl" () {
    // Needs to be cdecl in order to be a callback for atexit
    posix.tcsetattr(posix.STDIN_FILENO, posix.TC_Optional_Action.TCSAFLUSH, &orig_termios)
}

main :: proc() {
    enable_raw_mode()

    for {
        buf: [1]u8
        bytes_read := posix.read(posix.STDIN_FILENO, &buf[0], 1)
        if bytes_read < 0 {
            fmt.eprintln("Error reading from stdin")
            return
        }
        if buf[0] == 'q' {
            return
        }
        fmt.printfln("read: %d ('%v')\r", buf[0], rune(buf[0]))
    }
}