#!/usr/bin/sh
# set -x
install_user_home=$1
vimforcpp_home=$install_user_home/.VimForCpp
# 是否安装 cquery 标记.
install_cquery_flag=0

function InstallEnv() {
  # 检查操作系统版本是否 ok
  version_ok=`uname -a | awk '{ if (index($0, "el7.x86_64") > 0) print 1; else print 0;}'`
  if [ $version_ok -eq 0 ]; then
    echo "操作系统版本不支持! 目前只支持 centos7 x86_64!"
    exit 1
  fi
  # 安装 git
  git --version > /dev/null
  if [ $? -ne 0 ]; then
    echo "未安装 git, 尝试安装 git"
    yum -y install git
  fi
  git --version > /dev/null
  if [ $? -ne 0 ]; then
    echo "git 安装失败!"
    exit 1
  fi
  # 安装 neovim
  echo "尝试安装 neovim"
  yum -y install epel-release
  yum install -y neovim.x86_64 python36-neovim.noarch
  nvim --version
  if [ $? -ne 0 ]; then
    echo "neovim 安装失败!"
    exit 1
  fi
  # 由于 centos7 yum 源上默认的 neovim 升级到了 neovim 0.3.0, 但是这个版本
  # 目前还有问题. 所以仍然需要使用 neovim 0.2.2. 上面的操作只是为了安装 Python 扩展
  yum install -y fuse-libs.x86_64 fuse.x86_64
  # 敲下 vim 命令实际启动了 nvim
  touch $install_user_home/.bashrc
  echo "alias vim='$vimforcpp_home/nvim'" >> $install_user_home/.bashrc

  # 安装 ctags
  yum -y install ctags
  # 安装 unzip
  yum -y install unzip
  echo "环境检测完毕!"
}

function DownloadVimConfig() {
  if [ -d $vimforcpp_home ]; then
    rm -rf $vimforcpp_home
  fi
  git clone https://gitee.com/HGtz2222/VimForCpp.git $vimforcpp_home
  if [ $? -ne 0 ]; then
    echo "Vim 配置下载出错!"
    exit 1
  fi
  echo "Vim 配置下载完毕"
}

function GetWhiteList() {
  # 分析 init.vim 中的插件列表, 获取到白名单内容, 并写入到 git 的对应文件中
  initvim=$1/vim/init.vim
  whitelist=$2/.git/info/sparse-checkout
  awk -F "[/\']" '{ if (index($1, "Plug") == 1) print $3; }' $initvim > $whitelist
  if grep -q "YouCompleteMe" $whitelist; then
    # 发现白名单中包含了 YCM, 则把对应的动态库的白名单也放进去.
    # TODO 后续考虑根据操作系统版本来决定下载哪个库
    echo "YCM.zip" >> $whitelist
    echo "YCM.so" >> $whitelist
  fi

  # 发现白名单中包含 cquery, 则需要准备后续的环境变量和安装额外的库
  if grep -q "LanguageClient" $whitelist; then
    install_cquery_flag=1
  fi
}

function DownloadPlugin() {
  bundle_dir=$vimforcpp_home/vim/bundle
  mkdir -p $bundle_dir
  cd $bundle_dir
  git init
  git remote add -f origin https://gitee.com/HGtz2222/vim-plugin-fork.git
  git config core.sparsecheckout true 
  GetWhiteList $vimforcpp_home $bundle_dir
  git pull origin master  
  # 增加对 YCM 的解压缩
  unzip YCM.zip
  cp $bundle_dir/YCM.so/el7.x86_64/* $bundle_dir/YouCompleteMe/third_party/ycmd/
  if [ $? -ne 0 ]; then
    echo "插件下载失败!"
    exit 1
  fi
  echo "插件下载完毕!"
}

function InstallCQuery() {
  # 0. 检查如果不需要安装 cquery 就直接返回
  if [ $install_cquery_flag -eq 0 ]; then
    return 0;
  fi
  # 1. 安装依赖的库
  if [ ! -f /usr/lib64/libatomic.so.1 ]; then
    echo "未找到 libstdatomic, 尝试安装..."
    yum install -y libatomic.x86_64
  fi
  # 2. 添加环境变量
  if ! grep -q ".VimForCpp/vim/bundle/YCM.so/el7.x86_64" $install_user_home/.bashrc; then
    echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/.VimForCpp/vim/bundle/YCM.so/el7.x86_64' >> $install_user_home/.bashrc
  fi
  # 3. 准备临时目录
  if [ -d /tmp/cquery -o -f /tmp/cquery ]; then
    rm -rf /tmp/cquery
  fi
  mkdir /tmp/cquery
  mkdir /tmp/cquery/cache
  cp $vimforcpp_home/cquery/config/settings.json /tmp/cquery/
}

function LinkDir() {
  # 先备份原有的 vim 配置文件
  today=`date +%m%d`
  mv $install_user_home/.vim $install_user_home/.vim.bak_${today} 2>/dev/null
  mv $install_user_home/.vimrc $install_user_home/.vimrc.bak_${today} 2>/dev/null
  mv $install_user_home/.ycm_extra_conf.py $install_user_home/.ycm_extra_conf.py.bak_${today} 2>/dev/null

  # 创建需要的软连接
  mkdir -p $install_user_home/.config
  rm -f $install_user_home/.config/nvim
  ln -s $vimforcpp_home/vim $install_user_home/.config/nvim
  ln -s $vimforcpp_home/vim $install_user_home/.vim
  ln -s $vimforcpp_home/vim/init.vim $install_user_home/.vimrc
  ln -s $vimforcpp_home/ycm_extra_conf.py $install_user_home/.ycm_extra_conf.py
  
  # 修改文件拥有者, 获得权限
  install_user=`echo $install_user_home | awk -F '/' '{print $3}'`
  chown -R $install_user:$install_user $vimforcpp_home
  chown -R $install_user:$install_user $install_user_home/.config/nvim
  chown -R $install_user:$install_user $install_user_home/.vim
  chown -R $install_user:$install_user $install_user_home/.vimrc
  chown -R $install_user:$install_user $install_user_home/.ycm_extra_conf.py
  chown -R $install_user:$install_user $vimforcpp_home/nvim

  if [ $install_cquery_flag -eq 1 ]; then
    chown -R $install_user:$install_user /tmp/cquery
    ln -s $vimforcpp_home/cquery/config/cquery.config $install_user_home/.cquery
    chown -R $install_user:$install_user $install_user_home/.cquery
  fi
}

# 1. 检查并安装依赖的软件
InstallEnv
# 2. 从码云上下载 vim 配置
DownloadVimConfig
# 3. 从码云上下载依赖的插件
DownloadPlugin
# 4. 决定是否安装 cquery
InstallCQuery
# 5. 备份对应用户的 .vim 目录, 并且建立好连接, 并修改文件权限
LinkDir
echo '安装成功! 请手动执行 "source ~/.bashrc" 或者重启终端, 使 vim 配置生效!'
