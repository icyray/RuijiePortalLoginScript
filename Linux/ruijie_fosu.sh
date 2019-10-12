#!/bin/bash

#Config
userAgent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36"
CaptiveServer="http://www.google.cn/generate_204"

#If received logout parameter, send a logout request to eportal server
if [ "${1}" = "logout" ]; then
  interFace=""
  if [ -n "${2}" ]; then
    interFace="--interface ${2} "
  fi

  userIndex=`curl -s ${interFace}-A "${userAgent}" -I http://10.10.10.4/eportal/redirectortosuccess.jsp | grep -o 'userIndex=.*'` #Fetch user index for logout request
  logoutResult=`curl -s ${interFace}-A "${userAgent}" -d "${userIndex}" http://10.10.10.4/eportal/InterFace.do?method=logout`
  echo $logoutResult
  exit 0
fi

#If received parameters is less than 3, print usage
if [ "${#}" -lt "3" ]; then
  echo "Usage: ./ruijie_fosu.sh service username password <interface>"
  echo "Service parameter can be \"chinamobile\", \"chinanet\" and \"chinaunicom\". If service parameter do not set as these value, it will use campus network as default internet service provider."
  echo "[Optional] You can set an interface parameter to assign the correct network card. Keep this parameter empty if you want to use the default value."
  echo "Example: ./ruijie_fosu.sh chinanet 201620000000 123456 eth0"
  echo "if you want to logout, use: ./ruijie_fosu.sh logout"
  exit 1
fi

#If received interface parameter, set the right interface to curl
interFace=""
if [ -n "${4}" ]; then
  interFace="--interface ${4} "
fi

#Exit the script when is already online, use www.google.cn/generate_204 to check the online status
captiveReturnCode=`curl -s ${interFace}-I -m 10 -o /dev/null -s -w %{http_code} ${CaptiveServer}`
if [ "${captiveReturnCode}" = "204" ]; then
  echo "You are already online!"
  exit 0
fi

#If not online, begin Ruijie Auth

#Get Ruijie login page URL
loginPageURL=`curl -s ${interFace}"${CaptiveServer}" | awk -F \' '{print $2}'`
campus="%25e6%25a0%25a1%25e5%2586%2585%25e7%25bd%2591"
chinanet="%25e7%2594%25b5%25e4%25bf%25a1"
chinaunicom="%25e8%2581%2594%25e9%2580%259a"
chinamobile="%25e7%25a7%25bb%25e5%258a%25a8"

service=""

if [ "${1}" = "chinamobile" ]; then
  echo "Use ChinaMobile as internet service provider."
  service="${chinamobile}"
fi

if [ "${1}" = "chinanet" ]; then
  echo "Use ChinaNet as internet service provider."
  service="${chinanet}"
fi

if [ "${1}" = "chinaunicom" ]; then
  echo "Use ChinaUnicom as internet service provider."
  service="${chinaunicom}"
fi

if [ -z "${service}" ]; then
  echo "Use Campus Network internet service provider."
  service="${campus}"
fi

#Structure loginURL
loginURL=`echo ${loginPageURL} | awk -F \? '{print $1}'`
loginURL="${loginURL/index.jsp/InterFace.do?method=login}"

#Structure quertString
queryString=`echo ${loginPageURL} | awk -F \? '{print $2}'`
queryString="${queryString//&/%2526}"
queryString="${queryString//=/%253D}"

#Send Ruijie eportal auth request and output result
if [ -n "${loginURL}" ]; then
  authResult=`curl -s ${interFace}-A "${userAgent}" -e "${loginPageURL}" -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" -d "userId=${2}&password=${3}&service=${service}&queryString=${queryString}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" "${loginURL}"`
  echo $authResult
fi