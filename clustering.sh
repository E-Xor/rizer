#!/bin/sh

# 1.
# cd $MAHOUT_DIR/bin
# hadoop fs -put /root/mounts/mahout-examples/synthetic_control.data.txt /mahout_data/
# ./mahout seqdirectory -i /mahout_data/ -o /mahout_seq2/ -xm sequential
# ./mahout seq2sparse -i /mahout_seq2/ -o /mahout_vector4/ --maxDFPercent 100
# ./mahout kmeans -i /mahout_vector4/tfidf-vectors -c /clustered_data_tmp -o /kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
# ./mahout clusterdump -i /kmeans_output/clusters-1-final -p /kmeans_output/clusteredPoints -dt sequencefile -d /mahout_vector4/dictionary.file-0

# 2.
# Run searches_to_doc.rb
# http://192.168.99.100:50070/
cd $MAHOUT_DIR/bin
hadoop fs -mkdir /mahout_data_search_docs
hadoop fs -put /root/mounts/mahout-examples/search-docs/ /mahout_data_search_docs/
./mahout seqdirectory -i /mahout_data_search_docs/ -o /mahout_seq_search/ -xm sequential
./mahout seq2sparse -i /mahout_seq_search/ -o /mahout_vector_search/ --maxDFPercent 100
./mahout kmeans -i /mahout_vector_search/tfidf-vectors -c /clustered_data_tmp -o /kmeans_output_search -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
mkdir /root/mounts/mahout-examples/search-clusters
./mahout clusterdump -i /kmeans_output_search/clusters-0 -p /kmeans_output_search/clusteredPoints -dt sequencefile -d /mahout_vector_search/dictionary.file-0 > /root/mounts/mahout-examples/search-clusters/0.txt
./mahout clusterdump -i /kmeans_output_search/clusters-1 -p /kmeans_output_search/clusteredPoints -dt sequencefile -d /mahout_vector_search/dictionary.file-0 > /root/mounts/mahout-examples/search-clusters/1.txt
./mahout clusterdump -i /kmeans_output_search/clusters-2 -p /kmeans_output_search/clusteredPoints -dt sequencefile -d /mahout_vector_search/dictionary.file-0 > /root/mounts/mahout-examples/search-clusters/2.txt
./mahout clusterdump -i /kmeans_output_search/clusters-3-final -p /kmeans_output_search/clusteredPoints -dt sequencefile -d /mahout_vector_search/dictionary.file-0 > /root/mounts/mahout-examples/search-clusters/3-final.txt

