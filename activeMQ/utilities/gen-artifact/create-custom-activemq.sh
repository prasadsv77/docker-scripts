#!/usr/bin/env bash

PID=$$
SCRIPT_NAME=`basename $0`
CURRENT_DIR=`pwd`
BASE_DIR="$(cd "$(dirname "$0")"; pwd)";
cd $BASE_DIR
BUILD_DIR=build
CUR_TS=$(date "+%Y%m%d%H%M%S")
echo "PWD =>" `pwd`

if [ -f "./data.json" ]; then
    JSON_DATA=$(<data.json)
else
    echo "Input file - 'data.json' file not found."
    cd $CURRENT_DIR
    exit 1
fi

case "$OSTYPE" in
  solaris*) echo
    echo "SOLARIS"
    jq="./jq/linux/jq"
    ;;
  darwin*)  echo
    echo "OSX"
    jq="./osx/jq"
    export PATH=$BASE_DIR/jq/osx:$PATH
    ;;
  linux*)   echo
    echo "LINUX"
    jq="./jq/linux/jq"
    export PATH=$BASE_DIR/jq/linux:$PATH
    ;;
  bsd*)  echo
    echo "BSD"
    jq="./linux/jq"
    ;;
  msys*)   echo
    echo "WINDOWS"
    ;;
  *)    echo
    echo "unknown: $OSTYPE"
    ;;
esac


sleep 2

ACTIVEMQ_VERSION=$(echo $JSON_DATA | jq -r '.activemqVersion' )
ACTIVEMQ_DIR_NAME="apache-activemq-$ACTIVEMQ_VERSION"
ACTIVEMQ_BINARY="$ACTIVEMQ_DIR_NAME-bin.tar.gz"
ACTIVEMQ_BINARY_BKP="$ACTIVEMQ_DIR_NAME-bin-$CUR_TS.tar.gz"
ACTIVEMQ_BINARY_DOWNLOAD_URL=$(echo $JSON_DATA | jq -r '.vanillaDownloadUrl')
ACTIVEMQ_BINARY_FALLBACK_DOWNLOAD_URL=$(echo $JSON_DATA | jq -r '.vanillaDownloadUrlFallback')


main()
{
if [ -f "./$ACTIVEMQ_BINARY" ]; then
    echo "Removing old stale copy of the vanilla artifact......"
    rm -rfv "$BASE_DIR/$ACTIVEMQ_DIR_NAME" "$BASE_DIR/$ACTIVEMQ_BINARY" $BASE_DIR/$BUILD_DIR

fi


echo "Downloading and Untar the fresh copy of vanilla artifact......"
curl -k "$ACTIVEMQ_BINARY_DOWNLOAD_URL"  -H Expect: -o "./$ACTIVEMQ_BINARY"
download_status=$?
if [ 0 -ne $download_status ]; then
  curl -k "$ACTIVEMQ_BINARY_FALLBACK_DOWNLOAD_URL"  -H Expect: -o "./$ACTIVEMQ_BINARY"
  download_status=$?
fi

if [ 0 -ne $download_status ]; then
    echo "Vanilla ActiveMQ $ACTIVEMQ_VERSION could not download."
    exit 1
fi

sleep 2

if [ -f "./$ACTIVEMQ_BINARY" ]; then
    tar -xzvf  "./$ACTIVEMQ_BINARY"
fi

if [ -d "./$ACTIVEMQ_DIR_NAME" ]; then

    if [ -d "./$ACTIVEMQ_DIR_NAME/lib" ]; then

        size=$(echo $JSON_DATA | jq -r '.activemqVulnerableJars | length')
        echo $size
        i=0

        while [ $i -lt $size ]
        do
            relativePath=$(echo $JSON_DATA | jq -r '.activemqVulnerableJars['${i}'] | "\(.relativePath)"')
            relativePathVulnerableJar=$(echo $JSON_DATA | jq -r '.activemqVulnerableJars['${i}'] | "\(.relativePath)/\(.artifactName)"')
            urlToDownloadFixedVersionJar=$(echo $JSON_DATA | jq -r '.activemqVulnerableJars['${i}'] | .fixedJarDwonloadUrl')

            if [ -f "$BASE_DIR/$ACTIVEMQ_DIR_NAME/$relativePathVulnerableJar" ]; then
                # deleting the vulnerable jars
                echo;echo;
                echo "File exists to delete => $BASE_DIR/$ACTIVEMQ_DIR_NAME/$relativePathVulnerableJar"
                echo;
                rm -vf "$BASE_DIR/$ACTIVEMQ_DIR_NAME/$relativePathVulnerableJar"
                echo "Downloading and Replacing fixed version of Jar .... $urlToDownloadFixedVersionJar" & copy to "./$ACTIVEMQ_DIR_NAME/$relativePath"

                if [ "$urlToDownloadFixedVersionJar" != "null" ]; then
                    cd "$BASE_DIR/$ACTIVEMQ_DIR_NAME/$relativePath" && { curl -O $urlToDownloadFixedVersionJar ; cd -; }
                fi
            fi

            i=`expr $i + 1`
        done
    fi

    # creating tar gz binary
    mkdir -p $BASE_DIR/$BUILD_DIR
    tar -czvf "$BASE_DIR/$BUILD_DIR/$ACTIVEMQ_BINARY" "./$ACTIVEMQ_DIR_NAME" --exclude=*.java

    if [ -f $BASE_DIR/$BUILD_DIR/$ACTIVEMQ_BINARY ]; then
        ftp_host=$(echo $JSON_DATA | jq -r '.ftp | .host')
        ftp_uname=$(echo $JSON_DATA | jq -r '.ftp | .username')
        ftp_pwd=$(echo $JSON_DATA | jq -r '.ftp | .password')
        ftp_dir=$(echo $JSON_DATA | jq -r '.ftp | .ftpDir')

        cd $BASE_DIR/$BUILD_DIR; cd -
        doftp $ftp_host $ftp_uname $ftp_pwd "$BASE_DIR/$BUILD_DIR" $ftp_dir $ACTIVEMQ_BINARY $ACTIVEMQ_BINARY_BKP
    fi
fi

cd $CURRENT_DIR
}

doftp ()
{
    ftp -n << END_SCRIPT
    open $1
    user $2 $3
    lcd $4
    cd $5
    rename $6 $7
    bin
    put $6
    get $6 retrieval.$$
    bye
END_SCRIPT

    if [ -f retrieval.$$ ]
    then
        echo "FTP of $6 to $1 worked"
        rm -f retrieval.$$
    else
        echo "FTP of $4 did not work"
    fi
}

main