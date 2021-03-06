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
package org.obm.sync;

import org.obm.dbcp.DatabaseConnectionProvider;
import org.obm.dbcp.DatabaseDriversModule;
import org.obm.domain.dao.AddressBookDao;
import org.obm.domain.dao.AddressBookDaoJdbcImpl;
import org.obm.domain.dao.ObmInfoDao;
import org.obm.domain.dao.ObmInfoDaoJdbcImpl;
import org.obm.domain.dao.UserDao;
import org.obm.domain.dao.UserDaoJdbcImpl;
import org.obm.domain.dao.UserPatternDao;
import org.obm.domain.dao.UserPatternDaoJdbcImpl;
import org.obm.provisioning.dao.GroupDao;
import org.obm.provisioning.dao.GroupDaoJdbcImpl;

import com.google.inject.AbstractModule;
import com.google.inject.multibindings.Multibinder;

import fr.aliacom.obm.common.addition.CommitedOperationDao;
import fr.aliacom.obm.common.addition.CommitedOperationDaoJdbcImpl;
import fr.aliacom.obm.common.calendar.CalendarDao;
import fr.aliacom.obm.common.calendar.CalendarDaoJdbcImpl;
import fr.aliacom.obm.common.contact.ContactDao;
import fr.aliacom.obm.common.contact.ContactDaoJdbcImpl;

public class DatabaseModule extends AbstractModule {

	@Override
	protected void configure() {
		install(new DatabaseDriversModule());
		bind(DatabaseConnectionProvider.class).to(RequestScopedDatabaseConnectionProvider.class);
		Multibinder<LifecycleListener> lifecycleListeners = Multibinder.newSetBinder(binder(), LifecycleListener.class);
		lifecycleListeners.addBinding().to(RequestScopedDatabaseConnectionProvider.class);
		bind(CalendarDao.class).to(CalendarDaoJdbcImpl.class);
		bind(ContactDao.class).to(ContactDaoJdbcImpl.class);
		bind(CommitedOperationDao.class).to(CommitedOperationDaoJdbcImpl.class);
		bind(ObmInfoDao.class).to(ObmInfoDaoJdbcImpl.class);
		bind(AddressBookDao.class).to(AddressBookDaoJdbcImpl.class);
		bind(UserPatternDao.class).to(UserPatternDaoJdbcImpl.class);
		bind(UserDao.class).to(UserDaoJdbcImpl.class);
		bind(GroupDao.class).to(GroupDaoJdbcImpl.class);
	}
}
