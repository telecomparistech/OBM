/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2014 Linagora
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
package org.obm.imap.archive.resources;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.Produces;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Application;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.obm.domain.dao.DomainDao;
import org.obm.provisioning.dao.exceptions.DaoException;
import org.obm.provisioning.dao.exceptions.DomainNotFoundException;

import com.google.common.base.Optional;
import com.google.inject.Inject;
import com.google.inject.Singleton;

import fr.aliacom.obm.common.domain.ObmDomain;
import fr.aliacom.obm.common.domain.ObmDomainUuid;

@Singleton
@Path("/")
@Produces(MediaType.APPLICATION_JSON)
public class RootHandler {

	@Inject
	@Context
	private Application application;

	@Inject
	private DomainDao domainDao;
	
	@GET
	@Path("/status")
	public Response status() {
		return Response.ok().build();
	}
	
	@Path("domains/{domain}/")
	public Class<DomainsResource> domains(@PathParam("domain") String domainId) throws DaoException {
		ObmDomainUuid checkedDomainUuid = checkDomainUuid(domainId);
		Optional<ObmDomain> domain = getDomain(checkedDomainUuid);
		if (!domain.isPresent()) {
			throw new WebApplicationException(Status.NOT_FOUND);
		} else {
			return DomainsResource.class;
		}
	}
	
	private ObmDomainUuid checkDomainUuid(String domainUuid) {
		try {
			return ObmDomainUuid.of(domainUuid);
		} catch (IllegalArgumentException e) {
			throw new WebApplicationException(Status.BAD_REQUEST);
		}
	}
	
	private Optional<ObmDomain> getDomain(ObmDomainUuid domainUuid) throws DaoException {
		try {
			return Optional.of(domainDao.findDomainByUuid(domainUuid));
		} catch (DomainNotFoundException e) {
			return Optional.absent();
		}
	}
}
