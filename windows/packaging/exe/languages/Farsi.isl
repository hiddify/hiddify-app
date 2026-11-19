; *** Inno Setup version 6.5.0+ Farsi messages ***
;
; To download user-contributed translations of this file, go to:
;   https://jrsoftware.org/files/istrans/
;
; Note: When translating this text, do not add periods (.) to the end of
; messages that didn't have them already, because on those messages Inno
; Setup adds the periods automatically (appending a period would result in
; two periods being displayed).
;
; Translated by:
;   Peyman Mohammadi (peymanr34@outlook.com)

[LangOptions]
; The following three entries are very important. Be sure to read and 
; understand the '[LangOptions] section' topic in the help file.
LanguageName=Farsi
LanguageID=$0429
LanguageCodePage=1256
RightToLeft=yes
; If the language you are translating to requires special font faces or
; sizes, uncomment any of the following entries and change them accordingly.
;DialogFontName=
;DialogFontSize=9
;DialogFontBaseScaleWidth=7
;DialogFontBaseScaleHeight=15
;WelcomeFontName=Segoe UI
;WelcomeFontSize=14

[Messages]

; *** Application titles
SetupAppTitle=نصب کننده
SetupWindowTitle=نصب کننده - %1
UninstallAppTitle=حذف کننده
UninstallAppFullTitle=%1 حذف کننده

; *** Misc. common
InformationTitle=اطلاعات
ConfirmTitle=تایید
ErrorTitle=خطا

; *** SetupLdr messages
SetupLdrStartupMessage=این %1 را نصب می‌کند. آیا مایل به ادامه هستید؟
LdrCannotCreateTemp=خطا در ایجاد یک فایل موقت. برنامه نصب لغو شد
LdrCannotExecTemp=خطا در اجرای فایل در پوشه موقت. برنامه نصب لغو شد
HelpTextNote=

; *** Startup error messages
LastErrorMessage=%1.%n%nخطا %2: %3
SetupFileMissing=فایل %1 در پوشه نصب وجود ندارد. لطفاً مشکل را برطرف کرده و یا یک کپی جدید از برنامه را دریافت کنید.
SetupFileCorrupt=فایل های نصب کننده آسیب دیده‌اند. لطفاً یک کپی جدید از برنامه را دریافت کنید.
SetupFileCorruptOrWrongVer=فایل های نصب کننده آسیب دیده‌اند، یا با این نسخه از نصب کننده سازگار نیستند. لطفاً مشکل را برطرف کرده و یا یک کپی جدید از برنامه را دریافت کنید.
InvalidParameter=یک پارامتر نامعتبر به خط فرمان ارسال شده است:%n%n%1
SetupAlreadyRunning=نصب کننده از قبل در حال اجراست.
WindowsVersionNotSupported=این برنامه از نسخه ویندوزی که بر روی کامپیوتر شما در حال اجراست پشتیبانی نمی‌کند.
WindowsServicePackRequired=این برنامه نیازمند %1 سرویس پک %2 یا بالاتر است.
NotOnThisPlatform=این برنامه روی %1 اجرا نمی‌شود.
OnlyOnThisPlatform=این برنامه باید بر روی %1 اجرا شود.
OnlyOnTheseArchitectures=این برنامه تنها می‌تواند بر روی نسخه های ویندوزی نصب شود که برای معماری های پردازنده زیر طراحی شده‌اند:%n%n%1
WinVersionTooLowError=این برنامه نیازمند %1 نسخه %2 یا بالاتر است.
WinVersionTooHighError=این برنامه نمی‌تواند بر روی %1 نسخه %2 یا بالاتر نصب شود.
AdminPrivilegesRequired=هنگام نصب این برنامه، شما باید به عنوان یک کاربر مدیر وارد سیستم شده باشید.
PowerUserPrivilegesRequired=در هنگام نصب این برنامه، شما باید به عنوان کاربر مدیر وارد سیستم شده باشید و یا اینکه عضو گروه Power Users باشید.
SetupAppRunningError=نصب کننده %1 هم اکنون در حال اجراست.%n%nلطفاً اکنون تمام نمونه های آن را بسته، و سپس برای ادامه بر روی تایید، و یا برای خروج بر روی انصراف کلیک کنید.
UninstallAppRunningError=حذف کننده تشخیص داده است که %1 هم اکنون در حال اجراست.%n%nلطفاً اکنون تمام نمونه های آن را بسته، و سپس برای ادامه بر روی تایید، و یا برای خروج بر روی انصراف کلیک کنید.

