
echo "switch to $1 mode"

if [ "$1" == "pro" ]; then
    sed "s/T4C .*<\/string>/Tweet4China<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/me.tuoxie.*<\/string>/me\.tuoxie\.\$\{PRODUCT_NAME\:rfc1034identifier\}Pro<\/string>/g"  Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/^#define FreeApp$/\/\/#define FreeApp/g"  src/HSUDefinitions.h > src/HSUDefinitions.h.tmp
    mv src/HSUDefinitions.h.tmp src/HSUDefinitions.h
elif [ "$1" == "free" ]; then
    sed "s/T4C .*<\/string>/T4C Free<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist
    sed "s/Tweet4China<\/string>/T4C Free<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/me.tuoxie.*<\/string>/me\.tuoxie\.\$\{PRODUCT_NAME\:rfc1034identifier\}<\/string>/g"  Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/\/\/#define FreeApp$/#define FreeApp/g"  src/HSUDefinitions.h > src/HSUDefinitions.h.tmp
    mv src/HSUDefinitions.h.tmp src/HSUDefinitions.h
elif [ "$1" == "hd" ]; then
    sed "s/T4C .*<\/string>/Tweet4China<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/me.tuoxie.*<\/string>/me\.tuoxie\.\$\{PRODUCT_NAME\:rfc1034identifier\}HD<\/string>/g"  Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/^#define FreeApp$/\/\/#define FreeApp/g"  src/HSUDefinitions.h > src/HSUDefinitions.h.tmp
    mv src/HSUDefinitions.h.tmp src/HSUDefinitions.h
elif [ "$1" == "test" ]; then
    sed "s/T4C .*<\/string>/T4C 内测$2<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist
    sed "s/Tweet4China<\/string>/T4C 内测$2<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/me.tuoxie.*<\/string>/me\.tuoxie\.\$\{PRODUCT_NAME\:rfc1034identifier\}30<\/string>/g"  Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/^#define FreeApp$/\/\/#define FreeApp/g"  src/HSUDefinitions.h > src/HSUDefinitions.h.tmp
    mv src/HSUDefinitions.h.tmp src/HSUDefinitions.h
elif [ "$1" == "sp" ]; then
    sed "s/T4C .*<\/string>/T4C 喵版<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist
    sed "s/Tweet4China<\/string>/T4C 喵版<\/string>/g" Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/me.tuoxie.*<\/string>/me\.tuoxie\.\$\{PRODUCT_NAME\:rfc1034identifier\}SP<\/string>/g"  Tweet4China/Tweet4China-Info.plist > Tweet4China/Tweet4China-Info.plist.tmp
    mv Tweet4China/Tweet4China-Info.plist.tmp Tweet4China/Tweet4China-Info.plist

    sed "s/^#define FreeApp$/\/\/#define FreeApp/g"  src/HSUDefinitions.h > src/HSUDefinitions.h.tmp
    mv src/HSUDefinitions.h.tmp src/HSUDefinitions.h
fi
