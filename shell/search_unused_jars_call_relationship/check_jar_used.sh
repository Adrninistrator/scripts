jar_name=$1
find_rows=$2
jar_dir="$jar_name"-dir
classes_slash_point_file="$jar_dir"/classes_slash_point.txt
classes_point_file="$jar_dir"/classes_point.txt
used_jar_by_class_result="$jar_dir"/used_jar_by_class.txt
used_jar_by_class_result_tmp="$used_jar_by_class_result".tmp
check_rows=1

if [ ! -f $jar_name ]; then
    echo "文件不存在 $jar_name"
    exit 1
fi

if [ "$find_rows" != "" ]; then
    if [[ ! "$find_rows" =~ ^[1-9]+[0-9]*$ ]]; then
        echo "输入的参数非法，不是整数 $find_rows"
        exit 1
    fi
    check_rows=$find_rows
fi

echo "$(date) $jar_name $find_rows"

for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do
    [ ! -d "$file"-dir ] && unzip -o $file -d "$file"-dir-tmp && mv "$file"-dir-tmp "$file"-dir
done

find $jar_dir -mindepth 2 -type f -name \*.class | awk -F "$jar_dir/" '{print $2}' | awk -F '\\.class' '{print $1}' | awk -F '$' '{print $1}' | sort | uniq | sort >$classes_slash_point_file

cat $classes_slash_point_file | sed "s#/#\\\\.#g" >$classes_point_file
cat $classes_point_file >>$classes_slash_point_file
rm $classes_point_file

echo "check_rows: $check_rows"

find . -type f -name \*.class | xargs grep -a -o -f $classes_slash_point_file --exclude=*"$jar_dir"/* | head -$check_rows >$used_jar_by_class_result_tmp

cat $used_jar_by_class_result_tmp | sort | uniq >$used_jar_by_class_result
rm $used_jar_by_class_result_tmp

num=$(head -1 $used_jar_by_class_result | wc -l)
if [ $num -eq 1 ]; then
    echo "当前Jar包有被其他Jar包使用"
    cat $used_jar_by_class_result
else
    echo "当前Jar包未被其他Jar包使用"
fi

echo $(date)
echo "保存当前Jar包包名信息文件: $classes_slash_point_file"
echo "保存当前Jar包被其他Jar包使用情况的文件: $used_jar_by_class_result"
