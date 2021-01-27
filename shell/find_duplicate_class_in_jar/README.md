# 1. 前言

当Java项目中引入的不同Jar包中存在重复同名类时，可能在不同情况下使用不同的加载顺序，导致生效的类不相同，可能会因此出现事故。尽早发现Java项目中引入Jar包的重复同名类并解决，可以避免事故发生。

以下提供Linux环境shell脚本（编写环境为GNU bash, version 4.2.46(1)-release (x86_64-redhat-linux-gnu)），用于查找Java项目中引入的Java包中存在的重复同名类，并比较相关类文件的HASH值是否相同。

以下脚本会查找包名非空，即不在根目录中的class文件，例如会处理“a/b1.class”文件，但不会处理“a1.class”文件。

以下脚本也不会处理META-INF目录中的class文件。

# 2. 不解压Jar包的脚本

find_duplicate_class_no_unzip.sh为查找Java项目引入Jar包中的重复同名类，不解压Jar包的脚本，可从当前目录下载。

## 2.1. 原理说明

参考 https://docs.oracle.com/javase/tutorial/deployment/jar/basicsindex.html ，JAR文件使用ZIP文件格式进行打包。

参考 https://support.pkware.com/home/pkzip/pkzip-securezip-for-unix-linux/pkzip_securezip-for-unix_linux-users-guide/how-pkzip-works-in-unix ，ZIP压缩包中的文件在被压缩前，会计算其CRC值，该值会被写入ZIP文件中。

使用unzip命令可以查看Jar包中的文件信息，不需要解压Jar包，可查看class文件的完整路径，以及其CRC值。可以根据CRC值对比不同Jar包中的重复同名类文件内容是否相同。

使用“unzip -lv xxx.jar”命令，查看Jar包中的文件信息，示例如下：

```
 Length   Method    Size  Cmpr    Date    Time   CRC-32   Name
--------  ------  ------- ---- ---------- ----- --------  ----
       0  Stored        0   0% 03-06-2019 08:19 00000000  org/apache/zookeeper/version/util/
     697  Defl:N      416  40% 03-06-2019 08:18 2b171d9d  org/apache/jute/BinaryInputArchive$BinaryIndex.class
    3946  Defl:N     1579  60% 03-06-2019 08:19 99129f5b  org/apache/jute/BinaryInputArchive.class
```

## 2.2. 使用方法

将以上脚本上传至服务器Java项目的lib目录中，执行“sh find_duplicate_class_no_unzip.sh”。

## 2.3. 执行结果

以上脚本执行完毕后，会生成两个文件：duplicate_classes2.txt、duplicate_jars_classes2.txt。

duplicate_classes2.txt文件中保存了查找到的重复同名类的完整类名，类名分隔符为“/”，后缀为“.class”，该文件内容示例如下：

```
org/apache/log4j/spi/LoggingEvent.class
org/apache/log4j/xml/DOMConfigurator.class
org/aspectj/internal/lang/annotation/ajcDeclareAnnotation.class
```

duplicate_jars_classes2.txt文件中保存了以下信息：

- 查找到的重复同名类的完整类名；

- 哪些Jar包中包含了对应的类（显示格式为“xxx.jar-list.txt”）；

- 对应类文件的CRC值；

- 不同Jar包中包含的同名类文件的CRC值是否相同（不相同时会显示“!!! not equals”）。

该文件每一行的内容格式为：“\[包含当前类的Jar包名称\]\[重复同名类的完整类名\] \[当前类文件的CRC值\]”。

当不同Jar包中包含的同名类文件的CRC值相同时，生成文件示例如下：

```
aspectjrt-1.8.13.jar-list.txt:org/aspectj/internal/lang/annotation/ajcPrivileged.class 4115d834
aspectjweaver-1.8.14.jar-list.txt:org/aspectj/internal/lang/annotation/ajcPrivileged.class 4115d834
```

当不同Jar包中包含的同名类文件的CRC值不同时，生成文件示例如下：

```
log4j-1.2-api-2.9.1.jar-list.txt:org/apache/log4j/PatternLayout.class 673920a8
log4j-over-slf4j-1.7.30.jar-list.txt:org/apache/log4j/PatternLayout.class 72df0330
!!! not equals

xmlpull-1.1.3.1.jar-list.txt:org/xmlpull/v1/XmlPullParserException.class fe486754
xpp3-1.1.4c.jar-list.txt:org/xmlpull/v1/XmlPullParserException.class 7cfaa309
xpp3_min-1.1.4c.jar-list.txt:org/xmlpull/v1/XmlPullParserException.class 7cfaa309
!!! not equals
```

# 3. 解压Jar包的脚本

使用SHA1计算文件的HASH值，比使用CRC计算的碰撞概率小很多，如果在查找Java项目引入Jar包中的重复同名类，判断重复同名类文件内容是否相同时，希望尽量降低文件HASH值碰撞概率，可以使用find_duplicate_class_unzip.sh脚本，使用SHA1计算文件的HASH值。

以上脚本在执行时会解压每个Jar包，相比不解压Jar包的脚本，耗时会增加很多。通常情况下，使用上述不解压Jar包的脚本即可。

## 3.1. 原理说明

以上脚本使用unzip命令将Jar包解压，使用sha1命令计算class文件的SHA1值。

## 3.2. 使用方法

建议将服务器Java项目的lib目录复制为一个新的目录，将以上脚本上传至该目录中，执行“sh find_duplicate_class_unzip.sh”。

## 3.3. 执行结果

以上脚本执行完毕后，会生成两个文件：duplicate_classes1.txt、duplicate_jars_classes1.txt。

duplicate_classes1.txt文件内容示例如下：

```
/javax/activation/MimeType.class
/javax/activation/MimeTypeParameterList.class
/javax/activation/MimeTypeParseException.class
```

duplicate_jars_classes1.txt文件内容示例如下：

```
./aspectjrt-1.8.13.jar-dir/org/aspectj/internal/lang/annotation/ajcDeclareEoW.class 75d8780931386bcac551a2fae8f9d786728646ce
./aspectjweaver-1.8.14.jar-dir/org/aspectj/internal/lang/annotation/ajcDeclareEoW.class 75d8780931386bcac551a2fae8f9d786728646ce

./log4j-1.2-api-2.9.1.jar-dir/org/apache/log4j/LogManager.class 461d374cd3f323252544f193e632c2a92c3e4da7
./log4j-over-slf4j-1.7.30.jar-dir/org/apache/log4j/LogManager.class 58df3c8f20b299b1b89074fbf9360c585da93281
!!! not equals

./xmlpull-1.1.3.1.jar-dir/org/xmlpull/v1/XmlPullParser.class b30e1a410526401b3c0e718324794663483e17c1
./xpp3-1.1.4c.jar-dir/org/xmlpull/v1/XmlPullParser.class ecacc7d9866fe0b6a25c3350db15488115795157
./xpp3_min-1.1.4c.jar-dir/org/xmlpull/v1/XmlPullParser.class ecacc7d9866fe0b6a25c3350db15488115795157
!!! not equals
```
