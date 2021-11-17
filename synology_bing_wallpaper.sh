# saving location
savepath="/volume1/download/wallpaper"
# using api provided by atlinker.cn
pic_info=$(wget -t 5 --no-check-certificate -qO- "https://fly.atlinker.cn/api/bing/cn.php")
pic_url=$(echo https://www.bing.com$(echo $pic_info|sed 's/.\+"url"[:" ]\+//g'|sed 's/".\+//g'))
date=$(echo $pic_info|sed 's/.\+enddate[": ]\+//g'|grep -Eo 2[0-9]{7}|head -1)
savefile=$savepath/$date"_bing.jpg"
wget -t 5 --no-check-certificate $pic_url -qO $savefile
[ -s $savefile ]||exit
rm -rf /usr/syno/etc/login_background*.jpg
cp -f $savefile /usr/syno/etc/login_background.jpg &>/dev/null
cp -f $savefile /usr/syno/etc/login_background_hd.jpg &>/dev/null
copyright=$(echo $pic_info|sed 's/.\+"copyright[:" ]\+//g'|sed 's/".\+//g')
cninfo=$(echo $copyright|sed 's/，/"/g'|sed 's/,/"/g'|sed 's/(/"/g'|sed 's/ //g'|sed 's/\//_/g'|sed 's/)//g')
line_1=$(echo $cninfo|cut -d'"' -f1)
line_2=$(echo $cninfo|cut -d'"' -f2)
sed -i s/login_background_customize=.*//g /etc/synoinfo.conf
echo "login_background_customize=\"yes\"">>/etc/synoinfo.conf
sed -i s/login_welcome_title=.*//g /etc/synoinfo.conf
echo "login_welcome_title=\"$line_1\"">>/etc/synoinfo.conf
sed -i s/login_welcome_msg=.*//g /etc/synoinfo.conf
echo "login_welcome_msg=\"$line_2\"">>/etc/synoinfo.conf
cp -f $savefile /usr/syno/etc/preference/gan/wallpaper