#!/bin/bash
# @Author: ThomasO
# @Date:   2016-01-15 12:24:57
# @Last Modified by:   ThomasO
# @Last Modified time: 2016-01-15 17:06:02

set -e

function usage()
{
    echo "init script"
    echo " * to help setting AWS credential in spark and environment variable"
    echo " * to change location of docker folder, for use of instance storage in EC2"
    echo \
    """ 
    OPTIONS """
    echo "	-h --help"
    echo "	-a --aws-access-key-id"
    echo "	-s --aws-secret-access-key"
    echo "	-m --mount"
    echo ""
}

while [ "$1" != "" ]; do
    case $1 in
        -a | --aws-access-key-id )          shift
                                			aws_access_key_id=$1
                                			;;
        -s | --aws-secret-access-key )    	shift
        									aws_secret_access_key=$1
                                			;;
        -m | --mount ) 						mount=1
        									;;
        -h | --help )           			usage
                                			exit
                                			;;
        * )                     			usage
                                			exit 1
    esac
    shift
done

function write_hdfs_site
{
	cat <<- _EOF_
	<?xml version="1.0"?>
	<configuration>
		<property>
		    <name>fs.s3a.access.key</name>
		    <value>$aws_access_key_id</value>
		</property>
		<property>
		    <name>fs.s3a.secret.key</name>
		    <value>$aws_secret_access_key</value>
		</property>
	</configuration>
	_EOF_
}

# Write hdfs-site.xml in spark conf folder with AWS credential
if [ "$aws_access_key_id" != "" ] && [ "$aws_secret_access_key" != "" ]; then 
	# hdfs-site.xml for spark	
	hdfs_site_path=$SPARK_HOME"/conf/hdfs-site.xml"
	write_hdfs_site >> $hdfs_site_path
	# ENV
	export AWS_ACCESS_KEY_ID=$aws_access_key_id
	export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
fi

# Mount instance storage and put docker folder on it
# * https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169
if [ "$mount" = "1" ]; then 
	sudo mkfs.ext4 /dev/xvdb && \
		mkdir /home/data/ && \
		mount /dev/xvdb /home/data/
	sudo service docker stop
	sudo chmod -R 777 /var/lib/docker/
	sudo mkdir /home/test/docker && \
		mv /var/lib/docker /home/test/docker && \
		ln -s /home/test/docker /var/lib/docker
fi

# stay in shell at the end
bash
#