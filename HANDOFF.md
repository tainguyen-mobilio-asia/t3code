# HANDOFF — fork cá nhân của T3 Code

Hướng dẫn build và cài app: `BUILD-LOCAL.md`. File này là sổ tay cho agent (và cho tôi) đọc lại sau khi session bị compact hoặc khi mở session mới.
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
3. **Giới hạn gói Claude (kiểu "Plan usage limits" của Claude Code)**:
   - Vấn đề gốc: probe `get_usage` lúc khởi động chạy không có OAuth (`tokenSource: none`) nên báo `rate_limits_available: false`,
     và upstream bỏ qua mọi `rate_limit_event` stream về sau khi probe nói "unsupported" → panel kẹt ở "Unavailable".
   - `packages/provider-core/src/server/usageLimits.ts`: `applyUsageLimitsUpdate` luôn nhận window từ stream và xóa `unavailable`;
     `resolveUsageLimitsAfterProbe` giữ window đã publish khi probe thất bại hoặc "unsupported". Test cập nhật theo.
   - `apps/server/src/provider/claudeUsageLimits.ts`: đọc `unifiedWindows` (mọi bucket trong một event); nhãn "5-hour limit",
     "Weekly · all models"; bucket `seven_day_overage_included` mặc định tên "Weekly · Fable" khi probe không đặt tên (giả định:
     allowlist overage của CLI hiện có đúng một model).
   - `apps/web/src/components/chat/ThreadDetailsUsage.tsx`: heading "Plan usage limits · <gói>", link "See all" → claude.ai/settings/usage,
     mỗi hàng: nhãn, "Resets at …", % đã dùng, thanh màu info bên dưới.
   - Số liệu chỉ có sau lượt Claude đầu tiên của phiên server (stream), không có ngay khi mở app.

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
export PATH="$HOME/.cargo/bin:$PWD/node_modules/.bin:$PATH"
vp i
vp run dist:desktop:dmg          # arm64 theo máy; ra thư mục release/; mất khoảng 1 phút
```

- Cần Rust (resource monitor của app). Đã cài qua rustup ngày 2026-11-14 vào `~/.cargo` (gỡ: `rustup self uninstall`).
  Nếu thiếu, build báo `MacDesktopBuildPrerequisitesMissingError`.
- Bản build local **không ký (unsigned)**. Lần đầu mở: chuột phải → Open, hoặc
  `xattr -dr com.apple.quarantine "/Applications/T3 Code (Beta).app"`.
- App build từ fork không có update feed, nên nó **không tự cập nhật**; cập nhật = làm quy trình ở trên rồi build lại.
- Kéo file `.dmg` trong `release/` vào Applications để thay bản cũ. Dữ liệu người dùng ở `~/.t3/userdata` giữ nguyên.

## Trạng thái

- 2026-11-14: tạo nhánh `tainguyen-mobilio-asia/2026-11-14`; thêm context breakdown; viết file này.
  Build DMG thành công: `release/T3-Code-0.1.9-arm64.dmg` (chưa ký). Chưa kiểm tra giao diện breakdown bằng một lượt Claude thật;
  việc tiếp theo: mở app đã build, bật Settings → Thread details → Context window, chạy một lượt Claude và xem panel phải.

## Nhật ký

- 2026-11-14 02:20: context breakdown code xong, unit test + check:changed pass.
- 2026-11-14 02:21: build DMG lần 1 lỗi thiếu Rust; cài rustup; build lần 2 thành công.
- 2026-11-14 02:47: fix breakdown mất khi lượt đang chạy (giữ rows trong tiến trình).
- 2026-11-14 03:12: plan usage limits lấy từ stream, UI kiểu Claude Code; build lần 4.
