#!/bin/bash

MEDIA_LIB_LOC='/var/bigpool/shares/dump/00_test_media_library'
INGEST_LOC='/var/bigpool/JupiterNT/test_ingest/davina/'
CURRENT_TIMESTAMP_WITH_MS=$(date +"%Y-%m-%dT%T.818Z")
CURRENT_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

 splash() {
    echo ">>>>>> WELCOME TO THE WIZARD FOR INGESTING MEDIA CONTENT FROM MARK HIMSLEY'S MEDIA LIBRARY ONTO NT <<<<<<"
    sleep 2
 }

 sending_auth() {
    echo $1
    sleep 2
    cat ~/.ssh/id_rsa.pub | ssh $2 ' cat >>.ssh/authorized_keys'
    sleep 2
 }

 display_list() {
     echo "choices are: "
     arr=("$@")
     for i in "${arr[@]}";
      do
        echo "$i"
      done
 }

 search_array() {
    arr=("${@:3}") 
    echo arr[@]: ${arr[@]}
    pos=$1
    focus=$2
    display_list "${arr[@]}"
    i=0
    while : ; do
        echo "... Please choose your $focus by typing in the whole filename or filepath ..."
        read selection
        echo "you have chosen: $selection .."

        while : ; do
            if [[ $selection == ${arr[$i]} ]] 
            then
            echo this $focus exists; 
            break 2 
            else
                if [ "$i" -eq $pos ]
                then
                    echo Am afraid this $focus is not on the list, try again ...
                    display_list "${arr[@]}"
                    i=0
                    break
                fi
            i=$((i+1)) 
            fi
        done 
    done
 }

 display_choices_and_prompt() {
    echo $1
    sleep 2
    if [[ $3 == 'resolution' ]]; then
        media_res=$(ssh npf@storage.jupiter.bbc.co.uk "cd $MEDIA_LIB_LOC;ls;")
    elif [[ $3 == 'file' ]]; then
        media_res=$(ssh npf@storage.jupiter.bbc.co.uk "cd $MEDIA_LIB_LOC/$chosen_res; find . -path '*.[a-z][a-z][a-z]' | cut -c2-")
    else
        echo " error with the 3rd argument, must be either 'resolution' or 'file"
        exit 1
    fi

    echo $2
    sleep 2
    media_res_array=($media_res)
    echo media_res_array: ${media_res_array[@]}
    mra_size=$(( ${#media_res_array[*]} - 1 ))
    search_array "$mra_size" $3 "${media_res_array[@]}"
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
    echo "3) I will create a new folder in NT (zgbwcjvsfs7ws01).. please log in with your jupiter password if this is the first time this script is run ..."
    sleep 2
    ssh zgbwcjvsfs7ws01.jupiter.bbc.co.uk "cd $INGEST_LOC;
    mkdir ivan-$CURRENT_TIMESTAMP;
    cd ivan-$CURRENT_TIMESTAMP;
    mkdir $1;
    cd $1;"
    echo "4) will need to login to dump again with npf to transfer source file to your directory temporarily ... "
    sleep 2
    scp npf@storage.jupiter.bbc.co.uk:/var/bigpool/shares/dump/00_test_media_library/$1/$selection ./
    echo "5) generating MD5 for this file ..."
    sleep 2
    md5sum $2 | cut -d' ' -f1 > $2.md5

    echo "6) will generate the xml file now... "
    sleep 2
    gen_xml $2.xml

    echo "7) will need to login to zgbwcjvsfs7ws01.jupiter.bbc.co.uk again with your Jupiter pw to transfer source file from your local to NT ingest server ... "
    sleep 2
    scp ./$2 ./$2.xml ./$2.md5 zgbwcjvsfs7ws01.jupiter.bbc.co.uk:/var/bigpool/JupiterNT/test_ingest/davina/ivan-$CURRENT_TIMESTAMP/$1
    rm ./$2 ./$2.xml ./$2.md5
 }

 success() {
    echo ">>>>>> The file $1 for resolution $2 has begun to be ingested <<<<<<"
    echo ">>>>>> check out the progress in http://zgbwcjvpxy7600.jupiter.bbc.co.uk/jupGUI/jobs/ <<<<<<"
    echo ">>>>>> After JOE jobs complete, check out the ingested media item in Jupiter Web https://test.jupiter.bbc.co.uk/#site=76&query=zzivan <<<<<<"
    sleep 2
 }

  failure() {
    echo ">>>>>> Unfortunately, The file $1 for resolution $2 could not be ingested <<<<<<"
    echo ">>>>>> Please run the script again <<<<<<"
    sleep 2
 }

splash
sending_auth " .. sending authorisation keys to the dump server where the contents are ... " npf@storage.jupiter.bbc.co.uk
sending_auth " .. sending authorisation keys to the destination NT server where the contents are, please log in with your JUPITER domain password if first time ... " zgbwcjvsfs7ws01.jupiter.bbc.co.uk
display_choices_and_prompt "1) SSHing to Test Library in storage.jupiter.bbc.co.uk ..." \
"Here are the resolutions available from the library ... " "resolution"
chosen_res=$selection
display_choices_and_prompt "2) OK, I will need to ask you which file in that resolution you would like to pick..." \
"Here are the files available in the library for that resolution ... " "file"
chosen_file=$(echo $selection |  rev | cut -d'/' -f1 | rev)

if [[ "$(ingest $chosen_res $chosen_file $selection)" != "0" ]];then
    success $chosen_file $chosen_res
else
    failure $chosen_file $chosen_res
fi

exit 0