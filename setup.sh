#!/bin/bash
# @Author: ThomasO
# @Date:   2016-01-15 12:24:57
# @Last Modified by:   ThomasO
# @Last Modified time: 2016-01-20 12:19:06

set -e


function usage()
{
	echo "init script"
	echo " * to help setting AWS credential in spark and environment variable"
	echo " * to change location of docker folder, for use of instance storage in EC2"
	echo \
	"""
	OPTIONS """
	echo "  -h --help"
	echo "  -a --aws-access-key-id"
	echo "  -s --aws-secret-access-key"
	echo "  -m --mount"
	echo ""
}

while [ "$1" != "" ]; do
	case $1 in
		-a | --aws-access-key-id )			shift
											aws_access_key_id=$1
											;;
		-s | --aws-secret-access-key )		shift
											aws_secret_access_key=$1
											;;
		-m | --mount )						mount=1
											;;
		-h | --help )                       usage
											exit
											;;
		* )									usage
											exit 1
	esac
	shift
done


# ########################################################################
# Hadoop Conf : AWS credentials + OutputCommiter for parquet file on S3
# ########################################################################

function write_hdfs_conf
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
		<property>
			<name>spark.sql.parquet.output.committer.class</name>
			<value>org.apache.spark.sql.parquet.DirectParquetOutputCommitter</value>
		</property>
	</configuration>
	_EOF_
}


# ########################################################################
# Mount Instance Storage on EC2 and change Docker Folder
# https://forums.docker.com/t/how-do-i-change-the-docker-image-installation-directory/1169
# ########################################################################

function mount_disc_docker
{
	sudo mkfs.ext4 /dev/xvdb && \
		mkdir /home/data/ && \
		mount /dev/xvdb /home/data/
	sudo service docker stop
	sudo chmod -R 777 /var/lib/docker/
	sudo mkdir /home/test/docker && \
		mv /var/lib/docker /home/test/docker && \
		ln -s /home/test/docker /var/lib/docker
}


# ########################################################################
# Main
# ########################################################################

# Write hdfs-site.xml for hadoop conf
if [ "$aws_access_key_id" != "" ] && [ "$aws_secret_access_key" != "" ]; then 
	# hdfs-site.xml for spark   
	hdfs_site_path=$SPARK_HOME"/conf/hdfs-site.xml"
	write_hdfs_conf >> $hdfs_site_path
	# ENV
	export AWS_ACCESS_KEY_ID=$aws_access_key_id
	export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key
	echo "" >> ~/.bashrc
	echo "# S3 Config" >> ~/.bashrc
	echo "export AWS_ACCESS_KEY_ID=$aws_access_key_id" >> ~/.bashrc
	echo "export AWS_SECRET_ACCESS_KEY=$aws_secret_access_key" >> ~/.bashrc
fi

# Mount instance storage and put docker folder on it
if [ "$mount" = "1" ]; then 
	mount_disc_docker
fi

# stay in shell at the end
bash
#