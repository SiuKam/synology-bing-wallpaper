# saving location
savepath="/volume1/download/wallpaper"
# using api provided by cn.bing.com
pic_info=$(wget -t 5 --no-check-certificate -qO- "https://bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&uhd=1&uhdwidth=3840&uhdheight=2160")
pic_url=$(echo https://www.cn.bing.com$(echo $pic_info|sed 's/.\+"url"[:" ]\+//g'|sed 's/".\+//g'))
date=$(echo $pic_info|sed 's/.\+enddate[": ]\+//g'|grep -Eo 2[0-9]{7}|head -1)
savefile=$savepath/$date"_bing.jpg"
wget -t 5 --no-check-certificate $pic_url -qO $savefile
[ -s $savefile ]||exit
rm -rf /usr/syno/etc/login_background*.jpg
cp -f $savefile /usr/syno/etc/login_background.jpg &>/dev/null
cp -f $savefile /usr/syno/etc/login_background_hd.jpg &>/dev/null
copyright=$(echo $pic_info|sed 's/.\+"copyright[:" ]\+//g'|sed 's/".\+//g')
title=$(echo $pic_info|sed 's/.\+"title[:" ]\+//g'|sed 's/".\+//g')
sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
echo "login_background_customize=\"yes\"">>/etc/synoinfo.conf
sed -i s/login_welcome_title=.*//g /etc/synoinfo.conf
echo "login_welcome_title=\"$title\"">>/etc/synoinfo.conf
sed -i s/login_welcome_msg=.*//g /etc/synoinfo.conf
echo "login_welcome_msg=\"$copyright\"">>/etc/synoinfo.conf
# DO remember to change the username
cp -f $savefile /usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg
ln -sf /usr/syno/synoman/webman/resources/images/2x/default_wallpaper/dsm7_01.jpg /usr/syno/synoman/webman/resources/images/1x/default_wallpaper/dsm7_01.jpg
