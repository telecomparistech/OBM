/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2011-2014  Linagora
 *
 * This program is free software: you can redistribute it and/or 
 * modify it under the terms of the GNU Affero General Public License as 
 * published by the Free Software Foundation, either version 3 of the 
 * License, or (at your option) any later version, provided you comply 
 * with the Additional Terms applicable for OBM connector by Linagora 
 * pursuant to Section 7 of the GNU Affero General Public License, 
 * subsections (b), (c), and (e), pursuant to which you must notably (i) retain 
 * the “Message sent thanks to OBM, Free Communication by Linagora” 
 * signature notice appended to any and all outbound messages 
 * (notably e-mail and meeting requests), (ii) retain all hypertext links between 
 * OBM and obm.org, as well as between Linagora and linagora.com, and (iii) refrain 
 * from infringing Linagora intellectual property rights over its trademarks 
 * and commercial brands. Other Additional Terms apply, 
 * see <http://www.linagora.com/licenses/> for more details. 
 *
 * This program is distributed in the hope that it will be useful, 
 * but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License 
 * for more details. 
 *
 * You should have received a copy of the GNU Affero General Public License 
 * and its applicable Additional Terms for OBM along with this program. If not, 
 * see <http://www.gnu.org/licenses/> for the GNU Affero General Public License version 3 
 * and <http://www.linagora.com/licenses/> for the Additional Terms applicable to 
 * OBM connectors. 
 * 
 * ***** END LICENSE BLOCK ***** */
package org.obm;

import java.io.File;
import java.nio.charset.Charset;
import java.util.Locale;
import java.util.ResourceBundle;
import java.util.concurrent.TimeUnit;

import com.google.common.base.Charsets;
import com.google.common.collect.ImmutableSet;

public class Configuration {

	public static class Locator {
		public String url = null;
		public int port = 8084;
		public int clientTimeout = 5;
		public int cacheTimeout = 10;
		public TimeUnit cacheTimeUnit = TimeUnit.SECONDS;
	}

	public static class Transaction {
		public int timeoutInSeconds = 10;
		public boolean usePersistentCache = true;
		public int toleranceInSeconds = 5;
		public File journal1 = null;
		public File journal2 = null;
		public boolean enableJournal = false;
	}

	public static class ObmSync {
		public String defaultTemplateFolder;
		public String overrideTemplateFolder;
		public String obmSyncMailer;
		public String ldapServer = null;
		public String ldapBaseDn = "dc=local";
		public String ldapFilter;
		public String ldapBindDn = "uid=uid=ldapadmin,ou=sysusers,dc=local";
		public String ldapBindPassword = "password";
		public Iterable<String> lemonLdapIps = ImmutableSet.of();
		public String rootAccounts = "";
		public String appliAccounts = "";
		public String anyUserAccounts = "";
		public String emailCalendarEncoding = "Auto";
		public boolean syncUsersAsAddressBook = true;
	}

	public static class ObmSyncWithLDAPAuth extends ObmSync {
		
		public ObmSyncWithLDAPAuth() {
			this.ldapServer = "ldap://localhost:33389";
			this.ldapBaseDn = "dc=local";
			this.ldapFilter = "(&(uid=%u)(obmDomain=%d))";
			this.ldapBindDn = "cn=directory manager";
			this.ldapBindPassword = "secret";
		}

	}

	public ResourceBundle bundle = ResourceBundle.getBundle("Messages", Locale.FRANCE);
	public Transaction transaction = new Transaction();
	public Locator locator = new Locator();
	public File dataDir;
	public Charset defautEncoding = Charsets.UTF_8;
	public int trustTokenTimeoutInSeconds = 10;
	public int solrCheckingInterval = 10;
	public String applicationName = "opush";
	public String obmUiBaseUrl = null;
	public String obmSyncServices = "services";
	public String activeSyncServletUrl = null;

}