; *** Startup questions
PrivilegesRequiredOverrideTitle=انتخاب نحوه نصب توسط نصب کننده
PrivilegesRequiredOverrideInstruction=انتخاب نحوه نصب
PrivilegesRequiredOverrideText1=%1 را می‌توان برای تمامی کاربران (نیازمند دسترسی مدیر سیستم)، و یا تنها برای شما نصب کرد.‏
PrivilegesRequiredOverrideText2=%1 را می‌توان تنها برای شما، و یا تمامی کاربران (نیازمند دسترسی مدیر سیستم) است.‏
PrivilegesRequiredOverrideAllUsers=نصب برای &تمامی کاربران
PrivilegesRequiredOverrideAllUsersRecommended=نصب برای &تمامی کاربران (پیشنهاد می‌شود)‏
PrivilegesRequiredOverrideCurrentUser=نصب تنها برای &من
PrivilegesRequiredOverrideCurrentUserRecommended=نصب تنها برای &من (پیشنهاد می‌شود)‏

; *** Misc. errors
ErrorCreatingDir=نصب کننده قادر به ایجاد پوشه نبود "%1"
ErrorTooManyFilesInDir=ایجاد یک فایل در پوشه "%1" بدلیل آنکه حاوی تعداد زیادی فایل است امکان پذیر نیست

; *** Setup common messages
ExitSetupTitle=خروج از نصب کننده
ExitSetupMessage=نصب به پایان نرسیده است. در صورتی که اکنون خارج شوید برنامه نصب نخواهد شد.‏%n%nشما می‌توانید نصب کننده را مجدداً در زمانی دیگر برای تکمیل عملیات نصب اجرا کنید.‏%n%nآیا مایل به خروج هستید؟
AboutSetupMenuItem=&درباره نصب کننده...
AboutSetupTitle=درباره نصب کننده
AboutSetupMessage=%1 نسخه %2%n%3%n%n%1 وب سایت:%n%4
AboutSetupNote=
TranslatorNote=

; *** Buttons
ButtonBack=< &قبلی
ButtonNext=&بعدی >
ButtonInstall=&نصب
ButtonOK=تایید
ButtonCancel=انصراف
ButtonYes=&بله
ButtonYesToAll=بله برای &همه
ButtonNo=&خیر
ButtonNoToAll=ن&ه برای همه
ButtonFinish=&پایان
ButtonBrowse=&مرور...
ButtonWizardBrowse=م&رور...‏
ButtonNewFolder=&ایجاد پوشه جدید

; *** "Select Language" dialog messages
SelectLanguageTitle=انتخاب زبان نصب کننده
SelectLanguageLabel=زبانی را که می‌خواهید در حین نصب استفاده کنید را انتخاب کنید.

; *** Common wizard text
ClickNext=برای ادامه بر روی بعدی کلیک کنید، برای خروج از نصب کننده بر روی انصراف کلیک کنید.‏
BeveledLabel=
BrowseDialogTitle=مرور برای پوشه
BrowseDialogLabel=از لیست زیر یک پوشه را انتخاب کرده و سپس بر روی تایید کلیک کنید.‏
NewFolderName=پوشه جدید

; *** "Welcome" wizard page
WelcomeLabel1=به ویزارد نصب کننده [name] خوش آمدید
WelcomeLabel2=این [name/ver] را بر روی کامپیوتر شما نصب می‌کند.‏%n%nپیشنهاد می‌شود قبل از ادامه تمامی اپلیکیشن های دیگر را ببندید.‏ 

