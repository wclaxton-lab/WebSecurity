#!/bin/bash
############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Management Center Script to aid API calls"
   echo
   echo "Syntax: MC [-u UUID|-d MC1|-a xyz|-o test.txt|-i input.txt|-f VIEW|-t POLICY|-h]"
   echo "options:"
   echo "u     UUID reference object"
   echo "d     MC Device"
   echo "a     MC API token bearer"
   echo "o     Output file"
   echo "i     Input file"
   echo "f     VIEW / UPDATE / RUN "
   echo "t     POLICY / JOB "
   echo "h     Print this Help."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":u:d:a:o:i:f:t:h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      u) # select uuid
         UUID=$OPTARG;;
      d) # select device
         DEVICE=$OPTARG;;
      a) # select authentication
         APIKEY=$OPTARG;;
      o) # select output file
         OUTPUT=$OPTARG;;
      i) # select input file
         INPUT=$OPTARG;;
      t) # select type
         TYPE=$OPTARG;;
      f) # select function
         FUNCTION=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option: -"$OPTARG""
         exit 1;;
      : ) echo "Option -"$OPTARG" requires an argument."
         exit 1;;
   esac
done

    case $FUNCTION in
      VIEW)
        METHOD="GET"
        if [ "$TYPE" = "JOB" ]
         then
          echo "only support run on job"
          exit 1
        fi
        INPUT=""
        ;;
      UPDATE)
        METHOD="POST"
         if [  -z "$INPUT" ]
         then
           echo "Need to specify input file for update, use the -i option."
           exit 1
         fi
         if [ "$TYPE" = "JOB" ]
         then
          echo "only support run on job"
          exit 1
        fi
         ;;
      RUN)
        if [ "$TYPE" = "POLICY" ]
         then
          echo "only support run on job"
          exit 1
        fi

        METHOD="POST"
        INPUT="";;
    esac


   case $TYPE in
     POLICY)
       MCAPIURL="https://$DEVICE/api/policies/$UUID/content"
     ;;
     JOB)
       MCAPIURL="https://$DEVICE/api/jobs/$UUID/run"
     ;;
   esac


status_code=$(curl --write-out '%{http_code}' -s --output $OUTPUT --data-binary "@$INPUT"  -k -H "X-Auth-Token: $APIKEY" -H "Content-Type: application/json" -X $METHOD $MCAPIURL )


if [ "$status_code" -ne 200 ] 
then
  echo "Issue with request - status code = $status_code"
  exit 1
fi
