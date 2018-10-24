-- MySQL dump 10.13  Distrib 5.7.23, for Linux (x86_64)
--
-- Host: localhost    Database: bht_core_dev
-- ------------------------------------------------------
-- Server version	5.7.23-0ubuntu0.18.04.1

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
-- Table structure for table `moh_regimens`
--

DROP TABLE IF EXISTS `moh_regimens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moh_regimens` (
  `regimen_id` int(11) NOT NULL AUTO_INCREMENT,
  `regimen_index` int(11) NOT NULL,
  `description` text,
  `date_created` datetime DEFAULT NULL,
  `date_updated` datetime DEFAULT NULL,
  `creator` int(11) NOT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`regimen_id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `moh_regimens`
--

LOCK TABLES `moh_regimens` WRITE;
/*!40000 ALTER TABLE `moh_regimens` DISABLE KEYS */;
INSERT INTO `moh_regimens` VALUES (1,0,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(2,2,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(3,4,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(4,5,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(5,6,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(6,7,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(7,8,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(8,9,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(9,10,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(10,11,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(11,12,NULL,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(12,13,NULL,NULL,NULL,1,0,NULL),(13,14,NULL,NULL,NULL,1,0,NULL),(14,15,NULL,NULL,NULL,1,0,NULL);
/*!40000 ALTER TABLE `moh_regimens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `moh_regimen_lookup`
--

DROP TABLE IF EXISTS `moh_regimen_lookup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moh_regimen_lookup` (
  `regimen_lookup_id` int(11) NOT NULL AUTO_INCREMENT,
  `num_of_drug_combination` int(11) DEFAULT NULL,
  `regimen_name` varchar(5) NOT NULL,
  `drug_inventory_id` int(11) DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `date_updated` datetime DEFAULT NULL,
  `creator` int(11) DEFAULT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`regimen_lookup_id`)
) ENGINE=InnoDB AUTO_INCREMENT=35 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `moh_regimen_lookup`
--

