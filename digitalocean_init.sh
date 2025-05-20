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
sudo apt-get update

echo ">>> Cài đặt CUDA Toolkit 12.9 (có thể mất một lúc)..."
sudo apt-get -y install cuda-toolkit-12-9 # Sử dụng phiên bản cụ thể

echo ">>> Cài đặt CUDA Drivers (có thể mất một lúc)..."
sudo apt-get install -y cuda-drivers

echo ">>> Dọn dẹp file keyring đã tải về..."
sudo rm "$CUDA_KEYRING_PKG"

echo ">>> Cài đặt NVIDIA CUDA Toolkit và Drivers hoàn tất."
echo ""

# --- Thiết lập thư mục /data và mount volume ---
echo ">>> Bắt đầu thiết lập thư mục /data và mount volume..."

echo ">>> Tạo thư mục /data nếu chưa tồn tại..."
sudo mkdir -p /data

# QUAN TRỌNG: ID đĩa '/dev/disk/by-id/scsi-0DO_Volume_framepack-gpu' rất cụ thể.
# Nếu bạn sử dụng server khác hoặc volume khác, ID này SẼ THAY ĐỔI.
# Bạn cần xác định ID đĩa chính xác trên server của mình (ví dụ: bằng lệnh `ls -l /dev/disk/by-id/`)
# và cập nhật dòng lệnh mount bên dưới.
DISK_ID="/dev/disk/by-id/scsi-0DO_Volume_framepack-gpu" # Đây là ID ví dụ từ câu hỏi của bạn

echo ">>> Mount volume $DISK_ID vào /data..."
sudo mount -o discard,defaults,noatime "$DISK_ID" /data

echo ">>> Kiểm tra điểm mount:"
df -h /data

echo ">>> Thiết lập thư mục /data và mount volume hoàn tất."
echo ""
echo "LƯU Ý QUAN TRỌNG:"
echo "1. Việc mount volume bằng lệnh 'mount' trong script này chỉ là TẠM THỜI."
echo "   Nếu server khởi động lại, volume sẽ KHÔNG tự động được mount lại."
echo "   Để mount vĩnh viễn, bạn cần chỉnh sửa file /etc/fstab."
echo "   Ví dụ dòng cho /etc/fstab (thay UUID và TYPE cho đúng):"
echo "   UUID=<UUID_CUA_DIA> /data <TYPE_FILESYSTEM> discard,defaults,noatime 0 2"
echo "   Bạn có thể tìm UUID bằng 'sudo blkid $DISK_ID'."
echo ""
echo "2. Đảm bảo URL CUDA repo và DISK_ID phù hợp với hệ thống của bạn."
echo ""
echo ">>> Script hoàn thành!"
