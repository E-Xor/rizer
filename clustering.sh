#!/bin/sh

# 1.
# cd $MAHOUT_DIR/bin
# hadoop fs -put /root/mounts/mahout-examples/synthetic_control.data.txt /mahout_data/
# ./mahout seqdirectory -i /mahout_data/ -o /mahout_seq2/ -xm sequential
# ./mahout seq2sparse -i /mahout_seq2/ -o /mahout_vector4/ --maxDFPercent 100
# ./mahout kmeans -i /mahout_vector4/tfidf-vectors -c /clustered_data_tmp -o /kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
# ./mahout clusterdump -i /kmeans_output/clusters-1-final -p /kmeans_output/clusteredPoints -dt sequencefile -d /mahout_vector4/dictionary.file-0

# 2.
# Run *_to_doc.rb
# http://192.168.99.100:50070/

cd $MAHOUT_DIR/bin

# Cleaning
hadoop fs -ls / | tail -n+2 | awk '{ print $8 }' | xargs hadoop fs -rm -r -f

# Clustering

hadoop fs -mkdir /search_mahout_data
hadoop fs -put /root/mounts/mahout-examples/search-text-docs/ /search_mahout_data/
./mahout seqdirectory -i /search_mahout_data/ -o /search_mahout_seq/ -xm sequential
./mahout seq2sparse -i /search_mahout_seq/ -o /search_mahout_vector/ --maxDFPercent 100
./mahout kmeans -i /search_mahout_vector/tfidf-vectors -c /temp -o /search_kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
mkdir /root/mounts/mahout-examples/search-text-clusters
./mahout clusterdump -i /search_kmeans_output/clusters-0 -p /search_kmeans_output/clusteredPoints -dt sequencefile -d /search_mahout_vector/dictionary.file-0 > /root/mounts/mahout-examples/search-text-clusters/0.txt
./mahout clusterdump -i /search_kmeans_output/clusters-1 -p /search_kmeans_output/clusteredPoints -dt sequencefile -d /search_mahout_vector/dictionary.file-0 > /root/mounts/mahout-examples/search-text-clusters/1.txt
./mahout clusterdump -i /search_kmeans_output/clusters-2 -p /search_kmeans_output/clusteredPoints -dt sequencefile -d /search_mahout_vector/dictionary.file-0 > /root/mounts/mahout-examples/search-text-clusters/2.txt
./mahout clusterdump -i /search_kmeans_output/clusters-3-final -p /search_kmeans_output/clusteredPoints -dt sequencefile -d /search_mahout_vector/dictionary.file-0 > /root/mounts/mahout-examples/search-text-clusters/3-final.txt