LOCK TABLES `moh_regimen_lookup` WRITE;
/*!40000 ALTER TABLE `moh_regimen_lookup` DISABLE KEYS */;
INSERT INTO `moh_regimen_lookup` VALUES (1,2,'0P',733,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(2,2,'0P',968,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(3,2,'0A',969,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(4,2,'0A',22,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(5,1,'2P',732,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(6,1,'2A',731,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(7,2,'4P',736,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(8,2,'4P',30,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(9,2,'4A',39,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(10,2,'4A',11,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(11,1,'5A',735,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(12,2,'6A',734,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(13,2,'6A',22,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(14,2,'7A',734,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(15,2,'7A',932,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(16,2,'8A',39,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(17,2,'8A',932,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(18,2,'9P',733,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(19,2,'9P',74,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(20,2,'9A',969,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(21,2,'9A',73,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(22,2,'10A',734,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(23,2,'10A',73,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(24,2,'11P',736,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(25,2,'11P',74,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(26,2,'11A',39,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(27,2,'11A',73,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(28,4,'12A',976,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(29,4,'12A',977,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(30,4,'12A',954,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(31,4,'12A',978,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(33,2,'9P',979,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(34,2,'11P',979,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL);
/*!40000 ALTER TABLE `moh_regimen_lookup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `moh_regimen_ingredient`
--

DROP TABLE IF EXISTS `moh_regimen_ingredient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moh_regimen_ingredient` (
  `ingredient_id` int(11) NOT NULL AUTO_INCREMENT,
  `regimen_id` int(11) DEFAULT NULL,
  `drug_inventory_id` int(11) DEFAULT NULL,
  `dose_id` int(11) DEFAULT NULL,
  `min_weight` float DEFAULT NULL,
  `max_weight` float DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `date_updated` datetime DEFAULT NULL,
  `creator` int(11) DEFAULT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  `min_age` int(11) DEFAULT NULL,
  `max_age` int(11) DEFAULT NULL,
  PRIMARY KEY (`ingredient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `moh_regimen_ingredient`
--

LOCK TABLES `moh_regimen_ingredient` WRITE;
/*!40000 ALTER TABLE `moh_regimen_ingredient` DISABLE KEYS */;
INSERT INTO `moh_regimen_ingredient` VALUES (1,1,733,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(2,1,968,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(3,1,733,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(4,1,968,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(5,1,733,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(6,1,968,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(7,1,733,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(8,1,968,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(9,1,733,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(10,1,968,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(11,1,969,6,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(12,1,22,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(13,2,732,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(14,2,732,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(15,2,732,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(16,2,732,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(17,2,732,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(18,2,731,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(19,3,736,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(20,3,30,6,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(22,3,736,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(23,3,736,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(24,3,736,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(25,3,736,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(26,3,30,7,14,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(27,3,30,8,25,34.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(28,3,11,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(29,3,39,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(30,4,735,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(31,5,734,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(32,5,22,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(33,6,734,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(34,6,932,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(35,7,39,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(36,7,932,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(37,8,733,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(38,8,733,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(39,8,733,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(40,8,733,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(41,8,733,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(42,8,969,6,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(43,8,979,3,3,3.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(44,8,979,3,4,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(45,8,74,10,6,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(46,8,74,3,14,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(47,8,74,5,25,34.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(48,8,73,3,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(49,9,734,6,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(50,9,73,3,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(51,10,736,1,3,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(52,10,736,2,6,9.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(53,10,736,3,10,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(54,10,736,4,14,19.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(55,10,736,5,20,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(56,10,979,3,3,3.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(57,10,979,3,4,5.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(58,10,74,10,6,13.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(59,10,74,3,14,24.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(60,10,74,5,25,34.9,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(61,10,39,1,25,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(62,10,73,3,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(63,11,976,1,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(64,11,977,1,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(65,11,954,1,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(66,11,978,3,35,300,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL,NULL,NULL),(67,12,983,13,30,300,'2018-10-19 10:36:10','2018-10-19 10:36:10',NULL,0,NULL,45,200),(68,13,982,6,30,300,'2018-10-19 10:36:10','2018-10-19 10:36:10',NULL,0,NULL,45,200),(69,14,982,6,30,300,'2018-10-19 10:36:10','2018-10-19 10:36:10',NULL,0,NULL,45,200),(70,13,984,1,25,300,'2018-10-19 10:36:10','2018-10-19 10:36:10',NULL,0,NULL,NULL,NULL),(71,14,969,13,25,300,'2018-10-19 10:36:10','2018-10-19 10:36:10',NULL,0,NULL,NULL,NULL);
/*!40000 ALTER TABLE `moh_regimen_ingredient` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `moh_regimen_doses`
--

DROP TABLE IF EXISTS `moh_regimen_doses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moh_regimen_doses` (
  `dose_id` int(11) NOT NULL AUTO_INCREMENT,
  `am` float DEFAULT NULL,
  `pm` float DEFAULT NULL,
  `date_created` datetime DEFAULT NULL,
  `date_updated` datetime DEFAULT NULL,
  `creator` int(11) DEFAULT NULL,
  `voided` tinyint(1) NOT NULL DEFAULT '0',
  `voided_by` int(11) DEFAULT NULL,
  PRIMARY KEY (`dose_id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `moh_regimen_doses`
--

LOCK TABLES `moh_regimen_doses` WRITE;
/*!40000 ALTER TABLE `moh_regimen_doses` DISABLE KEYS */;
INSERT INTO `moh_regimen_doses` VALUES (1,1,1,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(2,1.5,1.5,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(3,2,2,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(4,2.5,2.5,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(5,3,3,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(6,0,1,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(7,0,1.5,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(8,0,2,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(9,0,0.5,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(10,2,1,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(11,0,2.5,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(12,0,3,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(13,1,0,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(14,1.5,0,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(15,2,0,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(16,2.5,0,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(17,3,0,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL),(18,4,4,'2016-09-19 16:00:00','2016-09-19 16:00:00',1,0,NULL);
/*!40000 ALTER TABLE `moh_regimen_doses` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-10-19 11:23:17