; *** "Password" wizard page
WizardPassword=گذرواژه
PasswordLabel1=این نصب کننده با گذرواژه محافظت شده است.‏
PasswordLabel3=لطفاً یک گذرواژه را وارد کنید، سپس بر روی بعدی کلیک کنید. گذرواژه ها حساس به حروف بزرگ و کوچک هستند.‏
PasswordEditLabel=&گذرواژه:‏
IncorrectPassword=گذرواژه وارد شده اشتباه است. لطفاً مجدداً تلاش کنید.‏

; *** "License Agreement" wizard page
WizardLicense=توافقنامه استفاده
LicenseLabel=لطفاً اطلاعات مهم زیر را قبل از ادامه مطالعه کنید.‏
LicenseLabel3=لطفاً توافقنامه زیر را مطالعه کنید. شما باید مفاد این توافقنامه را پیش از ادامه نصب برنامه بپذیرید.
LicenseAccepted=من توافقنامه را &می‌پذیرم
LicenseNotAccepted=من توافقنامه را &نمی‌پذیرم

; *** "Information" wizard pages
WizardInfoBefore=اطلاعات
InfoBeforeLabel=لطفاً اطلاعات مهم زیر را قبل از ادامه مطالعه کنید.‏‏
InfoBeforeClickLabel=زمانی که آماده برای ادامه نصب هستید، بر روی بعدی کلیک کنید‏.‏
WizardInfoAfter=اطلاعات
InfoAfterLabel=لطفاً اطلاعات مهم زیر را قبل از ادامه مطالعه کنید.‏
InfoAfterClickLabel=زمانی که آماده برای ادامه‌ی نصب هستید، بر روی بعدی کلیک کنید‏.‏

; *** "User Information" wizard page
WizardUserInfo=اطلاعات کاربر
UserInfoDesc=لطفاً اطلاعات خود را وارد کنید.‏
UserInfoName=&نام کاربری:‏
UserInfoOrg=&سازمان:‏
UserInfoSerial=&شماره سریال:‏
UserInfoNameRequired=شما باید یک نام را وارد کنید.

; *** "Select Destination Location" wizard page
WizardSelectDir=انتخاب محل مقصد
SelectDirDesc=کجا باید [name] نصب شود؟
SelectDirLabel3=نصب کننده [name] را در پوشه زیر نصب می‌کند.‏
SelectDirBrowseLabel=برای ادامه، بر روی بعدی کلیک کنید. اگر مایل به انتخاب پوشه دیگری هستید، بر روی مرور کلیک کنید.‏
DiskSpaceGBLabel=حداقل [gb] گیگابایت از فضای خالی دیسک مورد نیاز است.‏
DiskSpaceMBLabel=حداقل [mb] مگابایت از فضای خالی دیسک مورد نیاز است.‏
CannotInstallToNetworkDrive=نصب کننده نمی‌تواند در یک درایو شبکه نصب را انجام دهد.
CannotInstallToUNCPath=نصب کننده نمی‌تواند در یک UNC path نصب را انجام دهد.
InvalidPath=شما باید یک آدرس کامل همراه با اسم درایو وارد کنید؛ به عنوان مثال:%n%nC:\APP%n%nو یا یک مسیر UNC به شکل مقابل:%n%n\\server\share
InvalidDrive=درایو یا UNC share انتخاب شده وجود ندارد و یا غیر قابل دسترسی است. لطفاً یک مسیر دیگر را انتخاب کنید.
DiskSpaceWarningTitle=فضای خالی دیسک کافی نیست
DiskSpaceWarning=نصب کننده به حداقل %1 کیلوبایت فضای خالی برای نصب نیاز دارد، اما درایو انتخاب شده فقط %2 کیلوبایت فضای آزاد دارد.%n%nآیا مایل به ادامه هستید؟
DirNameTooLong=نام پوشه یا مسیر بسیار طولانی است.‏
InvalidDirName=نام پوشه صحیح نیست.‏
BadDirName32=نام پوشه‌ها نمی‌تواند شامل کاراکتر های مقابل باشد:%n%n%1
DirExistsTitle=پوشه از قبل وجود دارد
DirExists=این پوشه:%n%n%1%n%nاز قبل وجود دارد. آیا بهرحال مایل به نصب در آن پوشه هستید؟
DirDoesntExistTitle=پوشه وجود ندارد
DirDoesntExist=این پوشه:%n%n%1%n%nوجود ندارد. آیا مایل به ساختن آن هستید؟

