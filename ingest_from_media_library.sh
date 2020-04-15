#!/bin/bash

DUMP_HOST='storage.jupiter.bbc.co.uk'
NT_INGEST_HOST='zgbwcJNTfs7601.jupiter.bbc.co.uk'
DUMP_USER='npf'
DUMP_PW='npf'
MOUNT_PT=dump
MEDIA_LIB_LOC="./$MOUNT_PT/00_test_media_library"
INGEST_LOC='/var/bigpool/JupiterNT/test_ingest/davina'
CURRENT_TIMESTAMP_WITH_MS=$(date +"%Y-%m-%dT%T.818Z")
CURRENT_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_EXTS=('MXF' 'mov' 'avi' 'AVI' 'wav' 'ts' 'BIM' 'PPN' 'SMI' 'IND' 'BMP' 'mp4')
FIND_FILES_CMD="find ."
TMP_DIR=to_be_ingested_tmp


 splash() {
    echo ">>>>>> WELCOME TO THE WIZARD FOR INGESTING MEDIA CONTENT FROM MARK HIMSLEY'S MEDIA LIBRARY ONTO NT <<<<<<"
    sleep 2
    read -p " ... please type your jupiter username for NT ingest server $NT_INGEST_HOST : " ingest_host_user
 }

 mkdir_test() {
    if [ ! -d "$1" ]; then
       echo "... you dont have dump mount point"
       mkdir $1
    else
       echo "... you have storage directory already"
    fi
 }

 mount_host() {
    echo $1
    mkdir_test $5
    mount -t smbfs //$2:$3@$4/$5 ./$5/
 }

 unmount_host() {
   echo $1
   umount $2
 }

 sending_auth() {
    echo $1
    sleep 2
    ssh-copy-id -i ~/.ssh/id_rsa.pub $2
    sleep 2
 }

 display_list() {
     echo "... choices are: "
     arr=("$@")
     for i in "${!arr[@]}";
      do
        echo "$i ) - ${arr[$i]}"
      done
 }

 try_again_sub() {
    echo "... error: $1. Try again between 0 and $2" >&2
 }

 search_array() {
    arr=("${@:3}")
    pos=$1
    focus=$2
    display_list "${arr[@]}"

    while : ; do

        read -p "... Please choose your $focus by typing in the index: " selection
        echo "... you have chosen: $selection .."

        re='^[0-9]+$'
        if ! [[ $selection =~ $re ]] ; then
            try_again_sub "Not a number" $pos
            display_list "${arr[@]}"
        else
            if [[ $selection -ge 0 && $selection -le $pos ]]; then
                echo "... this $focus exists";
                break
            else
                try_again_sub "Am afraid this $focus is not on the list" $pos
                display_list "${arr[@]}"
            fi
        fi
    done
 }

 build_find_command() {
    echo " ... gathering all the file extensions set in this script under FILE_EXTS to search "
    for i in ${!FILE_EXTS[@]}; do
        if [[ $i -eq 0 ]]; then
            FIND_FILES_CMD+=" -path '*.${FILE_EXTS[$i]}' "
        else
            FIND_FILES_CMD+="-o  -path '*.${FILE_EXTS[$i]}' "
        fi
    done
 }

 display_choices_and_prompt() {
    echo $1
    sleep 2

    if [[ $3 == 'resolution' ]]; then
        media_display=$(cd $MEDIA_LIB_LOC;ls;)
        media_display_array=($media_display)
    elif [[ $3 == 'file' ]]; then
        build_find_command
        results_raw=$(cd $MEDIA_LIB_LOC/$chosen_res; eval $FIND_FILES_CMD)

        media_display=$(echo $results_raw)

        if [[ ! $media_display ]]; then
            return 1
        else
            delimiter=" ."
            s=$(echo $media_display | cut -c2-)$delimiter
            media_display_array=();
            while [[ $s ]]; do
                media_display_array+=( "${s%%"$delimiter"*}" );
                s=${s#*"$delimiter"};
            done;
        fi
    else
        echo "... error with the 3rd argument, must be either 'resolution' or 'file" >&2
        exit 1
    fi
    sleep 2

    mra_size=$(( ${#media_display_array[*]} - 1 ))
    search_array $mra_size $3 "${media_display_array[@]}"

 }

 select_res_and_file() {
    while : ; do
        display_choices_and_prompt "1) Locating the Test Media Library in the mounted drive: $DUMP_HOST ..." \
        "Here are the resolutions available from the library ... " "resolution"
        chosen_res=${media_display_array[$selection]}

        display_choices_and_prompt "2) Locating the Files for that resolution ..." \
        "Here are the files available in the library for that resolution ... " "file"
        if [[ $? -eq 0 ]];then
            echo "good to go, there are files "
            break
        else
            echo "... sorry there are currently no files for this resolution! try picking another resolution ... "
        fi
    done
 }

 gen_xml() {
     echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <newsMessage xmlns=\"http://iptc.org/std/nar/2006-10-01/\" xmlns:php=\"http://php.net/xsl\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" xmlns:jupiter=\"http://jupiter.bbc.co.uk/newsml\" >
        <header>
            <sent>$CURRENT_TIMESTAMP_WITH_MS</sent>
            <sender>Shoot edit tool</sender>
            <priority>4</priority>
        </header>
        <itemSet>
            <newsItem standard=\"NewsML-G2\" standardversion=\"2.25\" conformance=\"power\" guid=\"$UUID\"  >
                <catalogRef href=\"http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_22.xml\"/>
                <rightsInfo>
                    <copyrightHolder  literal=\"TEST 2\" jupiter:item=\"summarycopyrightholder\">
                        <name>BSD</name>
                    </copyrightHolder>
                    <usageTerms jupiter:item_trafficlightdescription=\"RED\">WARNING THIS A TRAFFICLIGHT DESCRIPTION

                        This content is for testing  purposes only.</usageTerms>
                </rightsInfo>
                <itemMeta>
                    <itemClass qcode=\"ninat:video\"/>
                    <provider qcode=\"nprov:BBC\"/>
                    <versionCreated jupiter:item=\"arrivaldatetime\">$CURRENT_TIMESTAMP_WITH_MS</versionCreated>
                    <generator/>
                    <profile/>
                </itemMeta>
                <contentMeta>
                    <contentCreated jupiter:item=\"creationdatetime\">$CURRENT_TIMESTAMP_WITH_MS</contentCreated>
                    <contentModified>2020-03-16T13:00:51.818Z</contentModified>

                    <creator jupiter:item=\"createdbyuser\">
                        <name>Ivan</name>
                    </creator>
                    <slugline jupiter:item=\"storyname\">zzivan</slugline>
                    <headline jupiter:item=\"details\">ingest test sprint 43- 1731 ($chosen_res / $chosen_file)</headline>
                    <description jupiter:item=\"description\">
                        this is to test ingest of $chosen_res with file $chosen_file
                     </description>

                    <keyword/>
                    <language tag=\"en-GB\"/>
                    <jupiter:outlet>News</jupiter:outlet>
                    <jupiter:mediastatus>Rough Cut</jupiter:mediastatus>
                    <jupiter:mediacategory>Fimport</jupiter:mediacategory>
                    <jupiter:description>
                        <jupiter:sourcedescription>BSD</jupiter:sourcedescription>
                        <jupiter:crewcamerman>Ivan</jupiter:crewcamerman>
                    </jupiter:description>
                </contentMeta>
            </newsItem>
        </itemSet>
    </newsMessage>
    " >> $1
 }

 ingest() {
    echo "3) Just gonna create a temp folder to gather all the essential files for ingesting ..."
    sleep 2
    mkdir_test $4

    echo "4) copying over the file to temp dir ..."
    sleep 2
    cp $1 $4

    echo "5) generating MD5 for this file ..."
    sleep 2
    md5sum $2 | cut -d' ' -f1 > $2.md5
    md5sum ./$4/$2 | cut -d' ' -f1 > ./$4/$2.md5

    echo "6) will generate the xml file now... "
    sleep 2
    gen_xml ./$4/$2.xml

    echo "7) I will create a new folder in NT ($NT_INGEST_HOST).. please log in with your jupiter password if this is the first time this script is run ..."
    sleep 2
    ssh $NT_INGEST_HOST "cd $INGEST_LOC;
    mkdir ivan-$CURRENT_TIMESTAMP;
    cd ivan-$CURRENT_TIMESTAMP;
    mkdir $3;
    cd $3"

    echo "8) will begin SCP the contents of the temp dir to this folder"
    sleep 2
    cd ./$4/
    scp ./$2 ./$2.xml ./$2.md5 $NT_INGEST_HOST:$INGEST_LOC/ivan-$CURRENT_TIMESTAMP/$3
    cd ..
    rm -R ./$4
 }

 success() {
    echo ">>>>>> The file $1 for resolution $2 has begun to be ingested <<<<<<"
    echo ">>>>>> check out the progress in http://zgbwcjvpxy7600.jupiter.bbc.co.uk/jupGUI/jobs/ <<<<<<"
    echo ">>>>>> After JOE jobs complete, check out the ingested media item in Jupiter Web https://test.jupiter.bbc.co.uk/#site=76&query=zzivan <<<<<<"
    exit 0
 }

  failure() {
    echo ">>>>>> Unfortunately, The file $1 for resolution $2 could not be ingested <<<<<<"
    echo ">>>>>> Please run the script again <<<<<<"
    exit 1
 }

 test_ingest() {
    ingest $1 $2 $3
    if [ $? -eq 0 ]; then
        success $2 $1
    else
        failure $2 $1
    fi
 }

splash
mount_host " .. mounting Jupiter storage drive to local in order to retrieve files for ingest ... " $DUMP_USER $DUMP_PW $DUMP_HOST $MOUNT_PT
sending_auth " .. sending authorisation keys to the destination NT server where the contents are, please log in with your JUPITER domain password if first time ... " $ingest_host_user@$NT_INGEST_HOST
select_res_and_file
chosen_file_with_path=${media_display_array[$selection]}

echo DEBUG: chosen_file_with_path = $chosen_file_with_path

chosen_file=$(echo ${media_display_array[$selection]} |  rev | cut -d'/' -f1 | rev)

echo DEBUG: chosen_file = $chosen_file

path_to_file=$MEDIA_LIB_LOC/$chosen_res$chosen_file_with_path

echo DEBUG: path_to_file = $path_to_file

#test_ingest $path_to_file $chosen_file $chosen_res $TMP_DIR
unmount_host " 9) .. unmounting Jupiter storage drive to end testing ... " $MOUNT_PT
