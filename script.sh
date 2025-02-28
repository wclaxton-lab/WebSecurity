#!/bin/bash
declare -A TOPROCESS
declare -A FILTER
declare -A OUTPUTTYPE
declare -A CHANGETHRESHOLD

TOPROCESS[MCPOLICY_HELPDESK_ALLOWLIST]=TICKETSYSTEM
TOPROCESS[MCPOLICY_HELPDESK_BLOCKLIST]=TICKETSYSTEM
TOPROCESS[MCPOLICY_HELPDESK_ISOLATELIST]=TICKETSYSTEM
TOPROCESS[MCPOLICY_HELPDESK_JITLIST]=TICKETSYSTEM
TOPROCESS[MCPOLICY_HELPDESK_REVIEWLIST]=TICKETSYSTEM
TOPROCESS[MCPOLICY_GITHUB_BLOCKLIST]=LOCALFILE_CSV
TOPROCESS[MCPOLICY_GITHUB_ALLOWLIST]=LOCALFILE_CSV

#also do cpl

FILTER[MCPOLICY_HELPDESK_ALLOWLIST]='&filter[state][eq]=Closed&filter[status][eq]=Closed_Allowlist&fields[Cases]=requesturl_c,username_c,date_modified'
FILTER[MCPOLICY_HELPDESK_BLOCKLIST]='&filter[state][eq]=Closed&filter[status][eq]=Closed_Blocklist&fields[Cases]=requesturl_c,username_c,date_modified'
FILTER[MCPOLICY_HELPDESK_ISOLATELIST]='&filter[state][eq]=Closed&filter[status][eq]=Closed_Isolate&fields[Cases]=requesturl_c,username_c,date_modified'
FILTER[MCPOLICY_HELPDESK_JITLIST]='&filter[state][eq]=Closed&filter[status][eq]=Closed_JITAllow&fields[Cases]=requesturl_c,username_c,ruleexpiry_c,rulestart_c,date_modified'
FILTER[MCPOLICY_HELPDESK_REVIEWLIST]='&filter[state][eq]=Open&filter[status][eq]=Open_Review&fields[Cases]=requesturl_c,username_c'
FILTER[MCPOLICY_GITHUB_BLOCKLIST]='filename=BlockList.csv;header=enabled,url,description;columns=3'
FILTER[MCPOLICY_GITHUB_ALLOWLIST]='filename=AllowList.csv;header=enabled,url,description;columns=3'

OUTPUTTYPE[MCPOLICY_HELPDESK_ALLOWLIST]=CUSTOM_CATEGORY
OUTPUTTYPE[MCPOLICY_HELPDESK_BLOCKLIST]=CUSTOM_CATEGORY
OUTPUTTYPE[MCPOLICY_HELPDESK_ISOLATELIST]=CUSTOM_CATEGORY
OUTPUTTYPE[MCPOLICY_HELPDESK_JITLIST]=CPLJIT
OUTPUTTYPE[MCPOLICY_HELPDESK_REVIEWLIST]=CPLREVIEW
OUTPUTTYPE[MCPOLICY_GITHUB_ALLOWLIST]=CUSTOM_CATEGORY
OUTPUTTYPE[MCPOLICY_GITHUB_BLOCKLIST]=CUSTOM_CATEGORY

CHANGETHRESHOLD[MCPOLICY_HELPDESK_ALLOWLIST]=10
CHANGETHRESHOLD[MCPOLICY_HELPDESK_BLOCKLIST]=10
CHANGETHRESHOLD[MCPOLICY_HELPDESK_ISOLATELIST]=10
CHANGETHRESHOLD[MCPOLICY_HELPDESK_JITLIST]=100
CHANGETHRESHOLD[MCPOLICY_HELPDESK_REVIEWLIST]=100
CHANGETHRESHOLD[MCPOLICY_GITHUB_ALLOWLIST]=10
CHANGETHRESHOLD[MCPOLICY_GITHUB_BLOCKLIST]=10


