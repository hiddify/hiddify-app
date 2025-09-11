# key="FRu3eopQWgsvWmnycBXxv2eWpbUwGOu2"
# wget -O ../assets/translations/strings_en.i18n.json  "https://localise.biz/api/export/locale/en-US.json?index=id&format=i18next4&key=$key"
# wget -O ../assets/translations/strings_fa.i18n.json  "https://localise.biz/api/export/locale/fa.json?index=id&format=i18next4&key=$key"
# wget -O ../assets/translations/strings_zh.i18n.json  "https://localise.biz/api/export/locale/zh.json?index=id&format=i18next4&key=$key"
# # # wget -O ../assets/translations/strings_pt.i18n.json  "https://localise.biz/api/export/locale/pt.json?index=id&format=i18next4&key=$key"
# wget -O ../assets/translations/strings_ru.i18n.json  "https://localise.biz/api/export/locale/ru.json?index=id&format=i18next4&key=$key"



pip install polib deep-translator python-i18n

# python3 auto_translator.py fa en
python3 auto_translator.py en fa
python3 auto_translator.py en zh-CN
# python3 auto_translator.py en pt
python3 auto_translator.py en ru
python3 auto_translator.py en tr
python3 auto_translator.py en es



function update_localise(){
    lang=$1
	pat="../assets/translations/strings_${lang}.i18n.json"
	# if [[ $lang == 'en' ]];then
	# 	pat="../assets/translations/strings.i18n.json"
	# fi
# curl -X POST "https://localise.biz/api/import/json?locale=$lang&key=$LOCALIZ_KEY" \
curl "https://localise.biz/api/import/json?format=i18next4&delete-absent=false&ignore-existing=false&locale=$lang&flag-new=Provisional&key=$LOCALIZ_KEY" \
  -H 'Accept: application/json' \
  --data-binary @$pat 
  }


# update_localise en
# update_localise fa
# update_localise zh
# # # # update_localise pt
# update_localise ru