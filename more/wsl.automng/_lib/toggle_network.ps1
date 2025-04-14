# toggle_network.ps1
. $PSScriptRoot\common.ps1




function Update-ConfigSegment {
    param(
        [Parameter(Mandatory)] [string] $FilePath,
        [Parameter(Mandatory)] [string] $SectionHeader,  # 如 "[experimental]"
        [Parameter(Mandatory)] [string[]] $KeyValueLines, # 如 "networkingMode=mirrored", "dnsTunneling=true", ...
        [string] $Delimiter = "="
    )

    # 1) 如果文件不存在，直接创建并写入段落
    if (-not (Test-Path $FilePath)) {
        # 先写一个空行（避免直接顶到文件最上？可选）
        $newLines = @()
        $newLines += $SectionHeader
        $newLines += $KeyValueLines
        $newLines | Out-File $FilePath -Encoding UTF8
        return
    }

    # 2) 文件已存在，读取全部行到数组
    $content = Get-Content -Path $FilePath

    # 找段落开头行
    # 注意 -eq $SectionHeader 表示严格匹配整行 (如 "[experimental]")
    # 但若用户原本写成 "[experimental] #somecomment" 就不会匹配到
    # => 可以用下面的 For 查找
    $sectionStart = $null
    for ($i = 0; $i -lt $content.Count; $i++) {
        # 如果只想匹配行首 + [section] + 行尾 (无多余字符):
        # if ($content[$i] -match '^\[experimental\]$')
        # 或使用 -eq $SectionHeader 也行:
        if ($content[$i] -eq $SectionHeader) {
            $sectionStart = $i
            break
        }
        # 如果要容忍同一行有其他内容(如 "[experimental] foo=bar"),
        # 就得额外拆分处理(见下文 “如何处理多余内容”)
    }

    # 若没找到段落，则追加
    if ($sectionStart -eq $null) {
        # 在文件末尾追加空行、再写段落
        Add-Content -Path $FilePath -Value "`n"
        Add-Content -Path $FilePath -Value $SectionHeader
        Add-Content -Path $FilePath -Value $KeyValueLines
        return
    }

    # 否则段落已存在
    # 强制确保该行只含 "[experimental]"，如果有多余内容就抹掉
    if ($content[$sectionStart] -notmatch '^\[.*\]$') {
        # 如果想保留多余内容，可以做更智能的拆分
        # 这里为了简单，直接覆盖
        $content[$sectionStart] = $SectionHeader
    }

    # 找段落结束 (下一行开头是^[ 或到文件尾)
    $sectionEnd = $content.Count - 1
    for ($j = $sectionStart + 1; $j -lt $content.Count; $j++) {
        if ($content[$j] -match '^\[.*\]') {
            $sectionEnd = $j - 1
            break
        }
    }

    # 取出该段落的行(不含第一行)
    $sectionBody = $content[($sectionStart+1)..$sectionEnd]

    # 下一步: 按行更新/插入
    # 思路: 构造一个 ArrayList 来存放更新后的行
    $updatedBody = [System.Collections.ArrayList]@($sectionBody)

    foreach ($kv in $KeyValueLines) {
        # "networkingMode=mirrored" -> key= "networkingMode", value= "mirrored"
        $splitIndex = $kv.IndexOf($Delimiter)
        if ($splitIndex -lt 1) {
            # 无法分割, 跳过
            continue
        }
        $key   = $kv.Substring(0, $splitIndex).Trim()
        $value = $kv.Substring($splitIndex + 1).Trim()

        # 在 existing lines 找相同 key
        $foundKey = $false
        for ($k = 0; $k -lt $updatedBody.Count; $k++) {
            $line = $updatedBody[$k].Trim()
            # 忽略空行或注释行
            if (!$line -or $line.StartsWith("#")) {
                continue
            }
            # 分割行
            $lineSplitIndex = $line.IndexOf($Delimiter)
            if ($lineSplitIndex -lt 1) {
                continue
            }
            $existingKey = $line.Substring(0, $lineSplitIndex).Trim()
            if ($existingKey -eq $key) {
                # 替换成新的 k=v
                $updatedBody[$k] = "$key$Delimiter$value"
                $foundKey = $true
                break
            }
        }
        if (-not $foundKey) {
            # 末尾追加
            [void]$updatedBody.Add("$key$Delimiter$value")
        }
    }

    # 组装写回: 保留段落之前 & 该段落第一行 & 更新后的段落体 & 段落之后
    $beforeSection = if ($sectionStart -gt 0) {
        $content[0..($sectionStart - 1)]
    } else {
        @()
    }
    $afterSection = if ($sectionEnd -lt ($content.Count - 1)) {
        $content[($sectionEnd + 1)..($content.Count - 1)]
    } else {
        @()
    }

    # 新的段落体: [experimental] 做完后要紧跟换行(可选).
    # 先收集：原段落第一行(保证它只含 [SectionName]) + updatedBody
    $newSection = New-Object System.Collections.ArrayList
    [void]$newSection.Add($content[$sectionStart])  # "[experimental]" (单独)
    foreach ($line in $updatedBody) {
        [void]$newSection.Add($line)
    }

    # 拼起来
    $newContent = $beforeSection + $newSection + $afterSection

    # 写回文件
    $newContent | Out-File -FilePath $FilePath -Encoding UTF8
}





function Toggle-WSLNetwork {
    # 用户选择
    Write-Host (Get-Message "toggle_network_EnterChoice")
    $choice = Read-Host
    if ($choice -eq 'q') {
        return
    }

    $filePath = Join-Path $env:USERPROFILE ".wslconfig"

    switch ($choice) {
        "1" {
            # Mirrored
            Update-ConfigSegment -FilePath "$env:USERPROFILE\.wslconfig" `
            -SectionHeader "[experimental]" `
            -KeyValueLines @(
                "networkingMode=mirrored",
                "dnsTunneling=true",
                "autoProxy=true",
                "hostAddressLoopback=true"
            )

            Write-Host (Get-Message "toggle_network_Enabled")
        }
        "2" {
            # NAT
            Update-ConfigSegment -FilePath "$env:USERPROFILE\.wslconfig" `
            -SectionHeader "[experimental]" `
            -KeyValueLines @(
                "networkingMode=NAT",
                "dnsTunneling=true",
                "autoProxy=true",
                "hostAddressLoopback=true"
            )
        
            Write-Host (Get-Message "toggle_network_Disabled")
        }
        default {
            Write-Host (Get-Message "toggle_network_InvalidChoice") -ForegroundColor Yellow
        }
    }

    Write-Host (Get-Message "toggle_network_RestartNotice") -ForegroundColor Yellow
}

Toggle-WSLNetwork
