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

import org.obm.servlet.filter.resource.ResourcesFilter;
import org.obm.sync.resource.ResourceServlet;
import org.obm.sync.server.SyncServlet;

import com.google.inject.servlet.ServletModule;

import fr.aliacom.obm.freebusy.FreeBusyServlet;

public class ObmSyncServletModule  extends ServletModule {


	private static final String SERVICES_MAIN_SERVLET_PATH = "/services";
	private static final String SERVICES_SERVLET_PATH = SERVICES_MAIN_SERVLET_PATH + "/*";
	private static final String RESOURCES_SERVLET_PATH = "/resources/*";
	private static final String FREEBUSY_SERVLET_PATH = "/freebusy/*";

	@Override
	protected void configureServlets() {
		super.configureServlets();
		
		serve(SERVICES_MAIN_SERVLET_PATH).with(SyncServlet.class);
		serve(SERVICES_SERVLET_PATH).with(SyncServlet.class);
		serve(RESOURCES_SERVLET_PATH).with(ResourceServlet.class);
		serve(FREEBUSY_SERVLET_PATH).with(FreeBusyServlet.class);
		
		filter("/*").through(LoggerFilter.class);
		filter("/*").through(ResourcesFilter.class);
	}
}
