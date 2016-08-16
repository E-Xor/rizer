#!/bin/sh

cd $MAHOUT_DIR/bin
# http://192.168.99.100:50070/

# Cleaning
hadoop fs -ls / | tail -n+2 | awk '{ print $8 }' | xargs hadoop fs -rm -r -f

# Generate seq files
./articles_posts_seq.rb /root/mounts/mahout-examples/articles-posts
articles-train
posts-test

hdfs dfs -put/root/mounts/mahout-examples/articles-posts/articles-train/* /articles-train
hdfs dfs -put/root/mounts/mahout-examples/articles-posts/posts-test/* /posts-test

# Classification
# ./mahout seqdirectory -i /news-all -o /news-seq -ow

./mahout seq2sparse -i /articles-train -o /articles-train-vectors -lnorm -nv -wt tfidf
./mahout seq2sparse -i /posts-test -o /posts-test-vectors -lnorm -nv -wt tfidf

# ./mahout split \
#         -i /news-vectors/tfidf-vectors \
#         --trainingOutput /news-train-vectors \
#         --testOutput /news-test-vectors \
#         --randomSelectionPct 40 \
#         --overwrite --sequenceFiles -xm sequential

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
