#!/usr/bin/sh
echo "
+------------------------------------------------------+
|                                                      |
|                      VimForCpp                       |
|                                                      |
+------------------------------------------------------+
安装开始!
整个过程大概需要下载大约 200MB 数据. 流量党请慎入!
"
# 切换到 root 用户, 并且触发安装脚本
install_user_home=$HOME

function SwitchRoot() {
  echo "为了安装依赖程序, 需要使用 root 账户. 您的密码不会被上传."
  echo "请输入 root 密码:"
  su -c "curl -sLf https://gitee.com/HGtz2222/VimForCpp/raw/master/start.sh -o /tmp/start.sh && bash /tmp/start.sh $install_user_home"
  rm -f /tmp/start.sh > /dev/null 2>&1
}

# 切换到 root 用户
SwitchRoot

