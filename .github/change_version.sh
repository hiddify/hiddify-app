#! /bin/bash
SED() { [[ "$OSTYPE" == "darwin"* ]] && sed -i '' "$@" || sed -i "$@"; }
echo "previous version was $(git describe --tags $(git rev-list --tags --max-count=1))"
echo "WARNING: This operation will creates version tag and push to github"
if [ "$(curl -o /dev/null -I -s -w "%{http_code}" https://github.com/hiddify/hiddify-core/releases/download/v${CORE_VERSION}/hiddify-core-linux-amd64.tar.gz)" = "404" ]; then 
    echo "Core v${CORE_VERSION} not Found"; 
    exit 3; 
fi


cversion_string=$(grep -e "^version:" pubspec.yaml | cut -d: -f2-)
cstr_version=`echo "${cversion_string}" | sed -n "s/[ ]*\\([0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\)+.*/\\1/p"`
[ "$cversion_string" == "" ] && { echo "getting old version error"; exit 1 ; }
cbuild_number=`echo "${cversion_string}" | sed -n "s/.*+\\([0-9]\\+\\)/\\1/p"`
echo "Current Version Name:${cstr_version}   Build Number:${cbuild_number}"
read -p "new Version? (provide the next x.y.z semver) : " TAG 
echo $TAG 
[[ "$TAG" =~ ^[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}(\.dev)?$ ]] || { echo "Incorrect tag. e.g., 1.2.3 or 1.2.3.dev"; exit 1; } 
IFS="." read -r -a VERSION_ARRAY <<< "$TAG" 
VERSION_STR="${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}.${VERSION_ARRAY[2]}" 
BUILD_NUMBER=$(( ${VERSION_ARRAY[0]} * 10000 + ${VERSION_ARRAY[1]} * 100 + ${VERSION_ARRAY[2]} )) 
echo "version: ${VERSION_STR}+${BUILD_NUMBER}" 

SED "s/^version: .*/version: ${VERSION_STR}\+${BUILD_NUMBER}/g" pubspec.yaml 
SED "s/^msix_version: .*/msix_version: ${VERSION_ARRAY[0]}.${VERSION_ARRAY[1]}.${VERSION_ARRAY[2]}.0/g" windows/packaging/msix/make_config.yaml 
SED "s/CURRENT_PROJECT_VERSION = ${cbuild_number}/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER}/g" ios/Runner.xcodeproj/project.pbxproj 
SED "s/MARKETING_VERSION = ${cstr_version}/MARKETING_VERSION = ${VERSION_STR}/g" ios/Runner.xcodeproj/project.pbxproj 

git tag ${TAG} > /dev/null 

gitchangelog > HISTORY.md || { git tag -d ${TAG}; echo "Please run pip install gitchangelog pystache mustache markdown"; exit 2; } 
git tag -d ${TAG} > /dev/null 
git add libcore dependencies.properties ios/Runner.xcodeproj/project.pbxproj pubspec.yaml windows/packaging/msix/make_config.yaml HISTORY.md 
git commit -m "release: version ${TAG}" 
echo "creating git tag : v${TAG}" 
git push 
git tag v${TAG} 
git push -u origin HEAD --tags 
echo "Github Actions will detect the new tag and release the new version."
