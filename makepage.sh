#!/bin/bash
if [ $# -ne 3 ]; then
    echo "Error: 请输入 3 个参数"
    echo "用法: $0 <仓库> <密钥> <输出目录>"
    exit 1
fi
repo=$1
token=$2
targetPath=$3

json_data=$(curl -H "Authorization: token $token" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/$repo/releases/latest)

createdAt=$(jq -r '.created_at' <<< "$json_data")
tagName=$(jq -r '.tag_name' <<< "$json_data")
assets=$(jq '.assets' <<< "$json_data")
createdAt=$(TZ=Asia/Shanghai date -d @$(date -d "$createdAt" +%s) +"%Y-%m-%d %H:%M:%S")
output_json='
{
    [url]
    "version": "'${tagName:1}'",
    "createdAt": "'$createdAt'"
}
'
urls=''
output=''

for item in $(echo "$assets" | jq -c '.[]'); do
    name=$(echo "$item" | jq -r '.name')
    url=$(echo "$item" | jq -r '.browser_download_url')
    url=${url//github.com/gh.bajamead.eu.org}
    size=$(numfmt --to=si $(echo "$item" | jq '.size'))
    
    remark="支持以上所有运行平台"
    linkText='"all" : "'$url'",'
    if [[ $name == *arm64* ]]; then
        remark="安卓手机、平板"
        linkText='"arm64" : "'$url'",'
    elif [[ $name == *x64* ]]; then
        remark="Intel x64 架构，包括Windows 中的 WSA、模拟器、或者其它 X64 机型"
        linkText='"x64" : "'$url'",'
    fi

    urls="$urls
    $linkText"

    output="$output
[$name]($url) ($size) $remark
"
done
output_json=${output_json//\[url\]/$urls}

mkdir -p $targetPath
echo "$output_json" > $targetPath/version.json

output="
<br>
软件下载：$tagName ($createdAt)

$output

<br>
[版本历史 (github.com)](https://github.com/$repo/releases)
"

file_content=$(<README.md)
echo "$file_content
$output
" > temp.md

pandoc temp.md -o $targetPath/index.html
rm temp.md
