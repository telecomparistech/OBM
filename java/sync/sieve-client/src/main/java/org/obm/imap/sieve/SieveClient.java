/* ***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2011-2015  Linagora
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

package org.obm.imap.sieve;

import java.io.IOException;
import java.util.List;

import javax.security.sasl.SaslException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.fluffypeople.managesieve.ManageSieveClient;
import com.fluffypeople.managesieve.ManageSieveResponse;
import com.fluffypeople.managesieve.ParseException;
import com.fluffypeople.managesieve.ServerCapabilities;
import com.fluffypeople.managesieve.SieveScript;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Lists;

/**
 * Client API to cyrus sieve server
 * 
 * <code>http://www.ietf.org/proceedings/06mar/slides/ilemonade-1.pdf</code>
 */
public class SieveClient {

	private static final Logger logger = LoggerFactory
			.getLogger(SieveClient.class);

	private final String host;
	private final int port;
	private final AuthenticationIdentity authIdentity;
	private final AuthorizationIdentity autzIdentity;
	private final ManageSieveClient manageSieveClient;

	public SieveClient(String hostname, int port, AuthenticationIdentity authIdentity,
			AuthorizationIdentity autzIdentity) {
		this.host = hostname;
		this.port = port;
		this.authIdentity = authIdentity;
		this.autzIdentity = autzIdentity;
		this.manageSieveClient = new ManageSieveClient();
	}

	public void login() throws SieveException {
		logger.debug("login called");
		try {
			if (!this.manageSieveClient.connect(host, port).isOk()) {
				throw new SieveConnectionException();
			}
			ServerCapabilities capabilities = this.manageSieveClient.getCapabilities();
			
			if (capabilities.hasTLS()) {
				if (!this.manageSieveClient.starttls().isOk()) {
					throw new SieveConnectionException();
				}
			}
			if (!this.manageSieveClient.authenticate(this.authIdentity.getLogin(),
					this.authIdentity.getPassword().getStringValue(),
					this.autzIdentity.getLogin()).isOk()) {
				throw new SieveAuthException();
			}
		} catch (ParseException e) {
			throw new SieveParseException(e);
		} catch (SaslException e) {
			throw new SieveAuthException(e);
		} catch (IOException e) {
			throw new SieveException(e);
		}
	}

	public List<SieveScript> listscripts() throws SieveException {
		List<SieveScript> out = Lists.newArrayList();
		try {
			if (!this.manageSieveClient.listscripts(out).isOk()) {
				throw new SieveException();
			}
			return ImmutableList.copyOf(out);
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}

	}

	public void putscript(String name, String scriptContent) throws SieveException {
		try {
			if (!this.manageSieveClient.putscript(name, scriptContent).isOk()) {
				throw new SieveException();
			}
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}
	}

	public void unauthenticate() throws SieveException {
		try {
			this.manageSieveClient.logout();
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}
	}

	public Optional<SieveScript> getScriptContent(String name) throws SieveException {
		SieveScript out = new SieveScript();
		out.setName(name);
		ManageSieveResponse response;
		try {
			response = this.manageSieveClient.getScript(out);
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}
		return response.isOk() ? Optional.<SieveScript>of(out) : Optional.<SieveScript>absent();
	}

	public void activate(String name) throws SieveException {
		try {
			if (!this.manageSieveClient.setactive(name).isOk()) {
				throw new SieveException();
			}
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}
	}

	public boolean deletescript(String name) throws SieveException {
		try {
			return this.manageSieveClient.deletescript(name).isOk();
		} catch (IOException | ParseException e) {
			throw new SieveException(e);
		}
	}

}
