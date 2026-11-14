# ~/.profile: login-shell env shared by bash and other POSIX shells.
GPG_TTY=$(tty 2>/dev/null) || GPG_TTY=""
export GPG_TTY

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
true
