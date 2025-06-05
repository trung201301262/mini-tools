#!/bin/bash
set -e # Thoát ngay nếu có lệnh nào trả về lỗi

# --- Cài đặt NVIDIA CUDA Toolkit và Drivers ---
echo ">>> Bắt đầu cài đặt NVIDIA CUDA Toolkit và Drivers..."

# QUAN TRỌNG: URL này dành cho Ubuntu 24.04.
# Nếu server của bạn chạy phiên bản Ubuntu khác (ví dụ: 22.04),
# bạn CẦN THAY ĐỔI URL repo cho phù hợp.
# Truy cập https://developer.nvidia.com/cuda-downloads để tìm URL chính xác.
CUDA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb"
CUDA_KEYRING_PKG=$(basename "$CUDA_REPO_URL")

echo ">>> Tải về CUDA Keyring: $CUDA_KEYRING_PKG"
wget "$CUDA_REPO_URL"

echo ">>> Cài đặt CUDA Keyring..."
sudo dpkg -i "$CUDA_KEYRING_PKG"

echo ">>> Cập nhật danh sách gói phần mềm..."
sudo apt-get update # Giữ nguyên apt-get ở đây như script gốc

echo ">>> Cài đặt CUDA Toolkit 12.9 (có thể mất một lúc)..."
sudo apt-get -y install cuda-toolkit-12-9 # Sử dụng phiên bản cụ thể

echo ">>> Cài đặt CUDA Drivers (có thể mất một lúc)..."
sudo apt-get install -y cuda-drivers

echo ">>> Dọn dẹp file keyring đã tải về..."
sudo rm "$CUDA_KEYRING_PKG"

echo ">>> Cài đặt NVIDIA CUDA Toolkit và Drivers hoàn tất."
echo ""
# --- Kết thúc Cài đặt NVIDIA CUDA Toolkit và Drivers ---

# --- Thiết lập thư mục /data và mount volume ---
echo ">>> Bắt đầu thiết lập thư mục /data và mount volume..."

echo ">>> Tạo thư mục /data nếu chưa tồn tại..."
sudo mkdir -p /data

# QUAN TRỌNG: ID đĩa '/dev/disk/by-id/scsi-0DO_Volume_framepack-gpu' rất cụ thể.
# Nếu bạn sử dụng server khác hoặc volume khác, ID này SẼ THAY ĐỔI.
# Bạn cần xác định ID đĩa chính xác trên server của mình (ví dụ: bằng lệnh `ls -l /dev/disk/by-id/`)
# và cập nhật dòng lệnh mount bên dưới.
DISK_ID="/dev/disk/by-id/scsi-0DO_Volume_framepack-gpu" # Đây là ID ví dụ

echo ">>> Mount volume $DISK_ID vào /data..."
sudo mount -o discard,defaults,noatime "$DISK_ID" /data

echo ">>> Kiểm tra điểm mount:"
df -h /data

echo ">>> Thiết lập thư mục /data và mount volume hoàn tất."
echo ""
echo "LƯU Ý QUAN TRỌNG VỀ VIỆC MOUNT VOLUME:"
echo "1. Việc mount volume bằng lệnh 'mount' trong script này chỉ là TẠM THỜI."
echo "   Nếu server khởi động lại, volume sẽ KHÔNG tự động được mount lại."
echo "   Để mount vĩnh viễn, bạn cần chỉnh sửa file /etc/fstab."
echo "   Ví dụ dòng cho /etc/fstab (thay UUID và TYPE cho đúng):"
echo "   UUID=<UUID_CUA_DIA> /data <TYPE_FILESYSTEM> discard,defaults,noatime 0 2"
echo "   Bạn có thể tìm UUID bằng 'sudo blkid $DISK_ID'."
echo ""
echo "2. Đảm bảo URL CUDA repo và DISK_ID phù hợp với hệ thống của bạn."
echo ""
# --- Kết thúc Thiết lập thư mục /data và mount volume ---

# --- Cài đặt Caddy Server ---
echo ">>> Bắt đầu cài đặt Caddy Server..."
echo ">>> Cài đặt các gói phụ thuộc cần thiết cho Caddy..."
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https curl

