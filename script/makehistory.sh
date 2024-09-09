#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Error: 请输入 1 个参数"
    echo "用法: $0 <仓库>"
    exit 1
fi
REPO=$1
json_data=$(curl -s "https://api.github.com/repos/$REPO/releases")
releases=$(echo "$json_data" | jq -c '.[]')

echo '# MifiTool 版本历史：
&nbsp;&nbsp;


'
# 遍历每个 release
echo "$releases" | while read -r release; do
  tag_name=$(echo "$release" | jq -r '.tag_name')
  created_at=$(echo "$release" | jq -r '.created_at')
  timestamp=$(date -d "$created_at" +%s)
  created_at=$(TZ=Asia/Shanghai date -d@$timestamp "+%Y-%m-%d %H:%M:%S")
  name=$(echo "$release" | jq -r '.name')
  
  echo "
<br>
版本: **$tag_name**
    
时间: $created_at
  
资源:
"
  # 提取每个资产信息
  assets=$(echo "$release" | jq -c '.assets[] | select(.name | endswith(".apk"))')
  
  echo "$assets" | while read -r asset; do
    asset_name=$(echo "$asset" | jq -r '.name')
    asset_url=$(echo "$asset" | jq -r '.browser_download_url')
    asset_url=${asset_url//github.com/gh.bajamead.eu.org}
    asset_size=$(echo "$asset" | jq -r '.size')
    asset_size=$(numfmt --to=iec --format=%.1f $asset_size)
    
    echo "
  - [$asset_name($asset_size)]($asset_url)"
  done
done  
