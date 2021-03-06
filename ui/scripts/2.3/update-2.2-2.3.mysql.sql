-- Write that the 2.2->2.3 has started
UPDATE ObmInfo SET obminfo_value='2.2.x->2.3.0' WHERE obminfo_name='db_version';
-- -----------------------------------------------------------------------------

--
-- Table structure for table `AddressBook`
--
DROP TABLE IF EXISTS `AddressBook`;
CREATE TABLE `AddressBook` (
  `id`         int(8) NOT NULL auto_increment,
  `domain_id`  int(8) NOT NULL,
  `timeupdate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `timecreate` timestamp NOT NULL default '0000-00-00 00:00:00',
  `userupdate` int(8) default NULL,
  `usercreate` int(8) default NULL,
  `origin`     varchar(255) NOT NULL,
  `owner`      int(8) default NULL,
  `name`       varchar(64) NOT NULL,
  `is_default`    int(1) default 0,
  `syncable`   int(1) default 1,
  PRIMARY KEY (`id`),
  KEY `addressbook_domain_id_domain_id_fkey` (`domain_id`),
  KEY `addressbook_userupdate_userobm_id_fkey` (`userupdate`),
  KEY `addressbook_usercreate_userobm_id_fkey` (`usercreate`),
  KEY `addressbook_owner_userobm_id_fkey` (`owner`),
  CONSTRAINT `addressbook_domain_id_domain_id_fkey` FOREIGN KEY (`domain_id`) REFERENCES `Domain` (`domain_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `addressbook_userupdate_userobm_id_fkey` FOREIGN KEY (`userupdate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `addressbook_usercreate_userobm_id_fkey` FOREIGN KEY (`usercreate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `addressbook_owner_userobm_id_fkey` FOREIGN KEY (`owner`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `addressbookEntity`
--
DROP TABLE IF EXISTS `AddressbookEntity`;
CREATE TABLE `AddressbookEntity` (
  `addressbookentity_entity_id`      int(8) NOT NULL,
  `addressbookentity_addressbook_id` int(8) NOT NULL,
  PRIMARY KEY (`addressbookentity_entity_id`,`addressbookentity_addressbook_id`),
  KEY `addressbookentity_addressbook_id_addressbook_id_fkey` (`addressbookentity_addressbook_id`),
  CONSTRAINT addressbookentity_addressbook_id_addressbook_id_fkey FOREIGN KEY (addressbookentity_addressbook_id) REFERENCES AddressBook (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `addressbookentity_entity_id_entity_id_fkey` FOREIGN KEY (`addressbookentity_entity_id`) REFERENCES `Entity` (`entity_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Contact update
--
ALTER TABLE Contact ADD COLUMN contact_addressbook_id int(8) default NULL AFTER contact_datasource_id; 
ALTER TABLE Contact ADD CONSTRAINT contact_addressbook_id_addressbook_id_fkey FOREIGN KEY (contact_addressbook_id) REFERENCES AddressBook (id) ON DELETE SET NULL ON UPDATE CASCADE;

-- Populating AddressBook
INSERT INTO AddressBook (domain_id, timecreate, usercreate, origin, owner, name, is_default, syncable) 
SELECT userobm_domain_id, NOW(), userobm_id, 'obm-storage-migration-2.3', userobm_id, 'contacts', true, true
FROM UserObm INNER JOIN Domain ON userobm_domain_id = domain_id WHERE domain_global = false;

INSERT INTO AddressBook (domain_id, timecreate, usercreate, origin, owner, name, is_default, syncable) 
SELECT userobm_domain_id, NOW(), userobm_id, 'obm-storage-migration-2.3', userobm_id, 'collected_contacts', true, true
FROM UserObm INNER JOIN Domain ON userobm_domain_id = domain_id WHERE domain_global = false;

INSERT INTO AddressBook (domain_id, timecreate, usercreate, origin, owner, name, is_default, syncable)
SELECT domain_id, NOW(), MIN(userobm_id), 'obm-storage-migration-2.3', MIN(userobm_id), 'public_contacts', true, false
FROM Domain INNER JOIN UserObm ON userobm_domain_id = domain_id WHERE domain_global = false AND userobm_perms = 'admin'
GROUP BY domain_id;

CREATE TABLE TmpEntity (
  entity_id     int(8) auto_increment,
  id_entity     integer,
  PRIMARY KEY (entity_id)
);
INSERT INTO TmpEntity (entity_id) SELECT MAX(entity_id) FROM Entity;
DELETE FROM TmpEntity;
INSERT INTO TmpEntity (id_entity) SELECT id from AddressBook;
INSERT INTO Entity (entity_id , entity_mailing) SELECT entity_id , true FROM TmpEntity ;
INSERT INTO AddressbookEntity (addressbookentity_addressbook_id, addressbookentity_entity_id) SELECT id_entity, entity_id FROM TmpEntity;

DROP TABLE TmpEntity;

-- setting default right on public_contacts address book
INSERT INTO EntityRight (entityright_entity_id, entityright_consumer_id, entityright_access, entityright_read, entityright_write, entityright_admin)
SELECT AddressbookEntity.addressbookentity_entity_id, NULL, 0, 1, 0, 0
FROM AddressbookEntity INNER JOIN AddressBook
ON AddressBook.id=AddressbookEntity.addressbookentity_addressbook_id
WHERE AddressBook.name='public_contacts';


UPDATE Contact SET contact_addressbook_id = (SELECT id from AddressBook WHERE owner = contact_usercreate and name = 'contacts') WHERE contact_privacy = 1 AND contact_collected = false;
UPDATE Contact SET contact_addressbook_id = (SELECT id from AddressBook WHERE owner = contact_usercreate and name = 'collected_contacts') WHERE contact_privacy = 1 AND contact_collected = true;
UPDATE Contact SET contact_addressbook_id = (SELECT id from AddressBook WHERE domain_id = contact_domain_id and name = 'public_contacts') WHERE contact_privacy = 0;
-- End populating addressbook

ALTER TABLE Contact DROP COLUMN contact_privacy;


--
-- Table structure for table `DeletedAddressbook`
--
DROP TABLE IF EXISTS `DeletedAddressbook`;
CREATE TABLE `DeletedAddressbook` (
  `addressbook_id` int(8) NOT NULL,
  `user_id`        int(8) NOT NULL,
  `timestamp`      timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `origin`         varchar(255) NOT NULL,
  PRIMARY KEY (`addressbook_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `DeletedContact`
--
DROP TABLE IF EXISTS `DeletedContact`;
CREATE TABLE `DeletedContact` (
  `deletedcontact_contact_id` int(8) NOT NULL,
  `deletedcontact_addressbook_id` int(8) NOT NULL,
  `deletedcontact_timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `deletedcontact_origin` varchar(255) NOT NULL,
  PRIMARY KEY  (`deletedcontact_contact_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Table structure for table `SyncedAddressbook`
--
DROP TABLE IF EXISTS `SyncedAddressbook`;
CREATE TABLE `SyncedAddressbook` (
  `user_id`        int(8) NOT NULL,
  `addressbook_id` int(8) NOT NULL,
  `timestamp`      timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`user_id`, `addressbook_id`),
  KEY `syncedaddressbook_user_id_user_id_fkey` (`user_id`),
  KEY `syncedaddressbook_addressbook_id_addressbook_id_fkey` (`addressbook_id`),
  CONSTRAINT `syncedaddressbook_user_id_userobm_id_fkey` FOREIGN KEY (user_id) REFERENCES `UserObm` (`userobm_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT syncedaddressbook_addressbook_id_addressbook_id_fkey FOREIGN KEY (addressbook_id) REFERENCES AddressBook (id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO SyncedAddressbook (user_id, addressbook_id, timestamp)
SELECT owner, id, now() FROM AddressBook WHERE name = 'contacts' AND is_default = true;

DROP TABLE IF EXISTS `SynchedContact`;

-- 
-- Table structure for table `EventTag`
-- 
DROP TABLE IF EXISTS `EventTag` ;
CREATE TABLE `EventTag` ( 
  `eventtag_id` int(8) NOT NULL auto_increment, 
  `eventtag_user_id` int(8) NOT NULL, 
  `eventtag_label` varchar(128) default NULL, 
  `eventtag_color` char(7) default NULL, 
  PRIMARY KEY  (`eventtag_id`), 
  KEY `eventtag_label_fkey` (`eventtag_label`),
	KEY `eventtag_user_id_userobm_id_fkey` (`eventtag_user_id`), 
  CONSTRAINT `eventtag_user_id_userobm_id_fkey` FOREIGN KEY (`eventtag_user_id`) REFERENCES `UserObm` (`userobm_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ;

-- 
-- Alter table `Event` to add tag infos
-- 
ALTER TABLE `Event` ADD COLUMN `event_tag_id` int(8) ; 
ALTER TABLE `Event` ADD KEY `event_tag_id_eventtag_id_fkey` (`event_tag_id`) ;
ALTER TABLE `Event` ADD CONSTRAINT `event_tag_id_eventtag_id_fkey` FOREIGN KEY (`event_tag_id`) REFERENCES `EventTag` (`eventtag_id`) ON DELETE SET NULL ON UPDATE CASCADE ;

-- 
-- Alter `Event` and `DocumentLink` for document attachment
-- 
ALTER TABLE `Event` ADD COLUMN `event_allow_documents` tinyint(1) NULL DEFAULT '0' AFTER `event_url`;
ALTER TABLE `DocumentLink` ADD COLUMN `documentlink_usercreate` int(8) NULL DEFAULT NULL;
ALTER TABLE `DocumentLink` ADD KEY `documentlink_usercreate_userobm_id_fkey` (`documentlink_usercreate`) ;
ALTER TABLE `DocumentLink` ADD CONSTRAINT `documentlink_usercreate_userobm_id_fkey` FOREIGN KEY (`documentlink_usercreate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Table structure for table `EventTemplate`
--
DROP TABLE IF EXISTS `EventTemplate`;
CREATE TABLE `EventTemplate` (
  `eventtemplate_id` int(8) NOT NULL auto_increment,
  `eventtemplate_domain_id` int(8) NOT NULL,
  `eventtemplate_timeupdate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `eventtemplate_timecreate` timestamp NOT NULL default '0000-00-00 00:00:00',
  `eventtemplate_userupdate` int(8) default NULL,
  `eventtemplate_usercreate` int(8) default NULL,
  `eventtemplate_owner` int(8) default NULL,
  `eventtemplate_name` varchar(255) default NULL,
  `eventtemplate_title` varchar(255) default NULL,
  `eventtemplate_location` varchar(100) default NULL,
  `eventtemplate_category1_id` int(8) default NULL,
  `eventtemplate_priority` int(2) default NULL,
  `eventtemplate_privacy` int(2) NOT NULL default '0',
  `eventtemplate_date` datetime default NULL,
  `eventtemplate_duration` int(8) NOT NULL default '0',
  `eventtemplate_allday` tinyint(1) default '0',
  `eventtemplate_repeatkind` varchar(20) NOT NULL default 'none',
  `eventtemplate_repeatfrequence` int(3) default NULL,
  `eventtemplate_repeatdays` varchar(7) default NULL,
  `eventtemplate_endrepeat` datetime default NULL,
  `eventtemplate_allow_documents` tinyint(1) NULL DEFAULT '0',
  `eventtemplate_alert` int(8) NOT NULL default '0',
  `eventtemplate_description` text,
  `eventtemplate_properties` text,
  `eventtemplate_tag_id` int(8) default NULL,
  `eventtemplate_user_ids` text NULL,
  `eventtemplate_contact_ids` text NULL,
  `eventtemplate_resource_ids` text NULL,
  `eventtemplate_document_ids` text NULL,
  `eventtemplate_group_ids` text NULL,
  PRIMARY KEY  (`eventtemplate_id`),
  KEY `eventtemplate_domain_id_domain_id_fkey` (`eventtemplate_domain_id`),
  KEY `eventtemplate_owner_userobm_id_fkey` (`eventtemplate_owner`),
  KEY `eventtemplate_userupdate_userobm_id_fkey` (`eventtemplate_userupdate`),
  KEY `eventtemplate_usercreate_userobm_id_fkey` (`eventtemplate_usercreate`),
  KEY `eventtemplate_category1_id_eventcategory1_id_fkey` (`eventtemplate_category1_id`),
	KEY `eventtemplate_tag_id_eventtag_id_fkey` (`eventtemplate_tag_id`),
  CONSTRAINT `eventtemplate_category1_id_eventcategory1_id_fkey` FOREIGN KEY (`eventtemplate_category1_id`) REFERENCES `EventCategory1` (`eventcategory1_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `eventtemplate_domain_id_domain_id_fkey` FOREIGN KEY (`eventtemplate_domain_id`) REFERENCES `Domain` (`domain_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `eventtemplate_owner_userobm_id_fkey` FOREIGN KEY (`eventtemplate_owner`) REFERENCES `UserObm` (`userobm_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `eventtemplate_tag_id_eventtag_id_fkey` FOREIGN KEY (`eventtemplate_tag_id`) REFERENCES `EventTag` (`eventtag_id`) ON DELETE SET NULL ON UPDATE CASCADE,
	CONSTRAINT `eventtemplate_usercreate_userobm_id_fkey` FOREIGN KEY (`eventtemplate_usercreate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `eventtemplate_userupdate_userobm_id_fkey` FOREIGN KEY (`eventtemplate_userupdate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Event exceptions : drop parent_id from Event and add parent_id/child_id in EventException
--
ALTER TABLE `EventException` DROP FOREIGN KEY `eventexception_event_id_eventevent_id_fkey`;
ALTER TABLE `EventException` CHANGE COLUMN eventexception_event_id eventexception_parent_id INT(8) NOT NULL;
ALTER TABLE `EventException` ADD CONSTRAINT `eventexception_parent_id_event_id_fkey` FOREIGN KEY (`eventexception_parent_id`) REFERENCES `Event` (`event_id`) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE `EventException` ADD COLUMN eventexception_child_id INT(8) DEFAULT NULL AFTER eventexception_parent_id;
ALTER TABLE `EventException` ADD CONSTRAINT `eventexception_child_id_event_id_fkey` FOREIGN KEY (`eventexception_child_id`) REFERENCES `Event` (`event_id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- useless because event_parent_id was not used
-- UPDATE EventException ee
-- SET ee.eventexception_child_id = (
--    SELECT e.event_id
--    FROM Event e
--    WHERE e.event_parent_id = ee.eventexception_parent_id);
ALTER TABLE `Event` DROP FOREIGN KEY `event_parent_id_event_id_fkey`;
ALTER TABLE `Event` DROP COLUMN `event_parent_id`;
CREATE INDEX event_ext_id_idx ON Event (event_ext_id);
ALTER TABLE `Event` MODIFY COLUMN `event_ext_id` varchar(300);


--
-- Table structure for table `PlannedTask`
--
DROP TABLE IF EXISTS `PlannedTask`;
CREATE TABLE `PlannedTask` (
  `plannedtask_id` int(8) NOT NULL auto_increment,
  `plannedtask_domain_id` int(8) default '0',
  `plannedtask_timeupdate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `plannedtask_timecreate` timestamp NOT NULL default '0000-00-00 00:00:00',
  `plannedtask_userupdate` int(8) default NULL,
  `plannedtask_usercreate` int(8) default NULL,
  `plannedtask_user_id` int(8) default NULL,
  `plannedtask_datebegin` date default NULL,
  `plannedtask_dateend` date default NULL,
  `plannedtask_period` enum ('0','1','2') NOT NULL default '0',
  `plannedtask_project_id` int(8) default NULL,
  `plannedtask_tasktype_id` int(8) default NULL,
  `plannedtask_overrun` enum ('0','1') NOT NULL default '0',
  `plannedtask_comment` text,
  PRIMARY KEY  (`plannedtask_id`),
  KEY `plannedtask_domain_id_domain_id_fkey` (`plannedtask_domain_id`),
  KEY `plannedtask_user_id_userobm_id_fkey` (`plannedtask_user_id`),
  KEY `plannedtask_datebegin_key` (`plannedtask_datebegin`),
  KEY `plannedtask_dateend_key` (`plannedtask_dateend`),
  CONSTRAINT `plannedtask_domain_id_domain_id_fkey` FOREIGN KEY (`plannedtask_domain_id`) REFERENCES `Domain` (`domain_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plannedtask_usercreate_userobm_id_fkey` FOREIGN KEY (`plannedtask_usercreate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `plannedtask_userupdate_userobm_id_fkey` FOREIGN KEY (`plannedtask_userupdate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `plannedtask_project_id_project_id_fkey` FOREIGN KEY (`plannedtask_project_id`) REFERENCES `Project` (`project_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plannedtask_tasktype_id_tasktype_id_fkey` FOREIGN KEY (`plannedtask_tasktype_id`) REFERENCES `TaskType` (`tasktype_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `plannedtask_user_id_userobm_id_fkey` FOREIGN KEY (`plannedtask_user_id`) REFERENCES `UserObm` (`userobm_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


--
-- Table structure for table `TaskTypeGroup`
--

DROP TABLE IF EXISTS `TaskTypeGroup`;
CREATE TABLE `TaskTypeGroup` (
  `tasktypegroup_id` int(8) NOT NULL auto_increment,
  `tasktypegroup_domain_id` int(8) default '0',
  `tasktypegroup_timeupdate` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `tasktypegroup_timecreate` timestamp NOT NULL default '0000-00-00 00:00:00',
  `tasktypegroup_userupdate` int(8) default NULL,
  `tasktypegroup_usercreate` int(8) default NULL,
  `tasktypegroup_label` varchar(32) default NULL,
  `tasktypegroup_code` varchar(20) default NULL,
  `tasktypegroup_bgcolor` varchar(7) default NULL,
  `tasktypegroup_fgcolor` varchar(7) default NULL,
  KEY `tasktypegroup_domain_id_domain_id_fkey` (`tasktypegroup_domain_id`),
  CONSTRAINT `tasktypegroup_domain_id_domain_id_fkey` FOREIGN KEY (`tasktypegroup_domain_id`) REFERENCES `Domain` (`domain_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `tasktypegroup_usercreate_userobm_id_fkey` FOREIGN KEY (`tasktypegroup_usercreate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `tasktypegroup_userupdate_userobm_id_fkey` FOREIGN KEY (`tasktypegroup_userupdate`) REFERENCES `UserObm` (`userobm_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  PRIMARY KEY  (`tasktypegroup_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE TaskType ADD
  `tasktype_tasktypegroup_id` int(8) AFTER tasktype_internal;
ALTER TABLE TaskType ADD
  CONSTRAINT `tasktype_tasktypegroup_id_tasktypegroup_id_fkey` FOREIGN KEY (`tasktype_tasktypegroup_id`) REFERENCES `TaskTypeGroup` (`tasktypegroup_id`) ON DELETE SET NULL ON UPDATE CASCADE;



CREATE TABLE opush_device (
       id 		INT(8) NOT NULL AUTO_INCREMENT PRIMARY KEY,
       identifier 	VARCHAR(255) NOT NULL,
       owner		INTEGER REFERENCES userobm(userobm_id) ON DELETE CASCADE,
       type		VARCHAR(64) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE opush_folder_mapping (
       id		INT(8) NOT NULL AUTO_INCREMENT PRIMARY KEY,
       device_id	INTEGER NOT NULL REFERENCES opush_device(id) ON DELETE CASCADE,
       collection	VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- store last sync dates
CREATE TABLE opush_sync_state (
	sync_key	VARCHAR(64) UNIQUE NOT NULL,
	collection_id   INTEGER NOT NULL REFERENCES opush_folder_mapping(id) ON DELETE CASCADE,
	device_id	INTEGER NOT NULL REFERENCES opush_device(id) ON DELETE CASCADE,
	last_sync	TIMESTAMP NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE opush_sync_state ADD CONSTRAINT 
unique_opush_col_dev UNIQUE (collection_id, device_id);

CREATE TABLE opush_sec_policy (
       id				INT(8) NOT NULL AUTO_INCREMENT PRIMARY KEY,
       device_password_enabled		BOOLEAN DEFAULT FALSE
       -- add other fields fields...
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- A row exists if a user is allowed to Sync.
CREATE TABLE opush_sync_perms (
       owner		INTEGER REFERENCES userobm(userobm_id) ON DELETE CASCADE,
       device_id	INTEGER NOT NULL REFERENCES opush_device(id) ON DELETE CASCADE,
       -- add not null later
       policy		INTEGER REFERENCES opush_sec_policy(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE opush_sync_mail (
        collection_id   INTEGER NOT NULL REFERENCES opush_folder_mapping(id) ON DELETE CASCADE,
        device_id       INTEGER NOT NULL REFERENCES opush_device(id) ON DELETE CASCADE,
        mail_uid        INTEGER NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'people', 'userobm_direction', 11, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'people', 'userobm_service', 12, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'people', 'userobm_address', 13, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'people', 'userobm_town', 14, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'people', 'userobm_zipcode', 15, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'user', 'userobm_direction', 26, 1);
INSERT INTO DisplayPref (display_user_id,display_entity,display_fieldname,display_fieldorder,display_display) VALUES (NULL,'user', 'userobm_service', 27, 1);

-- ----------------------------------------------------------------------------
-- Adding needed system users
-- obmSatellite
DELETE FROM UserSystem WHERE usersystem_login='obmsatelliterequest';
INSERT INTO UserSystem (usersystem_login, usersystem_password, usersystem_uid, usersystem_gid,usersystem_homedir, usersystem_lastname, usersystem_firstname, usersystem_shell) VALUES ( 'obmsatelliterequest', 'PgpTWb7x', 201, 65534, '/', 'OBM Satellite', 'HTTP auth request', '/bin/false' );

-- Reset all contacts display prefs
DELETE FROM DisplayPref WHERE display_user_id IS NOT NULL and display_entity = 'contact';

-- ----------------------------------------------------------------------------
-- Delete unused domain properties
DELETE FROM DomainProperty WHERE domainproperty_key='last_public_contact_export';
DELETE FROM DomainPropertyValue WHERE domainpropertyvalue_property_key='last_public_contact_export';

-- ----------------------------------------------------------------------------
-- Obm product ID
INSERT INTO ObmInfo SELECT 'product_id', LPAD(MD5(FLOOR(RAND()*NOW())), 24, 0);
UPDATE Event SET event_ext_id = CONCAT((select obminfo_value from ObmInfo where obminfo_name = 'prod_id'),MD5(FLOOR(RAND()*NOW())),MD5(FLOOR(RAND()*NOW())),MD5(FLOOR(RAND()*NOW())),MD5(FLOOR(RAND()*NOW())),MD5(FLOOR(RAND()*NOW()))) WHERE event_ext_id IS NULL OR event_ext_id = '';

-- ----------------------------------------------------------------------------
-- Write that the 2.2->2.3 is completed
UPDATE ObmInfo SET obminfo_value='2.3.0' WHERE obminfo_name='db_version';
