# HANDOFF — fork cá nhân của T3 Code

File này là sổ tay cho agent (và cho tôi) đọc lại sau khi session bị compact hoặc khi mở session mới.
Đọc file này trước khi làm bất cứ việc gì trên fork. Cập nhật mục "Trạng thái" sau mỗi phiên làm việc.

## Bối cảnh

- `origin` = fork cá nhân `tainguyen-mobilio-asia/t3code`. `upstream` = `pingdotgg/t3code`.
- Nhánh làm việc **duy nhất**: `tainguyen-mobilio-asia/YYYY-MM-DD` (ngày tạo nhánh). Mọi tính năng riêng commit vào đây.
  Nhánh hiện tại: `tainguyen-mobilio-asia/2026-11-14`.
- Nhánh cũ `feat/sidebar-claude-style-folders` là tiền thân (1 commit: sidebar gom thread theo folder project). Đã gộp vào nhánh trên; không commit thêm vào nhánh cũ.
- `main` luôn là bản sao sạch của `upstream/main`. Không commit tính năng riêng vào `main`.
- Commit subject theo quy ước của chủ máy: `YYYY-MM-DD HH:MM - <tóm tắt>`, không có trailer Co-Authored-By.
- Máy này không có `vp` toàn cục. Dùng `export PATH="$PWD/node_modules/.bin:$PATH"` rồi chạy `vp ...` bình thường,
  hoặc cài toàn cục: `curl -fsSL https://vite.plus | bash`.

## Tính năng riêng (những gì khác upstream)

1. **Sidebar gom thread theo folder project** (từ nhánh feat/sidebar-claude-style-folders).
2. **Context breakdown ở panel phải** (kiểu `/context` của Claude Code):
   - `packages/contracts/src/orchestrationV2.ts`: thêm `OrchestrationV2ContextUsageCategory` và field tùy chọn `contextCategories` trên `OrchestrationV2ProviderTurnTokenUsage`.
   - `apps/server/src/provider/ClaudeTurnTokenUsage.ts`: `claudeContextCategories()` chuyển response của SDK thành rows.
   - `apps/server/src/orchestration-v2/Adapters/ClaudeAdapterV2.ts`: session có thêm `contextUsage` (gọi `query.getContextUsage({ detail: "summary" })`);
     khi frame `result` báo context mới, `readContextCategories` lấy rows (timeout 3s, lỗi thì bỏ qua) và gắn vào `tokenUsage`.
   - `packages/client-runtime/src/state/contextWindow.ts`: `ContextWindowSnapshot.categories`.
   - `apps/web/src/components/chat/ThreadDetailsUsage.tsx`: `ContextBreakdown` (thanh phân đoạn + từng dòng) dưới hàng "Context".
   - Bật ở Settings → Thread details → "Context window" và "Usage limits" (mặc định tắt trong upstream).
3. **Giới hạn gói Claude (5-hour, Weekly)**: upstream đã có sẵn (`ThreadDetailsUsage`, `claudeUsageLimits.ts`). Không phải code riêng.
   "Limits: Unavailable" nghĩa là probe `get_usage` của Claude CLI thất bại hoặc tài khoản không có rate limit; kiểm tra bản Claude Code CLI đang cài.

## Quy trình cập nhật từ upstream

```bash
export PATH="$PWD/node_modules/.bin:$PATH"
git checkout main
git fetch upstream
git merge --ff-only upstream/main
git push origin main

git checkout tainguyen-mobilio-asia/2026-11-14
git tag backup/$(date +%Y%m%d-%H%M)          # lưới an toàn trước khi rebase
git rebase main                               # conflict: sửa -> git add -> git rebase --continue
git push --force-with-lease origin tainguyen-mobilio-asia/2026-11-14

vp i
vp run check:changed
```

Nếu muốn mở nhánh theo ngày mới: `git checkout -b tainguyen-mobilio-asia/$(date +%Y-%m-%d)` từ nhánh hiện tại, push, và cập nhật tên nhánh trong file này.

`git config rerere.enabled true` đã bật để Git nhớ cách giải conflict.

## Build app Electron (macOS, chạy local)

```bash
export PATH="$PWD/node_modules/.bin:$PATH"
vp i
vp run dist:desktop:dmg          # arm64 theo máy; ra thư mục release/
```

- Bản build local **không ký (unsigned)**. Lần đầu mở: chuột phải → Open, hoặc
  `xattr -dr com.apple.quarantine "/Applications/T3 Code (Beta).app"`.
- App build từ fork không có update feed, nên nó **không tự cập nhật**; cập nhật = làm quy trình ở trên rồi build lại.
- Kéo file `.dmg` trong `release/` vào Applications để thay bản cũ. Dữ liệu người dùng ở `~/.t3/userdata` giữ nguyên.

## Trạng thái

- 2026-11-14: tạo nhánh `tainguyen-mobilio-asia/2026-11-14`; thêm context breakdown; viết file này. Build DMG: xem mục "Nhật ký" bên dưới.

## Nhật ký

- 2026-11-14 02:20 — Context breakdown code xong, unit test pass. Đang typecheck + build DMG.