; *** "Select Components" wizard page
WizardSelectComponents=انتخاب اجزاء
SelectComponentsDesc=کدام اجزاء باید نصب شوند؟
SelectComponentsLabel2=اجزایی که مایل به نصب آن‌ها هستید را انتخاب کنید؛ اجزایی را که نمی‌خواهید نصب کنید را از حالت انتخاب بردارید.‏ زمانی که آماده برای ادامه بودید بر روی بعدی کلیک کنید.
FullInstallation=نصب کامل
; if possible don't translate 'Compact' as 'Minimal' (I mean 'Minimal' in your language)
CompactInstallation=نصب فشرده
CustomInstallation=نصب سفارشی
NoUninstallWarningTitle=اجزاء وجود دارند
NoUninstallWarning=نصب کننده تشخیص داده است که اجزای فوق از قبل بر روی کامپیوتر شما نصب شده است:%n%n%1%n%nعدم انتخاب این اجزاء باعث حذف شدن آن‌ها نمی‌شود.%n%nآیا مایل به ادامه هستید؟
ComponentSize1=%1 کیلوبایت
ComponentSize2=%1 مگابایت
ComponentsDiskSpaceGBLabel=انتخاب فعلی به حداقل [gb] گیگابایت فضای خالی دیسک نیاز دارد.‏
ComponentsDiskSpaceMBLabel=انتخاب فعلی به حداقل [mb] مگابایت فضای خالی دیسک نیاز دارد.‏

; *** "Select Additional Tasks" wizard page
WizardSelectTasks=انتخاب وظایف اضافی
SelectTasksDesc=کدام وظایف اضافی باید انجام شود؟
SelectTasksLabel2=وظایف اضافی را که تمایل دارید در هنگام نصب [name] انجام داده شود را انتخاب کرده، سپس بر روی بعدی کلیک کنید.‏

; *** "Select Start Menu Folder" wizard page
WizardSelectProgramGroup=انتخاب پوشه منوی استارت
SelectStartMenuFolderDesc=نصب کننده در کجا باید میانبر های برنامه را قرار دهد؟ 
SelectStartMenuFolderLabel3=نصب کننده میانبر های برنامه را در پوشه زیر در منوی استارت ایجاد خواهد کرد.
SelectStartMenuFolderBrowseLabel=برای ادامه، بر روی بعدی کلیک کنید. در صورتی که تمایل به انتخاب پوشه دیگری دارید، بر روی مرور کلیک کنید.
MustEnterGroupName=شما باید یک اسم پوشه را وارد کنید.
GroupNameTooLong=نام پوشه و یا مسیر آن بسیار طولانی است.
InvalidGroupName=نام پوشه صحیح نیست.
BadGroupName=نام پوشه نباید شامل هر یک از کاراکتر های زیر باشد:%n%n%1
NoProgramGroupCheck2=پوشه‌ای در منوی استارت ایجاد &نشود

; *** "Ready to Install" wizard page
WizardReady=آماده نصب
ReadyLabel1=نصب کننده آماده شروع نصب [name] بر روی کامپیوتر شماست.‏
ReadyLabel2a=برای ادامه نصب بر روی نصب کلیک کنید، و یا اگر تمایل به بازبینی یا تغییر تنظیمات دارید بر روی قبلی کلیک کنید.
ReadyLabel2b=برای ادامه نصب بر روی نصب کلیک کنید.‏
ReadyMemoUserInfo=اطلاعات کاربر:
ReadyMemoDir=محل مقصد:
ReadyMemoType=نوع نصب:
ReadyMemoComponents=اجزاء انتخاب شده:
ReadyMemoGroup=پوشه منوی استارت:
ReadyMemoTasks=وظایف اضافی:

