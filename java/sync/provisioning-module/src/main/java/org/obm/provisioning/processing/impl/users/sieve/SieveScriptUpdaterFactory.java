/* ***** BEGIN LICENSE BLOCK *****
 * Copyright (C) 2015  Linagora
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version, provided you comply with the Additional Terms applicable for OBM
 * software by Linagora pursuant to Section 7 of the GNU Affero General Public
 * License, subsections (b), (c), and (e), pursuant to which you must notably (i)
 * retain the displaying by the interactive user interfaces of the “OBM, Free
 * Communication by Linagora” Logo with the “You are using the Open Source and
 * free version of OBM developed and supported by Linagora. Contribute to OBM R&D
 * by subscribing to an Enterprise offer !” infobox, (ii) retain all hypertext
 * links between OBM and obm.org, between Linagora and linagora.com, as well as
 * between the expression “Enterprise offer” and pro.obm.org, and (iii) refrain
 * from infringing Linagora intellectual property rights over its trademarks and
 * commercial brands. Other Additional Terms apply, see
 * <http://www.linagora.com/licenses/> for more details.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
 * PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License and
 * its applicable Additional Terms for OBM along with this program. If not, see
 * <http://www.gnu.org/licenses/> for the GNU Affero General   Public License
 * version 3 and <http://www.linagora.com/licenses/> for the Additional Terms
 * applicable to the OBM software.
 * ***** END LICENSE BLOCK ***** */
package org.obm.provisioning.processing.impl.users.sieve;

import org.obm.imap.sieve.SieveClient;
import org.obm.imap.sieve.SieveException;

import com.google.inject.Inject;

import fr.aliacom.obm.common.system.ObmSystemUser;
import fr.aliacom.obm.common.user.ObmUser;

public class SieveScriptUpdaterFactory {

	private final SieveClientFactory sieveClientFactory;

	@Inject
	public SieveScriptUpdaterFactory(SieveClientFactory sieveClientFactory) {
		this.sieveClientFactory = sieveClientFactory;
	}

	public SieveScriptUpdater build(ObmSystemUser authUser, ObmUser autzUser) throws SieveException {
		SieveClient sieveClient = this.sieveClientFactory.build(authUser, autzUser);
		return new SieveScriptUpdater(autzUser, sieveClient,
				new SieveBuilder(autzUser));
	}
}
