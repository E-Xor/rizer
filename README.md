# rizer
Mahout. Clustering. Trends.

# Notes
```

# Quick start
raizer-run # docker run -it -v ~/other-apps/rizer/:/root/mounts/rizer -v ~/other-apps/rizer-storage:/root/mounts/rizer-storage -v ~/other-apps/mahout-examples/:/root/mounts/mahout-examples -p 50070:50070 -p 9000:9000 -p 8088:8088 rizer:latest bash
~/startup.sh
http://192.168.99.100:50070
http://192.168.99.100:8088

# Resources I used
# Required X11 https://mahout.apache.org/users/clustering/visualizing-sample-clusters.html
# http://www.tutorialspoint.com/mahout/mahout_environment.htm
# https://mahout.apache.org/users/clustering/k-means-clustering.html
# https://mahout.apache.org/users/clustering/fuzzy-k-means.html
# Try other algorithms than k-means
# https://github.com/apache/mahout/blob/master/examples/bin/cluster-reuters.sh
# http://unmeshasreeveni.blogspot.com/2014/11/how-to-run-k-means-clustering-in-mahout.html

# Run
docker run -it -v ~/other-apps/rizer/:/root/mounts/rizer -v ~/other-apps/rizer-storage:/root/mounts/rizer-storage -p 50070:50070 -p 9000:9000 -p 8088:8088 rizer:latest bash

# How I setup
apt-get install curl
\curl -sSL https://get.rvm.io | bash
source /usr/local/rvm/scripts/rvm
mkdir ~/jruby-test
cd ~/jruby-test
rvm install jruby-9.0.4.0
exit
docker commit -m 'jruby' 225fbc939132 rizer:latest

cd ~/jruby-test
apt-get install wget
wget https://archive.apache.org/dist/mahout/0.7/mahout-distribution-0.7.tar.gz
tar -zxvf mahout-distribution-0.7.tar.gz
export MAHOUT_DIR=/root/jruby-test/mahout-distribution-0.7
vi ~/.bashrc
export MAHOUT_DIR=/root/jruby-test/mahout-distribution-0.7
:wq!
exit
docker commit -m 'Downlaod Mahout' b1ebe0bdb2a5 rizer:latest

docker run -it -v ~/other-apps/rizer/:/root/jruby-test/rizer rizer:latest bash
vi ~/.vimrc
set term=builtin_ansi
set nocompatible
:wq!
cd /root/jruby-test/rizer
vi Gemfile
source 'https://rubygems.org'
gem "jruby_mahout"
:wq!
vi .ruby-version
jruby-9.0.4.0@rizer
:wq!
vi ~/.bashrc
# add to the end
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm" # Load RVM into a shell session *as a function*
:wq!
cd ..
cd rizer
#gemset created /usr/local/rvm/gems/jruby-9.0.4.0@rizer
gem install bundler
bundle

readlink -f /usr/bin/java | sed "s:bin/java::"
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre/
wget postgresql-9.4.1207.jre7.jar; mv jars/

# Hadoop
wget http://mirrors.advancedhosters.com/apache/hadoop/common/hadoop-2.7.2/hadoop-2.7.2.tar.gz
tar -zxvf hadoop-2.7.2.tar.gz
mv hadoop-2.7.2 hadoop

vi ~/.bashrc
export HADOOP_HOME=/root/jruby-test/hadoop
export HADOOP_PREFIX=$HADOOP_HOME
export HADOOP_MAPRED_HOME=$HADOOP_PREFIX
export HADOOP_COMMON_HOME=$HADOOP_PREFIX
export HADOOP_HDFS_HOME=$HADOOP_PREFIX
export YARN_HOME=$HADOOP_PREFIX
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_PREFIX/lib/native
export PATH=$PATH:$HADOOP_PREFIX/sbin:$HADOOP_PREFIX/bin
export HADOOP_INSTALL=$HADOOP_PREFIX
export HADOOP_YARN_HOME=$HADOOP_PREFIX
export JAVA_LIBRARY_PATH=$HADOOP_PREFIX/lib/native:$JAVA_LIBRARY_PATH
export HADOOP_OPTS="$HADOOP_OPTS -Djava.library.path=$HADOOP_PREFIX/lib"
source ~/.bashrc

cd $HADOOP_HOME/etc/hadoop
vi core-site.xml
<configuration>
   <property>
      <name>fs.default.name</name>
      <value>hdfs://localhost:9000</value>
   </property>
</configuration>

mkdir -p ~/jruby-test/hadoopinfra/hdfs/namenode
mkdir -p ~/jruby-test/hadoopinfra/hdfs/datanode

vi hdfs-site.xml
<configuration>
   <property>
      <name>dfs.replication</name>
      <value>1</value>
   </property>

   <property>
      <name>dfs.name.dir</name>
      <value>file:///root/jruby-test/hadoopinfra/hdfs/namenode</value>
   </property>

   <property>
      <name>dfs.data.dir</name>
      <value>file:///root/jruby-test/hadoopinfra/hdfs/datanode</value>
   </property>
</configuration>

vi yarn-site.xml
<configuration>
   <property>
      <name>yarn.nodemanager.aux-services</name>
      <value>mapreduce_shuffle</value>
   </property>
</configuration>

cp mapred-site.xml.template mapred-site.xml
vi mapred-site.xml
<configuration>
   <property>
      <name>mapreduce.framework.name</name>
      <value>yarn</value>
   </property>
</configuration>

vi hadoop-env.sh
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre/

cd ../../
hdfs namenode -format

apt-get install ssh
/etc/init.d/ssh restart
ssh localhost
ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys

start-dfs.sh
start-yarn.sh
http://192.168.99.100:50070
http://192.168.99.100:8088

hadoop fs -mkdir -p /mahout_data
hadoop fs -mkdir -p /clustered_data
hadoop fs -mkdir -p /mahout_seq
http://192.168.99.100:50070/explorer.html#/
http://192.168.99.100:8088/cluster

# Visualization
apt-get update
apt-get install openjdk-7-jdk

wget http://www.gtlib.gatech.edu/pub/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar -zxf apache-maven-3.3.9-bin.tar.gz
sudo cp -R apache-maven-3.3.9 /usr/local
sudo ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/bin/mvn
# Download mahout-master.zip from github and unpack in ~/other-apps/mahout-examples/
cd ~/mounts/mahout-examples/mahout-master/examples
mvn clean install
mvn -q exec:java -Dexec.mainClass=org.apache.mahout.clustering.display.DisplayClustering
# Needs X11 at this point, somehow it should direct image to file.
# https://mail-archives.apache.org/mod_mbox/mahout-user/201203.mbox/%3CCAMjSrvn-zJaMsGpn1SCCof1cBjHQXw-P32YqR8_oZrHoFXaMjw@mail.gmail.com%3E

# Clustering
# get synthetic_control.data.txt
hadoop fs -put /root/mounts/mahout-examples/synthetic_control.data.txt /mahout_data/
cd $MAHOUT_DIR/bin
./mahout seqdirectory --help

vi ~/.bashrc
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
source ~/.bashrc

./mahout seqdirectory -i hdfs://localhost:9000/mahout_data/ -o hdfs://localhost:9000/mahout_seq2/ -xm sequential
./mahout seq2sparse -i hdfs://localhost:9000/mahout_seq2/ -o hdfs://localhost:9000/mahout_vector3/ --namedVector
./mahout canopy -i hdfs://localhost:9000/mahout_vector3/tfidf-vectors -o hdfs://localhost:9000/clustered_data3 -t1 20 -t2 30 -ow
./mahout kmeans -i hdfs://localhost:9000/mahout_vector3/tfidf-vectors -c hdfs://localhost:9000/clustered_data3/clusters-0-final/part-r-00000 -o  hdfs://localhost:9000/kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -ow —clustering # fail with -c

./mahout streamingkmeans -i hdfs://localhost:9000/mahout_vector3/tfidf-vectors --tempDir hdfs://localhost:9000/temp -o hdfs://localhost:9000/streamingkmeans -sc org.apache.mahout.math.neighborhood.FastProjectionSearch -dm org.apache.mahout.common.distance.SquaredEuclideanDistanceMeasure -k 10 -km 100 -ow

./mahout qualcluster -i hdfs://localhost:9000/mahout_vector3/tfidf-vectors/part-r-00000 -c hdfs://localhost:9000/streamingkmeans/part-r-00000 -o ~/csv/streamingkmeans.csv
# gave empty output in file

# This finally worked! Problem was solved by adding `-seq --maxDFPercent 100` params for seq2sparse, works without `-seq` too.
./mahout seq2sparse -i hdfs://localhost:9000/mahout_seq2/ -o hdfs://localhost:9000/mahout_vector4/ -seq --maxDFPercent 100
./mahout kmeans -i hdfs://localhost:9000/mahout_vector4/tfidf-vectors -c hdfs://localhost:9000/clustered_data_tmp -o  hdfs://localhost:9000/kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
./mahout clusterdump -i /kmeans_output/clusters-1-final -p /kmeans_output/clusteredPoints -dt sequencefile -d /mahout_vector4/dictionary.file-0

# http://unmeshasreeveni.blogspot.com/2014/11/how-to-run-k-means-clustering-in-mahout.html
(wget http://archive.ics.uci.edu/ml/databases/synthetic_control/synthetic_control.data)
hadoop fs -mkdir /testdata
hadoop fs -put /root/mounts/mahout-examples/synthetic_control.data.txt /testdata

```