; *** TDownloadWizardPage wizard page and DownloadTemporaryFile
DownloadingLabel2=در حال دانلود فایل ها...
ButtonStopDownload=&توقف دانلود
StopDownload=آیا مطمئن هستید که می‌خواهید دانلود را متوقف کنید؟
ErrorDownloadAborted=دانلود متوقف شد
ErrorDownloadFailed=دانلود ناموفق بود: %1 %2
ErrorDownloadSizeFailed=دریافت حجم ناموفق بود: %1 %2
ErrorProgress=پیشرفت نامعتبر: %1 از %2
ErrorFileSize=اندازه فایل نامعتبر: مورد انتظار %، پیدا شده %2

; *** TExtractionWizardPage wizard page and ExtractArchive
ExtractingLabel=در حال استخراج فایل ها...
ButtonStopExtraction=&توقف استخراج
StopExtraction=آیا مطمئن هستید که می‌خواهید استخراج را متوقف کنید؟
ErrorExtractionAborted=استخراج متوقف شد
ErrorExtractionFailed=استخراج ناموفق: %1

; *** Archive extraction failure details
ArchiveIncorrectPassword=گذرواژه اشتباه است
ArchiveIsCorrupted=فایل فشرده آسیب دیده است
ArchiveUnsupportedFormat=فرمت فایل فشرده پشتیبانی نمی‌شود

; *** "Preparing to Install" wizard page
WizardPreparing=در حال آماده سازی برای نصب
PreparingDesc=نصب کننده در حال آماده سازی برای نصب [name] بر روی کامپیوتر شماست.
PreviousInstallNotCompleted=نصب/حذف برنامه قبلی تکمیل نشده است. شما باید کامپیوتر خود را برای تکمیل عملیات نصب مجدداً راه‌اندازی کنید.%n%nپس از ری‌استارت کامپیوتر، نصب کننده را مجدداً برای تکمیل عملیات نصب [name] اجرا کنید.
CannotContinue=نصب کننده قادر به ادامه نیست. لطفاً برای خروج بر روی انصراف کلیک کنید.
ApplicationsFound=اپلیکیشن های زیر در حال استفاده از فایل هایی هستند که نیازمند بروزرسانی توسط نصب کننده هستند. پیشنهاد می‌شود به نصب کننده اجازه دهید تا این اپلیکیشن ها به صورت خودکار بسته شوند.
ApplicationsFound2=اپلیکیشن های زیر در حال استفاده از فایل هایی هستند که نیازمند بروزرسانی توسط نصب کننده هستند. پیشنهاد می‌شود به نصب کننده اجازه دهید تا این اپلیکیشن ها به صورت خودکار بسته شوند. پس از پایان نصب، نصب کننده تلاش می‌کند تا این اپلیکیشن ها را مجدداً اجرا کند.
CloseApplications=بستن &خودکار اپلیکیشن ها
DontCloseApplications=اپلیکیشن ها بسته &نشوند
ErrorCloseApplications=نصب کننده قادر به بستن خودکار تمام اپلیکیشن ها نبود. پیشنهاد می‌شود تمام اپلیکیشن هایی که از فایل هایی که نیاز به بروزرسانی توسط نصب کننده را دارند را قبل از ادامه ببندید.
PrepareToInstallNeedsRestart=نصب کننده باید کامپیوتر را مجدداً راه‌اندازی کند. پس از ری‌استارت کامپیوتر، نصب کننده را برای تکمیل عملیات نصب [name] مجدداً اجرا کنید.%n%nآیا مایل به راه‌اندازی مجدد هستید؟

; *** "Installing" wizard page
WizardInstalling=در حال نصب
InstallingLabel=لطفاً تا زمانی که نصب کننده [name] را بر روی کامپیوتر شما نصب می‌کند، صبر کنید.

