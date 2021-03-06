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
package org.obm.provisioning.user;


import static com.jayway.restassured.RestAssured.given;
import static org.hamcrest.Matchers.containsString;
import static org.obm.provisioning.ProvisioningIntegrationTestUtils.getAdminUserJsonWithGroup;
import static org.obm.provisioning.ProvisioningIntegrationTestUtils.userUrl;

import java.io.File;
import java.net.URL;

import javax.ws.rs.core.Response.Status;

import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.container.test.api.RunAsClient;
import org.jboss.arquillian.test.api.ArquillianResource;
import org.jboss.shrinkwrap.api.spec.WebArchive;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.obm.provisioning.ProvisioningArchiveUtils;
import org.obm.push.arquillian.ManagedTomcatGuiceArquillianRunner;

import com.jayway.restassured.RestAssured;

import fr.aliacom.obm.common.domain.ObmDomainUuid;

@RunWith(ManagedTomcatGuiceArquillianRunner.class)
public class UserIntegrationTest {

	@Test
	@RunAsClient
	public void testGetUserWithGroup(@ArquillianResource URL baseURL) {
		ObmDomainUuid obmDomainUuid = ObmDomainUuid.of("123456789");
		RestAssured.baseURI = userUrl(baseURL, obmDomainUuid);
		
		given()
			.auth().basic("admin0@global.virt", "admin0").
		expect()
			.statusCode(Status.OK.getStatusCode())
			.body(containsString(getAdminUserJsonWithGroup())).
		when()
			.get("/Admin0ExtId");
	}
	
	@Deployment
	public static WebArchive createDeployment() throws Exception {
		return ProvisioningArchiveUtils.buildWebArchive(
				new File(ClassLoader.getSystemResource("dbInitialScriptUser.sql").toURI()));
	}
}
