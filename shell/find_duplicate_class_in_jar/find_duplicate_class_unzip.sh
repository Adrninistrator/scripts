tmp_file_list_dir=tmp_file_list1
output=duplicate_classes1.txt
output_detail=duplicate_jars_classes1.txt

>$output_detail

[ -d $tmp_file_list_dir ] || mkdir $tmp_file_list_dir
rm "$tmp_file_list_dir"/*-list.txt 2>/dev/null

for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do
    [ ! -d "$file"-dir ] && unzip -o $file -d "$file"-dir-tmp && mv "$file"-dir-tmp "$file"-dir
done

for file in $(find . -maxdepth 1 -type d -name \*.jar-dir | sort); do
    find $file -mindepth 2 -type f -name \*.class | grep -v META-INF >"$tmp_file_list_dir"/"$file"-list.txt
done

echo 查找重复同名类

cat "$tmp_file_list_dir"/*-list.txt | awk -F 'jar-dir' '{print $2}' | sort | uniq -c | sort -r -n -k 1 | awk '{if($1>1){print $2}}' | sort >$output

cat $output | while read file; do
    echo "处理文件 $file"

    first_hash=""
    not_equals=0

    used=$(grep $file "$tmp_file_list_dir"/*-list.txt)
    used_array=(${used})
    for used_info in ${used_array[@]}; do
        class_file=$(echo $used_info | awk -F '.jar-dir-list.txt:' '{print $2}')

        sha1=$(sha1sum $class_file | awk '{print $1}')
        echo "$class_file $sha1" >>$output_detail

        [ "$first_hash" == "" ] && first_hash=$sha1
        [ ! "$first_hash" == "" ] && [ "$first_hash" != "$sha1" ] && not_equals=1
    done

    [ $not_equals -eq 1 ] && echo "!!! not equals" >>$output_detail

    echo >>$output_detail
done

echo "output: $output"
echo "output_detail: $output_detail"