; *** "Setup Completed" wizard page
FinishedHeadingLabel=در حال تکمیل ویزارد نصب کننده [name]
FinishedLabelNoIcons=نصب کننده، عملیات نصب [name] بر روی کامپیوتر شما را به پایان رساند.
FinishedLabel=نصب کننده، عملیات نصب [name] بر روی کامپیوتر شما را به پایان رساند. اپلیکیشن می‌تواند با انتخاب میانبر های نصب شده اجرا شود.
ClickFinish=برای خروج از نصب کننده بر روی پایان کلیک کنید.
FinishedRestartLabel=برای تکمیل عملیات نصب [name]، نصب کننده باید کامپیوتر شما راه مجدداً راه‌اندازی کند. آیا هم اکنون مایل به ری‌استارت هستید؟
FinishedRestartMessage=برای تکمیل عملیات نصب [name]، نصب کننده باید کامپیوتر شما را مجدداً راه‌اندازی کند.%n%nآیا هم اکنون مایل به ری‌استارت هستید؟
ShowReadmeCheck=بله، مایل به مشاهده فایل README هستم.
YesRadio=&بله، اکنون کامپیوتر را دوباره راه‌اندازی کن
NoRadio=&نه، بعداً خودم کامپیوتر را راه‌اندازی مجدد خواهم کرد
; used for example as 'Run MyProg.exe'
RunEntryExec=اجرای %1
; used for example as 'View Readme.txt'
RunEntryShellExec=مشاهده‌ی %1

; *** "Setup Needs the Next Disk" stuff
ChangeDiskTitle=نصب کننده به دیسک بعدی نیاز دارد
SelectDiskLabel2=لطفاً دیسک %1 را وارد کرده و بر روی تایید کلیک کنید.%n%nدر صورتی که فایل های روی این دیسک در پوشه‌ای غیر از پوشه نمایش داده شده قابل پیدا شدن است، مسیر صحیح را وارد کرده و یا بر روی مرور کلیک کنید.
PathLabel=&مسیر:
FileNotInDir2=فایل "%1" در مسیر "%2" پیدا نشد. لطفاً دیسک صحیح را وارد کرده و یا یک پوشه دیگر را انتخاب کنید.
SelectDirectoryLabel=لطفاً آدرس دیسک بعدی را تعیین کنید.

; *** Installation phase messages
SetupAborted=نصب کننده تکمیل نشد.%n%nلطفاً مشکل را برطرف کرده و سپس نصب کننده را مجدداً اجرا کنید.
AbortRetryIgnoreSelectAction=انتخاب عمل
AbortRetryIgnoreRetry=&تلاش مجدد
AbortRetryIgnoreIgnore=&صرف نظر از خطا و ادامه
AbortRetryIgnoreCancel=انصراف از عملیات نصب
RetryCancelSelectAction=انتخاب عملیات
RetryCancelRetry=&تلاش مجدد
RetryCancelCancel=انصراف

; *** Installation status messages
StatusClosingApplications=درحال بستن اپلیکیشن ها...
StatusCreateDirs=در حال ایجاد پوشه ها...
StatusExtractFiles=در حال استخراج فایل ها...
StatusDownloadFiles=در حال دانلود فایل ها...
StatusCreateIcons=در حال ایجاد میانبر ها...
StatusCreateIniEntries=در حال ایجاد ورودی های INI...
StatusCreateRegistryEntries=در حال ایجاد ورودی های ریجستری...
StatusRegisterFiles=در حال ریجستر فایل ها...
StatusSavingUninstall=در حال ذخیره اطلاعات حذف کننده...
StatusRunProgram=در حال پایان نصب...
StatusRestartingApplications=در حال راه‌اندازی مجدد اپلیکیشن ها...
StatusRollback=درحال بازگردانی تغییرات...

; *** Misc. errors
ErrorInternal2=خطای داخلی: %1
ErrorFunctionFailedNoCode=%1 ناموفق
ErrorFunctionFailed=%1 ناموفق؛ کد %2
ErrorFunctionFailedWithMessage=%1 ناموفق؛ کد %2.%n%3
ErrorExecutingProgram=خطا در اجرای فایل:%n%1

; *** Registry errors
ErrorRegOpenKey=خطا در بازکردن کلید ریجستری:%n%1\%2
ErrorRegCreateKey=خطا در ایجاد کلید ریجستری:%n%1\%2
ErrorRegWriteKey=خطا در نوشتن در کلید ریجستری:%n%1\%2

; *** INI errors
ErrorIniEntry=خطا در ایجاد ورودی INI در فایل "%1".

