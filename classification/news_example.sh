#!/bin/sh

cd $MAHOUT_DIR/bin
# http://192.168.99.100:50070/

# Cleaning
hadoop fs -ls / | tail -n+2 | awk '{ print $8 }' | xargs hadoop fs -rm -r -f

# Copy
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate/20news-bydate-test/* /news-all
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate/20news-bydate-train/* /news-all


hadoop fs vs hdfs

# Classification
./mahout seqdirectory -i /news-all -o /news-seq -ow

./mahout seq2sparse -i /news-seq -o /news-vectors -lnorm -nv -wt tfidf

./mahout split \
        -i /news-vectors/tfidf-vectors \
        --trainingOutput /news-train-vectors \
        --testOutput /news-test-vectors \
        --randomSelectionPct 40 \
        --overwrite --sequenceFiles -xm sequential

./mahout trainnb \
        -i /news-train-vectors \
        -o /news-model \
        -li /news-labelindex \
        -ow \
        -c

./mahout testnb \
        -i /news-test-vectors \
        -m /news-model \
        -l /news-labelindex \
        -ow \
        -o /news-testing \
        -c > /root/mounts/mahout-examples/news-testing.txt 2>&1

# No C
hdfs dfs -rm -r -f /temp

./mahout trainnb \
        -i /news-train-vectors \
        -o /news-model-no-c \
        -li /news-labelindex-no-c \
        -ow

./mahout testnb \
        -i /news-test-vectors \
        -m /news-model-no-c \
        -l /news-labelindex-no-c \
        -ow \
        -o /news-testing-no-c > /root/mounts/mahout-examples/news-testing-no-c.txt 2>&1

# Different categories in train and test
hdfs dfs -mkdir /news-split-test
hdfs dfs -mkdir /news-split-train
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate-split/20news-bydate-test/* /news-split-test
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate-split/20news-bydate-train/* /news-split-train

./mahout seqdirectory -i /news-split-test -o /news-split-seq-test -ow -xm sequential
./mahout seqdirectory -i /news-split-train -o /news-split-seq-train -ow -xm sequential

# ./mahout seq2sparse -i /news-split-seq-test -o /news-split-vectors-test -lnorm -nv -wt tfidf
# ./mahout seq2sparse -i /news-split-seq-train -o /news-split-vectors-train -lnorm -nv -wt tfidf

./mahout seq2sparse -i /news-split-seq-train -o /news-split-vectors-train --maxDFPercent 100
./mahout seq2sparse -i /news-split-seq-test -o /news-split-vectors-test --maxDFPercent 100

hdfs dfs -rm -r -f /temp
./mahout trainnb \
        -i /news-split-vectors-train/tfidf-vectors \
        -o /news-split-model \
        -li /news-split-labelindex \
        -ow \
        -c

# Test is specifically to run on the same dataset as train, not to categorise external data
# ./mahout testnb \
#         -i /news-split-vectors-test/tfidf-vectors \
#         -m /news-split-model \
#         -l /news-split-labelindex \
#         -ow \
#         -o /news-split-testing \
#         -c > /root/mounts/mahout-examples/news-split-testing.txt 2>&1

# ./mahout org.apache.mahout.classifier.Classify \
#   -m /home/hanish/opt/20news-bydate/bayes-model \
#   --classify /home/hanish/name.txt \
#   -ng 1 \
#   -type bayes \
#   -a org.apache.mahout.vectorizer.DefaultAnalyzer \
#   --encoding UTF-8 \
#   --defaultCat unknown \
#   -source hdfs \
# > /root/mounts/mahout-examples/news-split-testing.txt 2>&1

./mahout org.apache.mahout.classifier.Classify \
  -m /news-split-model \
  --classify /news-split-test/76115 \
  -type bayes \
  -a org.apache.mahout.vectorizer.DefaultAnalyzer


