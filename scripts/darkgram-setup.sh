#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/GeorgyAliabyev/DarkGram.git"
BRANCH="darkgram/player-a11y"
TARGET="$HOME/DarkGram"

say()  { printf '\n==> %s\n' "$*"; }
fail() { printf '\n!!! %s\n' "$*" >&2; exit 1; }
trap 'fail "Шаг не удался. Текст ошибки выше — пришли его."' ERR

[ "$(uname -s)" = "Darwin" ] || fail "Скрипт только для macOS."

say "1/7 проверяю Homebrew"
if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if ! command -v brew >/dev/null 2>&1; then
  echo "Установщик Homebrew спросит пароль от Mac и попросит нажать Enter."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
fi
brew --version | awk 'NR==1'

say "2/7 проверяю Rust"
if ! command -v cargo >/dev/null 2>&1 && [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
if ! command -v cargo >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
  . "$HOME/.cargo/env"
fi
cargo --version

say "3/7 настраиваю git для подмодулей"
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global url."https://gitlab.com/".insteadOf "git@gitlab.com:"

say "4/7 клонирую репозиторий с подмодулями"
if [ -d "$TARGET/.git" ]; then
  git -C "$TARGET" submodule update --init --recursive
else
  git clone --recurse-submodules "$REPO_URL" "$TARGET"
fi
cd "$TARGET"
git checkout "$BRANCH"
[ -f "Telegram-Mac.xcworkspace/contents.xcworkspacedata" ] || fail "В клоне нет Telegram-Mac.xcworkspace"

say "5/7 проверяю Xcode"
XCODE_APP="/Applications/Xcode.app/Contents/Developer"
[ -d "$XCODE_APP" ] || fail "Не нашёл Xcode в /Applications. Поставь Xcode из App Store и запусти скрипт снова."
CURRENT_DEV="$(xcode-select -p 2>/dev/null || true)"
if [ "$CURRENT_DEV" != "$XCODE_APP" ]; then
  echo "Активный Xcode сейчас: ${CURRENT_DEV:-не задан}. Переключаю на Xcode — понадобится пароль от Mac."
  sudo xcode-select --switch "$XCODE_APP"
fi
XCODE_RAW="$(xcodebuild -version 2>&1 || true)"
XCODE_VERSION="$(printf '%s\n' "$XCODE_RAW" | awk 'NR==1{print $2}')"
XCODE_MAJOR="${XCODE_VERSION%%.*}"
case "$XCODE_MAJOR" in
  ''|*[!0-9]*) fail "xcodebuild не отвечает версией. Ответ: $XCODE_RAW" ;;
esac
echo "Xcode $XCODE_VERSION"
if [ "$XCODE_MAJOR" -ge 27 ]; then
  sh scripts/xcode27.sh apply
else
  echo "Патч для Xcode 27 не нужен."
fi

say "6/7 ставлю зависимости и собираю нативные библиотеки (долго)"
sh scripts/setup_build_env.sh --build

say "7/7 открываю Xcode"
open "Telegram-Mac.xcworkspace"

printf '\nГотово. В Xcode слева выбери схему Telegram и нажми Command+R.\n'