; *** File copying errors
FileAbortRetryIgnoreSkipNotRecommended=&پرش از این فایل (پیشنهاد نمی‌شود)
FileAbortRetryIgnoreIgnoreNotRecommended=&نادیده گرفتن خطا و ادامه (پیشنهاد نمی‌شود)
SourceIsCorrupted=فایل منبع آسیب دیده است
SourceDoesntExist=فایل منبع "%1" وجود ندارد
SourceVerificationFailed=اعتبار سنجی فایل منبع ناموفق بود: %1
VerificationSignatureDoesntExist=فایل امضاء "%1" وجود ندارد
VerificationSignatureInvalid=فایل امضاء "%1" نامعتبر است
VerificationKeyNotFound=فایل امضاء "%1" از کلیدی ناشناخته استفاده می‌کند
VerificationFileNameIncorrect=نام فایل اشتباه است
VerificationFileTagIncorrect=تگ فایل اشتباه است
VerificationFileSizeIncorrect=اندازه فایل اشتباه است
VerificationFileHashIncorrect=هش فایل اشتباه است
ExistingFileReadOnly2=فایل موجود بدلیل فقط-خواندنی بودن قابل جایگزینی نیست.
ExistingFileReadOnlyRetry=&حذف خصوصیت فقط-خواندنی و تلاش مجدد
ExistingFileReadOnlyKeepExisting=&نگه داشتن فایل موجود
ErrorReadingExistingDest=در هنگام تلاش برای خواندن فایل موجود خطایی رخ داده است:
FileExistsSelectAction=انتخاب عمل
FileExists2=فایل از قبل وجود دارد.
FileExistsOverwriteExisting=&بازنویسی فایل موجود
FileExistsKeepExisting=&نگه‌داشتن فایل موجود
FileExistsOverwriteOrKeepAll=&این کار را برای تداخل های بعد انجام بده
ExistingFileNewerSelectAction=انتخاب عمل
ExistingFileNewer2=فایل موجود از فایلی که نصب کننده در تلاش برای نصب آن است جدیدتر است.
ExistingFileNewerOverwriteExisting=&بازنویسی فایل موجود
ExistingFileNewerKeepExisting=&نگه داشتن فایل موجود (پیشنهاد می‌شود)
ExistingFileNewerOverwriteOrKeepAll=&این کار را برای تداخل های بعدی انجام بده
ErrorChangingAttr=در هنگام تلاش برای تغییر خصوصیت فایل موجود خطایی رخ داده است:
ErrorCreatingTemp=در هنگام تلاش برای ایجاد یک فایل در پوشه مقصد خطایی رخ داده است:
ErrorReadingSource=در هنگام تلاش برای خواندن فایل مبداء خطایی رخ داده است:
ErrorCopying=در هنگام تلاش برای کپی فایل خطایی رخ داده است:
ErrorDownloading=در هنگام تلاش برای دانلود فایل خطایی رخ داده است:
ErrorExtracting=در هنگام تلاش برای استخراج فایل فشرده خطایی رخ داده است:
ErrorReplacingExistingFile=در هنگام تلاش برای جایگزینی فایل موجود خطایی رخ داده است:
ErrorRestartReplace=RestartReplace ناموفق بود:
ErrorRenamingTemp=در هنگام تلاش برای تغییر نام یک فایل در پوشه مقصد خطایی رخ داده است:
ErrorRegisterServer=خطا در ریجستر DLL/OCX برای: %1
ErrorRegSvr32Failed=RegSvr32 با کد خطای ناموفق بود %1
ErrorRegisterTypeLib=قادر به ریجستر کتابخانه نوع نبود: %1

; *** Uninstall display name markings
; used for example as 'My Program (32-bit)'
UninstallDisplayNameMark=%1 (%2)
; used for example as 'My Program (32-bit, All users)'
UninstallDisplayNameMarks=%1 (%2، %3)
UninstallDisplayNameMark32Bit=32-بیت
UninstallDisplayNameMark64Bit=64-بیت
UninstallDisplayNameMarkAllUsers=تمامی کاربران
UninstallDisplayNameMarkCurrentUser=کاربر فعلی

