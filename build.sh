#!/bin/bash
set -e

echo "Đang tải Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:$(pwd)/flutter/bin"

echo "Đang vô hiệu hóa check root..."
sed -i 's/if \[\[ "\$EUID" -eq 0 \]\]; then/if false; then/g' flutter/bin/internal/shared.sh

echo "Đang build Flutter Web..."
flutter config --enable-web
flutter pub get
flutter build web --release