echo ">>> Thêm Caddy GPG key..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

echo ">>> Thêm Caddy repository..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

echo ">>> Cập nhật danh sách gói phần mềm sau khi thêm Caddy repo..."
sudo apt update

echo ">>> Cài đặt Caddy (có thể mất một lúc)..."
sudo apt install -y caddy

echo ">>> Cài đặt Caddy Server hoàn tất."
echo ""
# --- Kết thúc Cài đặt Caddy Server ---

# --- Thiết lập thư mục cấu hình Caddy ---
echo ">>> Bắt đầu thiết lập thư mục cấu hình Caddy..."
CADDY_CONFIG_DIR="/data/caddyserver" # Thư mục bạn muốn chứa Caddyfile
USER_CADDYFILE="$CADDY_CONFIG_DIR/Caddyfile"

echo ">>> Tạo thư mục $CADDY_CONFIG_DIR nếu chưa tồn tại..."
sudo mkdir -p "$CADDY_CONFIG_DIR"
# Quyền cho thư mục này: Nếu Caddy chạy dưới user 'caddy' (mặc định khi cài từ apt và chạy service),
# user 'caddy' cần quyền đọc Caddyfile và các file liên quan (ví dụ: SSL certs nếu bạn tự quản lý).
# `sudo mkdir -p` sẽ tạo thư mục với chủ sở hữu là root.
# Bạn có thể cần `sudo chown -R caddy:caddy $CADDY_CONFIG_DIR` nếu user `caddy` cần ghi vào đây,
# hoặc ít nhất là quyền đọc.

echo ">>> Thiết lập thư mục cấu hình Caddy hoàn tất."
echo "LƯU Ý QUAN TRỌNG VỀ CẤU HÌNH CADDY:"
echo "1. Hãy đảm bảo bạn tạo và đặt file Caddyfile của mình tại: $USER_CADDYFILE"
echo "2. Cài đặt Caddy qua 'apt' thường sẽ cấu hình Caddy chạy như một dịch vụ systemd,"
echo "   sử dụng file cấu hình mặc định tại /etc/caddy/Caddyfile."
echo "3. Nếu bạn muốn dịch vụ Caddy sử dụng file tại $USER_CADDYFILE:"
echo "   a. Bạn cần sửa file dịch vụ systemd của Caddy (thường là /lib/systemd/system/caddy.service)."
echo "   b. Thay đổi dòng 'ExecStart' từ:"
echo "      ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile"
echo "   thành:"
echo "      ExecStart=/usr/bin/caddy run --environ --config $USER_CADDYFILE"
echo "   c. Sau đó, chạy 'sudo systemctl daemon-reload' và 'sudo systemctl restart caddy'."
echo "   d. Đảm bảo user 'caddy' (hoặc user mà dịch vụ Caddy chạy dưới quyền) có quyền đọc $USER_CADDYFILE và các file/thư mục liên quan trong $CADDY_CONFIG_DIR."
echo "4. Hoặc, bạn có thể chạy Caddy thủ công từ terminal (không qua service systemd) với lệnh:"
echo "   caddy run --config $USER_CADDYFILE"
echo "   (Chạy lệnh này từ bất kỳ đâu, hoặc từ thư mục $CADDY_CONFIG_DIR)."
echo ""
# --- Kết thúc Thiết lập thư mục cấu hình Caddy ---

# --- Cài đặt các gói tiện ích khác ---
echo ">>> Bắt đầu cài đặt các gói tiện ích khác..."

echo ">>> Cài đặt python3-dev (cần cho một số package Python)..."
sudo apt install -y python3-dev

echo ">>> Cài đặt nvitop (theo dõi GPU tiện lợi)..."
sudo apt install -y nvitop

echo ">>> Cài đặt các gói tiện ích khác hoàn tất."
echo ""
# --- Kết thúc Cài đặt các gói tiện ích khác ---

echo ">>> SCRIPT HOÀN THÀNH TOÀN BỘ! Kiểm tra lại các LƯU Ý QUAN TRỌNG ở trên. ✨"
