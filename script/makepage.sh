#!/bin/bash
if [ $# -ne 3 ]; then
    echo "Error: 请输入 3 个参数"
    echo "用法: $0 <仓库> <密钥> <输出目录>"
    exit 1
fi
repo=$1
token=$2
targetPath=$3

json_data=$(curl -s -H "Authorization: token $token" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/$repo/releases/latest)

id=$(jq -r '.id // empty' <<< "$json_data")
if [ -z $id ]; then
    echo "$json_data"
    exit
fi

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
    size=$(numfmt --to=iec --format=%.1f $(echo "$item" | jq '.size'))
    
    remark="以上都支持"
    linkText='"all" : "'$url'",'
    if [[ $name == *arm64* ]]; then
        remark="常用安卓手机平板"
        linkText='"arm64" : "'$url'",'
    elif [[ $name == *x64* ]]; then
        remark="Intel x64 架构安卓"
        linkText='"x64" : "'$url'",'
    fi

    urls="$urls
    $linkText"

    output="$output
- [$name]($url) ($size) $remark
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
[版本历史](./history.html)

联系邮箱：<a id="mail"></span>
<script>
    var mail = decodeURIComponent(atob('d2lsZHdpbmQyMDAwQGdtYWlsLmNvbQ=='));
    var ctl = document.getElementById('mail');
    ctl.innerText = mail;
    ctl.href = 'mailto:' + mail;
</script>
"

file_content=$(<README.md)
echo "<html>
<body>
$file_content
$output
</body>
</html>
" > temp.md

pandoc temp.md -o $targetPath/index.html

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
$SCRIPT_DIR/makehistory.sh $repo > temp.md
pandoc temp.md -o $targetPath/history.html
rm temp.md

cp -r ./home/* $targetPath