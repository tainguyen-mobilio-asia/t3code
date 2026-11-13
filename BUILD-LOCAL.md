# Build T3 Code (macOS) từ fork này

Hướng dẫn build app Electron từ thư mục dự án và cài đè lên bản đang dùng.
Quy trình đồng bộ với upstream và danh sách tính năng riêng nằm trong `HANDOFF.md`.

## Dữ liệu có mất không?

Không. App build từ đây và app đang cài là cùng một app:

- Bundle id `com.t3tools.t3code`, tên `T3 Code (Beta)`.
- Dữ liệu nằm ngoài app, ở `~/.t3/userdata` (database `statev2.sqlite`, `client-settings.json`, attachments, đăng nhập provider).
- Cài bản mới = thay file `.app` trong `/Applications`. Thư mục `~/.t3` không bị đụng tới.

Vì vậy sidebar chat, project, thread, cài đặt, và phiên đăng nhập Claude/Codex giữ nguyên.
Database chỉ được nâng cấp tiến (migrate) khi app mới hơn mở nó. Đừng cài một bản build cũ hơn bản
đã từng mở database, vì bản cũ có thể không đọc được schema mới. Muốn an toàn tuyệt đối, sao lưu
trước khi cài:

```bash
cp -R ~/.t3/userdata ~/.t3/userdata.backup-$(date +%Y%m%d)
```

## Chuẩn bị máy (làm một lần)

1. Xcode Command Line Tools: `xcode-select --install` (máy này đã có Xcode).
2. Rust (resource monitor của app cần): `curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal`
   (máy này đã cài ngày 2026-11-14, nằm ở `~/.cargo`).
3. `vp` (Vite+): cài toàn cục bằng `curl -fsSL https://vite.plus | bash`, hoặc dùng bản trong
   `node_modules/.bin` như các lệnh dưới đây.

## Cách nhanh: app nằm ngay ở thư mục gốc

```bash
cd ~/Documents/GitHub/t3code
./build-app.sh            # build rồi đặt "T3 Code (Beta).app" ở thư mục gốc
./build-app.sh --unpack   # chỉ giải nén bản build mới nhất trong release/, không build lại
open "T3 Code (Beta).app"
```

Script tự thêm Rust và `vp` vào PATH, từ chối chạy khi app đang mở, xóa bản app cũ ở gốc rồi
giải nén bản mới và bỏ cờ quarantine. App ở gốc được gitignore. Dữ liệu vẫn ở `~/.t3/userdata`,
nên app này và bản trong `/Applications` dùng chung dữ liệu; chỉ mở một trong hai cùng lúc.

Để mở từ Dock hoặc Spotlight, kéo app này vào Dock một lần; mỗi lần build lại, Dock vẫn trỏ đúng đường dẫn.

## Chạy dev (không build) khi đang sửa code

```bash
./dev-app.sh          # mở Electron ở chế độ dev, hot reload; Ctrl+C để dừng tất cả
```

- Dùng cùng `~/.t3/userdata` với app đã build, nên chat và project giữ nguyên. Vì dùng chung database,
  script từ chối chạy khi app đã build đang mở, và ngược lại phải tắt dev trước khi mở app đã build.
- Dev chậm và nặng hơn bản build (Vite dev server, code chưa minify). Chỉ dùng khi sửa code; dùng hằng ngày thì build.
- Khi hài lòng với thay đổi, tắt dev rồi `./build-app.sh` để có bản production.

## Build thủ công

```bash
cd ~/Documents/GitHub/t3code
export PATH="$HOME/.cargo/bin:$PWD/node_modules/.bin:$PATH"

git status                      # đảm bảo đang ở nhánh tainguyen-mobilio-asia/<ngày>
vp i                            # cài dependency (bỏ qua nếu không đổi package.json)
vp run dist:desktop:dmg         # khoảng 1-2 phút trên Apple Silicon
```

Kết quả trong `release/`:

| File                              | Dùng để                             |
| --------------------------------- | ----------------------------------- |
| `T3-Code-<version>-arm64.dmg`     | cài đặt                             |
| `T3-Code-<version>-arm64.zip`     | giải nén trực tiếp, không cần mount |
| `*.blockmap`, `builder-debug.yml` | bỏ qua                              |

Thư mục `release/` được gitignore, không commit.

## Cài

1. Thoát app `T3 Code (Beta)` đang chạy (Cmd+Q). App này cũng là server local, nên phải tắt hẳn.
2. Mở file `.dmg`, kéo `T3 Code (Beta)` vào `Applications`, chọn **Replace**.
3. Bản build local không ký và không notarize, nên lần đầu macOS chặn. Bỏ chặn bằng một trong hai cách:
   - chuột phải vào app → **Open** → **Open**;
   - hoặc `xattr -dr com.apple.quarantine "/Applications/T3 Code (Beta).app"`.
4. Mở app. Mọi project và thread cũ hiện lại như trước.

## Khi muốn cập nhật từ upstream

Làm theo mục "Quy trình cập nhật từ upstream" trong `HANDOFF.md`, rồi build và cài lại theo hai mục trên.
App build từ fork không có kênh auto-update, nên đây là cách duy nhất để lên bản mới.

## Lỗi thường gặp

- `MacDesktopBuildPrerequisitesMissingError ... Rust/Cargo`: thiếu `~/.cargo/bin` trong PATH hoặc chưa cài Rust. Chạy lại dòng `export PATH=...` ở trên.
- `vp: command not found`: chưa thêm `node_modules/.bin` vào PATH, hoặc chưa chạy `vp i`.
- Build bị khóa (`desktop build lock`): một lần build trước chưa thoát. Đợi nó xong hoặc kiểm tra tiến trình `build-desktop-artifact`.
- Muốn build cho máy Intel: `vp run dist:desktop:dmg:x64` sau khi `rustup target add x86_64-apple-darwin`.
