package org.obm.push;

import java.util.Collections;
import java.util.TimeZone;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

import org.obm.annotations.transactional.TransactionalModule;
import org.obm.configuration.ConfigurationService;
import org.obm.dbcp.DBCP;
import org.obm.dbcp.IDBCP;
import org.obm.push.backend.IBackend;
import org.obm.push.backend.IContentsExporter;
import org.obm.push.backend.IContentsImporter;
import org.obm.push.backend.IErrorsManager;
import org.obm.push.backend.IHierarchyExporter;
import org.obm.push.backend.OBMBackend;
import org.obm.push.impl.InvitationFilterManagerImpl;
import org.obm.push.mail.EmailManager;
import org.obm.push.mail.IEmailManager;
import org.obm.push.store.DaoModule;
import org.obm.push.store.ISyncStorage;
import org.obm.push.store.MonitoredCollectionDao;
import org.obm.push.store.SyncStorage;
import org.obm.push.store.SyncedCollectionDao;
import org.obm.push.store.UnsynchronizedItemDao;
import org.obm.push.store.ehcache.MonitoredCollectionDaoEhcacheImpl;
import org.obm.push.store.ehcache.SyncedCollectionDaoEhcacheImpl;
import org.obm.push.store.ehcache.UnsynchronizedItemDaoEhcacheImpl;
import org.obm.sync.XTrustProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.inject.AbstractModule;
import com.google.inject.CreationException;
import com.google.inject.Guice;
import com.google.inject.Injector;
import com.google.inject.spi.Message;

public class GuiceServletContextListener implements ServletContextListener { 

	private static final Logger logger = LoggerFactory.getLogger(GuiceServletContextListener.class);
	
	public static final String ATTRIBUTE_NAME = "OpushGuiceInjecter";
	
    public void contextInitialized(ServletContextEvent servletContextEvent) {
    	
        final ServletContext servletContext = servletContextEvent.getServletContext(); 
        
        try {
        	Injector injector = createInjector(servletContext);
        	if (injector == null) { 
        		failStartup("Could not create injector: createInjector() returned null"); 
        	} 
        	servletContext.setAttribute(ATTRIBUTE_NAME, injector);
        	XTrustProvider.install();
        	TimeZone.setDefault(TimeZone.getTimeZone("GMT"));
        } catch (Exception e) {
        	logger.error(e.getMessage(), e);
        	failStartup(e.getMessage());
        } 
    } 
    
    private Injector createInjector(final ServletContext servletContext) {
    	return Guice.createInjector(new AbstractModule() {
			@Override
			protected void configure() {
				bind(ISyncStorage.class).to(SyncStorage.class);
				bind(IEmailManager.class).to(EmailManager.class);
				bind(IHierarchyExporter.class).to(HierarchyExporter.class);
				bind(IContentsExporter.class).to(ContentsExporter.class);
				bind(ConfigurationService.class).to(OpushConfigurationService.class);
				bind(IInvitationFilterManager.class).to(InvitationFilterManagerImpl.class);	
				bind(IBackend.class).to(OBMBackend.class);
				bind(IContentsImporter.class).to(ContentsImporter.class);
				bind(IErrorsManager.class).to(ErrorsManager.class);
				bind(UnsynchronizedItemDao.class).to(UnsynchronizedItemDaoEhcacheImpl.class);
				bind(MonitoredCollectionDao.class).to(MonitoredCollectionDaoEhcacheImpl.class);
				bind(SyncedCollectionDao.class).to(SyncedCollectionDaoEhcacheImpl.class);
				bind(ServletContext.class).toInstance(servletContext);
				bind(IDBCP.class).to(DBCP.class);
			}
    	}, new TransactionalModule(), new DaoModule());
    }
    
    private void failStartup(String message) { 
        throw new CreationException(Collections.nCopies(1, new Message(this, message))); 
    }
    
    public void contextDestroyed(ServletContextEvent servletContextEvent) { 
    	servletContextEvent.getServletContext().setAttribute(ATTRIBUTE_NAME, null); 
    }
    
}