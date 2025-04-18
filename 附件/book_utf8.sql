-- MySQL dump 10.13  Distrib 5.5.32, for Linux (x86_64)
--
-- Host: localhost    Database: book2
-- ------------------------------------------------------
-- Server version	5.5.32-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `books`
--

DROP TABLE IF EXISTS `books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `books` (
  `bId` int(4) NOT NULL AUTO_INCREMENT,
  `bName` varchar(255) DEFAULT NULL,
  `bTypeId` enum('1','2','3','4','5','6','7','8','9','10') DEFAULT NULL,
  `publishing` varchar(255) DEFAULT NULL,
  `price` int(4) DEFAULT NULL,
  `pubDate` date DEFAULT NULL,
  `author` varchar(30) DEFAULT NULL,
  `ISBN` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`bId`)
) ENGINE=MyISAM AUTO_INCREMENT=45 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `books`
--

LOCK TABLES `books` WRITE;
/*!40000 ALTER TABLE `books` DISABLE KEYS */;
INSERT INTO `books` VALUES (1,'网站制作直通车','2','电脑爱好者杂志社',34,'2004-10-01','苗壮','7505380796'),(2,'黑客与网络安全','6','航空工业出版社',41,'2002-07-01','白立超','7121010925'),(3,'网络程序与设计－asp','2','北方交通大学出版社',43,'2005-02-01','王玥','75053815x'),(4,'pagemaker 7.0短期培训教程','9','中国电力出版社',43,'2005-01-01','孙利英','7121008947'),(5,'黑客攻击防范秘笈','6','北京腾图电子出版社',44,'2003-06-29','赵雷雨','7120000233'),(6,'Dreamweaver 4入门与提高','2','清华大学出版社',44,'2004-06-01','岳玉博','7505397699'),(7,'网页样式设计－CSS','2','人民邮电出版社',45,'2002-03-01','张晓阳','7505383663'),(8,'Internet操作技术','7','清华大学出版社',45,'2002-02-01','肖铭','7121003023'),(9,'Dreamweaver 4网页制作','2','清华大学出版社',45,'2004-04-01','黄宇','7505380796'),(10,'3D MAX 3.0 创作效果百例','3','北京万水电子信息出版社',45,'2002-09-01','耿影','7505380796'),(11,'Auto CAD职业技能培训教程','10','北京希望电子出版社',47,'2004-06-01','张晓阳','7505380796'),(12,'Fireworks 4网页图形制作','2','清华大学出版社',48,'2004-04-01','白立超','7505380796'),(13,'自己动手建立企业局域网','8','清华大学出版社',48,'2003-08-30','郭刚','7505380796'),(14,'页面特效精彩实例制作','2','人民邮电出版社',49,'2004-09-01','白宇','7505380796'),(15,'平面设计制作整合案例详解－页面设计卷','2','人民邮电出版社',49,'2004-04-01','陈继云','7505380796'),(16,'Illustrator 10完全手册','9','科学出版社',50,'2005-03-01','周玉勇','7505380796'),(17,'FreeHand 10基础教程','9','北京希望电子出版',50,'2005-02-01','耿影','7505380796'),(18,'网站设计全程教程','2','科学出版社',50,'2006-01-01','吴守辉','7505380796'),(19,'动态页面技术－HTML 4.0使用详解','2','人民邮电出版社',51,'2003-02-01','卢立超','7505380796'),(20,'Auto CAD 3D模型大师','10','中国铁道出版社',53,'2002-06-01','曹泽林','7505380796'),(21,'Linux傻瓜书','4','清华大学出版社',54,'2003-02-01','朱佳男','7505380796'),(22,'网页界面设计艺术教程','2','人民邮电出版社',54,'2006-01-01','刘刚','7505380796'),(23,'Flash MX 标准教程','2','北京希望电子出版社',54,'2005-05-01','郭刚','7505371215'),(24,'Auto CAD 2000 应用及实例基集锦','10','清华大学出版社',58,'2003-02-01','陈继云','7505388444'),(25,'Access 2000应用及实例基集锦','1','北京邮电出版社',59,'2004-06-01','于佳','7505396269'),(26,'ASP数据库系统开发实例导航','2','人民邮电出版社',60,'2006-01-01','刘刚','7505374710'),(27,'Delphi 5程序设计与控件参考','5','电子工业出版社',60,'2003-02-01','孟卫峰','7505377353'),(28,'活学活用Delphi5','5','人民邮电出版社',62,'2003-05-01','付强','7505396293'),(29,'Auto CAD 2002 中文版实用教程','2','人民邮电出版社',63,'2005-01-01','赵富雨','7121007436'),(30,'3DS MAX 4横空出世','3','清华大学出版社',63,'2005-01-01','付强','712100847'),(31,'精通Javascript','2','科学出版社',63,'2003-05-01','齐鹏','7505391860'),(32,'深入Flash 5教程','2','北京科海集团公司',64,'2004-03-01','卢立强','75053886441'),(33,'Auto CAD R14 中文版实用教程','10','人民邮电出版社',64,'2002-11-01','杜刚','394436'),(34,'ASP数据库系统开发实例导航','2','人民邮电出版社',60,'2006-01-01','刘刚','7505374710'),(35,'Frontpage 2000＆ ASP 网页设计技巧与网站维护','2','清华大学出版社',71,'2003-11-01','李雪','75053764774'),(36,'HTML设计实务','2','人民邮电出版社',72,'2002-11-01','韩旭颖','77121007460'),(37,'3D MAX R3动画制作与培训教程','3','人民邮电出版社',73,'2003-10-01','孙丽英','7505391623'),(38,'Javascript与Jscript从入门到精通','2','电子工业出版社',7500,'2002-08-01','韩旭颖','7505391410'),(39,'lllustrator 9宝典','9','电子工业出版社',83,'2004-05-01','周玉勇','7120000039'),(40,'3D Studio Max 3综合使用','3','人民邮电出版社',91,'2003-08-01','丁佳','7505386514'),(41,'SQL Server 2000 从入门到精通','1','电子工业出版社',93,'2004-03-01','薛聪颖','7505383608'),(42,'SQL Server 7.0数据库系统管理与应用开发','1','人民邮电出版社',95,'2003-05-01','肖铭','7121004771'),(43,'ASP 3初级教程','2','机械工业出版社',104,'2003-11-01','韩旭日','7505375458'),(44,'XML 完全探索','2','中国青年出版社',104,'2004-01-01','齐鹏','7505357778');
/*!40000 ALTER TABLE `books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `category`
--

DROP TABLE IF EXISTS `category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `category` (
  `bTypeId` int(4) NOT NULL AUTO_INCREMENT,
  `bTypeName` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`bTypeId`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `category`
--

LOCK TABLES `category` WRITE;
/*!40000 ALTER TABLE `category` DISABLE KEYS */;
INSERT INTO `category` VALUES (1,'windows应用'),(2,'网站'),(3,'3D动画'),(4,'linux学习'),(5,'Delphi学习'),(6,'黑客'),(7,'网络技术'),(8,'安全'),(9,'平面'),(10,'AutoCAD技术');
/*!40000 ALTER TABLE `category` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-11-06 19:00:58