for LISTTYPE in ${!TOPROCESS[@]}
do
		echo "Processing $LISTTYPE ..."
        
        case ${TOPROCESS[${LISTTYPE}]} in
         TICKETSYSTEM)
           TICKETAPIURLNEW=$TICKETAPIURL$APIFilter_Default${FILTER[${LISTTYPE}]}
    		TICKETLISTOUTPUT="tickets_$LISTTYPE.json"
	    	MCINPUT="MCINPUT_$LISTTYPE.json"
			MCEXISTING="MCEXISTING_$LISTTYPE.json"
			MCOUTPUT="MCOUTPUT_$LISTTYPE.json"
   	        PAYLOADE="MCEXISTINGPAYLOAD_$LISTTYPE.json"
  	        PAYLOADN="MCNEWPAYLOAD_$LISTTYPE.json"
        
			curl -s --location -g -k --request GET $TICKETAPIURLNEW --header "$TICKETAPIBEARER" >$TICKETLISTOUTPUT
			case ${OUTPUTTYPE[${LISTTYPE}]} in
			  CUSTOM_CATEGORY)
                cat BlockList.csv | jq -R '{content: {urls: (split(",") as $h|reduce inputs as $in ([]; . += [$in|split(",")|. as $a|reduce range(0,length) as $i ({};.[$h[$i]]=$a[$i])])),advancedSettings:{includeServerCertificateCpl: false,trigger: "URL",serverUrl:false}},schemaVersion: "1:0", contentType: "CUSTOM_CATEGORY",changeDescription: env.BUILD_TAG}' > BlockList_for_MC.json

				cat $TICKETLISTOUTPUT | jq '{content: {urls: (if ( .data |length==0) then ([{description: "placeholder", url:"notvalidurl.com",enabled:true}])  else ( .data |map( {description: ("Support Ticket: " + .id + ", Last Modified: " + .attributes.date_modified),url: (.attributes.requesturl_c |ascii_downcase|sub(":443";"")|sub(":80";"")|sub("https:\\/\\/";"")|sub("http:\\/\\/";"")), enabled: "true"})) end )},schemaVersion: "1:0", contentType: "CUSTOM_CATEGORY",changeDescription: env.BUILD_TAG}' > $MCINPUT
				;;
			  CPLJIT)
				cat $TICKETLISTOUTPUT | jq '{content: {sections:  [ { name: "JITCPL", purpose: "Just in time security CPL", defaultPolicy: (if ( .data |length==0) then (";no cpl") else ( .data |( "<proxy>\n" + ( map ( "user=\"" + .attributes.username_c + "\" url.domain=\"" + ( .attributes.requesturl_c |ascii_downcase|sub(":443";"")|sub(":80";"")|sub("https:\\/\\/";"")|sub("http:\\/\\/";"")) + "\" date=(" + (.attributes.rulestart_c |sub("T.*";"")|gsub("-";"")) + ".." + ( .attributes.ruleexpiry_c |sub("T.*";"")|gsub("-";"")) + ") allow     ;Support Ticket: " + .id + ", Last Modified: " + .attributes.date_modified )|join("\n"))))end), overridePolicy:null,mandatoryPolicy:null } ],editMode : "SIMPLE", referenceDeviceUuid : null }, schemaVersion: "1:0", contentType: "cplf",changeDescription: env.BUILD_TAG  } ' > $MCINPUT
				;;
			  CPLREVIEW)
				cat $TICKETLISTOUTPUT | jq '{content: {sections:  [ { name: "ReviewCPL", purpose: "Holding list for urls being reviewed", defaultPolicy: (if ( .data |length==0) then (";no cpl") else ( .data |( "<proxy>\n" + ( map ( "user=\"" + .attributes.username_c + "\" url.domain=\"" + ( .attributes.requesturl_c |ascii_downcase|sub(":443";"")|sub(":80";"")|sub("https:\\/\\/";"")|sub("http:\\/\\/";"")) + "\" force_exception(user-defined.ReviewState," + .id + ")\nurl.domain=\"" + ( .attributes.requesturl_c |ascii_downcase|sub(":443";"")|sub(":80";"")|sub("https:\\/\\/";"")|sub("http:\\/\\/";"")) + "\" force_exception(user-defined.ReviewStateGeneric)")|join("\n"))))end), overridePolicy:null,mandatoryPolicy:null } ],editMode : "SIMPLE", referenceDeviceUuid : null }, schemaVersion: "1:0", contentType: "cplf",changeDescription: env.BUILD_TAG  } ' > $MCINPUT
				;;
			  URLLIST)
				cat $TICKETLISTOUTPUT | jq '{content: {urls: (if ( .data |length==0) then ([{description: "placeholder", url:"notvalidurl.com",enabled:true}])  else ( .data |map( {description: ("Support Ticket: " + .id),url: (.attributes.requesturl_c |ascii_downcase|sub(":443";"")|sub(":80";"")|sub("https:\\/\\/";"")|sub("http:\\/\\/";"")), enabled: "true"})) end ),advancedSettings:{includeServerCertificateCpl: false,trigger: "URL",serverUrl:false}},schemaVersion: "1:0", contentType: "URL_LIST",changeDescription: env.BUILD_TAG}' > $MCINPUT
				;;
			esac
       ;;
         LOCALFILE_CSV)
            CSVDETAILS=${FILTER[${LISTTYPE}]}
            CSVFILE=$(echo $CSVDETAILS | cut -d ";" -f1 | cut -d "=" -f2)
            CSVHEADER=$(echo $CSVDETAILS | cut -d ";" -f2 | cut -d "=" -f2)
            CSVCOLUMNS=$(echo $CSVDETAILS | cut -d ";" -f3 | cut -d "=" -f2)
     
             #Validate the csv format first
            if [ "$CSVHEADER" != "" ]
            then
              CHECKHEADER="NR==1 && !/$CSVHEADER/{header++}"
            else
              CHECKHEADER=""
            fi
            if [ "$CSVCOLUMNS" != "" ]
            then
              CHECKCOLUMNS="NF!=3 {rows++}"
            else
              CHECKCOLUMNS=""
            fi
            
            VAL=`awk 'BEGIN{FS=OFS=","} '"$CHECKHEADER $CHECKCOLUMNS"' END{if (rows) {printf("File contains %d malformed line(s)\n",rows); exit 1}if(header){printf("Header contains malformed line\n"); exit 1}}' $CSVFILE`

			if [ "$VAL" != "" ]
			then
 				echo "$VAL"
 			exit 1
			fi
            
            #create output payloads
        	MCINPUT="MCINPUT_$LISTTYPE.json"
			MCEXISTING="MCEXISTING_$LISTTYPE.json"
			MCOUTPUT="MCOUTPUT_$LISTTYPE.json"
   	        PAYLOADE="MCEXISTINGPAYLOAD_$LISTTYPE.json"
  	        PAYLOADN="MCNEWPAYLOAD_$LISTTYPE.json"
        
			case ${OUTPUTTYPE[${LISTTYPE}]} in
              CUSTOM_CATEGORY)
				cat $CSVFILE | jq -R '{content: {urls: (split(",") as $h|reduce inputs as $in ([]; . += [$in|split(",")|. as $a|reduce range(0,length) as $i ({};.[$h[$i]]=$a[$i])])),advancedSettings:{includeServerCertificateCpl: false,trigger: "URL",serverUrl:false}},schemaVersion: "1:0", contentType: "CUSTOM_CATEGORY",changeDescription: env.BUILD_TAG}' > $MCINPUT
				;;
			  CPLJIT)
				#do nothing
                ;;
			  CPLREVIEW)
				#do nothing
                ;;
			  URLLIST)
				#do nothing
                ;;
              CPL)
                #create this one
                ;;
			esac
        ;;
      esac
        
        
        
        
        # Get existing MC payload
        sh ManagementCenterAPI.sh -f VIEW -t POLICY -u ${!LISTTYPE} -d $MCDEVICE1 -a $MCAPIKEY -i $MCINPUT -o $MCEXISTING
        
        #Compare against new MC payload
        cat $MCEXISTING | jq '.content' > $PAYLOADE
		cat $MCINPUT | jq '.content' > $PAYLOADN
		diff $PAYLOADE $PAYLOADN >/dev/null 2>&1
		DIFF=$?

		if [ $DIFF -eq 0 ]
		then
 			echo "No changes required"
		else
        	#check number of entries in old and new
            case ${OUTPUTTYPE[${LISTTYPE}]} in
		      CUSTOM_CATEGORY|URLLIST)
			    EXISTINGSIZE=`cat $MCEXISTING | jq '([.content.urls[].url]| length)'`
                NEWSIZE=`cat $MCINPUT | jq '([.content.urls[].url]| length)'`
             ;;
		     CPLJIT|CPLREVIEW)
			    EXISTINGSIZE=`cat $MCEXISTING | jq '.content.sections[].defaultPolicy | length'`
                NEWSIZE=`cat $MCINPUT | jq '.content.sections[].defaultPolicy | length'`
 			;;
		esac
        DIFFERENCE=`expr $EXISTINGSIZE - $NEWSIZE`
 		if [ $DIFFERENCE -lt 0 ]; then 
    	  DIFFERENCE=$(expr $DIFFERENCE \* -1) 
		fi 


        if [ $DIFFERENCE -gt ${CHANGETHRESHOLD[${LISTTYPE}]} ] 
        then
          echo "Changes to ${LISTTYPE} exceeded threshold of ${CHANGETHRESHOLD[${LISTTYPE}]} - Existing=$EXISTINGSIZE, New=$NEWSIZE, Difference=$DIFFERENCE"
          exit 1
        else
          echo "Changes to ${LISTTYPE} Submitting new file to Management Centre via API - Existing=$EXISTINGSIZE, New=$NEWSIZE, Difference=$DIFFERENCE"
          sh ManagementCenterAPI.sh -f UPDATE -t POLICY -u ${!LISTTYPE} -d $MCDEVICE1 -a $MCAPIKEY -i $MCINPUT -o $MCOUTPUT
        fi
 	fi    
done
