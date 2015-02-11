# 填坑計劃：InstallScripts

## Roadmap

### Minimal
簡潔版的最小化安裝腳本。只安裝基本系統，每個腳本檔單獨拷貝下來都能直接使用，無須安裝一套腳本。

### Full
計劃中……

## Resources

### 在 Archlinux 上使用 Yum 包管理器
`install-fedora.sh` 依賴 yum, 為了方便在 Archlinux 中直接安裝 Fedora, 提供以下倉庫：
<pre>
[water]
Server = http://cirno.xyz/~jqk/archlinux/water/$arch
SigLevel = Never
</pre>
Packages:

- python2-pyliblzma 0.5.3-6
 
- rpm-org 4.12.0.1-1

- yum 3.4.3-5

- yum-metadata-parser 1.1.4-7