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
package org.obm.push.store.ehcache;

import static org.easymock.EasyMock.createNiceMock;
import static org.fest.assertions.api.Assertions.assertThat;

import java.io.IOException;

import net.sf.ehcache.Cache;
import net.sf.ehcache.config.CacheConfiguration;

import org.junit.After;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.obm.configuration.ConfigurationService;
import org.obm.filter.Slow;
import org.obm.filter.SlowFilterRunner;
import org.obm.transaction.TransactionManagerRule;
import org.slf4j.Logger;

@Slow
@RunWith(SlowFilterRunner.class)
public class ObjectStoreManagerTest extends StoreManagerConfigurationTest {

	@Rule 
	public TransactionManagerRule transactionManagerRule = new TransactionManagerRule();
	
	private ObjectStoreManager opushCacheManager;
	private EhCacheConfiguration config;
	private ConfigurationService configurationService;
	private Logger logger;

	
	@Before
	public void init() throws IOException {
		logger = createNiceMock(Logger.class);
		configurationService = super.mockConfigurationService();
		config = new TestingEhCacheConfiguration();
		opushCacheManager = new ObjectStoreManager(configurationService, config, logger);
	}

	@After
	public void shutdown() {
		opushCacheManager.shutdown();
	}

	public void loadStores() {
		assertThat(opushCacheManager.listStores()).hasSize(8);
	}
	
	@Test
	public void createNewThreeCachesAndRemoveOne() {
		opushCacheManager.createNewStore("test 1");
		opushCacheManager.createNewStore("test 2");
		opushCacheManager.createNewStore("test 3");
		
		opushCacheManager.removeStore("test 2");

		assertThat(opushCacheManager.getStore("test 1")).isNotNull();
		assertThat(opushCacheManager.getStore("test 3")).isNotNull();
		assertThat(opushCacheManager.getStore("test 2")).isNull();
		assertThat(opushCacheManager.listStores()).hasSize(9);
	}
	
	@Test
	public void createAndRemoveCache() {
		opushCacheManager.createNewStore("test 1");
		opushCacheManager.removeStore("test 1");

		assertThat(opushCacheManager.getStore("test 1")).isNull();
	}

	@Test
	public void createTwoIdenticalCache() {
		opushCacheManager.createNewStore("test 1");
		opushCacheManager.createNewStore("test 1");
		
		assertThat(opushCacheManager.getStore("test 1")).isNotNull();
		assertThat(opushCacheManager.listStores()).hasSize(8);
	}
	
	@Test(expected=IllegalArgumentException.class)
	public void testRequiredStoreOnUnknownStore() {
		opushCacheManager.requiredStore("unknown");
	}
	
	@Test
	public void testRequiredStore() {
		String storeName = "test";
		Cache expectedStore = opushCacheManager.createNewStore(storeName);
		Cache store = opushCacheManager.requiredStore(storeName);
		assertThat(store).isEqualTo(expectedStore);
	}
	
	@Test(expected=IllegalArgumentException.class)
	public void testRequiredStoreConfigurationOnUnknownStore() {
		opushCacheManager.requiredStoreConfiguration("unknown");
	}
	
	@Test
	public void testRequiredStoreConfiguration() {
		String storeName = "test";
		Cache expectedStore = opushCacheManager.createNewStore(storeName);
		CacheConfiguration configuration = opushCacheManager.requiredStoreConfiguration(storeName);
		assertThat(configuration).isEqualTo(expectedStore.getCacheConfiguration());
	}
	
	@Test
	public void testCreateConfigReader() {
		ObjectStoreConfigReader configReader = opushCacheManager.createConfigReader();
		assertThat(configReader.storeManager).isEqualTo(opushCacheManager);
	}
}