; *** Post-installation errors
ErrorOpeningReadme=در هنگام تلاش برای بازکردن فایل README خطایی رخ داده است.
ErrorRestartingComputer=نصب کننده قادر به راه‌اندازی مجدد کامپیوتر نبود. لطفاً به صورت دستی ری‌استارت کنید.

; *** Uninstaller messages
UninstallNotFound=فایل "%1" وجود ندارد. حذف امکان پذیر نیست.
UninstallOpenError=امکان باز کردن فایل"%1" وجود ندارد. حذف امکان پذیر نیست
UninstallUnsupportedVer=فایل لاگ حذف کننده "%1" در فرمتی قرار دارد که توسط این نسخه از حذف کننده قابل شناسایی نیست. حذف امکان پذیر نیست
UninstallUnknownEntry=با یک ورودی ناشناخته (%1) در فایل لاگ حذف مواجه شده است 
ConfirmUninstall=آیا از حذف %1 و تمام اجزای آن اطمینان دارید؟
UninstallOnlyOnWin64=این برنامه نصب شده تنها در ویندوز 64-بیت قابل حذف است.
OnlyAdminCanUninstall=این برنامه نصب شده، تنها توسط یک کاربر با دسترسی مدیر قابل حذف است.
UninstallStatusLabel=لطفاً تا زمان حذف %1 از کامپیوتر شما صبر کنید.
UninstalledAll=%1 با موفقیت از روی کامپیوتر شما حذف شد.
UninstalledMost=%1 حذف تکمیل شد.%n%nبرخی از اجزاء را نمی‌توان حذف کرد. این موارد به صورت جداگانه قابل حذف هستند.
UninstalledAndNeedsRestart=برای تکمیل حذف %1 کامپیوتر شما باید مجدداً راه‌اندازی شود.%n%nآیا مایل هستید هم‌اکنون ری‌استارت شود؟
UninstallDataCorrupted="%1" فایل ناقص است. حذف امکان پذیر نیست

; *** Uninstallation phase messages
ConfirmDeleteSharedFileTitle=حذف فایل اشتراکی؟
ConfirmDeleteSharedFile2=سیستم نشان می‌دهد که فایل اشتراکی زیر دیگر توسط هیچ برنامه دیگری در حال استفاده نیست. آیا مایل هستید که حذف کننده این فایل اشتراکی را حذف کند؟?%n%nاگر برنامه‌هایی هنوز از این فایل استفاده می‌کنند، با حذف این فایل این برنامه‌ها ممکن است به درستی کار نکنند. اگر مطمئن نیستید، خیر را انتخاب کنید. نگه‌داشتن فایل بر روی سیستم شما هیچ آسیبی نمی‌رساند.
SharedFileNameLabel=نام فایل:
SharedFileLocationLabel=محل فایل:
WizardUninstalling=وضعیت حذف
StatusUninstalling=در حال حذف %1...

; *** Shutdown block reasons
ShutdownBlockReasonInstallingApp=در حال نصب %1.
ShutdownBlockReasonUninstallingApp=در حال حذف %1.

; The custom messages below aren't used by Setup itself, but if you make
; use of them in your scripts, you'll want to translate them.

[CustomMessages]

NameAndVersion=%1 نسخه %2
AdditionalIcons=میانبر های جانبی:
CreateDesktopIcon=ایجاد &میانبر روی دسکتاپ
CreateQuickLaunchIcon=ایجاد یک میانبر اجرای &سریع
ProgramOnTheWeb=%1 بر روی وب
UninstallProgram=حذف %1
LaunchProgram=اجرای %1
AssocFileExtension=&اختصاص دادن %1 با پسوند فایل %2 
AssocingFileExtension=در حال اختصاص %1 با پسوند فایل %2...
AutoStartProgramGroupDescription=شروع همراه با ویندوز:
AutoStartProgram=شروع خودکار %1
AddonHostProgramNotFound=%1 در پوشه انتخاب شده یافت نشد.%n%nآیا بهرحال مایل به ادامه هستید؟