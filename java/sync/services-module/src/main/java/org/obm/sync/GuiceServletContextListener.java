/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2011-2012  Linagora
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

import java.util.Collections;
import java.util.TimeZone;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

import bitronix.tm.TransactionManagerServices;

import com.google.common.annotations.VisibleForTesting;
import com.google.common.base.Objects;
import com.google.common.base.Strings;
import com.google.common.collect.ImmutableList;
import com.google.inject.CreationException;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.Module;
import com.google.inject.internal.Errors;
import com.google.inject.spi.Message;
import com.linagora.obm.sync.QueueManager;

public class GuiceServletContextListener implements ServletContextListener { 

	public static final String ATTRIBUTE_NAME = "GuiceInjecter";
	
    @Override
	public void contextInitialized(ServletContextEvent servletContextEvent) {
    	XTrustProvider.install();
    	
        final ServletContext servletContext = servletContextEvent.getServletContext(); 
        
        try {
        	Injector injector = createInjector(servletContext);
        	if (injector == null) { 
        		failStartup("Could not create injector: createInjector() returned null"); 
        	} 
        	servletContext.setAttribute(ATTRIBUTE_NAME, injector);
        	TimeZone.setDefault(TimeZone.getTimeZone("GMT"));
        } catch (Exception e) {
        	failStartup(e.getMessage());
        } 
    } 
    
    private Injector createInjector(ServletContext servletContext)
    		throws ClassNotFoundException, InstantiationException, IllegalAccessException {
    	
        return Guice.createInjector(selectGuiceModule(servletContext));
    }

    @VisibleForTesting Module selectGuiceModule(ServletContext servletContext)
			throws ClassNotFoundException, InstantiationException, IllegalAccessException {
		
		return Objects.firstNonNull(newWebXmlModuleInstance(servletContext), new ObmSyncModule());
	}

    @VisibleForTesting Module newWebXmlModuleInstance(ServletContext servletContext)
    		throws ClassNotFoundException, InstantiationException, IllegalAccessException {
    	
		String guiceModuleClassName = servletContext.getInitParameter("guiceModule");
		if (Strings.isNullOrEmpty(guiceModuleClassName)) {
			return null;
		}
		return (Module) Class.forName(guiceModuleClassName).newInstance();
	}
    
    private void failStartup(String message) { 
        throw new CreationException(Collections.nCopies(1, new Message(this, message))); 
    }
    
    @Override
	public void contextDestroyed(ServletContextEvent servletContextEvent) { 
		Errors errors = new Errors();
		Injector injector = (Injector) servletContextEvent.getServletContext().getAttribute(ATTRIBUTE_NAME);

		try {
			if (injector != null) {
				injector.getInstance(QueueManager.class).stop();
			}
		}
		catch (Exception e) {
			errors.addMessage(new Message(ImmutableList.of(), "Failed to stop QueueManager.", e));
		}

		try {
			TransactionManagerServices.getTransactionManager().shutdown();
		}
		catch (Exception e) {
			errors.addMessage(new Message(ImmutableList.of(), "Failed to stop TransactionManager.", e));
		}

		servletContextEvent.getServletContext().setAttribute(ATTRIBUTE_NAME, null);
		errors.throwConfigurationExceptionIfErrorsExist();
    }
}