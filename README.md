https://confluence.dev.bbc.co.uk/display/JUPITER/Media+Ingest+Assistance+Script+for+NT+TEST

Media Ingest Assistance Script for NT TEST


Following up with the recent addition of the media test library on storage.jupiter.bbc.co.uk, which contains many files with different resolutions, the push was for QA to use this as extra ammunition to test NT ingest. Before this library, QA didn't really have a centralised location for media files and they weren't organised into folders according to their resolutions. File were loosely located on storage.


Issue:

    The process of testing ingest usually involves placing the media file, it's generated .md5 file and it's metadata .xml file into the NT test server at this location

zgbwcjntfs7601.jupiter.co.uk:/var/bigpool/JupiterNT/test_ingest/davina

    This will trigger the ingesting which appears in monitoring page 

zgbwcjntfs7601.jupiter.co.uk:/var/bigpool/JupiterNT/test_ingest/davina
zgbwcjvpxy7600.jupiter.bbc.co.uk/jupGUI/jobs

    Which should result in new item showing in Jweb

https://test.jupiter.bbc.co.uk/

    However this process when conducted manually can be a overhead, especially when transferring from storage.jupiter.bbc.co.uk, and with many files to test.


Solution:

ingest_from_media_library.sh written to automate most of the mundane processes, just will prompt user for 3 things:

    1) password to the NT test ingest server (only the first time script is run)
    2) video resolution
    3) file to choosse from


Usage Instructions:

    1) clone the ingest_from_media_library.sh script from this repo onto any location in your drive - https://github.com/bbc/bsd-qa-ingest-from-media-lib
    2) run - $sh ingest_from_media_library.sh
    3) select from the listed resolutions
    4) select from the listed files once resolution chosen
    5) the script will auto generate the .md5 and .xml files locally, before scp all 3 files to Ingest server
    6) user will be informed of completion success

