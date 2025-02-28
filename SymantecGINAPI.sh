#/usr/bin/sh
if [ $# -eq 0 ] ; then
    echo 'Usage: URL'
    exit 0
fi

TICKETURL=$1

TOKEN=`curl -s --location --request POST 'https://api.sep.securitycloud.symantec.com/v1/oauth2/tokens' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--header 'Authorization: Basic $GINBEARER'| cut -d "\"" -f4 `

echo Getting Symantec Threat Intelligence for $TICKETURL

TEXURL="https://api.sep.securitycloud.symantec.com/v1/threat-intel/insight/network/$TICKETURL"
AUTH="Authorization: Bearer "$TOKEN
RESP=`curl -s --location --request GET "$TEXURL" --header "$AUTH" `
URL=`echo $RESP | jq --raw-output 'try .network'`
TR=`echo $RESP | jq --raw-output 'try .threatRiskLevel.level'`
CAT=`echo $RESP | jq --raw-output 'try .categorization.categories[].name' |sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}'`
TOPCNT=`echo $RESP | jq --raw-output 'try .targetOrgs.topCountries[]' |sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}'`
TOPIND=`echo $RESP | jq --raw-output 'try .targetOrgs.topIndustries[]' |sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}'`
ACT=`echo $RESP | jq --raw-output 'try .actors[] ' |sed -n -e 'H;${x;s/\n/,/g;s/^,//;p;}'`
REP=`echo $RESP | jq --raw-output 'try .reputation'`
PRE=`echo $RESP | jq --raw-output 'try .prevalence'`
FS=`echo $RESP | jq --raw-output 'try .firstSeen'`
LS=`echo $RESP | jq --raw-output 'try .lastSeen'`

TEXT="URL: $URL&#13;&#10;Threat Risk: $TR&#13;&#10;Categorie(s): $CAT&#13;&#10;Reputation: $REP&#13;&#10;Prevalence: $PRE&#13;&#10;First Seen: $FS&#13;&#10;Last Seen: $LS&#13;&#10;Target Top Countries: $TOPCNT&#13;&#10;Target Top Industries: $TOPIND&#13;&#10;Actors: $ACT&#13;&#10;"

echo $TEXT
