#!/bin/bash

MEDIA_LIB_LOC='/var/bigpool/shares/dump/00_test_media_library'
INGEST_LOC='/var/bigpool/JupiterNT/test_ingest/davina/'
CURRENT_TIMESTAMP=$(date +"%Y-%m-%dT%T.818Z")


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
        echo "2) Please choose your $focus by typing in the whole filename or filepath ..."
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
    echo $selection
 }


echo "1) SSHing to Test Library in storage.jupiter.bbc.co.uk, please log in as 'npf/npf'..."
sleep 2
MEDIA_RES=$(ssh npf@storage.jupiter.bbc.co.uk "cd $MEDIA_LIB_LOC;ls;")
echo "Here are the resolutions available from the library ... "
sleep 2
echo MEDIA_RES: $MEDIA_RES
media_res_array=($MEDIA_RES) 
echo media_res_array: ${media_res_array[@]}
mra_size=$(( ${#media_res_array[*]} - 1 ))
search_array "$mra_size" "resolution" "${media_res_array[@]}"


CHOSEN_RES=$selection
echo $CHOSEN_RES


echo "3) OK, I will need to ask you which file in that resolution you would like to pick... so you need to login again as npf/npf..."
sleep 2
MEDIA_FILES=$(ssh npf@storage.jupiter.bbc.co.uk "cd $MEDIA_LIB_LOC/$CHOSEN_RES; find . -path '*.[a-z][a-z][a-z]' | cut -c2-")
echo "Here are the files available in the library for that resolution ... "
sleep 2
echo MEDIA_FILES: $MEDIA_FILES

media_files_array=($MEDIA_FILES)
mfa_size=$(( ${#media_files_array[*]} - 1 ))
search_array "$mfa_size" "file" "${media_files_array[@]}"


CHOSEN_FILE=$(echo $selection |  rev | cut -d'/' -f1 | rev)
echo CHOSEN_FILE = $CHOSEN_FILE


DESTINATION_DIR=$(date +%Y%m%d_%H%M%S)
echo DESTINATION_DIR: $DESTINATION_DIR

echo "4) I will create a new folder in NT (zgbwcjvsfs7ws01).. please log in with your jupiter password ..."
sleep 2
ssh zgbwcjvsfs7ws01.jupiter.bbc.co.uk "cd $INGEST_LOC;
ls;
mkdir ivan-$DESTINATION_DIR;
cd ivan-$DESTINATION_DIR;
mkdir $CHOSEN_RES;
cd $CHOSEN_RES;"
echo "5) will need to login to dump again with npf to transfer source file to your directory temporarily ... "
sleep 2
scp npf@storage.jupiter.bbc.co.uk:/var/bigpool/shares/dump/00_test_media_library/$CHOSEN_RES/$selection ./
echo "6) generating MD5 for this file ..."
sleep 3
md5sum $CHOSEN_FILE | cut -d' ' -f1 > $CHOSEN_FILE.md5

echo "7) will generate the xml file now... "
sleep 3

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<newsMessage xmlns=\"http://iptc.org/std/nar/2006-10-01/\" xmlns:php=\"http://php.net/xsl\" xmlns:xhtml=\"http://www.w3.org/1999/xhtml\" xmlns:jupiter=\"http://jupiter.bbc.co.uk/newsml\" >
	<header>
		<sent>$CURRENT_TIMESTAMP</sent>
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
				<versionCreated jupiter:item=\"arrivaldatetime\">$CURRENT_TIMESTAMP</versionCreated>
				<generator/>
				<profile/>
			</itemMeta>
			<contentMeta>
				<contentCreated jupiter:item=\"creationdatetime\">$CURRENT_TIMESTAMP</contentCreated>
				<contentModified>2020-03-16T13:00:51.818Z</contentModified>

				<creator jupiter:item=\"createdbyuser\">
					<name>Ivan</name>
				</creator>
				<slugline jupiter:item=\"storyname\">zzivan</slugline>
				<headline jupiter:item=\"details\">ingest test sprint 43- 1731 ($CHOSEN_RES)</headline>
				<description jupiter:item=\"description\">
					this is to test $CHOSEN_RES
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
" >> $CHOSEN_FILE.xml


echo "8) will need to login to zgbwcjvsfs7ws01.jupiter.bbc.co.uk again with your Jupiter pw to transfer source file from your local to NT ingest server ... "
scp ./$CHOSEN_FILE ./$CHOSEN_FILE.xml ./$CHOSEN_FILE.md5 zgbwcjvsfs7ws01.jupiter.bbc.co.uk:/var/bigpool/JupiterNT/test_ingest/davina/ivan-$DESTINATION_DIR/$CHOSEN_RES
rm ./$CHOSEN_FILE ./$CHOSEN_FILE.xml ./$CHOSEN_FILE.md5


exit 0